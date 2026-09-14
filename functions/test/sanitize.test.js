'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { sanitizeError, cleanEnvValue } = require('../src/sanitize');

test('sanitizeError no deja pasar claves de ningun proveedor', () => {
  const casos = [
    'OpenAI 401: Incorrect API key provided: sk-proj-ABCdef1234567890abcdef',
    'Hugging Face 401: invalid token hf_ABCdefGHIjkl1234567890',
    'Gemini 400: API key not valid AIzaSyABCdef1234567890ghi',
    'RevenueCat 401: Bearer sk_live_ABCdef1234567890',
    'fetch failed https://api.example.com/v1?key=SECRETO123456&x=1',
    'Error: OPENAI_API_KEY=sk-mi-clave-secreta no valida',
  ];

  for (const caso of casos) {
    const limpio = sanitizeError(new Error(caso));
    assert.ok(limpio.includes('<redacted>'), `no se ha redactado: ${caso}`);
    for (const fragmento of ['sk-proj-ABCdef1234567890abcdef', 'hf_ABCdefGHIjkl1234567890', 'AIzaSyABCdef1234567890ghi', 'sk_live_ABCdef1234567890', 'SECRETO123456', 'sk-mi-clave-secreta']) {
      assert.ok(!limpio.includes(fragmento), `se ha filtrado ${fragmento} en: ${limpio}`);
    }
  }
});

test('sanitizeError recorta a una linea y a 300 caracteres', () => {
  const largo = sanitizeError(new Error(`primera linea\nsegunda linea\n${'x'.repeat(500)}`));
  assert.equal(largo, 'primera linea');
  assert.ok(sanitizeError(new Error('y'.repeat(900))).length <= 300);
});

test('sanitizeError elimina claves privadas PEM completas', () => {
  const pem = '-----BEGIN PRIVATE KEY-----MIIEvQIBADANBgkq-----END PRIVATE KEY-----';
  const limpio = sanitizeError(new Error(`credencial mala ${pem}`));
  assert.ok(!limpio.includes('MIIEvQIBADANBgkq'));
  assert.ok(limpio.includes('<redacted>'));
});

test('sanitizeError aguanta errores que no son Error', () => {
  assert.equal(sanitizeError('fallo suelto'), 'fallo suelto');
  assert.equal(sanitizeError(null), 'null');
  assert.equal(sanitizeError(undefined), 'undefined');
});

test('cleanEnvValue rescata la clave cuando pegan un .env entero', () => {
  const pegote = 'OPENAI_API_KEY=sk-valor-real\nGEMINI_API_KEY=otra\nHF_TOKEN=tercera';
  assert.equal(cleanEnvValue(pegote, 'OPENAI_API_KEY'), 'sk-valor-real');
  assert.equal(cleanEnvValue('"entrecomillada"', 'X'), 'entrecomillada');
  assert.equal(cleanEnvValue('  limpia  ', 'X'), 'limpia');
  assert.equal(cleanEnvValue('', 'X'), '');
  assert.equal(cleanEnvValue(undefined, 'X'), '');
});
