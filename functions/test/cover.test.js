'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { installFetch } = require('./helpers/fetch');
const { generateCover } = require('../src/cover');
const { buildCoverPrompt, COVER_NEGATIVE } = require('../src/prompts');

const VISUAL = 'a lighthouse swallowed by a storm at dusk';

test('portada: si OpenAI falla con los dos modelos, entra Pollinations', async (t) => {
  process.env.OPENAI_API_KEY = 'sk-fake-key-para-pruebas';
  process.env.OPENAI_IMAGE_MODEL = 'gpt-image-1';
  t.after(() => {
    delete process.env.OPENAI_API_KEY;
    delete process.env.OPENAI_IMAGE_MODEL;
  });

  const modelsTried = [];
  const net = installFetch([
    {
      match: 'api.openai.com/v1/images/generations',
      respond: (url, init) => {
        modelsTried.push(JSON.parse(init.body).model);
        return { status: 403, json: { error: { message: 'organization must be verified' } } };
      },
    },
    {
      match: 'image.pollinations.ai',
      respond: { status: 200, body: 'bytes-de-imagen', headers: { 'content-type': 'image/jpeg' } },
    },
  ]);
  t.after(net.restore);

  const cover = await generateCover(VISUAL);

  assert.equal(cover.provider, 'pollinations');
  assert.equal(cover.contentType, 'image/jpeg');
  assert.equal(cover.buffer.toString(), 'bytes-de-imagen');
  assert.deepEqual(modelsTried, ['gpt-image-1', 'dall-e-3'], 'antes de rendirse reintenta con dall-e-3');
  assert.ok(
    net.calls.every((call) => call.init && call.init.signal instanceof AbortSignal),
    'cada peticion de imagen lleva su tope de tiempo',
  );

  const pollUrl = net.urls().find((u) => u.includes('pollinations'));
  assert.ok(pollUrl.includes('width=768&height=1024&nologo=true'));
  assert.ok(decodeURIComponent(pollUrl).includes(COVER_NEGATIVE));
});

test('portada: OpenAI devuelve b64_json y no se llama a Pollinations', async (t) => {
  process.env.OPENAI_API_KEY = 'sk-fake-key-para-pruebas';
  t.after(() => delete process.env.OPENAI_API_KEY);

  const net = installFetch([
    {
      match: 'api.openai.com/v1/images/generations',
      respond: { status: 200, json: { data: [{ b64_json: Buffer.from('imagen-openai').toString('base64') }] } },
    },
  ]);
  t.after(net.restore);

  const cover = await generateCover(VISUAL);
  assert.equal(cover.provider, 'openai');
  assert.equal(cover.buffer.toString(), 'imagen-openai');
  assert.equal(net.calls.length, 1);
});

test('portada: sin clave de OpenAI se va directo a Pollinations', async (t) => {
  delete process.env.OPENAI_API_KEY;
  const net = installFetch([
    { match: 'image.pollinations.ai', respond: { status: 200, body: 'bytes', headers: { 'content-type': 'image/jpeg' } } },
  ]);
  t.after(net.restore);

  const cover = await generateCover(VISUAL);
  assert.equal(cover.provider, 'pollinations');
  assert.equal(net.calls.length, 1);
});

test('el prompt de portada prohibe siempre texto y tipografia', () => {
  assert.ok(buildCoverPrompt(VISUAL).includes(COVER_NEGATIVE));
  assert.ok(buildCoverPrompt('').includes(COVER_NEGATIVE));
});
