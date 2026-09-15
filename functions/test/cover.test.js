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

  const bodies = [];
  const net = installFetch([
    {
      match: 'api.openai.com/v1/images/generations',
      respond: (url, init) => {
        bodies.push(JSON.parse(init.body));
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
  assert.deepEqual(bodies.map((body) => body.model), ['gpt-image-1', 'gpt-image-2'], 'antes de rendirse reintenta con gpt-image-2');
  for (const body of bodies) {
    assert.equal(body.size, '1024x1536');
    assert.equal(body.quality, 'medium');
    assert.equal(body.response_format, undefined, 'los modelos GPT Image no llevan response_format');
  }
  assert.ok(
    net.calls.every((call) => call.init && call.init.signal instanceof AbortSignal),
    'cada peticion de imagen lleva su tope de tiempo',
  );

  const pollUrl = net.urls().find((u) => u.includes('pollinations'));
  assert.ok(pollUrl.includes('width=768&height=1024&nologo=true'));
  assert.ok(decodeURIComponent(pollUrl).includes(COVER_NEGATIVE));
});

test('portada: por defecto pide gpt-image-2 (gpt-image-1 se apaga el 2026-10-23) y, si falla, no lo repite: entra Pollinations', async (t) => {
  process.env.OPENAI_API_KEY = 'sk-fake-key-para-pruebas';
  delete process.env.OPENAI_IMAGE_MODEL;
  t.after(() => delete process.env.OPENAI_API_KEY);
  t.mock.method(console, 'warn', () => {});

  const models = [];
  const net = installFetch([
    {
      match: 'api.openai.com/v1/images/generations',
      respond: (url, init) => {
        models.push(JSON.parse(init.body).model);
        return { status: 400, json: { error: { message: 'rejected by the safety system' } } };
      },
    },
    { match: 'image.pollinations.ai', respond: { status: 200, body: 'bytes', headers: { 'content-type': 'image/jpeg' } } },
  ]);
  t.after(net.restore);

  const cover = await generateCover(VISUAL);
  assert.equal(cover.provider, 'pollinations');
  assert.deepEqual(models, ['gpt-image-2']);
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
