'use strict';

const {
  DOCS_COLLECTION,
  SPENDS_COLLECTION,
  LOCKS_COLLECTION,
  IN_PROGRESS_STATUSES,
  ACTIVE_LOCK_MS,
  STALE_MS,
  QUEUE_STALE_MS,
  QUEUE_ACTIVE_MS,
  OUTLINE_MIN_SECTIONS,
  DEADLINE_GUARD_MS,
  CLOSE_MARGIN_MS,
  COVER_WAIT_MS,
  generationPlan,
  secrets,
} = require('./config');
const { sanitizeError } = require('./sanitize');
const { toMillis } = require('./util');
const { buildVisualPrompt } = require('./prompts');
const docugen = require('./docugen');
const defaultText = require('./text');
const defaultCover = require('./cover');
const defaultStorage = require('./storage');
const defaultCredits = require('./credits');

const { prepareSpendMark, SPEND_DELIVERED, SPEND_CLOSED_IN_ERROR } = defaultCredits;

const TEXT_PROVIDER = 'docugen';

// Orden de estados: nunca retrocedemos. La portada corre en paralelo con el
// guion, asi que ninguna escritura puede devolver el documento a un estado
// anterior. 'error' es terminal: lo pone la propia tarea al rendirse o el
// barrido, y en ambos casos va seguido de un reembolso, asi que nada puede
// sacarlo de ahi (entregar el documental despues seria regalarlo).
const STATUS_RANK = {
  pending: 0,
  generating_title: 1,
  generating_script: 2,
  error: 3,
  completed: 4,
};

const COVER_TIMED_OUT = Symbol('cover_timed_out');

class TerminatedError extends Error {
  constructor(reason) {
    super(`El documento lo cerro otro proceso (${reason})`);
    this.code = 'terminated';
    this.reason = reason;
  }
}

// Lo unico que admite un documento 'completed': la portada, que corre en
// paralelo con el guion y puede llegar despues de cerrarlo.
const LATE_COVER_FIELDS = ['newCover', 'generation.coverProvider'];

// Escritura guardada: relee el documento en una transaccion y no toca nada si
// ya esta en 'error' o reembolsado. Un 'completed' ya se entrego: una ejecucion
// duplicada o tardia de la tarea no puede truncarlo ni dejarlo esperando
// reintento. Con `status` null solo escribe `extra`.
// Con `spendMark` (SPEND_DELIVERED o SPEND_CLOSED_IN_ERROR) deja esa marca en el
// gasto del documento dentro de la misma transaccion.
// Devuelve { applied, reason?, status? }.
async function advanceStatus(db, docRef, status, extra = {}, { spendMark = null } = {}) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(docRef);
    if (!snap.exists) return { applied: false, reason: 'not_found' };
    const data = snap.data();
    if (data.status === 'error') return { applied: false, reason: 'terminal' };
    if ((data.generation || {}).refunded === true) return { applied: false, reason: 'refunded' };
    if (data.status === 'completed') {
      const fields = Object.keys(extra);
      const lateCover = !status && fields.length > 0 && fields.every((field) => LATE_COVER_FIELDS.includes(field));
      if (!lateCover) return { applied: false, reason: 'completed' };
    }

    const markSpend = spendMark
      ? await prepareSpendMark(tx, db, (data.generation || {}).spendId, spendMark, { uid: data.uId, docId: docRef.id })
      : null;

    const payload = { ...extra, updatedAt: new Date() };
    if (status) {
      const currentRank = STATUS_RANK[data.status] === undefined ? -1 : STATUS_RANK[data.status];
      const nextRank = STATUS_RANK[status] === undefined ? 0 : STATUS_RANK[status];
      if (nextRank >= currentRank) payload.status = status;
    }
    tx.update(docRef, payload);
    if (markSpend) markSpend();
    return { applied: true, status: payload.status || data.status };
  });
}

// Un documento en la cola de Cloud Tasks (aun sin despachar, o esperando su
// reintento) no escribe latidos: no esta atascado, espera turno.
function isQueued(data = {}) {
  const generation = data.generation || {};
  if (generation.awaitingRetry === true) return true;
  return data.status === 'pending' && !generation.attemptStartedAt;
}

// Tiempo sin latido tras el que el barrido da por atascado un documento en curso.
function staleAfterMs(data) {
  return isQueued(data) ? QUEUE_STALE_MS : STALE_MS;
}

// Bloqueo blando: un usuario no puede lanzar dos generaciones a la vez.
// Si la consulta falla (indice ausente) no bloqueamos al usuario: se registra y
// se deja pasar; el cerrojo de generationLocks es la barrera de verdad.
async function hasActiveGeneration(db, uid, now = Date.now()) {
  let snap;
  try {
    snap = await db
      .collection(DOCS_COLLECTION)
      .where('uId', '==', uid)
      .where('status', 'in', IN_PROGRESS_STATUSES)
      .get();
  } catch (error) {
    console.error(`[story] no se pudo comprobar si ${uid} ya esta generando: ${sanitizeError(error)}`);
    return false;
  }
  return snap.docs.some((doc) => {
    const data = doc.data();
    const last = Math.max(toMillis(data.updatedAt), toMillis(data.publishTime));
    const activeMs = isQueued(data) ? QUEUE_ACTIVE_MS : ACTIVE_LOCK_MS;
    return last === 0 || last > now - activeMs;
  });
}

// Cerrojo real por usuario: transaccion sobre generationLocks/{uid}. Dos
// llamadas simultaneas a startStory no pueden pasar las dos (la consulta de
// hasActiveGeneration no es atomica y dejaba cobrar dos veces).
async function acquireGenerationLock(db, uid, docId, now = Date.now()) {
  const lockRef = db.collection(LOCKS_COLLECTION).doc(uid);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(lockRef);
    if (snap.exists) {
      const lock = snap.data();
      const heldAt = toMillis(lock.acquiredAt);
      if (lock.docId && lock.docId !== docId && heldAt && now - heldAt < ACTIVE_LOCK_MS) return false;
    }
    tx.set(lockRef, { uid, docId, acquiredAt: new Date(now) });
    return true;
  });
}

// Suelta el cerrojo solo si sigue siendo de ese documento.
async function releaseGenerationLock(db, uid, docId) {
  if (!uid || !docId) return false;
  const lockRef = db.collection(LOCKS_COLLECTION).doc(uid);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(lockRef);
    if (!snap.exists || snap.data().docId !== docId) return false;
    tx.delete(lockRef);
    return true;
  });
}

function buildInitialDoc({
  uid,
  docId,
  prompt,
  genre,
  type,
  language,
  languageCode,
  coverUrl,
  chapters,
  durationMinutes,
  bukbukId,
  bukbukCategoryId,
  bukbukTypeNames,
  bukbukCategoryNames,
  gamificationSubject,
  gamificationEpisode,
  spendId,
  framework,
  provisionalTitle,
}) {
  const now = new Date();
  return {
    uId: uid,
    postId: docId,
    type,
    bukbukName: '',
    // Titulo que manda la app: lo muestra mientras bukbukName esta vacio (en cola o
    // si falla antes del definitivo) y es el respaldo si el Space no da titulo.
    provisionalTitle: provisionalTitle || '',
    // Ya no hay audio de servidor: la voz la pone el lector bimodal del dispositivo.
    bukbukUrl: '',
    description: [],
    newCover: coverUrl || '',
    coverImage: '',
    language: language || '',
    languageCode,
    bukbukId: bukbukId || '',
    bukbukCategoryId: bukbukCategoryId || '',
    bukbukTypeNames: bukbukTypeNames || {},
    bukbukCategoryNames: bukbukCategoryNames || {},
    prompt,
    genre: genre || '',
    ...(gamificationSubject ? { gamificationSubject } : {}),
    ...(gamificationEpisode !== undefined && gamificationEpisode !== null
      ? { gamificationEpisode }
      : {}),
    publishTime: now,
    updatedAt: now,
    status: 'pending',
    errorMessage: null,
    readyToRead: false,
    chaptersMeta: [],
    generation: {
      engine: 'firebase',
      textProvider: null,
      coverProvider: coverUrl ? 'user' : null,
      chapters,
      durationMinutes: durationMinutes || null,
      spendId: spendId || null,
      refunded: false,
      startedAt: now,
      finishedAt: null,
      // Marco del tipo o persona de gamificacion, fijado por el SERVIDOR al
      // crear el documento: un reintento sigue con el mismo. Vacio si no hay.
      systemPrompt: framework || '',
    },
  };
}

// Portada: OpenAI -> Pollinations con un prompt visual de titulo + tema. No pasa
// por el Space, asi que corre en paralelo con el guion.
async function runCoverTrack({ db, docRef, bucket, docId, data, title, deps }) {
  const cover = deps.cover || defaultCover;
  const storage = deps.storage || defaultStorage;
  const generation = data.generation || {};

  if (data.newCover) {
    if (!generation.coverProvider) await advanceStatus(db, docRef, null, { 'generation.coverProvider': 'user' });
    return { coverProvider: generation.coverProvider || 'user' };
  }

  const image = await cover.generateCover(buildVisualPrompt({ title, prompt: data.prompt }));
  const url = await storage.uploadCover(bucket, docId, image.buffer, image.contentType);
  await advanceStatus(db, docRef, null, {
    newCover: url,
    'generation.coverProvider': image.provider,
  });
  return { coverProvider: image.provider, newCover: url };
}

// La portada corre en paralelo con el guion y nunca rechaza. Al cerrar se espera
// como mucho waitMs, y nunca mas alla del plazo de la invocacion menos la reserva
// del desenlace: si no ha llegado, el documento se cierra sin ella.
async function waitForCover(ctx, waitMs, now) {
  if (!ctx.shared.cover) return;
  const budget = Math.max(0, ctx.deadline ? Math.min(waitMs, ctx.deadline - now() - CLOSE_MARGIN_MS) : waitMs);
  let timer;
  const timeout = new Promise((resolve) => {
    timer = setTimeout(resolve, budget, COVER_TIMED_OUT);
  });
  const outcome = await Promise.race([ctx.shared.cover, timeout]);
  clearTimeout(timer);
  if (outcome === COVER_TIMED_OUT) {
    console.warn(`[story] ${ctx.docId}: la portada no llego en ${Math.round(budget / 1000)} s; se cierra el documento sin esperarla`);
  }
}

// Pista A: identidad. Titulo y escaleta pasan por el Space, que atiende una
// generacion cada vez: van en serie y ANTES del guion. La portada arranca en
// cuanto hay titulo y queda en ctx.shared.cover (nunca rechaza).
async function runIdentityTrack(ctx) {
  const { db, docRef, docId, data, shared, client, plan, area, language, resumed } = ctx;

  let title = typeof data.bukbukName === 'string' ? data.bukbukName.trim() : '';
  if (!title) {
    try {
      title = await client.generateTitle({ topic: data.prompt, area, language });
    } catch (error) {
      // Un fatal (DeepSeek sin saldo, sin acceso al Space) no tiene arreglo: ni
      // titulo de respaldo ni portada para un documento que acabara en 'error'.
      if (docugen.isFatal(error)) throw error;
      // Respaldo: el titulo provisional de la app y, si no lo hay, el tema recortado.
      // Un provisional acabado en '...' es el tema que la app corta a 37 caracteres
      // (titleFromPrompt): fallbackTitle lo corta mejor, a 60 y entre palabras.
      const provisional = /(\.\.\.|…)\s*$/.test(String(data.provisionalTitle || ''))
        ? ''
        : docugen.cleanTitle(data.provisionalTitle);
      title = provisional || docugen.fallbackTitle(data.prompt);
      console.warn(
        `[story] ${docId}: titulo del Space fallido, se usa ${provisional ? 'el provisional de la app' : 'el tema'}: `
        + sanitizeError(error),
      );
    }
    const titled = await advanceStatus(db, docRef, 'generating_title', {
      bukbukName: title,
      'generation.area': area,
    });
    if (!titled.applied) throw new TerminatedError(titled.reason);
  }
  shared.title = title;
  shared.cover = runCoverTrack({ ...ctx, title }).catch((error) => {
    console.warn(`[story] ${docId}: pista de portada fallida: ${sanitizeError(error)}`);
    return null;
  });

  // La escaleta se pide una vez y se guarda: los reintentos la reutilizan. Si ya
  // hay secciones escritas sin escaleta no se pide (el resto no cuadraria).
  let outline = typeof data.outline === 'string' ? data.outline.trim() : '';
  if (!outline && plan.sections >= OUTLINE_MIN_SECTIONS && resumed.chaptersMeta.length === 0) {
    try {
      ({ outline } = await client.generateOutline({
        topic: data.prompt,
        area,
        language,
        durationMinutes: plan.durationMinutes,
      }));
    } catch (error) {
      if (docugen.isFatal(error)) throw error;
      outline = '';
      console.warn(`[story] ${docId}: sin escaleta, se sigue sin ella: ${sanitizeError(error)}`);
    }
    if (outline) {
      const saved = await advanceStatus(db, docRef, null, { outline });
      if (!saved.applied) throw new TerminatedError(saved.reason);
    }
  }
  return { title, outline };
}

// Lo ya escrito por un intento anterior (Cloud Tasks reintenta): se continua
// desde ahi. Cada seccion guarda su texto bruto en chaptersMeta[i].raw para
// reenviarlo como historial; los documentos anteriores a este formato lo
// reconstruyen con sus parrafos.
function resumeState(data, total) {
  const written = Array.isArray(data.description)
    ? data.description.filter((p) => typeof p === 'string' && p.trim())
    : [];
  if (!written.length) return { paragraphs: [], chaptersMeta: [] };

  const meta = Array.isArray(data.chaptersMeta)
    ? data.chaptersMeta.filter((m) => m && typeof m === 'object').slice(0, total)
    : [];
  if (!meta.length) {
    return {
      paragraphs: written,
      chaptersMeta: [{ index: 0, title: 'Sección 1', paragraphs: written.length, raw: written.join('\n\n') }],
    };
  }

  let offset = 0;
  const chaptersMeta = meta.map((m, i) => {
    const count = Math.max(0, Math.trunc(Number(m.paragraphs)) || 0);
    const own = written.slice(offset, offset + count);
    offset += count;
    return {
      ...m,
      index: Number.isInteger(m.index) ? m.index : i,
      raw: typeof m.raw === 'string' && m.raw.trim() ? m.raw : own.join('\n\n'),
    };
  });
  return { paragraphs: written, chaptersMeta };
}

// Pista B: guion por secciones encadenadas. Cada llamada lleva el historial
// completo (texto bruto de las secciones previas, nunca el razonamiento). Tras
// la primera, el documento ya es legible (readyToRead) y el gasto lleva la marca
// de entrega, escrita en la misma transaccion que el texto.
async function runScriptTrack(ctx) {
  const { db, docRef, data, client, plan, area, language, outline, resumed, deps } = ctx;
  const text = deps.text || defaultText;
  const now = deps.now || Date.now;
  const generation = data.generation || {};
  const total = plan.sections;

  const paragraphs = [...resumed.paragraphs];
  const chaptersMeta = [...resumed.chaptersMeta];
  const raws = chaptersMeta.map((meta) => meta.raw);

  if (chaptersMeta.length) {
    console.log(`[story] ${docRef.id}: se reanuda en la seccion ${chaptersMeta.length + 1} de ${total}`);
  }

  for (let index = chaptersMeta.length; index < total; index += 1) {
    if (ctx.deadline && ctx.deadline - now() < DEADLINE_GUARD_MS) {
      throw new docugen.RetryableError(
        `Quedan menos de ${Math.round(DEADLINE_GUARD_MS / 60000)} min de invocacion: `
        + `la seccion ${index + 1} de ${total} queda para el siguiente intento`,
      );
    }

    const extra = docugen.buildExtra({
      framework: generation.systemPrompt,
      systemPromptSource: generation.systemPromptSource,
      outline,
      index,
      total,
    });
    const messages = docugen.buildSectionMessages({ topic: data.prompt, extra, previous: raws, index, total });
    const result = await client.generateSection({
      docId: docRef.id,
      index,
      total,
      attempt: ctx.attempt,
      area,
      language,
      durationMinutes: plan.durationMinutes,
      messages,
      deadline: ctx.deadline,
    });

    // Sin las notas meta del modelo: ni se guardan ni se reenvian como historial.
    const raw = text.cleanAiNotes(result.content).trim();
    const sectionParagraphs = text.toParagraphs(raw);
    if (!sectionParagraphs.length) {
      throw new docugen.RetryableError(`La seccion ${index + 1} llego vacia tras limpiar el texto`);
    }

    paragraphs.push(...sectionParagraphs);
    chaptersMeta.push({
      index,
      title: text.sectionTitle(raw, index),
      paragraphs: sectionParagraphs.length,
      raw,
    });
    raws.push(raw);

    const fields = { description: [...paragraphs], chaptersMeta: [...chaptersMeta] };
    if (chaptersMeta.length === 1) {
      fields.readyToRead = true;
      fields['generation.textProvider'] = TEXT_PROVIDER;
    }
    const written = await advanceStatus(db, docRef, 'generating_script', fields, { spendMark: SPEND_DELIVERED });
    if (!written.applied) throw new TerminatedError(written.reason);
    ctx.shared.delivered = true;
  }

  return { paragraphs, chaptersMeta };
}

// Nucleo de la tarea generateStory. Idempotente: no hace nada si el documento
// ya esta 'completed', en 'error' (lo cerro el barrido o un intento anterior)
// o con el credito devuelto.
//  - FATAL (sin acceso al Space, Space pausado o roto, DeepSeek sin saldo o sin
//    clave, peticion rechazada): 'error' + reembolso sin reintentar.
//  - REINTENTABLE: se lanza para que Cloud Tasks reintente; el siguiente intento
//    reanuda desde chaptersMeta. En el ultimo intento: 'error' + reembolso.
async function runStory({
  db,
  bucket,
  docId,
  uid,
  isFinalAttempt = true,
  attempt = 0,
  deadline = null,
  deps = {},
}) {
  const credits = deps.credits || defaultCredits;
  const now = deps.now || Date.now;
  const docRef = db.collection(DOCS_COLLECTION).doc(docId);
  const snap = await docRef.get();

  if (!snap.exists) {
    console.warn(`[story] ${docId}: el documento ya no existe`);
    // Borrado antes de este intento: nada lo retiene (el cerrojo solo se suelta si es suyo).
    await releaseGenerationLock(db, uid, docId).catch(() => {});
    return { skipped: true, reason: 'not_found' };
  }

  const data = snap.data();
  const generation = data.generation || {};
  if (data.status === 'completed') {
    console.log(`[story] ${docId}: ya estaba completado, no se hace nada`);
    return { skipped: true, reason: 'already_completed' };
  }
  if (generation.refunded === true) {
    console.log(`[story] ${docId}: el credito ya se devolvio, no se genera`);
    return { skipped: true, reason: 'refunded' };
  }
  if (data.status === 'error') {
    console.log(`[story] ${docId}: el documento ya esta cerrado en error, no se genera`);
    return { skipped: true, reason: 'terminated' };
  }
  if (uid && data.uId && data.uId !== uid) {
    console.warn(`[story] ${docId}: el uid de la tarea no coincide con el del documento`);
    return { skipped: true, reason: 'uid_mismatch' };
  }

  const owner = data.uId || uid;
  const plan = generationPlan(data.type);
  const client = deps.docugen
    || docugen.createClient({ token: secrets.hfToken(), ...(deps.docugenOptions || {}) });
  const resumed = resumeState(data, plan.sections);
  const ctx = {
    db,
    docRef,
    bucket,
    docId,
    data,
    deps,
    client,
    plan,
    attempt,
    deadline,
    area: docugen.resolveArea(data),
    language: docugen.languageName(data.languageCode),
    resumed,
    // delivered: el documento ya tiene texto legible (de este intento o de otro).
    shared: { title: data.bukbukName || '', cover: null, delivered: resumed.chaptersMeta.length > 0 },
  };
  console.log(
    `[story] ${docId}: area ${ctx.area}, idioma ${ctx.language}, ${plan.sections} secciones `
    + `(${plan.durationMinutes} min), intento ${attempt + 1}`,
  );

  let failure = null;
  let script = null;
  try {
    // Latido de inicio de intento: desde aqui el documento ya no esta en cola.
    const started = await advanceStatus(db, docRef, null, {
      'generation.attemptStartedAt': new Date(),
      'generation.awaitingRetry': false,
    });
    if (!started.applied) throw new TerminatedError(started.reason);
    const identity = await runIdentityTrack(ctx);
    script = await runScriptTrack({ ...ctx, outline: identity.outline });
  } catch (error) {
    failure = error;
  }
  await waitForCover(ctx, deps.coverWaitMs || COVER_WAIT_MS, now);
  if (typeof client.flush === 'function') await client.flush();

  if (failure) {
    if (failure instanceof TerminatedError) {
      if (failure.reason === 'not_found') {
        if (ctx.shared.delivered) {
          // El dueno borro el documento cuando ya tenia texto legible: se entrego.
          console.log(`[story] ${docId}: borrado por su dueno despues de tener texto; se liquida el gasto`);
          if (generation.spendId) {
            await credits.settleSpend(db, generation.spendId).catch((error) => {
              console.error(`[story] ${docId}: no se pudo liquidar el gasto: ${sanitizeError(error)}`);
            });
          }
        }
        // Sin texto entregado el credito lo devuelve la conciliacion del barrido; el
        // cerrojo se suelta ya para que el usuario pueda crear otro.
        await releaseGenerationLock(db, owner, docId).catch(() => {});
      }
      console.log(`[story] ${docId}: ${failure.message}; no se entrega`);
      return { skipped: true, reason: failure.reason };
    }
    const message = sanitizeError(failure);
    const fatal = docugen.isFatal(failure);
    if (!fatal && !isFinalAttempt) {
      console.warn(`[story] ${docId}: fallo reintentable, Cloud Tasks reintentara: ${message}`);
      // Latido y marca de espera: el barrido no cierra un documento que espera
      // su reintento en la cola.
      await advanceStatus(db, docRef, null, {
        'generation.lastError': message,
        'generation.awaitingRetry': true,
      }).catch(() => {});
      throw failure;
    }
    console.error(`[story] ${docId}: ${fatal ? 'fallo fatal' : 'fallo en el ultimo intento'}: ${message}`);
    const marked = await advanceStatus(db, docRef, 'error', {
      errorMessage: message,
      'generation.lastError': message,
      'generation.finishedAt': new Date(),
    }, { spendMark: SPEND_CLOSED_IN_ERROR });
    if (!marked.applied) return { skipped: true, reason: marked.reason };
    await refundDoc(db, docId, credits).catch((error) => {
      console.error(`[story] ${docId}: no se pudo reembolsar: ${sanitizeError(error)}`);
    });
    await releaseGenerationLock(db, owner, docId).catch(() => {});
    return { status: 'error', errorMessage: message, fatal };
  }

  const { paragraphs, chaptersMeta } = script;
  const done = await advanceStatus(db, docRef, 'completed', {
    description: paragraphs,
    readyToRead: true,
    bukbukUrl: '',
    errorMessage: null,
    'generation.textProvider': TEXT_PROVIDER,
    'generation.lastError': null,
    'generation.finishedAt': new Date(),
  }, { spendMark: SPEND_DELIVERED });
  if (!done.applied) {
    console.log(`[story] ${docId}: no se marca completado (${done.reason})`);
    return { skipped: true, reason: done.reason };
  }

  // El contenido se entrego: el gasto deja de ser reembolsable. Si esto falla,
  // la pasada de conciliacion del barrido lo liquida despues (tambien si el
  // dueno borra el documento, por la marca de entrega del gasto).
  if (generation.spendId) {
    await credits.settleSpend(db, generation.spendId).catch((error) => {
      console.error(`[story] ${docId}: no se pudo liquidar el gasto: ${sanitizeError(error)}`);
    });
  }
  await releaseGenerationLock(db, owner, docId).catch(() => {});

  console.log(`[story] ${docId}: completado (${chaptersMeta.length} secciones, ${paragraphs.length} parrafos)`);
  return {
    status: 'completed',
    paragraphs: paragraphs.length,
    sections: chaptersMeta.length,
    textProvider: TEXT_PROVIDER,
  };
}

// Reembolsa el credito de un documento y deja constancia en generation.refunded.
// La autoridad es creditSpends (que el cliente no puede escribir): refundSpend
// comprueba que el gasto sea de este usuario y de este documento, y que no se
// haya liquidado ya.
async function refundDoc(db, docId, credits = defaultCredits) {
  const docRef = db.collection(DOCS_COLLECTION).doc(docId);
  const snap = await docRef.get();
  if (!snap.exists) return { refunded: false, reason: 'not_found' };
  const data = snap.data();
  const generation = data.generation || {};
  if (!generation.spendId) return { refunded: false, reason: 'no_spend_id' };
  if (generation.refunded === true) return { refunded: false, reason: 'already_refunded' };

  let result;
  try {
    result = await credits.refundSpend(db, generation.spendId, {}, { uid: data.uId, docId });
  } catch (error) {
    // Al agotar los intentos refundSpend deja el gasto en revision y relanza el error.
    const spend = await db.collection(SPENDS_COLLECTION).doc(generation.spendId).get().catch(() => null);
    if (spend && spend.exists && spend.data().refundState === 'needs_review') await flagRefundReview(docRef);
    throw error;
  }
  if (result.refunded || result.reason === 'already_refunded') {
    await docRef.update({ 'generation.refunded': true, updatedAt: new Date() });
  } else if (result.reason === 'needs_review') {
    await flagRefundReview(docRef);
  }
  return result;
}

// Contrato con la app: el gasto quedo para revision manual y ningun proceso lo va
// a devolver solo, asi que la app deja de decir que el credito esta en camino.
function flagRefundReview(docRef) {
  return docRef.update({ 'generation.refundState': 'needs_review', updatedAt: new Date() }).catch((error) => {
    console.error(`[story] ${docRef.id}: no se pudo marcar el reembolso para revision: ${sanitizeError(error)}`);
  });
}

module.exports = {
  runStory,
  runIdentityTrack,
  runScriptTrack,
  runCoverTrack,
  refundDoc,
  flagRefundReview,
  advanceStatus,
  hasActiveGeneration,
  acquireGenerationLock,
  releaseGenerationLock,
  buildInitialDoc,
  resumeState,
  isQueued,
  staleAfterMs,
  toMillis,
  STATUS_RANK,
  TEXT_PROVIDER,
  TerminatedError,
};
