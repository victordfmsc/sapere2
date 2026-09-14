'use strict';

const { defineSecret, defineString } = require('firebase-functions/params');
const { cleanEnvValue } = require('./sanitize');

// Firestore de sapere-f7150 esta en eur3 -> todas las funciones en europe-west1.
const REGION = 'europe-west1';
const DOCS_COLLECTION = 'sapere';
const SPENDS_COLLECTION = 'creditSpends';
const USERS_COLLECTION = 'users';
// Cerrojo por usuario (solo servidor: firestore.rules lo deniega al cliente).
const LOCKS_COLLECTION = 'generationLocks';
const TASK_QUEUE = 'generateStory';
// firebase-admin resuelve us-central1 si no se indica la region.
const TASK_QUEUE_RESOURCE = `locations/${REGION}/functions/${TASK_QUEUE}`;

const IN_PROGRESS_STATUSES = ['pending', 'generating_title', 'generating_script'];
// Tiempos coherentes entre si:
//  - cada paso de la generacion (inicio de intento, titulo, escaleta, seccion)
//    escribe updatedAt, y el peor caso de un paso (llamada fallida 2,5 min +
//    despertar el Space 3,7 + seccion 7) queda muy por debajo de STALE_MS: el
//    barrido no cierra un documento vivo;
//  - un documento en la cola de Cloud Tasks (aun sin despachar, o esperando su
//    reintento con generation.awaitingRetry) no escribe latidos: se mide con
//    QUEUE_STALE_MS, no con STALE_MS;
//  - ACTIVE_LOCK_MS >= STALE_MS + intervalo del barrido (5 min): mientras el
//    barrido no ha cerrado un documento, el usuario no puede lanzar otro.
const ACTIVE_LOCK_MS = 60 * 60 * 1000;
const STALE_MS = 45 * 60 * 1000;
// Topes de lo que manda el cliente a startStory: sin ellos la callable es un
// proxy abierto a las claves de los proveedores.
const MAX_PROMPT_CHARS = 4000;
const MAX_SHORT_CHARS = 200;
const MAX_MAP_ENTRIES = 50;
// Marco del documental (prompt del tipo en Firestore o persona de un episodio de
// gamificacion): los reales ocupan menos de 1000 caracteres.
const MAX_SYSTEM_PROMPT_CHARS = 4000;
// Documentos por pasada del barrido: acota lo viejo que puede estar el snapshot.
const SWEEP_BATCH = 200;

// Duracion y secciones por tipo: las decide el SERVIDOR (se ignora 'chapters'
// del cliente). Una seccion = una llamada al Space.
const GENERATION_PLANS = Object.freeze({
  sapere: Object.freeze({ durationMinutes: 30, sections: 6 }),
  gamification_episode: Object.freeze({ durationMinutes: 20, sections: 4 }),
  preview: Object.freeze({ durationMinutes: 5, sections: 1 }),
});
// Por debajo de este numero de secciones no se pide escaleta.
const OUTLINE_MIN_SECTIONS = 4;

function generationPlan(type) {
  return GENERATION_PLANS[type] || GENERATION_PLANS.sapere;
}

// generateStory (Cloud Tasks). 1800 s es el tope de las colas; el encolado usa el
// mismo valor como dispatchDeadline para que Cloud Tasks no relance la tarea
// mientras la primera invocacion sigue viva.
const GENERATE_TIMEOUT_SECONDS = 1800;
const GENERATE_MAX_ATTEMPTS = 5;
const GENERATE_MIN_BACKOFF_SECONDS = 60;
// Espera mas larga entre dos intentos: Cloud Tasks la duplica en cada reintento
// (60, 120, 240 y 480 s con 5 intentos).
const GENERATE_MAX_BACKOFF_SECONDS = GENERATE_MIN_BACKOFF_SECONDS * 2 ** (GENERATE_MAX_ATTEMPTS - 2);
// El Space atiende en la practica una generacion cada vez.
const GENERATE_MAX_CONCURRENT_DISPATCHES = 2;
// Un documento en cola (sin despachar o esperando su reintento) puede esperar a
// que la tarea que ocupa su hueco agote todos sus intentos con sus esperas, mas
// media hora de cola: hasta entonces el barrido no lo da por atascado.
const QUEUE_STALE_MS = (GENERATE_MAX_ATTEMPTS * (GENERATE_TIMEOUT_SECONDS + GENERATE_MAX_BACKOFF_SECONDS) + 30 * 60) * 1000;
// Mismo margen sobre QUEUE_STALE_MS que ACTIVE_LOCK_MS sobre STALE_MS.
const QUEUE_ACTIVE_MS = QUEUE_STALE_MS + (ACTIVE_LOCK_MS - STALE_MS);

// Reservas al final de la invocacion: ninguna seccion corre mas alla de
// plazo - DEADLINE_MARGIN_MS, y la espera de la portada nunca pasa de
// plazo - CLOSE_MARGIN_MS (borrados pendientes y escrituras del desenlace).
const SECTION_TIMEOUT_MS = 420 * 1000;
const DEADLINE_MARGIN_MS = 60 * 1000;
const CLOSE_MARGIN_MS = 30 * 1000;
// Si quedan menos de esto en la invocacion no se empieza otra seccion (tope de
// una seccion + reserva final = 8 min): se deja reintentar y se reanuda. Dentro
// de la seccion, el cliente del Space no despierta el Space ni repite la llamada
// si no le cabe, y acorta la seccion al plazo.
const DEADLINE_GUARD_MS = SECTION_TIMEOUT_MS + DEADLINE_MARGIN_MS;

// Portada (corre en paralelo con el guion): tope de cada peticion de imagen y
// espera maxima al cerrar el documento; si no ha llegado, se cierra sin ella.
const COVER_FETCH_TIMEOUT_MS = 120 * 1000;
const COVER_WAIT_MS = 2 * 60 * 1000;

// Space privado de Hugging Face que genera el texto (FastAPI + deepseek-reasoner).
const DOCUGEN = Object.freeze({
  baseUrl: 'https://bukbuk-docugenerator.hf.space',
  spaceId: 'Bukbuk/DocuGenerator',
  runtimeUrl: 'https://huggingface.co/api/spaces/Bukbuk/DocuGenerator/runtime',
  restartUrl: 'https://huggingface.co/api/spaces/Bukbuk/DocuGenerator/restart',
  level: 'intermedio',
  maxTokens: 4096,
  sectionTimeoutMs: SECTION_TIMEOUT_MS,
  deadlineMarginMs: DEADLINE_MARGIN_MS,
  idleTimeoutMs: 150 * 1000,
  titleTimeoutMs: 180 * 1000,
  outlineTimeoutMs: 300 * 1000,
  runtimeTimeoutMs: 15 * 1000,
  deleteTimeoutMs: 5 * 1000,
  wakePollMs: 10 * 1000,
  wakeMaxMs: 180 * 1000,
  maxOutlineChars: 6000,
  maxExtraChars: 10000,
});

const HF_TOKEN = defineSecret('HF_TOKEN');
const OPENAI_API_KEY = defineSecret('OPENAI_API_KEY');
const REVENUECAT_SECRET_KEY = defineSecret('REVENUECAT_SECRET_KEY');
const REVENUECAT_PROJECT_ID = defineSecret('REVENUECAT_PROJECT_ID');

const CREDIT_SECRETS = [REVENUECAT_SECRET_KEY, REVENUECAT_PROJECT_ID];
// HF_TOKEN: Space; OPENAI_API_KEY: portada; RevenueCat: reembolso si falla.
const GENERATE_SECRETS = [HF_TOKEN, OPENAI_API_KEY, REVENUECAT_SECRET_KEY, REVENUECAT_PROJECT_ID];

const OPENAI_IMAGE_MODEL = defineString('OPENAI_IMAGE_MODEL', { default: 'gpt-image-1' });
const REVENUECAT_CURRENCY = defineString('REVENUECAT_CURRENCY', { default: 'CRD' });

// .value() de un parametro lee process.env; si algo falla (despliegue, test)
// caemos a process.env directamente en vez de tumbar la funcion.
function readParam(param, name, fallback) {
  let raw;
  try {
    raw = param.value();
  } catch (_) {
    raw = undefined;
  }
  if (raw === undefined || raw === null || raw === '') raw = process.env[name];
  const clean = cleanEnvValue(raw, name);
  return clean || fallback || '';
}

const secrets = {
  hfToken: () => readParam(HF_TOKEN, 'HF_TOKEN'),
  openaiKey: () => readParam(OPENAI_API_KEY, 'OPENAI_API_KEY'),
  revenuecatKey: () => readParam(REVENUECAT_SECRET_KEY, 'REVENUECAT_SECRET_KEY'),
  revenuecatProject: () => readParam(REVENUECAT_PROJECT_ID, 'REVENUECAT_PROJECT_ID'),
};

const options = {
  openaiImageModel: () => readParam(OPENAI_IMAGE_MODEL, 'OPENAI_IMAGE_MODEL', 'gpt-image-1'),
  revenuecatCurrency: () => readParam(REVENUECAT_CURRENCY, 'REVENUECAT_CURRENCY', 'CRD'),
};

module.exports = {
  REGION,
  DOCS_COLLECTION,
  SPENDS_COLLECTION,
  USERS_COLLECTION,
  LOCKS_COLLECTION,
  TASK_QUEUE,
  TASK_QUEUE_RESOURCE,
  IN_PROGRESS_STATUSES,
  ACTIVE_LOCK_MS,
  STALE_MS,
  MAX_PROMPT_CHARS,
  MAX_SHORT_CHARS,
  MAX_MAP_ENTRIES,
  MAX_SYSTEM_PROMPT_CHARS,
  SWEEP_BATCH,
  GENERATION_PLANS,
  OUTLINE_MIN_SECTIONS,
  generationPlan,
  GENERATE_TIMEOUT_SECONDS,
  GENERATE_MAX_ATTEMPTS,
  GENERATE_MIN_BACKOFF_SECONDS,
  GENERATE_MAX_BACKOFF_SECONDS,
  GENERATE_MAX_CONCURRENT_DISPATCHES,
  QUEUE_STALE_MS,
  QUEUE_ACTIVE_MS,
  SECTION_TIMEOUT_MS,
  DEADLINE_MARGIN_MS,
  CLOSE_MARGIN_MS,
  DEADLINE_GUARD_MS,
  COVER_FETCH_TIMEOUT_MS,
  COVER_WAIT_MS,
  DOCUGEN,
  HF_TOKEN,
  OPENAI_API_KEY,
  REVENUECAT_SECRET_KEY,
  REVENUECAT_PROJECT_ID,
  CREDIT_SECRETS,
  GENERATE_SECRETS,
  OPENAI_IMAGE_MODEL,
  REVENUECAT_CURRENCY,
  secrets,
  options,
};
