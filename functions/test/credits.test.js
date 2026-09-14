'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { FakeFirestore } = require('./helpers/firestore');
const { installFetch } = require('./helpers/fetch');
const credits = require('../src/credits');

function withRevenueCat() {
  process.env.REVENUECAT_SECRET_KEY = 'sk_test_fake_key_para_pruebas';
  process.env.REVENUECAT_PROJECT_ID = 'proj_fake';
  process.env.REVENUECAT_CURRENCY = 'CRD';
}

function withoutRevenueCat() {
  delete process.env.REVENUECAT_SECRET_KEY;
  delete process.env.REVENUECAT_PROJECT_ID;
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

test('Un reembolso cuyo ajuste falla se reintenta como mucho MAX_REFUND_ATTEMPTS y luego queda para revision', async (t) => {
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

  await assert.rejects(() => credits.refundSpend(db, spend.spendId));
  stored = db.dump('creditSpends')[spend.spendId];
  assert.equal(stored.refundState, 'needs_review');
  assert.equal(stored.refundAttempts, credits.MAX_REFUND_ATTEMPTS);

  const third = await credits.refundSpend(db, spend.spendId);
  assert.deepEqual(third, { refunded: false, reason: 'needs_review' });
  assert.equal(refundPosts, credits.MAX_REFUND_ATTEMPTS, 'el barrido no reintenta para siempre');
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
