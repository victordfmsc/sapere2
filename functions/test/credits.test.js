'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { FakeFirestore } = require('./helpers/firestore');
const { installFetch } = require('./helpers/fetch');
const credits = require('../src/credits');
const revenuecat = require('../src/revenuecat');
const { TYPE_READ_TIMEOUT_MS } = require('../src/start');

function withRevenueCat() {
  process.env.REVENUECAT_SECRET_KEY = 'sk_test_fake_key_para_pruebas';
  process.env.REVENUECAT_PROJECT_ID = 'proj_fake';
  process.env.REVENUECAT_CURRENCY = 'CRD';
}

function withoutRevenueCat() {
  delete process.env.REVENUECAT_SECRET_KEY;
  delete process.env.REVENUECAT_PROJECT_ID;
}

// Simula que ya paso la espera minima desde el ultimo intento de reembolso.
function rewindLastRefundAttempt(db, spendId) {
  const key = `creditSpends/${spendId}`;
  db.store.set(key, { ...db.store.get(key), lastRefundAttemptAt: new Date(Date.now() - credits.REFUND_RETRY_MS - 1000) });
}

function appliedSpend(fields = {}) {
  return {
    uid: 'u1',
    source: 'revenuecat',
    docId: 'd1',
    applied: true,
    chargeState: 'applied',
    settled: false,
    refunded: false,
    refundState: 'pending',
    refundAttempts: 0,
    ...fields,
  };
}

test('RevenueCat: cobra 1 credito y lo reembolsa una sola vez', async (t) => {
  withRevenueCat();
  t.after(withoutRevenueCat);

  let balance = 3;
  const adjustments = [];
  const net = installFetch([
    {
      match: (url, init) => url.includes('/virtual_currencies/transactions') && init.method === 'POST',
      respond: (url, init) => {
        const delta = JSON.parse(init.body).adjustments.CRD;
        adjustments.push(delta);
        balance += delta;
        return { status: 200, json: { object: 'virtual_currency_transaction' } };
      },
    },
    {
      match: '/virtual_currencies',
      respond: () => ({ status: 200, json: { items: [{ currency: { code: 'CRD' }, balance }] } }),
    },
  ]);
  t.after(net.restore);

  const db = new FakeFirestore({ users: { u1: { credits: 0 } } });

  const spend = await credits.spendCredit(db, 'u1');
  assert.equal(spend.source, 'revenuecat');
  assert.equal(spend.balance, 2);
  assert.deepEqual(adjustments, [-1]);
  assert.equal(balance, 2);

  const stored = db.dump('creditSpends')[spend.spendId];
  assert.equal(stored.uid, 'u1');
  assert.equal(stored.refunded, false);

  const first = await credits.refundSpend(db, spend.spendId);
  assert.equal(first.refunded, true);
  assert.deepEqual(adjustments, [-1, 1]);
  assert.equal(db.dump('creditSpends')[spend.spendId].refunded, true);

  const second = await credits.refundSpend(db, spend.spendId);
  assert.equal(second.refunded, false);
  assert.equal(second.reason, 'already_refunded');
  assert.deepEqual(adjustments, [-1, 1], 'no se debe ajustar el saldo dos veces');
  assert.equal(balance, 3, 'el usuario recupera exactamente el credito que gasto');
});

test('Reserva heredada: cobra sobre users/{uid}.credits y reembolsa una sola vez', async (t) => {
  withoutRevenueCat();
  const net = installFetch([]);
  t.after(net.restore);

  const db = new FakeFirestore({ users: { u2: { credits: 2 } } });

  const spend = await credits.spendCredit(db, 'u2');
  assert.equal(spend.source, 'legacy');
  assert.equal(db.dump('users').u2.credits, 1);

  assert.equal((await credits.refundSpend(db, spend.spendId)).refunded, true);
  assert.equal(db.dump('users').u2.credits, 2);

  assert.equal((await credits.refundSpend(db, spend.spendId)).refunded, false);
  assert.equal(db.dump('users').u2.credits, 2, 'un segundo reembolso no regala creditos');
  assert.equal(net.calls.length, 0, 'sin RevenueCat no se llama a la red');
});

test('Sin saldo: spendCredit lanza insufficient_credits y no deja rastro', async (t) => {
  withoutRevenueCat();
  const net = installFetch([]);
  t.after(net.restore);

  const db = new FakeFirestore({ users: { u3: { credits: 0 } } });

  await assert.rejects(
    () => credits.spendCredit(db, 'u3'),
    (error) => error.code === 'insufficient_credits',
  );
  assert.deepEqual(db.dump('creditSpends'), {});
});

test('getBalances suma RevenueCat y reserva heredada', async (t) => {
  withRevenueCat();
  t.after(withoutRevenueCat);

  const net = installFetch([
    {
      match: '/virtual_currencies',
      respond: () => ({ status: 200, json: { items: [{ currency: { code: 'CRD' }, balance: 4 }] } }),
    },
  ]);
  t.after(net.restore);

  const db = new FakeFirestore({ users: { u4: { credits: 3 } } });
  const balance = await credits.getBalances(db, 'u4');
  assert.deepEqual(
    { revenuecat: balance.revenuecat, legacy: balance.legacy, total: balance.total },
    { revenuecat: 4, legacy: 3, total: 7 },
  );
  assert.equal(balance.revenuecatAvailable, true);
});

test('getBalances no lanza si cae RevenueCat: devuelve la reserva heredada con revenuecatAvailable:false', async (t) => {
  withRevenueCat();
  t.after(withoutRevenueCat);
  t.mock.method(console, 'warn', () => {});

  const net = installFetch([
    { match: '/virtual_currencies', respond: { status: 500, json: { message: 'Internal error' } } },
  ]);
  t.after(net.restore);

  const db = new FakeFirestore({ users: { u4: { credits: 3 } } });
  const balance = await credits.getBalances(db, 'u4');
  assert.deepEqual(
    {
      revenuecat: balance.revenuecat,
      legacy: balance.legacy,
      total: balance.total,
      revenuecatAvailable: balance.revenuecatAvailable,
    },
    { revenuecat: 0, legacy: 3, total: 3, revenuecatAvailable: false },
  );
});

test('getBalancesWithin no retrasa la respuesta: si RevenueCat no contesta a tiempo devuelve null', { timeout: 5000 }, async () => {
  const db = new FakeFirestore({ users: { u8: { credits: 2 } } });

  const colgado = { isEnabled: () => true, getBalance: () => new Promise(() => {}) };
  const t0 = Date.now();
  assert.equal(await credits.getBalancesWithin(db, 'u8', 50, { revenuecat: colgado }), null);
  assert.ok(Date.now() - t0 < 1000, `tardo ${Date.now() - t0} ms`);

  const rapido = { isEnabled: () => true, getBalance: async () => 4 };
  const balance = await credits.getBalancesWithin(db, 'u8', 1000, { revenuecat: rapido });
  assert.equal(balance.total, 6);
});

test('Si RevenueCat falla al leer el saldo (401, 5xx, red o timeout), cobra de la reserva heredada con un aviso', async (t) => {
  withRevenueCat();
  t.after(withoutRevenueCat);
  const warn = t.mock.method(console, 'warn', () => {});

  const failures = {
    401: () => ({ status: 401, json: { message: 'Invalid API key' } }),
    503: () => ({ status: 503, text: 'Service Unavailable' }),
    red: () => new Error('ECONNRESET'),
    timeout: () => new DOMException('The operation was aborted due to timeout', 'TimeoutError'),
  };

  for (const [name, respond] of Object.entries(failures)) {
    let posts = 0;
    const net = installFetch([
      {
        match: (url, init) => init.method === 'POST',
        respond: () => {
          posts += 1;
          return { status: 200, json: {} };
        },
      },
      { match: '/virtual_currencies', respond },
    ]);
    warn.mock.resetCalls();
    try {
      const db = new FakeFirestore({ users: { u1: { credits: 2 } } });
      const spend = await credits.spendCredit(db, 'u1', {}, { docId: `doc_${name}` });
      assert.equal(spend.source, 'legacy', name);
      assert.equal(spend.balance, 1, name);
      assert.equal(db.dump('users').u1.credits, 1, name);
      assert.equal(db.dump('creditSpends')[spend.spendId].applied, true, name);
      assert.equal(posts, 0, `${name}: no se toca el saldo de RevenueCat`);
      assert.ok(
        warn.mock.calls.some((call) => /reserva heredada/.test(String(call.arguments[0]))),
        `${name}: aviso en el log`,
      );
    } finally {
      net.restore();
    }
  }
});

test('Si RevenueCat falla y no hay reserva heredada, falla con el error de RevenueCat (no con sin creditos) y no deja gasto', async (t) => {
  withRevenueCat();
  t.after(withoutRevenueCat);

  let status = 503;
  const net = installFetch([
    { match: '/virtual_currencies', respond: () => ({ status, json: { message: 'caido' } }) },
  ]);
  t.after(net.restore);

  const db = new FakeFirestore({ users: { u1: { credits: 0 } } });
  await assert.rejects(
    () => credits.spendCredit(db, 'u1', {}, { docId: 'd1' }),
    (error) => error.status === 503 && error.code !== 'insufficient_credits',
  );
  assert.deepEqual(db.dump('creditSpends'), {});

  status = 404;
  await assert.rejects(
    () => credits.spendCredit(db, 'u1', {}, { docId: 'd1' }),
    (error) => error.code === 'insufficient_credits',
    'un 404 es un cliente nuevo sin saldo, no un fallo',
  );
  assert.deepEqual(db.dump('creditSpends'), {});
});

test('El recibo se escribe ANTES del cargo: si el ajuste falla con resultado incierto, queda para revision', async (t) => {
  withRevenueCat();
  t.after(withoutRevenueCat);

  let posts = 0;
  const net = installFetch([
    {
      match: (url, init) => url.includes('/virtual_currencies/transactions') && init.method === 'POST',
      respond: () => {
        posts += 1;
        return new Error('socket hang up');
      },
    },
    {
      match: '/virtual_currencies',
      respond: () => ({ status: 200, json: { items: [{ currency: { code: 'CRD' }, balance: 3 }] } }),
    },
  ]);
  t.after(net.restore);

  const db = new FakeFirestore();
  await assert.rejects(() => credits.spendCredit(db, 'u1', {}, { docId: 'docX' }));

  const spends = Object.entries(db.dump('creditSpends'));
  assert.equal(spends.length, 1, 'nunca hay cargo sin recibo');
  const [spendId, stored] = spends[0];
  assert.equal(stored.source, 'revenuecat');
  assert.equal(stored.docId, 'docX');
  assert.equal(stored.applied, false);
  assert.equal(stored.chargeState, 'unknown');
  assert.equal(stored.refundState, 'needs_review');

  const refund = await credits.refundSpend(db, spendId);
  assert.deepEqual(refund, { refunded: false, reason: 'needs_review' });
  assert.equal(posts, 1, 'un cargo dudoso no se devuelve a ciegas');
});

test('RevenueCat: cada llamada lleva un tope (con mas margen el ajuste, que no es idempotente), y un servidor colgado da un error con status timeout', { timeout: 5000 }, async (t) => {
  withRevenueCat();
  t.after(withoutRevenueCat);

  const net = installFetch([
    { match: '/customers/colgado/', respond: { hangHeaders: true } },
    { match: '/virtual_currencies', respond: { status: 200, json: { items: [{ currency: { code: 'CRD' }, balance: 2 }] } } },
  ]);
  t.after(net.restore);

  const t0 = Date.now();
  await assert.rejects(
    () => revenuecat.request('/customers/colgado/virtual_currencies', {}, 30),
    (error) => error.status === 'timeout' && /timeout/.test(error.message),
  );
  assert.ok(Date.now() - t0 < 2000, `tardo ${Date.now() - t0} ms`);

  const topes = [];
  const timeout = AbortSignal.timeout.bind(AbortSignal);
  t.mock.method(AbortSignal, 'timeout', (ms) => {
    topes.push(ms);
    return timeout(ms);
  });
  assert.equal(await revenuecat.getBalance('u1'), 2);
  await revenuecat.adjustBalance('u1', -1);
  for (const call of net.calls) {
    assert.ok(call.init.signal instanceof AbortSignal, `sin tope: ${call.url}`);
  }
  assert.deepEqual(topes, [revenuecat.REQUEST_TIMEOUT_MS, revenuecat.WRITE_TIMEOUT_MS]);
  assert.ok(revenuecat.REQUEST_TIMEOUT_MS <= 15000);
  assert.ok(revenuecat.WRITE_TIMEOUT_MS > revenuecat.REQUEST_TIMEOUT_MS);
  // Peor caso de startStory: tipo, saldo, ajuste, relectura del saldo tras una
  // respuesta perdida y los 3 s del saldo final (index.js). La app corta a los 60 s.
  assert.ok(
    TYPE_READ_TIMEOUT_MS + 2 * revenuecat.REQUEST_TIMEOUT_MS + revenuecat.WRITE_TIMEOUT_MS + 3000 <= 50 * 1000,
    'startStory tiene que responder antes de que la app se rinda',
  );
});

test('Un cobro que RevenueCat aplica pero contesta tarde se confirma releyendo el saldo; si el saldo no lo confirma, queda para revision', { timeout: 5000 }, async (t) => {
  withRevenueCat();
  t.after(withoutRevenueCat);
  t.mock.method(console, 'warn', () => {});
  t.mock.method(console, 'error', () => {});

  let balance = 3;
  let applies = true;
  const adjustments = [];
  const net = installFetch([
    {
      match: (url, init) => url.includes('/virtual_currencies/transactions') && init.method === 'POST',
      respond: (url, init) => {
        const delta = JSON.parse(init.body).adjustments.CRD;
        if (applies) {
          balance += delta;
          adjustments.push(delta);
        }
        return { hangHeaders: true };
      },
    },
    {
      match: '/virtual_currencies',
      respond: () => ({ status: 200, json: { items: [{ currency: { code: 'CRD' }, balance }] } }),
    },
  ]);
  t.after(net.restore);
  // El modulo real con un tope de milisegundos: la respuesta del ajuste llega tarde.
  const lento = { ...revenuecat, adjustBalance: (uid, delta, opts) => revenuecat.adjustBalance(uid, delta, { ...opts, timeoutMs: 30 }) };

  const db = new FakeFirestore();
  const spend = await credits.spendCredit(db, 'u1', { revenuecat: lento }, { docId: 'd1' });
  assert.deepEqual({ source: spend.source, balance: spend.balance }, { source: 'revenuecat', balance: 2 });
  const stored = db.dump('creditSpends')[spend.spendId];
  assert.equal(stored.applied, true, 'el cargo aplicado no se pierde en revision');
  assert.equal(stored.chargeState, 'applied');
  assert.equal(stored.refundState, 'pending', 'sigue siendo reembolsable si la generacion falla');
  assert.deepEqual(adjustments, [-1]);

  applies = false;
  const dudoso = new FakeFirestore();
  await assert.rejects(
    () => credits.spendCredit(dudoso, 'u1', { revenuecat: lento }, { docId: 'd2' }),
    (error) => error.status === 'timeout',
  );
  const [pendiente] = Object.values(dudoso.dump('creditSpends'));
  assert.equal(pendiente.applied, false);
  assert.equal(pendiente.chargeState, 'unknown');
  assert.equal(pendiente.refundState, 'needs_review', 'sin confirmacion no se da por cobrado');
  assert.equal(balance, 2);
});

test('Un reembolso cuyo ajuste falla se reintenta como mucho MAX_REFUND_ATTEMPTS, con espera entre intentos, y luego queda para revision', async (t) => {
  withRevenueCat();
  t.after(withoutRevenueCat);

  let balance = 3;
  let refundPosts = 0;
  const net = installFetch([
    {
      match: (url, init) => url.includes('/virtual_currencies/transactions') && init.method === 'POST',
      respond: (url, init) => {
        const delta = JSON.parse(init.body).adjustments.CRD;
        if (delta > 0) {
          refundPosts += 1;
          return new Error('ECONNRESET');
        }
        balance += delta;
        return { status: 200, json: { object: 'virtual_currency_transaction' } };
      },
    },
    {
      match: '/virtual_currencies',
      respond: () => ({ status: 200, json: { items: [{ currency: { code: 'CRD' }, balance }] } }),
    },
  ]);
  t.after(net.restore);

  const db = new FakeFirestore();
  const spend = await credits.spendCredit(db, 'u1', {}, { docId: 'd1' });
  assert.equal(db.dump('creditSpends')[spend.spendId].applied, true);

  await assert.rejects(() => credits.refundSpend(db, spend.spendId));
  let stored = db.dump('creditSpends')[spend.spendId];
  assert.equal(stored.refunded, false);
  assert.equal(stored.refundState, 'pending');
  assert.equal(stored.refundAttempts, 1);

  assert.deepEqual(await credits.refundSpend(db, spend.spendId), { refunded: false, reason: 'retry_later' });
  assert.equal(refundPosts, 1, 'un segundo intento antes de la espera no llama a RevenueCat');
  assert.equal(db.dump('creditSpends')[spend.spendId].refundAttempts, 1, 'ni gasta intento');

  rewindLastRefundAttempt(db, spend.spendId);
  await assert.rejects(() => credits.refundSpend(db, spend.spendId));
  stored = db.dump('creditSpends')[spend.spendId];
  assert.equal(stored.refundState, 'needs_review');
  assert.equal(stored.refundAttempts, credits.MAX_REFUND_ATTEMPTS);

  const third = await credits.refundSpend(db, spend.spendId);
  assert.deepEqual(third, { refunded: false, reason: 'needs_review' });
  assert.equal(refundPosts, credits.MAX_REFUND_ATTEMPTS, 'el barrido no reintenta para siempre');
});

test('Un cobro que RevenueCat rechaza (4xx o 503) no se da por hecho aunque el saldo releido cuadre: no queda recibo y un 422 es sin creditos', async (t) => {
  withRevenueCat();
  t.after(withoutRevenueCat);
  t.mock.method(console, 'warn', () => {});
  t.mock.method(console, 'error', () => {});

  // Saldo 1: entre la lectura y el ajuste otro cobro (Railway, sin el cerrojo de
  // Firebase) se lleva el credito, asi que el saldo releido es justo uno menos.
  for (const status of [422, 401, 429, 503]) {
    let balance = 1;
    let reads = 0;
    const net = installFetch([
      {
        match: (url, init) => url.includes('/virtual_currencies/transactions') && init.method === 'POST',
        respond: () => {
          balance -= 1;
          return { status, json: { message: "Customer's balance is not enough to perform the transaction." } };
        },
      },
      {
        match: '/virtual_currencies',
        respond: () => {
          reads += 1;
          return { status: 200, json: { items: [{ currency: { code: 'CRD' }, balance }] } };
        },
      },
    ]);
    try {
      const db = new FakeFirestore({ users: { u1: { credits: 0 } } });
      await assert.rejects(
        () => credits.spendCredit(db, 'u1', {}, { docId: `d${status}` }),
        (error) => (status === 422 ? error.code === 'insufficient_credits' : error.status === status),
        `${status}`,
      );
      assert.deepEqual(db.dump('creditSpends'), {}, `${status}: sin cargo no queda recibo`);
      assert.equal(reads, 1, `${status}: no se relee el saldo`);
    } finally {
      net.restore();
    }
  }
});

test('Un 502 del ajuste no dice si el cobro se aplico: se sigue confirmando releyendo el saldo', async (t) => {
  withRevenueCat();
  t.after(withoutRevenueCat);
  t.mock.method(console, 'warn', () => {});

  let balance = 3;
  const net = installFetch([
    {
      match: (url, init) => url.includes('/virtual_currencies/transactions') && init.method === 'POST',
      respond: () => {
        balance -= 1;
        return { status: 502, text: 'Bad Gateway' };
      },
    },
    {
      match: '/virtual_currencies',
      respond: () => ({ status: 200, json: { items: [{ currency: { code: 'CRD' }, balance }] } }),
    },
  ]);
  t.after(net.restore);

  const db = new FakeFirestore();
  const spend = await credits.spendCredit(db, 'u1', {}, { docId: 'd1' });
  assert.deepEqual({ source: spend.source, balance: spend.balance }, { source: 'revenuecat', balance: 2 });
  assert.equal(db.dump('creditSpends')[spend.spendId].applied, true);
});

test('Un reembolso que RevenueCat rechaza por una incidencia (401, 403, 429, 503) no gasta intento: pasada la caida se devuelve', async (t) => {
  withRevenueCat();
  t.after(withoutRevenueCat);
  t.mock.method(console, 'error', () => {});

  for (const status of [401, 403, 429, 503]) {
    let down = true;
    let balance = 0;
    let posts = 0;
    const net = installFetch([
      {
        match: (url, init) => url.includes('/virtual_currencies/transactions') && init.method === 'POST',
        respond: (url, init) => {
          posts += 1;
          if (down) return { status, json: { message: 'caido' } };
          balance += JSON.parse(init.body).adjustments.CRD;
          return { status: 200, json: {} };
        },
      },
    ]);
    try {
      const db = new FakeFirestore({ creditSpends: { s1: appliedSpend() } });
      for (let i = 0; i <= credits.MAX_REFUND_ATTEMPTS; i += 1) {
        await assert.rejects(() => credits.refundSpend(db, 's1'), (error) => error.status === status, `${status}`);
        const stored = db.dump('creditSpends').s1;
        assert.deepEqual(
          { refundState: stored.refundState, refundAttempts: stored.refundAttempts },
          { refundState: 'pending', refundAttempts: 0 },
          `${status}: no gasta intento`,
        );
        rewindLastRefundAttempt(db, 's1');
      }
      down = false;
      assert.equal((await credits.refundSpend(db, 's1')).refunded, true, `${status}`);
      assert.equal(balance, 1, `${status}`);
      assert.equal(posts, credits.MAX_REFUND_ATTEMPTS + 2, `${status}`);
    } finally {
      net.restore();
    }
  }

  // Lo que no se arregla solo, puede venir de la clave repetida o pudo aplicarse si gasta intento.
  for (const status of [404, 409, 500, 504]) {
    const net = installFetch([
      {
        match: (url, init) => url.includes('/virtual_currencies/transactions') && init.method === 'POST',
        respond: { status, json: { message: 'error' } },
      },
    ]);
    try {
      const db = new FakeFirestore({ creditSpends: { s1: appliedSpend() } });
      await assert.rejects(() => credits.refundSpend(db, 's1'), (error) => error.status === status);
      assert.equal(db.dump('creditSpends').s1.refundAttempts, 1, `${status}`);
    } finally {
      net.restore();
    }
  }
});

test('Un reembolso que RevenueCat aplica pero contesta tarde no se devuelve dos veces: sus intentos repiten la Idempotency-Key, distinta en cada gasto', { timeout: 5000 }, async (t) => {
  withRevenueCat();
  t.after(withoutRevenueCat);
  t.mock.method(console, 'error', () => {});

  // RevenueCat ejecuta como mucho una vez cada Idempotency-Key.
  let balance = 0;
  const keys = [];
  const executed = new Set();
  const net = installFetch([
    {
      match: (url, init) => url.includes('/virtual_currencies/transactions') && init.method === 'POST',
      respond: (url, init) => {
        const key = init.headers['Idempotency-Key'];
        keys.push(key);
        if (!key || !executed.has(key)) {
          executed.add(key);
          balance += JSON.parse(init.body).adjustments.CRD;
        }
        return keys.length === 1 ? { hangHeaders: true } : { status: 200, json: {} };
      },
    },
  ]);
  t.after(net.restore);
  const lento = { ...revenuecat, adjustBalance: (uid, delta, opts) => revenuecat.adjustBalance(uid, delta, { ...opts, timeoutMs: 30 }) };

  const db = new FakeFirestore({ creditSpends: { s1: appliedSpend(), s2: appliedSpend({ docId: 'd2' }) } });
  await assert.rejects(() => credits.refundSpend(db, 's1', { revenuecat: lento }), (error) => error.status === 'timeout');
  rewindLastRefundAttempt(db, 's1');
  assert.equal((await credits.refundSpend(db, 's1', { revenuecat: lento })).refunded, true);
  assert.equal(balance, 1, 'el usuario recupera un credito, no dos');
  assert.ok(keys[0], 'el ajuste lleva Idempotency-Key');
  assert.equal(keys[1], keys[0], 'el reintento repite la clave');

  assert.equal((await credits.refundSpend(db, 's2', { revenuecat: lento })).refunded, true);
  assert.notEqual(keys[2], keys[0], 'otro gasto lleva otra clave');
  assert.equal(balance, 2);
});

test('Un gasto liquidado (documental entregado) no se puede reembolsar', async (t) => {
  withoutRevenueCat();
  const net = installFetch([]);
  t.after(net.restore);

  const db = new FakeFirestore({ users: { u5: { credits: 2 } } });
  const spend = await credits.spendCredit(db, 'u5', {}, { docId: 'entregado' });
  assert.equal(db.dump('users').u5.credits, 1);

  assert.deepEqual(await credits.settleSpend(db, spend.spendId), { settled: true });
  assert.deepEqual(await credits.refundSpend(db, spend.spendId), { refunded: false, reason: 'already_settled' });
  assert.equal(db.dump('users').u5.credits, 1, 'mentir en el documento no devuelve el credito');
  assert.equal((await credits.settleSpend(db, spend.spendId)).reason, 'already_settled');
});

test('refundSpend exige que el gasto sea de ese usuario y de ese documento', async (t) => {
  withoutRevenueCat();
  const net = installFetch([]);
  t.after(net.restore);

  const db = new FakeFirestore({ users: { u6: { credits: 2 } } });
  const spend = await credits.spendCredit(db, 'u6', {}, { docId: 'mio' });

  assert.equal((await credits.refundSpend(db, spend.spendId, {}, { uid: 'intruso' })).reason, 'uid_mismatch');
  assert.equal((await credits.refundSpend(db, spend.spendId, {}, { uid: 'u6', docId: 'ajeno' })).reason, 'doc_mismatch');
  assert.equal(db.dump('users').u6.credits, 1);
});

test('Dos devoluciones simultaneas del mismo gasto: la segunda espera a la que esta en vuelo', async (t) => {
  withoutRevenueCat();
  const net = installFetch([]);
  t.after(net.restore);

  const db = new FakeFirestore({ users: { u7: { credits: 2 } } });
  const spend = await credits.spendCredit(db, 'u7', {}, { docId: 'd7' });
  const key = `creditSpends/${spend.spendId}`;
  db.store.set(key, { ...db.store.get(key), refundState: 'in_flight', refundStartedAt: new Date() });

  assert.deepEqual(await credits.refundSpend(db, spend.spendId), { refunded: false, reason: 'in_flight' });
  assert.equal(db.dump('users').u7.credits, 1);
});
