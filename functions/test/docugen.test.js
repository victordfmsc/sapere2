'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { installFetch } = require('./helpers/fetch');
const { createSpace, sse, RESTART } = require('./helpers/space');
const docugen = require('../src/docugen');

const TOKEN = 'hf_test_token_para_pruebas';

// Reloj falso: sleep avanza el tiempo sin esperar de verdad.
function fakeClock(start = 1000000) {
  let now = start;
  return {
    now: () => now,
    sleep: async (ms) => {
      now += ms;
    },
  };
}

function newClient(options = {}) {
  const clock = fakeClock();
  return docugen.createClient({ token: TOKEN, now: clock.now, sleep: clock.sleep, ...options });
}

function sectionArgs(overrides = {}) {
  return {
    docId: 'doc1',
    index: 0,
    total: 6,
    attempt: 0,
    area: 'historia',
    language: 'español',
    durationMinutes: 30,
    messages: docugen.buildSectionMessages({
      topic: 'Shackleton',
      extra: 'Esta es la sección 1 de 6.',
      index: 0,
      total: 6,
    }),
    ...overrides,
  };
}

test('SSE: trozos partidos en cualquier byte (multibyte y CRLF), razonamiento ignorado', () => {
  const content = 'Ñandú: «año» 東京 — 🌍 fin.';
  const raw = `data: {"type":"reasoning","reasoning":"NO-GUARDAR"}\r\n\r\n${
    sse([
      { type: 'content', content: content.slice(0, 5) },
      { type: 'content', content: content.slice(5) },
      { type: 'done', conversation_id: 'c', estimated_minutes: 5.2, usage: { total_tokens: 9 } },
    ]).join('').replace(/\n/g, '\r\n')
  }: comentario\n\n`;
  const bytes = Buffer.from(raw, 'utf8');

  for (let size = 1; size <= 9; size += 1) {
    const reader = docugen.createSectionReader();
    for (let i = 0; i < bytes.length; i += size) reader.push(new Uint8Array(bytes.subarray(i, i + size)));
    const result = reader.finish();
    assert.equal(result.content, content, `trozos de ${size} bytes`);
    assert.equal(result.estimatedMinutes, 5.2);
    assert.ok(!result.content.includes('NO-GUARDAR'));
  }
});

test('SSE: error de saldo -> FATAL; otro error -> REINTENTABLE; sin done o vacio -> REINTENTABLE', () => {
  const balance = docugen.createSectionReader();
  assert.throws(
    () => balance.push(sse([{ type: 'error', detail: "Error de la API DeepSeek: Error code: 402 - {'error': {'message': 'Insufficient Balance'}}" }]).join('')),
    (error) => error.fatal === true && /sin saldo/.test(error.message),
  );

  const other = docugen.createSectionReader();
  assert.throws(
    () => other.push(sse([{ type: 'error', detail: 'Error de la API DeepSeek: Connection error.' }]).join('')),
    (error) => error instanceof docugen.RetryableError && error.fatal === false,
  );

  const cut = docugen.createSectionReader();
  cut.push(sse([{ type: 'content', content: 'a medias' }]).join(''));
  assert.throws(() => cut.finish(), (error) => error.fatal === false && /sin evento done/.test(error.message));

  const empty = docugen.createSectionReader();
  empty.push(sse([{ type: 'content', content: '   ' }, { type: 'done' }]).join(''));
  assert.throws(() => empty.finish(), (error) => error.fatal === false && /vacia/.test(error.message));

  for (const code of [400, 422]) {
    const rejected = docugen.createSectionReader();
    assert.throws(
      () => rejected.push(sse([{ type: 'error', detail: `Error de la API DeepSeek: Error code: ${code} - {'error': {'message': 'Invalid request'}}` }]).join('')),
      (error) => error.fatal === true && /rechazo la peticion/.test(error.message),
      `DeepSeek ${code} -> FATAL`,
    );
  }

  const badKey = docugen.classifyDetail("Error code: 401 - {'error': {'message': 'Authentication Fails, Your api key: ****abcd is invalid'}}");
  assert.equal(docugen.isFatal(badKey), true);
  assert.equal(docugen.classifyDetail('Error code: 500 - upstream'), null);
  assert.equal(docugen.classifyDetail('Error de la API DeepSeek: Error code: 429 - rate limit reached'), null);
  assert.equal(docugen.classifyDetail('Error code: 503 - max 4000 tokens'), null);
});

test('plazo: sin tiempo para despertar el Space + seccion + reserva no se consulta el runtime ni se repite; con tiempo, si', async (t) => {
  const MINUTE = 60 * 1000;
  for (const { minutesLeft, retried } of [{ minutesLeft: 9, retried: false }, { minutesLeft: 12, retried: true }]) {
    let calls = 0;
    const space = createSpace({
      section: () => {
        calls += 1;
        return calls === 1 ? { status: 503, json: { error: 'Space restarting' } } : undefined;
      },
    });
    const net = installFetch(space.routes);
    try {
      const clock = fakeClock();
      const client = docugen.createClient({ token: TOKEN, now: clock.now, sleep: clock.sleep });
      const deadline = clock.now() + minutesLeft * MINUTE;

      if (retried) {
        const result = await client.generateSection(sectionArgs({ deadline }));
        assert.match(result.content, /Sección 1/);
        assert.equal(space.log.runtimes, 1);
        assert.equal(space.log.sections.length, 2);
      } else {
        await assert.rejects(
          () => client.generateSection(sectionArgs({ deadline })),
          (error) => error.fatal === false && /sin tiempo para despertar el Space/.test(error.message),
        );
        assert.equal(space.log.runtimes, 0);
        assert.equal(space.log.sections.length, 1);
      }
      await client.flush();
    } finally {
      net.restore();
    }
  }
  t.diagnostic('9 y 12 min');
});

test('plazo: la seccion se corta antes del limite de la invocacion aunque su propio tope sea mayor', async (t) => {
  const space = createSpace({
    section: () => ({
      status: 200,
      stream: sse(Array.from({ length: 100 }, () => ({ type: 'reasoning', reasoning: 'x' }))),
      delayMs: 5,
      hang: true,
    }),
  });
  const net = installFetch(space.routes);
  t.after(net.restore);
  const client = docugen.createClient({
    token: TOKEN,
    config: { idleTimeoutMs: 5000, sectionTimeoutMs: 60000, deadlineMarginMs: 50 },
  });

  const started = Date.now();
  await assert.rejects(
    () => client.generateSection(sectionArgs({ deadline: Date.now() + 150 })),
    (error) => error.fatal === false && /antes del plazo de la invocacion/.test(error.message),
  );
  await client.flush();
  assert.ok(Date.now() - started < 2000, 'no espera al tope de la seccion');
});

test('historial: alterna, termina en user, sin razonamiento; el marco solo va si lo eligio el usuario', () => {
  const previous = ['## Sección Uno: A\n\nTexto uno.', '## Sección Dos: B\n\nTexto dos.'];
  const extra = docugen.buildExtra({
    framework: 'Eres un narrador de misterio.',
    systemPromptSource: 'type',
    outline: 'Escaleta X',
    index: 2,
    total: 6,
  });
  const messages = docugen.buildSectionMessages({ topic: 'Shackleton', extra, previous, index: 2, total: 6 });

  assert.deepEqual(messages.map((m) => m.role), ['system', 'user', 'assistant', 'user', 'assistant', 'user']);
  assert.equal(messages[1].content, 'Shackleton');
  assert.equal(messages[2].content, previous[0]);
  assert.equal(messages[4].content, previous[1]);
  assert.match(messages[3].content, /sección 2 de 6/);
  assert.match(messages[5].content, /sección 3 de 6/);
  assert.ok(extra.startsWith('Eres un narrador de misterio.'));
  assert.match(extra, /Escaleta X/);
  assert.match(extra, /Esta es la sección 3 de 6\.$/);

  assert.equal(
    docugen.buildExtra({ framework: 'Marco aleatorio', systemPromptSource: 'framework', outline: '', index: 0, total: 1 }),
    'Esta es la sección 1 de 1.',
    'los marcos aleatorios de source framework no se envian',
  );
  assert.equal(
    docugen.buildExtra({ framework: 'Marco viejo', systemPromptSource: undefined, index: 0, total: 1 }),
    'Esta es la sección 1 de 1.',
  );
  assert.match(docugen.buildExtra({ framework: 'Persona', systemPromptSource: 'gamification_client', index: 0, total: 4 }), /^Persona/);

  const last = docugen.buildSectionMessages({ topic: 't', extra: 'x', previous: ['a', 'b', 'c'], index: 3, total: 4 });
  assert.equal(last[last.length - 1].role, 'user');
  assert.match(last[last.length - 1].content, /la última: cierra el documental/);

  const huge = docugen.buildExtra({
    framework: 'f'.repeat(5000),
    systemPromptSource: 'type',
    outline: 'o'.repeat(20000),
    index: 0,
    total: 6,
    maxChars: 3000,
  });
  assert.ok(huge.length <= 3000, `extra de ${huge.length} caracteres`);
  assert.match(huge, /Esta es la sección 1 de 6\.$/, 'la posicion nunca se recorta');
});

test('seccion: POST con Bearer y stream, conversation_id distinto en cada llamada y DELETE de cada una', async (t) => {
  const space = createSpace();
  const net = installFetch(space.routes);
  t.after(net.restore);
  const client = newClient();

  const first = await client.generateSection(sectionArgs());
  const second = await client.generateSection(sectionArgs());
  await client.flush();

  assert.notEqual(first.conversationId, second.conversationId);
  assert.deepEqual([...space.log.deletes].sort(), [first.conversationId, second.conversationId].sort());

  const call = space.log.sections[0];
  assert.equal(call.area, 'historia');
  assert.equal(call.headers.Authorization, `Bearer ${TOKEN}`);
  assert.equal(call.body.conversation_id, first.conversationId);
  assert.equal(call.body.stream, true);
  assert.equal(call.body.level, 'intermedio');
  assert.equal(call.body.max_tokens, 16000, 'sitio para el razonamiento y para 650-800 palabras');
  assert.equal(call.body.duration_minutes, 30);
  assert.equal(call.body.language, 'español');
  assert.match(first.content, /^## Sección 1:/);
  assert.ok(!first.content.includes('RAZONAMIENTO-OCULTO'));
});

test('conversationId distinto aunque coincidan documento, seccion, intento y reloj', () => {
  const a = docugen.conversationId({ docId: 'd', index: 0, attempt: 1, now: 5 });
  const b = docugen.conversationId({ docId: 'd', index: 0, attempt: 1, now: 5 });
  assert.notEqual(a, b);
  assert.match(a, /^sapere-d-s1-a1-/);
});

test('runtime 401 -> FATAL (HF_TOKEN sin acceso) y ya no se vuelve a llamar al Space', async (t) => {
  const space = createSpace({
    section: () => ({ status: 404, text: 'Not Found' }),
    runtime: [{ status: 401, json: { error: 'Invalid credentials' } }],
  });
  const net = installFetch(space.routes);
  t.after(net.restore);
  const client = newClient();

  await assert.rejects(
    () => client.generateSection(sectionArgs()),
    (error) => error.fatal === true && /HF_TOKEN sin acceso al Space Bukbuk\/DocuGenerator/.test(error.message),
  );
  await client.flush();
  const calls = net.calls.length;

  await assert.rejects(() => client.generateTitle({ topic: 't', area: 'general', language: 'español' }), (error) => error.fatal);
  assert.equal(net.calls.length, calls, 'con un fatal recordado no hay mas peticiones');
});

test('SLEEPING -> restart (aunque lo rechace) -> RUNNING -> se reintenta una vez y sale bien', async (t) => {
  let calls = 0;
  const space = createSpace({
    section: () => {
      calls += 1;
      return calls === 1 ? { status: 503, json: { error: 'Space is sleeping' } } : undefined;
    },
    runtime: [
      { status: 200, json: { stage: 'SLEEPING' } },
      { status: 200, json: { stage: 'APP_STARTING' } },
      { status: 200, json: { stage: 'RUNNING' } },
    ],
    restart: { status: 403, json: { error: 'write access required' } },
  });
  const net = installFetch(space.routes);
  t.after(net.restore);
  const client = newClient();

  const result = await client.generateSection(sectionArgs());
  await client.flush();

  assert.match(result.content, /Sección 1/);
  assert.equal(space.log.restarts, 1);
  assert.equal(space.log.restartHeaders.Authorization, `Bearer ${TOKEN}`);
  assert.ok(net.calls.some((c) => c.url === RESTART && c.init.method === 'POST'));
  assert.equal(space.log.runtimes, 3);
  assert.equal(space.log.sections.length, 2, 'un unico reintento');
  assert.notEqual(space.log.sections[0].body.conversation_id, space.log.sections[1].body.conversation_id);
});

test('PAUSED -> FATAL sin reinicio ni espera', async (t) => {
  const space = createSpace({
    section: () => ({ status: 503, text: '' }),
    runtime: [{ status: 200, json: { stage: 'PAUSED' } }],
  });
  const net = installFetch(space.routes);
  t.after(net.restore);

  await assert.rejects(
    () => newClient().generateSection(sectionArgs()),
    (error) => error.fatal === true && /PAUSED/.test(error.message),
  );
  assert.equal(space.log.restarts, 0);
  assert.equal(space.log.sections.length, 1);
});

test('si el Space no llega a RUNNING en 180 s -> REINTENTABLE', async (t) => {
  const space = createSpace({
    section: () => ({ status: 502, text: 'Bad Gateway' }),
    runtime: [{ status: 200, json: { stage: 'BUILDING' } }],
  });
  const net = installFetch(space.routes);
  t.after(net.restore);

  await assert.rejects(
    () => newClient().generateSection(sectionArgs()),
    (error) => error.fatal === false && /no arranco en 180 s/.test(error.message),
  );
  assert.ok(space.log.runtimes >= 18, `sondeos: ${space.log.runtimes}`);
  assert.equal(space.log.sections.length, 1, 'sin RUNNING no se reintenta la llamada');
});

test('HTTP del Space: saldo, clave y 400/422 son FATALES; 429, 5xx y un 502 persistente son REINTENTABLES', async (t) => {
  const cases = [
    { response: { status: 500, json: { detail: 'Error de la API DeepSeek: Error code: 402 - Insufficient Balance' } }, fatal: true, pattern: /sin saldo/ },
    { response: { status: 402, json: { detail: 'Payment Required' } }, fatal: true, pattern: /sin saldo/ },
    { response: { status: 503, json: { detail: 'DEEPSEEK_API_KEY no configurada en el Space' } }, fatal: true, pattern: /DEEPSEEK_API_KEY/ },
    { response: { status: 422, json: { detail: [{ msg: 'field required' }] } }, fatal: true, pattern: /rechazo la peticion \(422\)/ },
    { response: { status: 400, json: { detail: 'No user message' } }, fatal: true, pattern: /\(400\)/ },
    { response: { status: 429, json: { detail: 'rate limit' } }, fatal: false, pattern: /429/ },
    { response: { status: 500, json: { detail: 'Error de la API DeepSeek: Connection error.' } }, fatal: false, pattern: /500/ },
    { response: { status: 502, text: 'Bad Gateway' }, fatal: false, pattern: /sigue sin responder/ },
  ];

  for (const { response, fatal, pattern } of cases) {
    const space = createSpace({ section: () => response });
    const net = installFetch(space.routes);
    try {
      await assert.rejects(
        () => newClient().generateSection(sectionArgs()),
        (error) => error.fatal === fatal && pattern.test(error.message),
        `HTTP ${response.status}`,
      );
      if (fatal) assert.equal(space.log.runtimes, 0, `un fatal no consulta el runtime (HTTP ${response.status})`);
    } finally {
      net.restore();
    }
  }
  t.diagnostic(`${cases.length} casos`);
});

test('timeouts: sin bytes, sin cabeceras, seccion interminable y stream cortado -> REINTENTABLES', async (t) => {
  const responses = [
    { response: { status: 200, stream: sse([{ type: 'reasoning', reasoning: 'x' }]), hang: true }, pattern: /sin recibir datos/ },
    { response: { hangHeaders: true }, pattern: /sin recibir datos/ },
    {
      response: { status: 200, stream: sse(Array.from({ length: 40 }, () => ({ type: 'reasoning', reasoning: 'x' }))), delayMs: 5, hang: true },
      pattern: /sin terminar/,
    },
    { response: { status: 200, stream: sse([{ type: 'content', content: 'medio' }]), cut: true }, pattern: /stream cortado/ },
    { response: { status: 200, stream: sse([{ type: 'content', content: 'medio' }]) }, pattern: /sin evento done/ },
  ];

  for (const { response, pattern } of responses) {
    const space = createSpace({ section: () => response });
    const net = installFetch(space.routes);
    try {
      const client = docugen.createClient({
        token: TOKEN,
        config: { idleTimeoutMs: 40, sectionTimeoutMs: 120 },
      });
      await assert.rejects(
        () => client.generateSection(sectionArgs()),
        (error) => error.fatal === false && pattern.test(error.message),
      );
      await client.flush();
      assert.equal(space.log.deletes.length, 1, 'tambien se borra la conversacion fallida');
    } finally {
      net.restore();
    }
  }
  t.diagnostic(`${responses.length} casos`);
});

test('DELETE nunca lanza: un error de red o una peticion colgada se resuelven a false', async (t) => {
  const net = installFetch([
    { match: '/conversations/a', respond: new Error('ECONNRESET') },
    { match: '/conversations/b', respond: { hangHeaders: true } },
  ]);
  t.after(net.restore);
  const client = docugen.createClient({ token: TOKEN, config: { deleteTimeoutMs: 20 } });

  assert.equal(await client.deleteConversation('a'), false);
  assert.equal(await client.deleteConversation('b'), false);
  await client.flush();
});

test('titulo y escaleta: cuerpo correcto, limpieza, area validada y titulo de respaldo', async (t) => {
  const space = createSpace({ title: { status: 200, json: { title: '"Título: Hielo y hambre."' } } });
  const net = installFetch(space.routes);
  t.after(net.restore);
  const client = newClient();

  assert.equal(await client.generateTitle({ topic: 'Shackleton', area: 'historia', language: 'español' }), 'Hielo y hambre');
  assert.deepEqual(space.log.titles[0], { input: 'Shackleton', area: 'historia', language: 'español' });

  const outline = await client.generateOutline({ topic: 'Shackleton', area: 'inventada', language: 'inglés', durationMinutes: 20 });
  assert.match(outline.outline, /El barco/);
  assert.deepEqual(space.log.outlines[0], {
    input: 'Shackleton',
    area: 'general',
    level: 'intermedio',
    language: 'inglés',
    duration_minutes: 20,
  });

  const fallback = docugen.fallbackTitle('la expedición imperial transantártica de Shackleton y el hundimiento del Endurance');
  assert.ok(fallback.length <= 60);
  assert.ok(fallback.startsWith('La expedición imperial'));
  assert.ok(!/\bhun$/.test(fallback), 'corta en frontera de palabra');
  assert.equal(docugen.fallbackTitle('  '), 'Documental');
});

test('sin HF_TOKEN o con historial que no acaba en user -> FATAL sin tocar la red', async (t) => {
  const net = installFetch([]);
  t.after(net.restore);

  await assert.rejects(
    () => docugen.createClient({ token: '' }).generateSection(sectionArgs()),
    (error) => error.fatal === true && /Falta HF_TOKEN/.test(error.message),
  );
  await assert.rejects(
    () => newClient().generateSection(sectionArgs({ messages: [{ role: 'user', content: 't' }, { role: 'assistant', content: 'x' }] })),
    (error) => error.fatal === true && /terminar en un mensaje user/.test(error.message),
  );
  assert.equal(net.calls.length, 0);
});

test('area: ids de categoria conocidos', () => {
  const expected = {
    '0Wm8Jabc33BRlzDPPz94': 'arte_cultura',
    '7VXB5mEUW9okmxbbIhZ9': 'tecnologia',
    HyoQuHiHOpCJNX4aKVcn: 'psicologia_mente',
    KGF9MTtz4v4RSOj93Y1l: 'psicologia_mente',
    SSc7UwgbUf5eAb6TmCkz: 'biografias',
    T0rSe6AITj3lL9DYDeCU: 'general',
    ay9mWgYmMMPVqhtUy7Gb: 'general',
    dqpZObGn0lcaVQZnLSHG: 'historia',
  };
  for (const [id, area] of Object.entries(expected)) {
    assert.equal(docugen.resolveArea({ bukbukCategoryId: id, genre: 'Science' }), area, id);
  }
});

test('area: categorias de gamificacion en varios idiomas, sin tildes ni emojis, y por defecto general', () => {
  const cases = [
    ['salud_biologia', ['Health', 'Salud', 'Gesundheit', 'Santé', 'Saúde', 'Salute', 'Здоровье', '健康', '건강', 'الصحة']],
    ['historia', ['History', 'Historia', 'Geschichte', 'Histoire', 'História', 'Storia', 'История', '历史', '歴史', '역사', 'التاريخ']],
    ['filosofia_ideas', ['Humanities', 'Humanidades', 'Geisteswissenschaften', 'Humanités', 'Umanistiche', 'Гуманитарные науки', '人文科学', '人文', '인문학', 'العلوم الإنسانية']],
    ['naturaleza_medioambiente', ['Nature', 'Naturaleza', 'Natur', 'Natureza', 'Natura', 'Природа', '自然', '자연', 'الطبيعة']],
    ['ciencia', ['Science', 'Ciencia', 'Wissenschaft', 'Ciência', 'Scienza', 'Наука', '科学', '과학', 'العلم']],
    ['sociedad_politica', ['Society', 'Sociedad', 'Gesellschaft', 'Société', 'Sociedade', 'Società', 'Общество', '社会', '사회', 'المجتمع']],
    ['tecnologia', ['Technology', 'Tecnología', 'Technologie', 'Tecnologia', 'Технологии', '技術', '技术', '기술', 'التكنولوجيا']],
  ];
  for (const [area, names] of cases) {
    for (const genre of names) assert.equal(docugen.resolveArea({ genre }), area, genre);
  }

  assert.equal(docugen.resolveArea({ genre: 'General', bukbukCategoryNames: { es_ES: '🎨 Artes', en_US: 'Arts' } }), 'arte_cultura');
  assert.equal(docugen.resolveArea({ genre: 'General', gamificationSubject: '🔭 Astronomía y Espacio' }), 'espacio_universo');
  assert.equal(docugen.resolveArea({ genre: 'Science', gamificationSubject: '🏛️ Historia Antigua' }), 'ciencia', 'genre va primero');
  assert.equal(docugen.resolveArea({ genre: 'Varios' }), 'general');
  assert.equal(docugen.resolveArea({}), 'general');

  assert.equal(docugen.AREAS.length, 16);
  assert.ok(Object.values(docugen.CATEGORY_AREAS).every((area) => docugen.AREAS.includes(area)));
  assert.ok(docugen.AREA_KEYWORDS.every(([area]) => docugen.AREAS.includes(area)));
});

test('idioma: los 29 locales de la app y respaldo', () => {
  const expected = {
    es_ES: 'español', es_MX: 'español de México', es_AR: 'español de Argentina', es_CO: 'español de Colombia',
    en_US: 'inglés', en_GB: 'inglés británico', fr_FR: 'francés', de_DE: 'alemán', pt_PT: 'portugués',
    pt_BR: 'portugués de Brasil', it_IT: 'italiano', nl_NL: 'neerlandés', pl_PL: 'polaco', sv_SE: 'sueco',
    no_NO: 'noruego', da_DK: 'danés', el_GR: 'griego', ru_RU: 'ruso', tr_TR: 'turco', ar_AR: 'árabe',
    hi_IN: 'hindi', ta_IN: 'tamil', id_ID: 'indonesio', vi_VN: 'vietnamita', tl_PH: 'filipino',
    ja_JP: 'japonés', ko_KR: 'coreano', zh_CN: 'chino simplificado', zh_TW: 'chino tradicional',
  };
  assert.equal(Object.keys(expected).length, 29);
  assert.deepEqual({ ...docugen.LANGUAGE_NAMES }, expected);
  for (const [code, name] of Object.entries(expected)) assert.equal(docugen.languageName(code), name, code);

  assert.equal(docugen.languageName('pt-BR'), 'portugués de Brasil');
  assert.equal(docugen.languageName('es_419'), 'español');
  assert.equal(docugen.languageName('zh_HK'), 'chino tradicional');
  assert.equal(docugen.languageName('fr_CA'), 'francés');
  assert.equal(docugen.languageName(''), 'español');
  assert.equal(docugen.languageName('xx_YY'), 'español');
});

test('max_tokens: si usage.completion_tokens llega al tope la seccion se recorta a la ultima oracion completa; sin ninguna, REINTENTABLE', () => {
  const read = (content, usage, maxTokens = 100) => {
    const reader = docugen.createSectionReader({ maxTokens });
    reader.push(sse([{ type: 'content', content }, { type: 'done', estimated_minutes: 5, usage }]).join(''));
    return reader.finish();
  };

  const cut = read('## Sección 2: El hielo\n\nEl barco crujía. «¿Resistirá?» Nadie lo sab', { completion_tokens: 100 });
  assert.equal(cut.truncated, true);
  assert.equal(cut.content, '## Sección 2: El hielo\n\nEl barco crujía. «¿Resistirá?»');
  assert.equal(read('東京は大きい。人が多', { completion_tokens: 120 }).content, '東京は大きい。');

  const whole = read('Frase completa. Otra a medi', { completion_tokens: 99 });
  assert.equal(whole.truncated, false, 'por debajo del tope no se toca');
  assert.equal(whole.content, 'Frase completa. Otra a medi');
  assert.equal(read('Sin completion_tokens', { total_tokens: 500 }).truncated, false);
  assert.equal(read('Sin usage', undefined).truncated, false);

  assert.throws(
    () => read('El razonamiento se lo comio to', { completion_tokens: 100 }),
    (error) => error instanceof docugen.RetryableError && /cortada por max_tokens/.test(error.message),
  );
});

test('max_tokens con cutToSentence false: lo cortado se entrega tal cual (truncated) para que lo interprete quien llama; sin texto, REINTENTABLE', () => {
  const read = (content, cutToSentence) => {
    const reader = docugen.createSectionReader({ maxTokens: 100, cutToSentence });
    const events = content ? [{ type: 'content', content }] : [];
    reader.push(sse([...events, { type: 'done', usage: { completion_tokens: 100 } }]).join(''));
    return reader.finish();
  };
  const json = '[{"q":"¿A?","a":"B."},\n{"q":"¿C?","a":"D';

  assert.throws(() => read(json, true), /sin ninguna oracion completa/);
  const raw = read(json, false);
  assert.equal(raw.content, json);
  assert.equal(raw.truncated, true);
  assert.throws(
    () => read('', false),
    (error) => error instanceof docugen.RetryableError && /max_tokens \(100\) sin devolver texto/.test(error.message),
  );
});

test('seccion cortada por max_tokens: se entrega hasta la ultima oracion completa y queda un aviso en el log', async (t) => {
  const { DOCUGEN } = require('../src/config');
  const warn = t.mock.method(console, 'warn', () => {});
  const space = createSpace({
    section: () => ({
      status: 200,
      stream: sse([
        { type: 'reasoning', reasoning: 'x' },
        { type: 'content', content: '## Sección 1: A\n\nPrimera frase entera. Segunda a me' },
        { type: 'done', estimated_minutes: 1, usage: { completion_tokens: DOCUGEN.maxTokens } },
      ]),
    }),
  });
  const net = installFetch(space.routes);
  t.after(net.restore);
  const client = newClient();

  const result = await client.generateSection(sectionArgs());
  await client.flush();

  assert.equal(result.truncated, true);
  assert.equal(result.content, '## Sección 1: A\n\nPrimera frase entera.');
  const warnings = warn.mock.calls.map((call) => String(call.arguments[0]));
  assert.ok(
    warnings.some((message) => message.includes(`seccion 1/6 (${result.conversationId}): cortada por max_tokens`)),
    warnings.join('\n'),
  );
});

test('los errores y avisos del Space no repiten la etiqueta de la llamada', async (t) => {
  const warn = t.mock.method(console, 'warn', () => {});
  const cases = [
    {
      options: { title: { status: 503, json: { error: 'Space restarting' } } },
      call: (client) => client.generateTitle({ topic: 't', area: 'general', language: 'español' }),
      message: 'titulo: el Space sigue sin responder tras comprobar su estado (Space no disponible (503))',
    },
    {
      options: { section: () => ({ status: 503, json: { error: 'Space restarting' } }) },
      call: (client, clock) => client.generateSection(sectionArgs({ deadline: clock.now() + 5 * 60 * 1000 })),
      message: 'seccion 1/6: Space no disponible (503); sin tiempo para despertar el Space en esta invocacion',
    },
  ];
  for (const { options, call, message } of cases) {
    const space = createSpace(options);
    const net = installFetch(space.routes);
    try {
      const clock = fakeClock();
      const client = docugen.createClient({ token: TOKEN, now: clock.now, sleep: clock.sleep });
      await assert.rejects(() => call(client, clock), (error) => {
        assert.equal(error.message, message);
        return true;
      });
      await client.flush();
    } finally {
      net.restore();
    }
  }
  const warnings = warn.mock.calls.map((call) => String(call.arguments[0]));
  assert.deepEqual(warnings, ['[docugen] titulo: Space no disponible (503); se consulta el estado del Space']);
});

test('texto suelto: POST /generate con el area validada en el cuerpo, max_tokens propio y reasoning_effort solo si se pide; las secciones no cambian', async (t) => {
  const warn = t.mock.method(console, 'warn', () => {});
  const space = createSpace({
    generate: (call, log) => (log.generates.length === 3
      ? { status: 200, stream: sse([{ type: 'content', content: 'Frase entera. A me' }, { type: 'done', usage: { completion_tokens: 50 } }]) }
      : undefined),
  });
  const net = installFetch(space.routes);
  t.after(net.restore);
  const client = newClient();
  const messages = docugen.buildSectionMessages({ topic: 'Faros', extra: 'Marco', index: 0, total: 1 });
  const args = { language: 'inglés', durationMinutes: 5, messages };

  const plain = await client.generateText({ ...args, kind: 'community', area: 'inventada', maxTokens: 777 });
  await client.generateText({ ...args, kind: 'flashcards', area: 'historia', reasoningEffort: 'low' });
  const cut = await client.generateText({ ...args, kind: 'flashcards', area: 'historia', maxTokens: 50 });
  await client.generateSection(sectionArgs());
  await client.flush();

  const [first, second] = space.log.generates;
  assert.match(plain.content, /Párrafo A/);
  assert.ok(!plain.content.includes('RAZONAMIENTO-OCULTO'));
  assert.equal(first.headers.Authorization, `Bearer ${TOKEN}`);
  assert.deepEqual(first.body.messages, messages);
  assert.equal(first.body.stream, true);
  assert.equal(first.body.area, 'general');
  assert.equal(first.body.max_tokens, 777);
  assert.equal('reasoning_effort' in first.body, false);
  assert.equal(second.body.area, 'historia');
  assert.equal(second.body.max_tokens, 16000);
  assert.equal(second.body.reasoning_effort, 'low');
  assert.equal(cut.truncated, true, 'el corte por max_tokens usa el tope de la llamada');
  assert.equal(cut.content, 'Frase entera.');
  assert.ok(warn.mock.calls.some((call) => /de 50 tokens/.test(String(call.arguments[0]))));

  const ids = space.log.generates.map((call) => call.body.conversation_id);
  assert.equal(new Set(ids).size, 3);
  assert.deepEqual([...space.log.deletes].sort(), [...ids, space.log.sections[0].body.conversation_id].sort());
  assert.deepEqual(
    Object.keys(space.log.sections[0].body).sort(),
    ['conversation_id', 'duration_minutes', 'language', 'level', 'max_tokens', 'messages', 'stream'],
  );
});
