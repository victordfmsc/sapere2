'use strict';

const {
  DOCS_COLLECTION,
  AI_USAGE_COLLECTION,
  LEARNING_CARDS_COLLECTION,
  MAX_PROMPT_CHARS,
  MAX_SHORT_CHARS,
  ASSIST_DOCUGEN,
  ASSIST_MIN_CALL_MS,
  COMMUNITY_TEXT_PLAN,
  FLASHCARDS_PLAN,
  AI_USAGE_MAX_CALLS,
  AI_USAGE_WINDOW_MS,
  secrets,
} = require('./config');
const { sanitizeError } = require('./sanitize');
const docugen = require('./docugen');
const text = require('./text');
const {
  StartError,
  TYPE_READ_TIMEOUT_MS,
  isSafeId,
  readRequiredString,
  readOptionalString,
  resolveSystemPrompt,
} = require('./start');

// Nucleo de las callables generateCommunityText y generateFlashcards, que
// sustituyen a las llamadas de la app a Railway. Sin firebase-functions para
// poder probarlo: como en startStory, index.js traduce StartError a HttpsError.

const MAX_LANGUAGE_CODE_CHARS = 16;
const MAX_CARDS = 3;
const MAX_QUESTION_CHARS = 300;
const MAX_ANSWER_CHARS = 600;
const CARD_REVIEW_DELAY_MS = 24 * 60 * 60 * 1000;

// ---------------------------------------------------------------- errores

// FATAL del Space (DeepSeek sin saldo, credencial, Space pausado...) no se
// arregla reintentando: 'ai_unavailable', sin el detalle, que puede llevar datos
// de la cuenta de DeepSeek. REINTENTABLE (no responde, no despierta, corta el
// stream, 429 o 5xx) es transitorio: 'unavailable'. Lo demas, 'internal'.
function toStartError(error, tag) {
  if (error instanceof StartError) return error;
  const message = sanitizeError(error);
  if (docugen.isFatal(error)) {
    console.error(`[${tag}] el Space no puede generar:`, message);
    return new StartError('failed-precondition', 'ai_unavailable');
  }
  if (error instanceof docugen.RetryableError) {
    console.warn(`[${tag}] el Space no respondio:`, message);
    return new StartError('unavailable', message);
  }
  console.error(`[${tag}] error inesperado:`, message);
  return new StartError('internal', message);
}

// ---------------------------------------------------------------- limite de uso

// Ventana deslizante en aiUsage/{uid}: marcas (ms) de las llamadas de las
// ultimas AI_USAGE_WINDOW_MS. Se apunta en una transaccion ANTES de llamar al
// Space, asi que dos llamadas simultaneas no se quedan las dos con el ultimo hueco.
async function consumeAiUsage(db, uid, now = Date.now()) {
  const ref = db.collection(AI_USAGE_COLLECTION).doc(uid);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const stored = snap.exists ? (snap.data() || {}).calls : null;
    const calls = (Array.isArray(stored) ? stored : [])
      .map(Number)
      .filter((at) => Number.isFinite(at) && at > now - AI_USAGE_WINDOW_MS)
      .sort((a, b) => a - b);
    if (calls.length >= AI_USAGE_MAX_CALLS) return false;
    calls.push(now);
    tx.set(ref, { calls, updatedAt: new Date(now) });
    return true;
  });
}

async function requireAiUsage(db, uid, now) {
  if (!(await consumeAiUsage(db, uid, now))) throw new StartError('resource-exhausted', 'rate_limited');
}

function spaceClient(client) {
  return client || docugen.createClient({ token: secrets.hfToken(), config: ASSIST_DOCUGEN });
}

// ---------------------------------------------------------------- texto de comunidad

// El Space trata cada respuesta como una de unas 4 secciones y pide cerrarla
// abriendo la siguiente: el texto de comunidad es una pieza unica.
const COMMUNITY_SYSTEM = [
  'Esta petición no es una sección de un documental más largo: es una pieza única y completa.',
  'Por encima de las reglas anteriores sobre secciones, recorre el arco entero en esta respuesta',
  'y termina con la conclusión reflexiva, sin preguntas ni ganchos hacia una sección siguiente y sin encabezado de sección.',
].join(' ');

async function communityText({ db, uid, data, deadline, client, now, typeReadTimeoutMs }) {
  if (!uid) throw new StartError('unauthenticated', 'Hay que iniciar sesion');
  const prompt = readRequiredString(data.prompt, 'prompt', MAX_PROMPT_CHARS);
  const languageCode = readRequiredString(data.languageCode, 'languageCode', MAX_LANGUAGE_CODE_CHARS);
  const bukbukCategoryId = readOptionalString(data.bukbukCategoryId, 'bukbukCategoryId', MAX_SHORT_CHARS);
  const bukbukId = readOptionalString(data.bukbukId, 'bukbukId', MAX_SHORT_CHARS);

  // Marco del tipo leido en Firestore con la logica de startStory: solo lo da
  // un tipo visible. Un systemPrompt del cliente nunca llega a resolveSystemPrompt.
  const resolved = await resolveSystemPrompt({
    db,
    bukbukCategoryId,
    bukbukId,
    languageCode,
    timeoutMs: typeReadTimeoutMs,
  });
  const extra = [resolved.framework, COMMUNITY_SYSTEM].filter(Boolean).join('\n\n');

  await requireAiUsage(db, uid, now());
  const space = spaceClient(client);
  try {
    const result = await space.generateText({
      kind: 'community',
      area: docugen.resolveArea({ bukbukCategoryId }),
      language: docugen.languageName(languageCode),
      durationMinutes: COMMUNITY_TEXT_PLAN.durationMinutes,
      maxTokens: COMMUNITY_TEXT_PLAN.maxTokens,
      messages: docugen.buildSectionMessages({ topic: prompt, extra, index: 0, total: 1 }),
      deadline,
      retryNeedsMs: ASSIST_MIN_CALL_MS,
    });
    const paragraphs = text.toParagraphs(result.content);
    if (!paragraphs.length) throw new docugen.RetryableError('community: el texto llego vacio tras limpiarlo');
    return { text: paragraphs.join('\n\n') };
  } finally {
    await space.flush();
  }
}

// ---------------------------------------------------------------- flashcards

// Texto del documental para el prompt: sus parrafos no vacios. Si pasa del tope
// se corta en el ultimo final de parrafo de la segunda mitad o, si no hay, en el
// ultimo espacio, sin dejar medio caracter.
function readableContent(description, maxChars = FLASHCARDS_PLAN.maxContentChars) {
  const full = (Array.isArray(description) ? description : [description])
    .filter((paragraph) => typeof paragraph === 'string')
    .map((paragraph) => paragraph.trim())
    .filter(Boolean)
    .join('\n\n');
  if (full.length <= maxChars) return full;
  const head = full.slice(0, maxChars);
  const paragraphEnd = head.lastIndexOf('\n\n');
  if (paragraphEnd >= maxChars / 2) return head.slice(0, paragraphEnd);
  const space = head.search(/\s\S*$/);
  if (space > 0) return head.slice(0, space).trim();
  return head.replace(/[\uD800-\uDBFF]$/, '');
}

// El Space mete esto dentro de su prompt de documental: la respuesta no es una
// seccion y solo vale el JSON.
const FLASHCARDS_SYSTEM = [
  'Esta petición no es una sección del documental: es una tarea de repaso sobre un documental ya escrito.',
  'Por encima de las reglas anteriores de formato, estilo y extensión, responde únicamente con el JSON que se pide,',
  'sin título, sin encabezados, sin bloques de código y sin ningún texto fuera del JSON.',
].join(' ');

// Prompt pedagogico que montaba la app (learning_provider.dart), con el idioma
// del documental.
function buildFlashcardsPrompt({ content, language }) {
  return [
    'Eres un experto en pedagogía y neurociencia cognitiva.',
    'Basándote en el siguiente contenido detallado de un documental educativo, genera exactamente 3 flashcards de repaso.',
    'Cada tarjeta debe tener una pregunta clara en el anverso y una respuesta concisa en el reverso.',
    'Enfócate en conceptos clave, datos curiosos o relaciones causa-efecto.',
    `Escribe las preguntas y las respuestas en ${language}, el idioma del documental.`,
    '',
    'Contenido:',
    content,
    '',
    'Responde SOLO en formato JSON estructurado:',
    '[',
    '  {"q": "Pregunta 1", "a": "Respuesta 1"},',
    '  {"q": "Pregunta 2", "a": "Respuesta 2"},',
    '  {"q": "Pregunta 3", "a": "Respuesta 3"}',
    ']',
  ].join('\n');
}

function tryParseJson(value) {
  try {
    return JSON.parse(value);
  } catch (_) {
    return undefined;
  }
}

function between(source, open, close) {
  const start = source.indexOf(open);
  const end = source.lastIndexOf(close);
  return start !== -1 && end > start ? source.slice(start, end + 1) : '';
}

function cardItems(value) {
  if (Array.isArray(value)) return value;
  if (!value || typeof value !== 'object') return [];
  return ['cards', 'flashcards', 'tarjetas'].map((key) => value[key]).find(Array.isArray) || [value];
}

// Una cara de la tarjeta: una linea sin markdown y acotada.
function cardFace(value, max) {
  const raw = typeof value === 'number' && Number.isFinite(value) ? String(value) : value;
  if (typeof raw !== 'string') return '';
  const clean = raw.replace(/[#*_`]/g, '').replace(/\s+/g, ' ').trim();
  const chars = Array.from(clean);
  return chars.length <= max ? clean : `${chars.slice(0, max - 1).join('').trimEnd()}…`;
}

function normalizeCards(items) {
  const cards = [];
  const seen = new Set();
  for (const item of items) {
    if (!item || typeof item !== 'object' || Array.isArray(item)) continue;
    const question = cardFace(item.q !== undefined ? item.q : item.question, MAX_QUESTION_CHARS);
    const answer = cardFace(item.a !== undefined ? item.a : item.answer, MAX_ANSWER_CHARS);
    const key = question.toLowerCase();
    if (!question || !answer || seen.has(key)) continue;
    seen.add(key);
    cards.push({ question, answer });
    if (cards.length === MAX_CARDS) break;
  }
  return cards;
}

// De 0 a 3 tarjetas de la respuesta del modelo. Aguanta bloques de codigo, texto
// alrededor, un objeto { cards: [...] } y un JSON roto o cortado, del que se
// rescatan los objetos completos.
function parseFlashcards(raw) {
  const source = String(raw || '').replace(/```[a-z]*/gi, '').trim();
  for (const candidate of [source, between(source, '[', ']'), between(source, '{', '}')]) {
    if (!candidate) continue;
    const cards = normalizeCards(cardItems(tryParseJson(candidate)));
    if (cards.length) return cards;
  }
  return normalizeCards((source.match(/\{[^{}]*\}/g) || []).map(tryParseJson));
}

function cardsQuery(db, uid, postId) {
  return db.collection(LEARNING_CARDS_COLLECTION)
    .where('userId', '==', uid)
    .where('postId', '==', postId)
    .limit(1);
}

// Los mismos campos que LearningCard.toMap de la app, con fechas ISO 8601.
function buildCard({ id, uid, postId, question, answer, at }) {
  return {
    id,
    userId: uid,
    noteId: null,
    postId,
    question,
    answer,
    box: 1,
    nextReview: new Date(at + CARD_REVIEW_DELAY_MS).toISOString(),
    correctCount: 0,
    wrongCount: 0,
    createdAt: new Date(at).toISOString(),
  };
}

async function flashcards({ db, uid, data, deadline, client, now }) {
  if (!uid) throw new StartError('unauthenticated', 'Hay que iniciar sesion');
  const { postId } = data;
  if (!isSafeId(postId)) throw new StartError('invalid-argument', 'postId no valido');

  const snap = await db.collection(DOCS_COLLECTION).doc(postId).get();
  if (!snap.exists) throw new StartError('not-found', 'post_not_found');
  const post = snap.data() || {};
  const content = readableContent(post.description);
  if (!content) throw new StartError('failed-precondition', 'no_readable_text');

  if (!(await cardsQuery(db, uid, postId).get()).empty) return { created: 0, skipped: true };

  await requireAiUsage(db, uid, now());
  const space = spaceClient(client);
  const language = docugen.languageName(post.languageCode);
  let result;
  try {
    result = await space.generateText({
      kind: 'flashcards',
      area: docugen.resolveArea(post),
      language,
      durationMinutes: FLASHCARDS_PLAN.durationMinutes,
      maxTokens: FLASHCARDS_PLAN.maxTokens,
      reasoningEffort: FLASHCARDS_PLAN.reasoningEffort,
      // Cortado por max_tokens, parseFlashcards rescata las tarjetas completas.
      cutToSentence: false,
      messages: docugen.buildSectionMessages({
        topic: buildFlashcardsPrompt({ content, language }),
        extra: FLASHCARDS_SYSTEM,
        index: 0,
        total: 1,
      }),
      deadline,
      retryNeedsMs: ASSIST_MIN_CALL_MS,
    });
  } finally {
    await space.flush();
  }

  const cards = parseFlashcards(result.content);
  if (!cards.length) {
    console.error(`[generateFlashcards] respuesta sin tarjetas validas (${postId}, ${result.content.length} caracteres)`);
    throw new StartError('internal', 'invalid_flashcards');
  }

  // Se vuelve a mirar dentro de la transaccion: otra llamada para el mismo
  // documental puede haber escrito sus tarjetas mientras esta generaba.
  const created = await db.runTransaction(async (tx) => {
    if (!(await tx.get(cardsQuery(db, uid, postId))).empty) return 0;
    const at = now();
    for (const card of cards) {
      const ref = db.collection(LEARNING_CARDS_COLLECTION).doc();
      tx.set(ref, buildCard({ id: ref.id, uid, postId, ...card, at }));
    }
    return cards.length;
  });
  return created ? { created } : { created: 0, skipped: true };
}

// ---------------------------------------------------------------- flujos

async function generateCommunityTextFlow({
  db,
  uid,
  data = {},
  deadline = null,
  client = null,
  now = Date.now,
  typeReadTimeoutMs = TYPE_READ_TIMEOUT_MS,
}) {
  try {
    return await communityText({ db, uid, data, deadline, client, now, typeReadTimeoutMs });
  } catch (error) {
    throw toStartError(error, 'generateCommunityText');
  }
}

async function generateFlashcardsFlow({
  db,
  uid,
  data = {},
  deadline = null,
  client = null,
  now = Date.now,
}) {
  try {
    return await flashcards({ db, uid, data, deadline, client, now });
  } catch (error) {
    throw toStartError(error, 'generateFlashcards');
  }
}

module.exports = {
  generateCommunityTextFlow,
  generateFlashcardsFlow,
  COMMUNITY_SYSTEM,
  consumeAiUsage,
  readableContent,
  buildFlashcardsPrompt,
  parseFlashcards,
  buildCard,
};
