'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { FakeFirestore } = require('./helpers/firestore');
const { installFetch } = require('./helpers/fetch');
const {
  createSpace,
  sse,
  sectionText,
  sectionStream,
} = require('./helpers/space');
const {
  runStory,
  buildInitialDoc,
  advanceStatus,
  acquireGenerationLock,
  releaseGenerationLock,
  resumeState,
  hasActiveGeneration,
  refundDoc,
} = require('../src/story');
const { GENERATION_PLANS, QUEUE_ACTIVE_MS } = require('../src/config');

const BUCKET = { name: 'sapere-f7150.firebasestorage.app' };
const MINUTE = 60 * 1000;
const TOKEN = 'hf_test_token_para_pruebas';
const PROMPT = 'La expedicion de Shackleton';

function seedDoc(overrides = {}, generation = {}) {
  const type = overrides.type || 'sapere';
  const plan = GENERATION_PLANS[type];
  const doc = buildInitialDoc({
    uid: 'u1',
    docId: 'doc1',
    prompt: PROMPT,
    genre: 'Historia',
    type,
    language: 'Spanish (Spain)',
    languageCode: 'es_ES',
    coverUrl: '',
    chapters: plan.sections,
    durationMinutes: plan.durationMinutes,
    spendId: 'spend1',
  });
  doc.generation.systemPromptSource = 'framework';
  return { ...doc, ...overrides, generation: { ...doc.generation, ...generation } };
}

function fakeClock(start = 1000000) {
  let now = start;
  return {
    now: () => now,
    sleep: async (ms) => {
      now += ms;
    },
  };
}

// El cliente del Space es el real (fetch interceptado); portada, subida y
// creditos son dobles.
function fakeDeps({ clock = fakeClock() } = {}) {
  const log = { covers: 0, uploads: 0, refunds: 0, settles: 0, coverPrompts: [] };
  return {
    log,
    deps: {
      docugenOptions: { token: TOKEN, now: clock.now, sleep: clock.sleep },
      cover: {
        async generateCover(prompt) {
          log.covers += 1;
          log.coverPrompts.push(prompt);
          return { buffer: Buffer.from('png'), contentType: 'image/png', provider: 'openai' };
        },
      },
      storage: {
        async uploadCover(bucket, docId) {
          log.uploads += 1;
          return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/covers%2F${docId}.png?alt=media&token=tok`;
        },
      },
      credits: {
        async refundSpend() {
          log.refunds += 1;
          return { refunded: true, source: 'revenuecat', uid: 'u1' };
        },
        async settleSpend() {
          log.settles += 1;
          return { settled: true };
        },
      },
    },
  };
}

function withSpace(t, options) {
  const space = createSpace(options);
  const net = installFetch(space.routes);
  t.after(net.restore);
  return { space, net };
}

const LOCK = { u1: { uid: 'u1', docId: 'doc1', acquiredAt: new Date() } };
const SPEND = {
  uid: 'u1',
  docId: 'doc1',
  source: 'revenuecat',
  applied: true,
  settled: false,
  refunded: false,
  refundState: 'pending',
  refundAttempts: 0,
  createdAt: new Date(),
};

test('idempotente: un documento ya completado no se toca ni se llama al Space', async (t) => {
  const db = new FakeFirestore({
    sapere: { doc1: seedDoc({ status: 'completed', description: ['ya escrito'], readyToRead: true }) },
  });
  const { net } = withSpace(t);
  const { deps, log } = fakeDeps();
  db.writes = 0;

  const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', deps });

  assert.deepEqual(result, { skipped: true, reason: 'already_completed' });
  assert.equal(db.writes, 0);
  assert.equal(net.calls.length, 0);
  assert.equal(log.covers + log.refunds + log.settles, 0);
});

test('flujo completo: titulo, escaleta, portada y 6 secciones encadenadas; completed, gasto liquidado y cerrojo suelto', async (t) => {
  const db = new FakeFirestore({ sapere: { doc1: seedDoc() }, generationLocks: { ...LOCK } });
  const readyWhenCalled = [];
  const { space } = withSpace(t, {
    section: () => {
      readyWhenCalled.push(db.dump('sapere').doc1.readyToRead);
      return undefined;
    },
  });
  const { deps, log } = fakeDeps();

  const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', deps });
  const doc = db.dump('sapere').doc1;

  assert.equal(result.status, 'completed');
  assert.equal(result.sections, 6);
  assert.equal(doc.status, 'completed');
  assert.equal(doc.bukbukName, 'Hielo y hambre');
  assert.equal(doc.outline, '1. El barco\n2. El hielo\n3. La huida');
  assert.equal(doc.readyToRead, true);
  assert.equal(doc.bukbukUrl, '');
  assert.equal(doc.errorMessage, null);
  assert.equal(doc.generation.textProvider, 'docugen');
  assert.equal(doc.generation.coverProvider, 'openai');
  assert.equal(doc.generation.area, 'historia');
  assert.ok(doc.generation.attemptStartedAt, 'latido de inicio de intento');
  assert.equal(doc.generation.awaitingRetry, false);
  assert.match(doc.newCover, /covers%2Fdoc1\.png\?alt=media&token=/);

  assert.equal(doc.chaptersMeta.length, 6);
  assert.deepEqual(doc.chaptersMeta.map((c) => c.title), [1, 2, 3, 4, 5, 6].map((n) => `Parte ${n} de 6`));
  assert.deepEqual(doc.chaptersMeta.map((c) => c.raw), [1, 2, 3, 4, 5, 6].map((n) => sectionText(n, 6)));
  assert.equal(doc.description.length, 18);
  assert.deepEqual(doc.description.slice(0, 3), ['Sección 1: Parte 1 de 6', 'Párrafo A de la sección 1.', 'Párrafo B de la sección 1.']);
  assert.ok(doc.description.every((p) => !p.includes('#') && !p.includes('RAZONAMIENTO')));
  assert.deepEqual(readyWhenCalled, [false, true, true, true, true, true], 'legible desde la primera seccion');

  assert.equal(log.settles, 1);
  assert.equal(log.refunds, 0);
  assert.equal(db.dump('generationLocks').u1, undefined);

  assert.deepEqual(space.log.titles, [{ input: PROMPT, area: 'historia', language: 'español' }]);
  assert.equal(space.log.outlines.length, 1);
  assert.equal(space.log.outlines[0].duration_minutes, 30);

  assert.equal(space.log.sections.length, 6);
  space.log.sections.forEach((call, i) => {
    const { messages } = call.body;
    const assistants = messages.filter((m) => m.role === 'assistant');
    assert.equal(call.area, 'historia');
    assert.equal(call.body.duration_minutes, 30);
    assert.equal(messages[0].role, 'system');
    assert.match(messages[0].content, /1\. El barco/, 'la escaleta viaja en el extra');
    assert.match(messages[0].content, new RegExp(`Esta es la sección ${i + 1} de 6`));
    assert.equal(messages[1].content, PROMPT);
    assert.equal(messages[messages.length - 1].role, 'user');
    assert.deepEqual(assistants.map((m) => m.content), Array.from({ length: i }, (_, k) => sectionText(k + 1, 6)));
    assert.ok(messages.every((m) => !m.content.includes('RAZONAMIENTO-OCULTO')));
  });
  const ids = space.log.sections.map((c) => c.body.conversation_id);
  assert.equal(new Set(ids).size, 6, 'conversation_id nuevo en cada llamada');
  assert.deepEqual([...space.log.deletes].sort(), [...ids].sort(), 'DELETE de cada conversacion');

  assert.equal(log.covers, 1);
  assert.match(log.coverPrompts[0], /Hielo y hambre/);
  assert.match(log.coverPrompts[0], /Shackleton/);
});

test('por tipo: gamificacion 4 secciones de 20 min, preview 1 sin escaleta; el marco solo viaja si lo eligio el usuario', async () => {
  const cases = [
    { type: 'gamification_episode', source: 'gamification_client', framework: 'Eres la profesora de Historia.', sections: 4, minutes: 20, outline: 1, sent: true },
    { type: 'sapere', source: 'framework', framework: 'Marco aleatorio antiguo.', sections: 6, minutes: 30, outline: 1, sent: false },
    { type: 'preview', source: 'type', framework: 'Marco del tipo.', sections: 1, minutes: 5, outline: 0, sent: true },
  ];
  for (const c of cases) {
    const db = new FakeFirestore({
      sapere: { doc1: seedDoc({ type: c.type }, { systemPrompt: c.framework, systemPromptSource: c.source }) },
    });
    const space = createSpace();
    const net = installFetch(space.routes);
    try {
      const { deps } = fakeDeps();
      const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', deps });
      const doc = db.dump('sapere').doc1;
      assert.equal(result.status, 'completed', c.type);
      assert.equal(space.log.sections.length, c.sections, c.type);
      assert.equal(space.log.outlines.length, c.outline, c.type);
      assert.equal(doc.chaptersMeta.length, c.sections);
      for (const call of space.log.sections) {
        assert.equal(call.body.duration_minutes, c.minutes, c.type);
        assert.equal(call.body.messages[0].content.includes(c.framework), c.sent, c.type);
      }
      if (!c.outline) assert.equal(doc.outline, undefined);
    } finally {
      net.restore();
    }
  }
});

test('si el titulo del Space falla se usa el tema recortado y la generacion sigue', async (t) => {
  const db = new FakeFirestore({ sapere: { doc1: seedDoc({ type: 'preview' }) } });
  withSpace(t, { title: { status: 500, json: { detail: 'Error de la API DeepSeek: Connection error.' } } });
  const { deps, log } = fakeDeps();

  const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', deps });
  const doc = db.dump('sapere').doc1;

  assert.equal(result.status, 'completed');
  assert.equal(doc.bukbukName, PROMPT);
  assert.equal(log.refunds, 0);
});

test('si la escaleta falla sin ser fatal, el guion sigue sin ella y no se guarda', async (t) => {
  const db = new FakeFirestore({ sapere: { doc1: seedDoc({ type: 'gamification_episode' }) } });
  const { space } = withSpace(t, { outline: { status: 500, json: { detail: 'timeout upstream' } } });
  const { deps } = fakeDeps();

  const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', deps });

  assert.equal(result.status, 'completed');
  assert.equal(db.dump('sapere').doc1.outline, undefined);
  assert.equal(space.log.sections.length, 4);
  assert.ok(space.log.sections.every((call) => !call.body.messages[0].content.includes('Escaleta')));
});

test('DeepSeek sin saldo (evento error 402) es FATAL: error + reembolso aunque queden intentos', async (t) => {
  const db = new FakeFirestore({ sapere: { doc1: seedDoc() }, generationLocks: { ...LOCK }, creditSpends: { spend1: SPEND } });
  const { space } = withSpace(t, {
    section: (call) => (call.number === 3
      ? { status: 200, stream: sse([{ type: 'error', detail: "Error de la API DeepSeek: Error code: 402 - {'error': {'message': 'Insufficient Balance'}}" }]) }
      : undefined),
  });
  const { deps, log } = fakeDeps();

  const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', isFinalAttempt: false, deps });
  const doc = db.dump('sapere').doc1;

  assert.equal(result.status, 'error');
  assert.equal(result.fatal, true);
  assert.equal(doc.status, 'error');
  assert.match(doc.errorMessage, /sin saldo/);
  assert.equal(doc.generation.refunded, true);
  assert.equal(log.refunds, 1);
  assert.equal(log.settles, 0);
  assert.equal(space.log.sections.length, 3, 'no se sigue llamando tras un fatal');
  assert.equal(db.dump('generationLocks').u1, undefined);
  const spend = db.dump('creditSpends').spend1;
  assert.ok(spend.deliveredAt, 'hubo entrega (2 secciones)');
  assert.ok(spend.closedInErrorAt, 'y el servidor lo cerro en error: si la app borra el documento, se devuelve');
});

test('DeepSeek sin saldo ya en el titulo (HTTP 500 + 402) es FATAL: error y reembolso sin portada, escaleta ni secciones', async () => {
  for (const type of ['sapere', 'preview']) {
    const db = new FakeFirestore({ sapere: { doc1: seedDoc({ type }) }, generationLocks: { ...LOCK } });
    const space = createSpace({
      title: { status: 500, json: { detail: "Error de la API DeepSeek: Error code: 402 - {'error': {'message': 'Insufficient Balance'}}" } },
    });
    const net = installFetch(space.routes);
    try {
      const { deps, log } = fakeDeps();
      const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', isFinalAttempt: false, deps });
      const doc = db.dump('sapere').doc1;

      assert.equal(result.status, 'error', type);
      assert.equal(result.fatal, true, type);
      assert.equal(doc.status, 'error', type);
      assert.match(doc.errorMessage, /sin saldo/, type);
      assert.equal(doc.bukbukName, '', `${type}: sin titulo de respaldo`);
      assert.equal(log.refunds, 1, type);
      assert.equal(log.covers + log.uploads, 0, `${type}: ninguna portada`);
      assert.equal(space.log.outlines.length + space.log.sections.length, 0, type);
      assert.equal(db.dump('generationLocks').u1, undefined, type);
    } finally {
      net.restore();
    }
  }
});

test('runtime 401 es FATAL: error + reembolso sin reintentar y sin llegar a las secciones', async (t) => {
  const db = new FakeFirestore({ sapere: { doc1: seedDoc() } });
  const { space } = withSpace(t, {
    title: { status: 404, text: 'Not Found' },
    outline: { status: 404, text: 'Not Found' },
    section: () => ({ status: 404, text: 'Not Found' }),
    runtime: [{ status: 401, json: { error: 'Invalid credentials' } }],
  });
  const { deps, log } = fakeDeps();

  const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', isFinalAttempt: false, deps });
  const doc = db.dump('sapere').doc1;

  assert.equal(result.status, 'error');
  assert.equal(result.fatal, true);
  assert.match(doc.errorMessage, /HF_TOKEN sin acceso al Space Bukbuk\/DocuGenerator/);
  assert.equal(log.refunds, 1);
  assert.equal(log.covers, 0, 'un fatal en el titulo no paga portada');
  assert.equal(log.uploads, 0);
  assert.equal(space.log.runtimes, 1);
  assert.equal(space.log.outlines.length, 0);
  assert.equal(space.log.sections.length, 0);
});

test('5xx en la seccion 3 es reintentable; el reintento reanuda desde la 3, sin repetir las anteriores y con la escaleta guardada', async (t) => {
  const db = new FakeFirestore({ sapere: { doc1: seedDoc() } });
  const { deps, log } = fakeDeps();

  const first = createSpace({
    section: (call) => (call.number === 3 ? { status: 500, json: { detail: 'upstream exploded' } } : undefined),
  });
  let net = installFetch(first.routes);
  try {
    await assert.rejects(
      () => runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', isFinalAttempt: false, attempt: 0, deps }),
      (error) => error.fatal === false && /500/.test(error.message),
    );
  } finally {
    net.restore();
  }

  let doc = db.dump('sapere').doc1;
  assert.equal(doc.status, 'generating_script');
  assert.equal(doc.readyToRead, true);
  assert.equal(doc.chaptersMeta.length, 2);
  assert.equal(doc.description.length, 6);
  assert.match(doc.generation.lastError, /500/);
  assert.equal(doc.generation.awaitingRetry, true, 'espera su reintento en la cola');
  assert.equal(log.refunds, 0);
  assert.equal(first.log.sections.length, 3);

  const second = createSpace();
  net = installFetch(second.routes);
  t.after(net.restore);
  const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', isFinalAttempt: false, attempt: 1, deps });
  doc = db.dump('sapere').doc1;

  assert.equal(result.status, 'completed');
  assert.equal(second.log.titles.length, 0, 'el titulo ya estaba');
  assert.equal(second.log.outlines.length, 0, 'la escaleta guardada se reutiliza');
  assert.deepEqual(second.log.sections.map((c) => c.number), [3, 4, 5, 6], 'no se repiten las secciones escritas');
  const history = second.log.sections[0].body.messages;
  assert.deepEqual(history.filter((m) => m.role === 'assistant').map((m) => m.content), [sectionText(1, 6), sectionText(2, 6)]);
  assert.match(history[0].content, /1\. El barco/);
  assert.match(second.log.sections[0].body.conversation_id, /-s3-a1-/);
  assert.deepEqual(doc.chaptersMeta.map((c) => c.index), [0, 1, 2, 3, 4, 5]);
  assert.equal(doc.description.length, 18);
  assert.equal(doc.generation.lastError, null);
  assert.equal(doc.generation.awaitingRetry, false, 'el nuevo intento ya no esta en cola');
  assert.equal(log.settles, 1);
  assert.equal(log.refunds, 0);
  assert.equal(log.covers, 1, 'la portada del primer intento no se repite');
});

test('borrado antes de que empiece la tarea: no llama al Space y suelta el cerrojo', async (t) => {
  const db = new FakeFirestore({ generationLocks: { ...LOCK } });
  const { net } = withSpace(t);
  const { deps, log } = fakeDeps();

  const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', deps });

  assert.deepEqual(result, { skipped: true, reason: 'not_found' });
  assert.equal(net.calls.length, 0);
  assert.equal(log.covers + log.settles + log.refunds, 0);
  assert.equal(db.dump('generationLocks').u1, undefined, 'el usuario puede crear otro sin esperar 60 min');
});

test('borrado por su dueno: con texto ya escrito la tarea liquida y suelta el cerrojo; sin texto no liquida, pero tambien lo suelta', async () => {
  for (const { deleteOn, settles, delivered } of [
    { deleteOn: 2, settles: 1, delivered: [false, true] },
    { deleteOn: 1, settles: 0, delivered: [false] },
  ]) {
    const db = new FakeFirestore({
      sapere: { doc1: seedDoc({ type: 'gamification_episode' }) },
      creditSpends: { spend1: SPEND },
      generationLocks: { ...LOCK },
    });
    const deliveredWhenCalled = [];
    const space = createSpace({
      section: (call) => {
        deliveredWhenCalled.push(Boolean(db.dump('creditSpends').spend1.deliveredAt));
        if (call.number === deleteOn) db.store.delete('sapere/doc1');
        return undefined;
      },
    });
    const net = installFetch(space.routes);
    try {
      const { deps, log } = fakeDeps();
      const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', isFinalAttempt: false, deps });

      assert.deepEqual(result, { skipped: true, reason: 'not_found' }, `borrado en la seccion ${deleteOn}`);
      assert.deepEqual(deliveredWhenCalled, delivered, 'la marca de entrega viaja con la primera seccion');
      assert.equal(space.log.sections.length, deleteOn);
      assert.equal(log.settles, settles, `borrado en la seccion ${deleteOn}`);
      assert.equal(log.refunds, 0);
      assert.equal(db.dump('generationLocks').u1, undefined, `borrado en la seccion ${deleteOn}: el cerrojo no bloquea 60 min`);
    } finally {
      net.restore();
    }
  }
});

test('una portada colgada no retiene el cierre: se espera acotado, tanto al completar como al fallar', async () => {
  const cases = [
    { section: undefined, isFinalAttempt: false, status: 'completed', refunds: 0 },
    { section: { status: 503, json: { error: 'overloaded' } }, isFinalAttempt: true, status: 'error', refunds: 1 },
  ];
  for (const c of cases) {
    const db = new FakeFirestore({ sapere: { doc1: seedDoc({ type: 'preview' }) }, generationLocks: { ...LOCK } });
    const space = createSpace({ section: () => c.section });
    const net = installFetch(space.routes);
    try {
      const { deps, log } = fakeDeps();
      deps.cover.generateCover = () => new Promise(() => {});
      deps.coverWaitMs = 20;

      const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', isFinalAttempt: c.isFinalAttempt, deps });
      const doc = db.dump('sapere').doc1;

      assert.equal(result.status, c.status);
      assert.equal(doc.status, c.status);
      assert.equal(doc.newCover, '');
      assert.equal(log.refunds, c.refunds);
      assert.equal(db.dump('generationLocks').u1, undefined);
    } finally {
      net.restore();
    }
  }
});

test('hasActiveGeneration: lo que espera en la cola sigue activo pasados 60 min; lo que se generaba y lleva 60 min sin latido, no', async () => {
  const now = Date.now();
  const at = (minutes) => new Date(now - minutes * MINUTE);
  const queueMinutes = QUEUE_ACTIVE_MS / MINUTE;
  const cases = [
    { name: 'sin despachar', data: { status: 'pending', updatedAt: at(90), publishTime: at(90), generation: {} }, active: true },
    {
      name: 'esperando reintento',
      data: { status: 'generating_script', updatedAt: at(90), publishTime: at(120), generation: { attemptStartedAt: at(100), awaitingRetry: true } },
      active: true,
    },
    {
      name: 'generando sin latido',
      data: { status: 'generating_script', updatedAt: at(61), publishTime: at(120), generation: { attemptStartedAt: at(100), awaitingRetry: false } },
      active: false,
    },
    { name: 'despachado sin latido', data: { status: 'pending', updatedAt: at(61), publishTime: at(61), generation: { attemptStartedAt: at(61) } }, active: false },
    {
      name: 'en cola mas alla del tope',
      data: { status: 'pending', updatedAt: at(queueMinutes + 1), publishTime: at(queueMinutes + 1), generation: {} },
      active: false,
    },
  ];
  for (const { name, data, active } of cases) {
    const db = new FakeFirestore({ sapere: { d: { uId: 'u1', ...data } } });
    assert.equal(await hasActiveGeneration(db, 'u1', now), active, name);
  }
});

test('en el ultimo intento un fallo reintentable cierra en error y reembolsa', async (t) => {
  const db = new FakeFirestore({ sapere: { doc1: seedDoc({ type: 'preview' }) } });
  withSpace(t, { section: () => ({ status: 503, json: { error: 'overloaded' } }) });
  const { deps, log } = fakeDeps();

  const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', isFinalAttempt: true, deps });
  const doc = db.dump('sapere').doc1;

  assert.equal(result.status, 'error');
  assert.equal(result.fatal, false);
  assert.equal(doc.status, 'error');
  assert.equal(doc.generation.refunded, true);
  assert.equal(log.refunds, 1);
});

test('guarda de plazo: con menos de 8 minutos por delante no se empieza otra seccion y se deja reintentar', async (t) => {
  const clock = fakeClock();
  const db = new FakeFirestore({ sapere: { doc1: seedDoc() } });
  const { space } = withSpace(t, {
    section: () => {
      clock.sleep(4 * MINUTE);
      return undefined;
    },
  });
  const { deps, log } = fakeDeps({ clock });
  deps.now = clock.now;
  const deadline = clock.now() + 20 * MINUTE;

  await assert.rejects(
    () => runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', isFinalAttempt: false, deadline, deps }),
    (error) => error.fatal === false && /Quedan menos de 8 min/.test(error.message),
  );
  const doc = db.dump('sapere').doc1;

  assert.equal(space.log.sections.length, 4, 'con 20 min y secciones de 4 min caben 4 antes de la guarda');
  assert.equal(doc.chaptersMeta.length, 4);
  assert.equal(doc.status, 'generating_script');
  assert.match(doc.generation.lastError, /Quedan menos de 8 min/);
  assert.equal(log.refunds, 0);
});

test('si el barrido cierra el documento a mitad de generacion, la tarea no lo entrega', async (t) => {
  const db = new FakeFirestore({ sapere: { doc1: seedDoc({ type: 'gamification_episode' }) } });
  const { space } = withSpace(t, {
    section: (call) => {
      if (call.number === 2) {
        const current = db.store.get('sapere/doc1');
        db.store.set('sapere/doc1', { ...current, status: 'error', generation: { ...current.generation, refunded: true } });
      }
      return undefined;
    },
  });
  const { deps, log } = fakeDeps();

  const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', deps });
  const doc = db.dump('sapere').doc1;

  assert.equal(result.skipped, true);
  assert.equal(doc.status, 'error', 'completed no pisa al error del barrido');
  assert.equal(doc.chaptersMeta.length, 1, 'la segunda seccion no se escribe');
  assert.equal(space.log.sections.length, 2);
  assert.equal(log.settles, 0);
});

test('si el usuario trajo portada no se genera ninguna imagen', async (t) => {
  const db = new FakeFirestore({ sapere: { doc1: seedDoc({ type: 'preview', newCover: 'https://cdn.example/mia.png' }) } });
  withSpace(t);
  const { deps, log } = fakeDeps();

  await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', deps });
  const doc = db.dump('sapere').doc1;

  assert.equal(log.covers, 0);
  assert.equal(doc.newCover, 'https://cdn.example/mia.png');
  assert.equal(doc.generation.coverProvider, 'user');
});

test('un fallo de portada no tumba el guion', async (t) => {
  const db = new FakeFirestore({ sapere: { doc1: seedDoc({ type: 'preview' }) } });
  withSpace(t);
  const { deps } = fakeDeps();
  deps.cover.generateCover = async () => {
    throw new Error('OpenAI imagen 429: rate limit');
  };

  const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', deps });
  const doc = db.dump('sapere').doc1;

  assert.equal(result.status, 'completed');
  assert.equal(doc.newCover, '');
  assert.equal(doc.description.length, 3);
});

test('una tarea que llega tarde a un documento reembolsado o en error no genera nada', async (t) => {
  const { net } = withSpace(t);
  const cases = [
    { overrides: { status: 'error' }, generation: { refunded: true }, reason: 'refunded' },
    { overrides: { status: 'pending' }, generation: { refunded: true }, reason: 'refunded' },
    { overrides: { status: 'error' }, generation: {}, reason: 'terminated' },
  ];
  for (const { overrides, generation, reason } of cases) {
    const db = new FakeFirestore({ sapere: { doc1: seedDoc(overrides, generation) } });
    const { deps, log } = fakeDeps();
    db.writes = 0;

    const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', deps });

    assert.deepEqual(result, { skipped: true, reason });
    assert.equal(db.writes, 0);
    assert.equal(log.covers + log.settles + log.refunds, 0);
  }
  assert.equal(net.calls.length, 0, 'ni Space ni portada');
});

test("advanceStatus: 'error' es terminal y 'completed' no puede pisarlo", async () => {
  const db = new FakeFirestore({ sapere: { doc1: seedDoc({ status: 'error' }) } });
  const ref = db.collection('sapere').doc('doc1');

  const result = await advanceStatus(db, ref, 'completed', { description: ['colado'] });

  assert.equal(result.applied, false);
  assert.equal(db.dump('sapere').doc1.status, 'error');
  assert.deepEqual(db.dump('sapere').doc1.description, []);
});

test('resumeState reconstruye el texto bruto de documentos anteriores al formato con raw', () => {
  const state = resumeState({
    description: ['a', 'b', 'c'],
    chaptersMeta: [
      { index: 0, title: 'Capitulo 1', paragraphs: 2 },
      { index: 1, title: 'X', paragraphs: 1, raw: '## Sección Dos: X\n\nc' },
    ],
  }, 6);
  assert.deepEqual(state.chaptersMeta.map((m) => m.raw), ['a\n\nb', '## Sección Dos: X\n\nc']);
  assert.deepEqual(state.paragraphs, ['a', 'b', 'c']);
  assert.deepEqual(resumeState({ description: ['solo'] }, 6).chaptersMeta.map((m) => m.raw), ['solo']);
  assert.deepEqual(resumeState({ description: [] }, 6), { paragraphs: [], chaptersMeta: [] });
});

test('buildInitialDoc guarda el marco que decide startStory y, sin marco, lo deja vacio', () => {
  const base = { uid: 'u1', docId: 'doc1', prompt: 'tema', type: 'sapere', languageCode: 'es_ES', chapters: 6, durationMinutes: 30 };
  const withFramework = buildInitialDoc({ ...base, framework: 'Marco del tipo elegido.' });
  assert.equal(withFramework.generation.systemPrompt, 'Marco del tipo elegido.');
  assert.equal(withFramework.generation.chapters, 6);
  assert.equal(withFramework.generation.durationMinutes, 30);
  assert.equal(buildInitialDoc(base).generation.systemPrompt, '');
});

test('cerrojo de generacion: uno por usuario, caduca a los 60 minutos y solo lo suelta su documento', async () => {
  const db = new FakeFirestore();
  const now = Date.now();

  assert.equal(await acquireGenerationLock(db, 'u1', 'docA', now), true);
  assert.equal(await acquireGenerationLock(db, 'u1', 'docB', now + 50 * MINUTE), false);
  assert.equal(await releaseGenerationLock(db, 'u1', 'docB'), false, 'otro documento no suelta el cerrojo');
  assert.equal(await acquireGenerationLock(db, 'u1', 'docB', now + 61 * MINUTE), true, 'caducado');
  assert.equal(await releaseGenerationLock(db, 'u1', 'docB'), true);
  assert.equal(await acquireGenerationLock(db, 'u1', 'docC', now + 61 * MINUTE), true);
});

test('titulo de respaldo: si el Space falla o lo devuelve vacio se usa el provisional de la app antes que el tema, salvo que sea el tema recortado; en un fatal, ninguno', async () => {
  const provisional = 'La caída de Constantinopla';
  const tema = 'La caída de Constantinopla y el fin del Imperio bizantino';
  const balance = "Error de la API DeepSeek: Error code: 402 - {'error': {'message': 'Insufficient Balance'}}";
  const cases = [
    { title: { status: 500, json: { detail: 'Error de la API DeepSeek: Connection error.' } }, provisional, expected: provisional, status: 'completed' },
    { title: { status: 200, json: { title: '' } }, provisional, expected: provisional, status: 'completed' },
    { title: { status: 200, json: { title: '' } }, provisional: '', expected: PROMPT, status: 'completed' },
    // Lo que manda la app con un tema de mas de 40 caracteres (titleFromPrompt).
    { title: { status: 200, json: { title: '' } }, prompt: tema, provisional: `${tema.slice(0, 37)}...`, expected: tema, status: 'completed' },
    { title: { status: 500, json: { detail: balance } }, provisional, expected: '', status: 'error' },
  ];
  for (const c of cases) {
    const db = new FakeFirestore({
      sapere: { doc1: seedDoc({ type: 'preview', provisionalTitle: c.provisional, ...(c.prompt ? { prompt: c.prompt } : {}) }) },
    });
    const space = createSpace({ title: c.title });
    const net = installFetch(space.routes);
    try {
      const { deps, log } = fakeDeps();
      const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', deps });
      const doc = db.dump('sapere').doc1;
      const label = `${JSON.stringify(c.title.json)} con provisional '${c.provisional}'`;

      assert.equal(result.status, c.status, label);
      assert.equal(doc.bukbukName, c.expected, label);
      assert.equal(doc.provisionalTitle, c.provisional, label);
      if (c.status === 'completed') assert.ok(log.coverPrompts[0].includes(c.expected), 'la portada usa ese titulo');
    } finally {
      net.restore();
    }
  }
});

test("advanceStatus: un 'completed' no admite mas escritura que la portada que llega tarde", async () => {
  const completed = seedDoc({
    status: 'completed',
    readyToRead: true,
    description: Array.from({ length: 18 }, (_, i) => `p${i}`),
    chaptersMeta: Array.from({ length: 6 }, (_, index) => ({ index, paragraphs: 3, raw: `s${index}` })),
  }, { awaitingRetry: false });
  const db = new FakeFirestore({ sapere: { doc1: completed } });
  const ref = db.collection('sapere').doc('doc1');

  const rejected = [
    ['generating_script', { description: ['p0'], chaptersMeta: [{ index: 0 }] }],
    [null, { 'generation.awaitingRetry': true, 'generation.lastError': 'HTTP 500' }],
    [null, { newCover: 'https://x/colada.png', description: [] }],
    ['completed', { description: ['otra'] }],
    ['error', { errorMessage: 'tarde' }],
  ];
  for (const [status, extra] of rejected) {
    assert.deepEqual(await advanceStatus(db, ref, status, extra), { applied: false, reason: 'completed' }, JSON.stringify(extra));
  }
  assert.deepEqual(db.dump('sapere').doc1, completed, 'nada cambia');

  const cover = await advanceStatus(db, ref, null, { newCover: 'https://x/portada.png', 'generation.coverProvider': 'openai' });
  const doc = db.dump('sapere').doc1;
  assert.equal(cover.applied, true);
  assert.equal(doc.newCover, 'https://x/portada.png');
  assert.equal(doc.generation.coverProvider, 'openai');
  assert.equal(doc.status, 'completed');
  assert.equal(doc.description.length, 18);
});

test('una ejecucion duplicada de la tarea no trunca el documento que otra ya completo ni lo deja esperando reintento', async () => {
  for (const failsAfter of [false, true]) {
    const db = new FakeFirestore({ sapere: { doc1: seedDoc() }, creditSpends: { spend1: SPEND } });
    let finished = null;
    const space = createSpace({
      section: (call) => {
        if (call.number !== 2) return undefined;
        // La otra ejecucion completa el documento mientras esta pide la seccion 2.
        finished = {
          ...db.store.get('sapere/doc1'),
          status: 'completed',
          description: Array.from({ length: 18 }, (_, i) => `completo ${i}`),
          chaptersMeta: Array.from({ length: 6 }, (_, index) => ({ index, title: `S${index + 1}`, paragraphs: 3, raw: `s${index}` })),
        };
        db.store.set('sapere/doc1', finished);
        return failsAfter ? { status: 500, json: { detail: 'upstream exploded' } } : undefined;
      },
    });
    const net = installFetch(space.routes);
    try {
      const { deps, log } = fakeDeps();
      const run = runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', isFinalAttempt: false, deps });
      if (failsAfter) {
        await assert.rejects(run, (error) => error.fatal === false);
      } else {
        assert.deepEqual(await run, { skipped: true, reason: 'completed' });
      }
      const doc = db.dump('sapere').doc1;

      assert.equal(doc.status, 'completed');
      assert.deepEqual(doc.description, finished.description, 'no vuelve a una seccion');
      assert.equal(doc.chaptersMeta.length, 6);
      assert.notEqual(doc.generation.awaitingRetry, true, 'un completed no espera reintento');
      assert.equal(space.log.sections.length, 2);
      assert.equal(log.refunds, 0);
    } finally {
      net.restore();
    }
  }
});

test('las notas meta del modelo no llegan a chaptersMeta.raw, ni a la descripcion, ni al historial de la seccion siguiente', async (t) => {
  const note = '\n\nNota: por límite de extensión, continuaré en la siguiente sección.';
  const db = new FakeFirestore({ sapere: { doc1: seedDoc({ type: 'gamification_episode' }) } });
  const { space } = withSpace(t, {
    section: (call) => (call.number === 1 ? { status: 200, stream: sectionStream(sectionText(1, 4) + note) } : undefined),
  });
  const { deps } = fakeDeps();

  const result = await runStory({ db, bucket: BUCKET, docId: 'doc1', uid: 'u1', deps });
  const doc = db.dump('sapere').doc1;

  assert.equal(result.status, 'completed');
  assert.equal(doc.chaptersMeta[0].raw, sectionText(1, 4));
  assert.ok(doc.description.every((p) => !p.includes('Nota:')));
  const history = space.log.sections[1].body.messages.filter((m) => m.role === 'assistant');
  assert.deepEqual(history.map((m) => m.content), [sectionText(1, 4)]);
});

test('refundDoc: un reembolso que queda para revision manual se refleja en generation.refundState; un primer fallo, no', async () => {
  const upstream = () => new Error('RevenueCat API 503: upstream');
  const cases = [
    {
      name: 'agota los intentos',
      credits: {
        async refundSpend(db, spendId) {
          await db.collection('creditSpends').doc(spendId).update({ refundState: 'needs_review' });
          throw upstream();
        },
      },
      throws: true,
      refundState: 'needs_review',
    },
    {
      name: 'ya estaba en revision',
      spend: { refundState: 'needs_review' },
      credits: { refundSpend: async () => ({ refunded: false, reason: 'needs_review' }) },
      throws: false,
      refundState: 'needs_review',
    },
    {
      name: 'primer fallo',
      credits: {
        async refundSpend(db, spendId) {
          await db.collection('creditSpends').doc(spendId).update({ refundState: 'pending', refundAttempts: 1 });
          throw upstream();
        },
      },
      throws: true,
      refundState: undefined,
    },
  ];
  for (const c of cases) {
    const db = new FakeFirestore({
      sapere: { doc1: seedDoc({ status: 'error' }) },
      creditSpends: { spend1: { ...SPEND, ...(c.spend || {}) } },
    });
    const run = refundDoc(db, 'doc1', c.credits);
    if (c.throws) await assert.rejects(run, /RevenueCat API 503/, c.name);
    else assert.deepEqual(await run, { refunded: false, reason: 'needs_review' }, c.name);
    const { generation } = db.dump('sapere').doc1;
    assert.equal(generation.refundState, c.refundState, c.name);
    assert.equal(generation.refunded, false, c.name);
  }
});
