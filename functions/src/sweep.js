'use strict';

const {
  DOCS_COLLECTION,
  SPENDS_COLLECTION,
  IN_PROGRESS_STATUSES,
  STALE_MS,
  SWEEP_BATCH,
} = require('./config');
const { sanitizeError } = require('./sanitize');
const { toMillis } = require('./util');
const {
  refundDoc,
  releaseGenerationLock,
  staleAfterMs,
  flagRefundReview,
} = require('./story');
const defaultCredits = require('./credits');

const { prepareSpendMark, SPEND_DELIVERED, SPEND_CLOSED_IN_ERROR } = defaultCredits;

function hasReadableText(data) {
  if (data.readyToRead === true) return true;
  return Array.isArray(data.description)
    && data.description.some((p) => typeof p === 'string' && p.trim());
}

// Un gasto en revision manual ya no lo devuelve ningun proceso. refundDoc lo
// refleja en su documento, pero por ahi no pasan ni un gasto que ya estaba en
// revision ni el que la conciliacion manda a revision: se marca aqui. Idempotente.
async function flagReviewOnDoc(db, spendId, spend, docData) {
  if (!docData || docData.status !== 'error') return;
  const generation = docData.generation || {};
  if (generation.spendId !== spendId || generation.refunded === true) return;
  if (generation.refundState === 'needs_review') return;
  if (spend.uid && docData.uId && docData.uId !== spend.uid) return;
  await flagRefundReview(db.collection(DOCS_COLLECTION).doc(spend.docId));
}

// Portado del watchdog de Railway (sapere-backend/src/watchdog.js), ahora como
// funcion programada. Dos trabajos:
//   1) documentos atascados en pending/generating_* -> 'error' + reembolso, o
//      'completed' parcial si ya tienen texto legible (el watchdog original
//      tampoco tocaba lo ya producido: `if (data.bukbukUrl) continue;`). Lo que
//      solo espera turno en la cola de Cloud Tasks se mide con QUEUE_STALE_MS.
//   2) conciliacion de creditSpends: la fuente de verdad del cobro es esa
//      coleccion (el cliente no la puede escribir), no los campos del documento.
async function sweepStalledDocs(db, { now = Date.now(), credits = defaultCredits } = {}) {
  const limit = now - STALE_MS;
  const result = { marked: 0, closed: 0, refunded: 0, settled: 0, checked: 0, errors: 0 };
  // Gastos cuyo reembolso ya se intento en esta pasada: la conciliacion no gasta
  // un segundo intento del mismo gasto en la misma invocacion.
  const refundTried = new Set();

  let stuck = { docs: [] };
  try {
    stuck = await db
      .collection(DOCS_COLLECTION)
      .where('status', 'in', IN_PROGRESS_STATUSES)
      .limit(SWEEP_BATCH)
      .get();
  } catch (error) {
    result.errors += 1;
    console.error(`[sweep] no se pudieron listar los documentos en curso: ${sanitizeError(error)}`);
  }

  for (const doc of stuck.docs) {
    result.checked += 1;
    try {
      // Se relee dentro de la transaccion: el snapshot de la consulta puede
      // tener minutos y la tarea haber terminado entre medias.
      const outcome = await db.runTransaction(async (tx) => {
        const fresh = await tx.get(doc.ref);
        if (!fresh.exists) return { action: 'gone' };
        const data = fresh.data();
        if (!IN_PROGRESS_STATUSES.includes(data.status)) return { action: 'moved' };
        const staleMs = staleAfterMs(data);
        const last = Math.max(toMillis(data.updatedAt), toMillis(data.publishTime));
        if (last === 0 || last > now - staleMs) return { action: 'alive' };

        // Constancia en el gasto de como se cerro: si el dueno borra despues el
        // documento, la conciliacion sabe si liquidar o devolver.
        const readable = hasReadableText(data);
        const markSpend = await prepareSpendMark(
          tx,
          db,
          (data.generation || {}).spendId,
          readable ? SPEND_DELIVERED : SPEND_CLOSED_IN_ERROR,
          { uid: data.uId, docId: doc.id },
        );

        const stamp = new Date(now);
        if (readable) {
          tx.update(doc.ref, {
            status: 'completed',
            readyToRead: true,
            errorMessage: `parcial: la generacion no termino (ultimo estado: ${data.status})`,
            'generation.finishedAt': stamp,
            updatedAt: stamp,
          });
          if (markSpend) markSpend();
          return { action: 'closed', data };
        }
        tx.update(doc.ref, {
          status: 'error',
          errorMessage: `La generacion no termino en ${Math.round(staleMs / 60000)} minutos (ultimo estado: ${data.status})`,
          'generation.finishedAt': stamp,
          updatedAt: stamp,
        });
        if (markSpend) markSpend();
        return { action: 'marked', data };
      });

      if (outcome.action === 'closed') {
        result.closed += 1;
        const spendId = (outcome.data.generation || {}).spendId;
        // El usuario ya tiene texto: el gasto se liquida, no se devuelve.
        if (spendId) {
          const settle = await credits.settleSpend(db, spendId);
          if (settle.settled) result.settled += 1;
        }
        await releaseGenerationLock(db, outcome.data.uId, doc.id).catch(() => {});
        console.log(`[sweep] ${doc.id} cerrado como completado parcial (atascado en ${outcome.data.status})`);
      } else if (outcome.action === 'marked') {
        result.marked += 1;
        console.log(`[sweep] ${doc.id} marcado como error (atascado en ${outcome.data.status})`);
        const spendId = (outcome.data.generation || {}).spendId;
        if (spendId) refundTried.add(spendId);
        try {
          const refund = await refundDoc(db, doc.id, credits);
          if (refund.refunded) result.refunded += 1;
        } finally {
          // Si el reembolso falla lo reintenta una pasada posterior; el cerrojo
          // se suelta igualmente.
          await releaseGenerationLock(db, outcome.data.uId, doc.id).catch(() => {});
        }
      }
    } catch (error) {
      result.errors += 1;
      console.error(`[sweep] ${doc.id}: ${sanitizeError(error)}`);
    }
  }

  let spends;
  try {
    spends = await db
      .collection(SPENDS_COLLECTION)
      .where('settled', '==', false)
      .where('refunded', '==', false)
      .limit(SWEEP_BATCH)
      .get();
  } catch (error) {
    result.errors += 1;
    console.error(`[sweep] no se pudieron listar los gastos pendientes: ${sanitizeError(error)}`);
    return result;
  }

  for (const spendDoc of spends.docs) {
    result.checked += 1;
    const spend = spendDoc.data();
    const created = toMillis(spend.createdAt);
    if (!created || created > limit) continue;
    if (refundTried.has(spendDoc.id)) continue;

    try {
      const docSnap = spend.docId
        ? await db.collection(DOCS_COLLECTION).doc(spend.docId).get()
        : null;
      const docData = docSnap && docSnap.exists ? docSnap.data() : null;

      if (spend.refundState === 'needs_review') {
        await flagReviewOnDoc(db, spendDoc.id, spend, docData);
        continue;
      }
      if (docData && IN_PROGRESS_STATUSES.includes(docData.status)) continue;

      if (docData && docData.status === 'completed') {
        const settle = await credits.settleSpend(db, spendDoc.id);
        if (settle.settled) result.settled += 1;
        continue;
      }

      // Documento inexistente con marca de entrega: el dueno lo borro despues de
      // tener texto legible, asi que se liquida. Si el servidor lo cerro en
      // 'error' (la app borra el fallido al pulsar Reintentar) se devuelve.
      if (!docData && spend[SPEND_DELIVERED] && !spend[SPEND_CLOSED_IN_ERROR]) {
        const settle = await credits.settleSpend(db, spendDoc.id);
        if (settle.settled) result.settled += 1;
        console.log(`[sweep] gasto ${spendDoc.id}: documento borrado despues de la entrega, se liquida`);
        continue;
      }

      // Documento en error o inexistente (fallo entre el cobro y la creacion,
      // o borrado sin haber entregado texto).
      if (spend.applied !== true) {
        // Nunca se confirmo el cargo: devolverlo a ciegas podria regalar un credito.
        await spendDoc.ref.update({ refundState: 'needs_review' });
        await flagReviewOnDoc(db, spendDoc.id, spend, docData);
        console.warn(`[sweep] gasto ${spendDoc.id} sin cargo confirmado: queda para revision manual`);
        continue;
      }

      const refund = docData
        ? await refundDoc(db, spend.docId, credits)
        : await credits.refundSpend(db, spendDoc.id, {}, { uid: spend.uid, docId: spend.docId });
      if (refund.refunded) {
        result.refunded += 1;
        console.log(`[sweep] gasto ${spendDoc.id}: credito reembolsado a posteriori`);
      }
    } catch (error) {
      result.errors += 1;
      console.error(`[sweep] gasto ${spendDoc.id}: ${sanitizeError(error)}`);
    }
  }

  return result;
}

module.exports = { sweepStalledDocs, hasReadableText };
