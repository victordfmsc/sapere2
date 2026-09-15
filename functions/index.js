'use strict';

const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { getFunctions } = require('firebase-admin/functions');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onTaskDispatched } = require('firebase-functions/v2/tasks');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { setGlobalOptions } = require('firebase-functions/v2');

const {
  REGION,
  TASK_QUEUE_RESOURCE,
  CREDIT_SECRETS,
  GENERATE_SECRETS,
  GENERATE_TIMEOUT_SECONDS,
  GENERATE_MAX_ATTEMPTS,
  GENERATE_MIN_BACKOFF_SECONDS,
  GENERATE_MAX_CONCURRENT_DISPATCHES,
  ASSIST_SECRETS,
  ASSIST_TIMEOUT_SECONDS,
} = require('./src/config');
const { sanitizeError } = require('./src/sanitize');
const credits = require('./src/credits');
const { runStory } = require('./src/story');
const { startStoryFlow, StartError } = require('./src/start');
const { sweepStalledDocs } = require('./src/sweep');
const { generateCommunityTextFlow, generateFlashcardsFlow } = require('./src/assist');

if (!getApps().length) initializeApp();

setGlobalOptions({ region: REGION, maxInstances: 10 });

// El saldo de la respuesta de startStory la app 1.4.1 solo lo escribe en el log:
// no puede retrasar la respuesta hasta el timeout de RevenueCat.
const START_BALANCE_TIMEOUT_MS = 3 * 1000;

function db() {
  return getFirestore();
}

function bucket() {
  return getStorage().bucket();
}

function defaultBucketName() {
  try {
    return bucket().name || '';
  } catch (_) {
    return '';
  }
}

exports.startStory = onCall(
  { region: REGION, secrets: CREDIT_SECRETS, timeoutSeconds: 120, memory: '256MiB' },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Hay que iniciar sesion');

    const firestore = db();
    let started;
    try {
      started = await startStoryFlow({
        db: firestore,
        uid,
        data: request.data || {},
        bucketName: defaultBucketName(),
        // dispatchDeadline = timeout de generateStory: con uno menor Cloud Tasks
        // relanzaria la tarea mientras la primera invocacion sigue generando.
        enqueue: (payload) => getFunctions()
          .taskQueue(TASK_QUEUE_RESOURCE)
          .enqueue(payload, { dispatchDeadlineSeconds: GENERATE_TIMEOUT_SECONDS }),
      });
    } catch (error) {
      if (error instanceof StartError) throw new HttpsError(error.code, error.message);
      console.error('[startStory] error inesperado:', sanitizeError(error));
      throw new HttpsError('internal', sanitizeError(error));
    }

    const balance = (await credits.getBalancesWithin(firestore, uid, START_BALANCE_TIMEOUT_MS)) || {
      revenuecat: 0,
      legacy: 0,
      total: 0,
    };

    return {
      docId: started.docId,
      status: 'pending',
      credits: {
        revenuecat: balance.revenuecat,
        legacy: balance.legacy,
        total: balance.total,
      },
    };
  },
);

exports.generateStory = onTaskDispatched(
  {
    region: REGION,
    secrets: GENERATE_SECRETS,
    retryConfig: {
      maxAttempts: GENERATE_MAX_ATTEMPTS,
      minBackoffSeconds: GENERATE_MIN_BACKOFF_SECONDS,
    },
    rateLimits: { maxConcurrentDispatches: GENERATE_MAX_CONCURRENT_DISPATCHES },
    timeoutSeconds: GENERATE_TIMEOUT_SECONDS,
    memory: '512MiB',
  },
  async (request) => {
    const deadline = Date.now() + GENERATE_TIMEOUT_SECONDS * 1000;
    const payload = request.data || {};
    const docId = payload.docId;
    const uid = payload.uid;
    if (!docId) {
      console.error('[generateStory] tarea sin docId, se descarta');
      return;
    }

    const retryCount = Number(request.retryCount || 0);
    const isFinalAttempt = retryCount >= GENERATE_MAX_ATTEMPTS - 1;

    await runStory({
      db: db(),
      bucket: bucket(),
      docId,
      uid,
      isFinalAttempt,
      attempt: retryCount,
      deadline,
    });
  },
);

exports.sweepStalled = onSchedule(
  {
    region: REGION,
    schedule: 'every 5 minutes',
    secrets: CREDIT_SECRETS,
    timeoutSeconds: 300,
    memory: '256MiB',
  },
  async () => {
    const result = await sweepStalledDocs(db());
    console.log(
      `[sweepStalled] revisados ${result.checked}, marcados ${result.marked}, cerrados parciales ${result.closed}, `
      + `reembolsados ${result.refunded}, liquidados ${result.settled}, errores ${result.errors}`,
    );
  },
);

// Callables de IA que sustituyen a Railway. Los flujos ya traducen los errores
// del Space a StartError; el plazo que les llega es el de esta invocacion.
// El limite de uso va por uid: una cuenta de email sin verificar o anonima se
// crea gratis con la API key publica de la app y lo multiplicaria. La app ya
// pide el email verificado al iniciar sesion.
async function runAssist(name, request, flow) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Hay que iniciar sesion');
  const token = request.auth.token || {};
  const provider = token.firebase && token.firebase.sign_in_provider;
  if (provider === 'anonymous' || (provider === 'password' && token.email_verified !== true)) {
    throw new HttpsError('permission-denied', 'verified_account_required');
  }
  const deadline = Date.now() + ASSIST_TIMEOUT_SECONDS * 1000;
  try {
    return await flow({ db: db(), uid, data: request.data || {}, deadline });
  } catch (error) {
    if (error instanceof StartError) throw new HttpsError(error.code, error.message);
    console.error(`[${name}] error inesperado:`, sanitizeError(error));
    throw new HttpsError('internal', sanitizeError(error));
  }
}

exports.generateCommunityText = onCall(
  { region: REGION, secrets: ASSIST_SECRETS, timeoutSeconds: ASSIST_TIMEOUT_SECONDS, memory: '256MiB' },
  (request) => runAssist('generateCommunityText', request, generateCommunityTextFlow),
);

exports.generateFlashcards = onCall(
  { region: REGION, secrets: ASSIST_SECRETS, timeoutSeconds: ASSIST_TIMEOUT_SECONDS, memory: '256MiB' },
  (request) => runAssist('generateFlashcards', request, generateFlashcardsFlow),
);

exports.creditsBalance = onCall(
  { region: REGION, secrets: CREDIT_SECRETS, timeoutSeconds: 30, memory: '256MiB' },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Hay que iniciar sesion');
    try {
      const balance = await credits.getBalances(db(), uid);
      return {
        revenuecat: balance.revenuecat,
        legacy: balance.legacy,
        total: balance.total,
        revenuecatAvailable: balance.revenuecatAvailable,
      };
    } catch (error) {
      console.error('[creditsBalance] error:', sanitizeError(error));
      throw new HttpsError('internal', sanitizeError(error));
    }
  },
);
