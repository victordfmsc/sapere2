'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

// Red de seguridad: si una prueba llegara a tocar Firestore iria a un emulador
// inexistente, nunca al proyecto real.
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:9';
process.env.GCLOUD_PROJECT = 'demo-sapere-test';

const { HttpsError } = require('firebase-functions/v2/https');
const functions = require('../index');

test('index: generateCommunityText y generateFlashcards con la region, el secreto, el timeout y la memoria del contrato', () => {
  for (const name of ['generateCommunityText', 'generateFlashcards']) {
    const endpoint = functions[name].__endpoint;
    assert.deepEqual(endpoint.callableTrigger, {}, name);
    assert.deepEqual(endpoint.region, ['europe-west1'], name);
    assert.equal(endpoint.timeoutSeconds, 300, name);
    assert.equal(endpoint.availableMemoryMb, 256, name);
    assert.deepEqual(endpoint.secretEnvironmentVariables, [{ key: 'HF_TOKEN' }], name);
  }
});

test('index: una cuenta de email sin verificar o anonima no llega al flujo de IA; verificada o de Google/Apple, si', async () => {
  const auth = (provider, extra = {}) => ({ uid: 'u1', token: { firebase: { sign_in_provider: provider }, ...extra } });
  // Entrada no valida a proposito: si el filtro deja pasar, el flujo responde
  // invalid-argument sin tocar Firestore.
  const invalid = { generateCommunityText: { prompt: '', languageCode: 'es_ES' }, generateFlashcards: { postId: '../x' } };
  const cases = [
    { name: 'generateCommunityText', auth: auth('password', { email_verified: false }), code: 'permission-denied' },
    { name: 'generateFlashcards', auth: auth('password', { email_verified: false }), code: 'permission-denied' },
    { name: 'generateFlashcards', auth: auth('password'), code: 'permission-denied' },
    { name: 'generateCommunityText', auth: auth('anonymous'), code: 'permission-denied' },
    { name: 'generateCommunityText', auth: auth('password', { email_verified: true }), code: 'invalid-argument' },
    { name: 'generateFlashcards', auth: auth('google.com', { email_verified: true }), code: 'invalid-argument' },
    { name: 'generateFlashcards', auth: auth('apple.com'), code: 'invalid-argument' },
  ];
  for (const { name, auth: requestAuth, code } of cases) {
    await assert.rejects(
      () => functions[name].run({ auth: requestAuth, data: invalid[name] }),
      (error) => error instanceof HttpsError && error.code === code,
      `${name} ${JSON.stringify(requestAuth.token)} -> ${code}`,
    );
  }
});

test('index: sin sesion o con entrada no valida responden HttpsError con el code del flujo, antes de tocar Firestore', async () => {
  const cases = [
    { name: 'generateCommunityText', request: { auth: null, data: { prompt: 'tema', languageCode: 'es_ES' } }, code: 'unauthenticated' },
    { name: 'generateFlashcards', request: { data: { postId: 'p1' } }, code: 'unauthenticated' },
    { name: 'generateCommunityText', request: { auth: { uid: 'u1' }, data: { prompt: '', languageCode: 'es_ES' } }, code: 'invalid-argument' },
    { name: 'generateCommunityText', request: { auth: { uid: 'u1' }, data: null }, code: 'invalid-argument' },
    { name: 'generateFlashcards', request: { auth: { uid: 'u1' }, data: { postId: '../x' } }, code: 'invalid-argument' },
  ];
  for (const { name, request, code } of cases) {
    await assert.rejects(
      () => functions[name].run(request),
      (error) => error instanceof HttpsError && error.code === code,
      `${name} -> ${code}`,
    );
  }
});
