'use strict';

const {
  DOCS_COLLECTION,
  MAX_PROMPT_CHARS,
  MAX_SHORT_CHARS,
  MAX_MAP_ENTRIES,
  MAX_SYSTEM_PROMPT_CHARS,
  generationPlan,
} = require('./config');
const { sanitizeError } = require('./sanitize');
const defaultCredits = require('./credits');
const {
  hasActiveGeneration,
  acquireGenerationLock,
  releaseGenerationLock,
  buildInitialDoc,
} = require('./story');

// Nucleo de la callable startStory, sin dependencias de firebase-functions para
// poder probarlo. index.js traduce StartError a HttpsError con el mismo code.
class StartError extends Error {
  constructor(code, message) {
    super(message || code);
    this.code = code;
  }
}

const VALID_TYPES = ['sapere', 'preview', 'gamification_episode'];

const CATEGORIES_COLLECTION = 'sapereCategories';
const TYPES_SUBCOLLECTION = 'sapereTypes';
// Los ids de categoria y tipo llegan del cliente y se usan para construir una
// ruta de Firestore: sin barras ni caracteres raros no pueden apuntar a otra.
// Firestore reserva los ids con forma __x__.
const FIRESTORE_ID = /^[A-Za-z0-9_-]{1,128}$/;
const RESERVED_ID = /^__.*__$/;
const TYPE_READ_TIMEOUT_MS = 5000;

function isSafeId(value) {
  return typeof value === 'string' && FIRESTORE_ID.test(value) && !RESERVED_ID.test(value);
}

function readRequiredString(value, field, max) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new StartError('invalid-argument', `${field} es obligatorio`);
  }
  const clean = value.trim();
  if (clean.length > max) {
    throw new StartError('invalid-argument', `${field} supera ${max} caracteres`);
  }
  return clean;
}

function readOptionalString(value, field, max) {
  if (typeof value !== 'string' || !value.trim()) return '';
  const clean = value.trim();
  if (clean.length > max) {
    throw new StartError('invalid-argument', `${field} supera ${max} caracteres`);
  }
  return clean;
}

// Mapas de nombres por idioma ({ es_ES: 'Historia', ... }): solo cadenas cortas.
function readNameMap(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return {};
  const out = {};
  for (const [key, name] of Object.entries(value).slice(0, MAX_MAP_ENTRIES)) {
    if (typeof name !== 'string' || key.length > 16) continue;
    out[key] = name.slice(0, MAX_SHORT_CHARS);
  }
  return out;
}

// La portada elegida por el usuario solo se acepta si vive en el bucket del
// proyecto. Cualquier otra URL la pintarian todos los dispositivos que abran el
// catalogo (tracking de IP, contenido ajeno): en ese caso se genera una.
function isAllowedCoverUrl(value, bucketName) {
  if (typeof value !== 'string' || !value.trim() || !bucketName) return false;
  let url;
  try {
    url = new URL(value.trim());
  } catch (_) {
    return false;
  }
  if (url.protocol !== 'https:' || url.username || url.password || url.port) return false;
  if (url.hostname === 'firebasestorage.googleapis.com') {
    return url.pathname.startsWith(`/v0/b/${bucketName}/o/`);
  }
  if (url.hostname === 'storage.googleapis.com') {
    return url.pathname.startsWith(`/${bucketName}/`);
  }
  return false;
}

// "es_ES" -> "Spanish (Spain)"; si el cliente ya manda language, gana el suyo.
function longLanguageName(languageCode) {
  try {
    const display = new Intl.DisplayNames(['en'], { type: 'language' });
    return display.of(String(languageCode).replace('_', '-')) || languageCode;
  } catch (_) {
    return languageCode;
  }
}

// prompts de un tipo: { es_ES: '...', en_US: '...' }. Idioma exacto, luego otra
// variante del mismo idioma, luego ingles o espanol. El idioma de salida lo fija
// igualmente languageLine() en el mensaje de sistema.
function pickPromptForLanguage(prompts, languageCode) {
  if (!prompts || typeof prompts !== 'object' || Array.isArray(prompts)) return '';
  const clean = (value) => (typeof value === 'string' ? value.trim() : '');
  const exact = clean(prompts[languageCode]);
  if (exact) return exact;
  const lang = String(languageCode || '').split(/[_-]/)[0];
  for (const [key, value] of Object.entries(prompts)) {
    if (key.split(/[_-]/)[0] === lang && clean(value)) return clean(value);
  }
  return clean(prompts.en_US) || clean(prompts.es_ES) || '';
}

function withTimeout(promise, ms, label) {
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => reject(new Error(`${label}: timeout tras ${ms} ms`)), ms);
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

// Marco narrativo del documental, decidido en el SERVIDOR:
//  - 'type': el prompt del tipo que eligio el usuario, leido de
//    sapereCategories/{categoria}/sapereTypes/{tipo}. El cliente solo manda los
//    ids; el contenido lo gestiona el equipo en Firestore. Solo cuentan los tipos
//    visibles en la app (userapp == true), y sus nombres salen del documento.
//  - 'gamification_client': la persona de un episodio de gamificacion se arma en
//    la app con datos locales de la materia y no existe en Firestore; se acepta
//    acotada. Controlarla da poco mas que controlar el tema (prompt), que el
//    usuario ya elige libremente, y se paga con su credito.
//  - 'framework': nada de lo anterior; no se guarda marco y el Space escribe
//    solo con su propio prompt de sistema.
// Si Firestore falla o no responde a tiempo lanza 'unavailable': todavia no se ha
// cobrado, y es mejor que el usuario reintente a entregarle un marco que no eligio.
async function resolveSystemPrompt({
  db,
  type,
  bukbukCategoryId,
  bukbukId,
  languageCode,
  clientSystemPrompt,
  timeoutMs = TYPE_READ_TIMEOUT_MS,
}) {
  if (isSafeId(bukbukCategoryId) && isSafeId(bukbukId)) {
    let snap;
    try {
      snap = await withTimeout(
        Promise.resolve().then(() => db
          .collection(`${CATEGORIES_COLLECTION}/${bukbukCategoryId}/${TYPES_SUBCOLLECTION}`)
          .doc(bukbukId)
          .get()),
        timeoutMs,
        'lectura del tipo',
      );
    } catch (error) {
      console.warn('[startStory] no se pudo leer el tipo:', sanitizeError(error));
      throw new StartError('unavailable', 'type_unavailable');
    }

    const typeData = snap.exists ? (snap.data() || {}) : null;
    if (typeData && typeData.userapp === true) {
      const text = pickPromptForLanguage(typeData.prompts, languageCode);
      if (text) {
        return {
          framework: text.slice(0, MAX_SYSTEM_PROMPT_CHARS),
          source: 'type',
          typeNames: readNameMap(typeData.names),
        };
      }
    }
  }

  if (type === 'gamification_episode' && typeof clientSystemPrompt === 'string' && clientSystemPrompt.trim()) {
    return {
      framework: clientSystemPrompt.trim().slice(0, MAX_SYSTEM_PROMPT_CHARS),
      source: 'gamification_client',
      typeNames: null,
    };
  }

  return { framework: '', source: 'framework', typeNames: null };
}

async function startStoryFlow({
  db,
  uid,
  data = {},
  bucketName = '',
  enqueue,
  credits = defaultCredits,
  now = Date.now(),
  typeReadTimeoutMs = TYPE_READ_TIMEOUT_MS,
}) {
  if (!uid) throw new StartError('unauthenticated', 'Hay que iniciar sesion');

  const prompt = readRequiredString(data.prompt, 'prompt', MAX_PROMPT_CHARS);
  const languageCode = readRequiredString(data.languageCode, 'languageCode', 16);
  const genre = readOptionalString(data.genre, 'genre', MAX_SHORT_CHARS);
  const type = VALID_TYPES.includes(data.type) ? data.type : 'sapere';
  // Duracion y secciones las decide el servidor por tipo: 'chapters' del cliente se ignora.
  const plan = generationPlan(type);
  const language = readOptionalString(data.language, 'language', MAX_SHORT_CHARS)
    || longLanguageName(languageCode);

  const bukbukId = readOptionalString(data.bukbukId, 'bukbukId', MAX_SHORT_CHARS);
  const bukbukCategoryId = readOptionalString(data.bukbukCategoryId, 'bukbukCategoryId', MAX_SHORT_CHARS);
  const gamificationSubject = readOptionalString(data.gamificationSubject, 'gamificationSubject', MAX_SHORT_CHARS);
  const gamificationEpisode = Number.isInteger(data.gamificationEpisode) ? data.gamificationEpisode : null;

  const coverUrl = isAllowedCoverUrl(data.coverUrl, bucketName) ? data.coverUrl.trim() : '';
  if (typeof data.coverUrl === 'string' && data.coverUrl.trim() && !coverUrl) {
    console.warn('[startStory] coverUrl fuera del bucket del proyecto: se ignora y se genera portada');
  }

  // Antes de cerrojo y cobro: si la lectura falla no queda nada que deshacer.
  const resolved = await resolveSystemPrompt({
    db,
    type,
    bukbukCategoryId,
    bukbukId,
    languageCode,
    clientSystemPrompt: data.systemPrompt,
    timeoutMs: typeReadTimeoutMs,
  });
  const bukbukTypeNames = resolved.typeNames && Object.keys(resolved.typeNames).length
    ? resolved.typeNames
    : readNameMap(data.bukbukTypeNames);

  if (await hasActiveGeneration(db, uid, now)) {
    throw new StartError('failed-precondition', 'already_generating');
  }

  const docRef = db.collection(DOCS_COLLECTION).doc();
  const docId = docRef.id;

  let locked;
  try {
    locked = await acquireGenerationLock(db, uid, docId, now);
  } catch (error) {
    console.error('[startStory] no se pudo tomar el cerrojo:', sanitizeError(error));
    throw new StartError('internal', sanitizeError(error));
  }
  if (!locked) throw new StartError('failed-precondition', 'already_generating');

  let spend;
  try {
    spend = await credits.spendCredit(db, uid, {}, { docId });
  } catch (error) {
    await releaseGenerationLock(db, uid, docId).catch(() => {});
    if (error && error.code === 'insufficient_credits') {
      throw new StartError('resource-exhausted', 'insufficient_credits');
    }
    console.error('[startStory] fallo al cobrar el credito:', sanitizeError(error));
    throw new StartError('internal', sanitizeError(error));
  }

  try {
    const initialDoc = buildInitialDoc({
      uid,
      docId,
      prompt,
      genre,
      type,
      language,
      languageCode,
      coverUrl,
      chapters: plan.sections,
      durationMinutes: plan.durationMinutes,
      bukbukId,
      bukbukCategoryId,
      bukbukTypeNames,
      bukbukCategoryNames: readNameMap(data.bukbukCategoryNames),
      gamificationSubject,
      gamificationEpisode,
      spendId: spend.spendId,
      framework: resolved.framework,
    });
    initialDoc.generation.systemPromptSource = resolved.source;
    await docRef.set(initialDoc);

    await enqueue({ docId, uid });
  } catch (error) {
    const message = sanitizeError(error);
    console.error(`[startStory] fallo tras cobrar (${docId}):`, message);
    const refund = await credits
      .refundSpend(db, spend.spendId, {}, { uid, docId })
      .catch((refundError) => {
        console.error('[startStory] ademas fallo el reembolso:', sanitizeError(refundError));
        return { refunded: false, reason: 'refund_failed' };
      });
    // generation.refunded refleja lo que paso DE VERDAD: si el reembolso fallo
    // queda en false y el barrido lo reintenta. uId y spendId van siempre para
    // que el documento sea conciliable aunque el set inicial no llegara a escribirse.
    await docRef
      .set({
        uId: uid,
        postId: docId,
        status: 'error',
        errorMessage: message,
        generation: { spendId: spend.spendId, refunded: refund.refunded === true },
        updatedAt: new Date(),
      }, { merge: true })
      .catch(() => {});
    await releaseGenerationLock(db, uid, docId).catch(() => {});
    throw new StartError('internal', message);
  }

  return { docId, status: 'pending', spendId: spend.spendId };
}

module.exports = {
  StartError,
  VALID_TYPES,
  TYPE_READ_TIMEOUT_MS,
  startStoryFlow,
  isAllowedCoverUrl,
  isSafeId,
  readRequiredString,
  readOptionalString,
  readNameMap,
  longLanguageName,
  pickPromptForLanguage,
  resolveSystemPrompt,
};
