'use strict';

const { randomUUID } = require('node:crypto');
const { FieldValue } = require('firebase-admin/firestore');
const { SPENDS_COLLECTION, USERS_COLLECTION } = require('./config');
const { sanitizeError } = require('./sanitize');
const { toMillis } = require('./util');
const defaultRevenuecat = require('./revenuecat');

// Portado de sapere-backend/src/credits.js.
// Orden de cobro: 1) moneda virtual de RevenueCat, 2) reserva heredada en users/{uid}.credits.
// Cada gasto deja un documento en 'creditSpends', la UNICA fuente de verdad del
// cobro: el cliente no puede escribir ahi (firestore.rules), asi que ni el saldo
// ni el reembolso dependen de lo que diga el documento de /sapere.
//
// Ciclo de vida de creditSpends/{id}:
//   applied:false  -> recibo escrito ANTES de tocar el saldo (nunca hay cargo sin recibo)
//   applied:true   -> el cargo se aplico de verdad
//   settled:true   -> la generacion se entrego: ya no se puede reembolsar
//   refunded:true  -> el credito se devolvio (una sola vez)
//   refundState    -> 'pending' | 'in_flight' | 'done' | 'needs_review'
//   refundKey      -> Idempotency-Key del +1 en RevenueCat, la misma en todos los intentos
//   deliveredAt    -> el usuario ya tuvo texto legible (misma transaccion que la
//                     seccion que lo escribio)
//   closedInErrorAt-> el servidor (tarea o barrido) cerro el documento en 'error'
// Las dos marcas deciden la conciliacion cuando el documento ya no existe: el
// dueno puede borrarlo despues de leerlo, y la app borra el fallido al reintentar.
//
// A diferencia de la ruta HTTP antigua no hay ventana de 15 min: el reembolso lo
// dispara el servidor (tarea o barrido) y el barrido corre a los 30 min. Por eso
// el reintento es automatico y perpetuo, y hay que acotarlo: si el ajuste de
// saldo falla (la respuesta se pudo perder DESPUES de aplicarse) solo se
// reintenta MAX_REFUND_ATTEMPTS veces, separadas al menos REFUND_RETRY_MS, y
// luego el gasto queda para revision manual, en vez de regalar un credito en
// cada pasada del barrido. Todos los intentos llevan la misma Idempotency-Key
// (RevenueCat no aplica el +1 dos veces) y un rechazo de una incidencia de
// RevenueCat no gasta intento, porque no aplico nada.

const SPEND_DELIVERED = 'deliveredAt';
const SPEND_CLOSED_IN_ERROR = 'closedInErrorAt';

const MAX_REFUND_ATTEMPTS = 2;
// Una devolucion en vuelo bloquea a las demas durante este tiempo: dos pasadas
// del barrido no pueden ajustar el saldo a la vez por el mismo gasto.
const REFUND_IN_FLIGHT_MS = 2 * 60 * 1000;
// Espera minima desde el ultimo intento de devolucion: un fallo breve de
// RevenueCat no agota los intentos (dos pasadas seguidas del barrido, o la
// tarea y el barrido a los pocos minutos).
const REFUND_RETRY_MS = 10 * 60 * 1000;
// Rechazos de una incidencia (clave rotada o sin permisos, limite de peticiones,
// caida) que se resuelven solos y no pueden ser la respuesta a un intento anterior
// con la misma clave. Otro 4xx no se arregla solo o puede venir de esa clave
// repetida (RevenueCat no documenta que contesta), y un 500/502/504 pudo llegar
// despues de aplicar el ajuste: esos si gastan intento.
const TRANSIENT_REJECTIONS = [401, 403, 429, 503];

// RevenueCat contesto sin ejecutar la transaccion: un 4xx (422 si el saldo no
// llega) o un 503 (no habia servidor que la atendiera). Un timeout, un error de
// red o un 500/502/504 no dicen si se aplico.
function notApplied(error) {
  const status = error && error.status;
  return status === 503 || (Number.isInteger(status) && status >= 400 && status < 500);
}

class CreditError extends Error {
  constructor(code, message) {
    super(message || code);
    this.code = code;
  }
}

function toCredits(value) {
  const n = Math.trunc(Number(value));
  return Number.isFinite(n) ? Math.max(0, n) : 0;
}

async function legacyCredits(db, uid) {
  const snap = await db.collection(USERS_COLLECTION).doc(uid).get();
  return snap.exists ? toCredits(snap.data().credits) : 0;
}

async function legacyAdjust(db, uid, delta) {
  const docRef = db.collection(USERS_COLLECTION).doc(uid);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(docRef);
    if (!snap.exists) return null;
    const current = toCredits(snap.data().credits);
    const next = current + delta;
    if (next < 0) return null;
    tx.update(docRef, { credits: next });
    return next;
  });
}

// Si RevenueCat no responde, la reserva heredada se sigue pudiendo leer: se
// devuelve con revenuecatAvailable:false en vez de fallar entero.
async function getBalances(db, uid, deps = {}) {
  const rc = deps.revenuecat || defaultRevenuecat;
  const enabled = rc.isEnabled();
  const [rcResult, legacyResult] = await Promise.allSettled([
    enabled ? rc.getBalance(uid) : 0,
    legacyCredits(db, uid),
  ]);
  if (legacyResult.status === 'rejected') throw legacyResult.reason;
  const legacy = legacyResult.value;
  const revenuecatAvailable = rcResult.status === 'fulfilled';
  if (!revenuecatAvailable) {
    console.warn(`[credits] RevenueCat no respondio al leer el saldo de ${uid}: ${sanitizeError(rcResult.reason)}`);
  }
  const revenuecat = revenuecatAvailable ? rcResult.value : 0;
  return { revenuecat, legacy, total: revenuecat + legacy, revenuecatEnabled: enabled, revenuecatAvailable };
}

// Saldo para una respuesta que no puede esperar: null si falla o no llega a tiempo.
async function getBalancesWithin(db, uid, timeoutMs, deps = {}) {
  let timer;
  const late = new Promise((resolve) => {
    timer = setTimeout(() => resolve(null), timeoutMs);
  });
  try {
    return await Promise.race([getBalances(db, uid, deps).catch(() => null), late]);
  } finally {
    clearTimeout(timer);
  }
}

// Cobra 1 credito. Devuelve { source, balance, spendId } o lanza CreditError('insufficient_credits').
//
// El recibo se escribe ANTES del cargo (con la fuente ya decidida) para que no
// pueda existir un cargo sin documento de gasto: un cargo huerfano no lo puede
// encontrar ni la tarea, ni el barrido, ni ninguna callable.
async function spendCredit(db, uid, deps = {}, meta = {}) {
  const rc = deps.revenuecat || defaultRevenuecat;

  // 1) Decidir de donde se cobra SIN tocar todavia ningun saldo.
  let intended = null;
  let revenuecatBalance = 0;
  let revenuecatError = null;
  if (rc.isEnabled()) {
    try {
      revenuecatBalance = await rc.getBalance(uid);
    } catch (error) {
      // 401, 5xx, red o timeout (el 404 ya cuenta como saldo 0): no se sabe el
      // saldo de RevenueCat, pero la reserva heredada si se puede cobrar.
      revenuecatError = error;
    }
    if (revenuecatBalance >= 1) intended = 'revenuecat';
  }
  if (!intended) {
    const legacy = await legacyCredits(db, uid);
    if (legacy >= 1) intended = 'legacy';
  }
  if (!intended) {
    // Sin saber el saldo de RevenueCat no se puede decir que no tenga creditos.
    if (revenuecatError) throw revenuecatError;
    throw new CreditError('insufficient_credits');
  }
  if (revenuecatError) {
    console.warn(
      `[credits] RevenueCat no respondio al leer el saldo de ${uid}; se cobra de la reserva heredada: `
      + sanitizeError(revenuecatError),
    );
  }

  // 2) Recibo primero: si el cargo se aplica y luego se cae la red, el gasto
  //    existe y es reembolsable.
  const spendRef = db.collection(SPENDS_COLLECTION).doc();
  await spendRef.set({
    uid,
    source: intended,
    docId: meta.docId || null,
    applied: false,
    chargeState: 'pending',
    settled: false,
    refunded: false,
    refundState: 'pending',
    refundAttempts: 0,
    createdAt: FieldValue.serverTimestamp(),
  });

  // 3) Cargo.
  let balance = 0;
  try {
    if (intended === 'revenuecat') {
      await rc.adjustBalance(uid, -1);
      balance = revenuecatBalance - 1;
    } else {
      const next = await legacyAdjust(db, uid, -1);
      if (next === null) {
        // Otra llamada se llevo el ultimo credito entre la lectura y la
        // transaccion: no se cobro nada, el recibo sobra.
        await spendRef.delete().catch(() => {});
        throw new CreditError('insufficient_credits');
      }
      balance = next;
    }
  } catch (error) {
    if (error instanceof CreditError) throw error;
    if (intended === 'revenuecat' && notApplied(error)) {
      // RevenueCat no desconto nada: el recibo sobra. Un 422 es que otro cobro se
      // llevo el saldo entre la lectura y el ajuste (las apps antiguas cobran por
      // Railway, sin este cerrojo).
      await spendRef.delete().catch(() => {});
      if (error.status === 422) throw new CreditError('insufficient_credits');
      throw error;
    }
    // Respuesta perdida (timeout, red, 500/502/504): el -1 pudo aplicarse igualmente.
    // Releer un saldo de exactamente uno menos lo confirma. Otro valor (una compra o
    // un reembolso entre medias, un ajuste que aun no se ve) no prueba nada.
    const expected = revenuecatBalance - 1;
    const landed = intended === 'revenuecat'
      && await Promise.resolve()
        .then(() => rc.getBalance(uid))
        .then((current) => current === expected, () => false);
    if (!landed) {
      // El ajuste pudo aplicarse o no: no se borra el recibo ni se reembolsa a
      // ciegas, se marca para revision.
      await spendRef
        .update({
          chargeState: 'unknown',
          refundState: 'needs_review',
          lastError: sanitizeError(error),
        })
        .catch(() => {});
      console.error(`[credits] cobro dudoso para ${uid} (gasto ${spendRef.id}):`, sanitizeError(error));
      throw error;
    }
    console.warn(`[credits] el saldo releido confirma el cobro de ${uid} (gasto ${spendRef.id}): ${sanitizeError(error)}`);
    balance = expected;
  }

  await spendRef
    .update({ applied: true, chargeState: 'applied', balanceAfter: balance })
    .catch((error) => {
      console.error(`[credits] no se pudo confirmar el recibo ${spendRef.id}:`, sanitizeError(error));
    });

  console.log(`[credits] credito cobrado (${intended}) para ${uid}: saldo ${balance}, gasto ${spendRef.id}`);
  return { source: intended, balance, spendId: spendRef.id };
}

// Cierra el gasto: la generacion se entrego, ya no se puede reembolsar.
// Es la segunda barrera contra un cliente que mienta en el documento de /sapere
// para provocar un reembolso de algo que si recibio.
async function settleSpend(db, spendId) {
  if (!spendId || typeof spendId !== 'string') return { settled: false, reason: 'no_spend_id' };
  const spendRef = db.collection(SPENDS_COLLECTION).doc(spendId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(spendRef);
    if (!snap.exists) return { settled: false, reason: 'not_found' };
    const data = snap.data();
    if (data.refunded === true) return { settled: false, reason: 'already_refunded' };
    if (data.settled === true) return { settled: true, reason: 'already_settled' };
    tx.update(spendRef, { settled: true, settledAt: FieldValue.serverTimestamp() });
    return { settled: true };
  });
}

// Marca de entrega o de cierre en error sobre el gasto de un documento, dentro
// de la MISMA transaccion que escribe el documento. Hace la lectura del gasto
// (en una transaccion las lecturas van antes que las escrituras) y devuelve la
// escritura pendiente, o null si no hay nada que marcar.
async function prepareSpendMark(tx, db, spendId, field, expect = {}) {
  if (!spendId || typeof spendId !== 'string') return null;
  const spendRef = db.collection(SPENDS_COLLECTION).doc(spendId);
  const snap = await tx.get(spendRef);
  if (!snap.exists) return null;
  const data = snap.data();
  if (expect.uid && data.uid && data.uid !== expect.uid) return null;
  if (expect.docId && data.docId && data.docId !== expect.docId) return null;
  if (data[field]) return null;
  return () => tx.update(spendRef, { [field]: FieldValue.serverTimestamp() });
}

// Devuelve el credito de un gasto. Idempotente: la transaccion sobre el
// documento de gasto impide reembolsar dos veces aunque la tarea se reintente.
//
// `expect` ata el gasto a su dueno y a su documento: un cliente que apunte
// generation.spendId al gasto de otro usuario no consigue nada.
async function refundSpend(db, spendId, deps = {}, expect = {}) {
  if (!spendId || typeof spendId !== 'string') return { refunded: false, reason: 'no_spend_id' };
  const rc = deps.revenuecat || defaultRevenuecat;
  const spendRef = db.collection(SPENDS_COLLECTION).doc(spendId);
  const now = Date.now();

  const outcome = await db.runTransaction(async (tx) => {
    const snap = await tx.get(spendRef);
    if (!snap.exists) return { reason: 'not_found' };
    const data = snap.data();

    if (expect.uid && data.uid && data.uid !== expect.uid) return { reason: 'uid_mismatch' };
    if (expect.docId && data.docId && data.docId !== expect.docId) return { reason: 'doc_mismatch' };

    if (data.refunded === true) return { reason: 'already_refunded' };
    if (data.settled === true) return { reason: 'already_settled' };
    if (data.refundState === 'needs_review') return { reason: 'needs_review' };

    const startedAt = toMillis(data.refundStartedAt);
    if (data.refundState === 'in_flight' && startedAt && now - startedAt < REFUND_IN_FLIGHT_MS) {
      return { reason: 'in_flight' };
    }
    const lastAttemptAt = toMillis(data.lastRefundAttemptAt);
    if (lastAttemptAt && now - lastAttemptAt < REFUND_RETRY_MS) return { reason: 'retry_later' };

    const attempts = Number(data.refundAttempts || 0);
    if (attempts >= MAX_REFUND_ATTEMPTS) {
      tx.update(spendRef, { refundState: 'needs_review' });
      return { reason: 'needs_review' };
    }

    const refundKey = data.refundKey || randomUUID();
    tx.update(spendRef, {
      refundState: 'in_flight',
      refundAttempts: attempts + 1,
      refundKey,
      refundStartedAt: FieldValue.serverTimestamp(),
      lastRefundAttemptAt: FieldValue.serverTimestamp(),
    });
    return { source: data.source, uid: data.uid, attempts: attempts + 1, refundKey };
  });

  if (outcome.reason) return { refunded: false, reason: outcome.reason };

  try {
    if (outcome.source === 'revenuecat') {
      await rc.adjustBalance(outcome.uid, 1, { idempotencyKey: outcome.refundKey });
    } else {
      const balance = await legacyAdjust(db, outcome.uid, 1);
      if (balance === null) throw new Error('user document missing');
    }
  } catch (error) {
    // El ajuste pudo haberse aplicado antes de perderse la respuesta: no se
    // vuelve a 'pending' sin limite. Al agotar los intentos el gasto queda para
    // revision manual y ninguna pasada del barrido lo vuelve a tocar. Un rechazo
    // de una incidencia de RevenueCat no aplico nada: no gasta intento.
    const rejected = outcome.source === 'revenuecat' && TRANSIENT_REJECTIONS.includes(error.status);
    const attempts = rejected ? outcome.attempts - 1 : outcome.attempts;
    const exhausted = attempts >= MAX_REFUND_ATTEMPTS;
    await spendRef
      .update({
        refundState: exhausted ? 'needs_review' : 'pending',
        refundAttempts: attempts,
        refundStartedAt: null,
        lastError: sanitizeError(error),
      })
      .catch(() => {});
    console.error('[credits] fallo el reembolso:', sanitizeError(error));
    throw error;
  }

  await spendRef.update({
    refunded: true,
    refundState: 'done',
    refundedAt: FieldValue.serverTimestamp(),
  });

  console.log(`[credits] credito reembolsado (${outcome.source}) para ${outcome.uid}: gasto ${spendId}`);
  return { refunded: true, source: outcome.source, uid: outcome.uid };
}

module.exports = {
  CreditError,
  SPEND_DELIVERED,
  SPEND_CLOSED_IN_ERROR,
  MAX_REFUND_ATTEMPTS,
  REFUND_IN_FLIGHT_MS,
  REFUND_RETRY_MS,
  toCredits,
  legacyCredits,
  legacyAdjust,
  getBalances,
  getBalancesWithin,
  spendCredit,
  settleSpend,
  prepareSpendMark,
  refundSpend,
};
