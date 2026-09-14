'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { FakeFirestore } = require('./helpers/firestore');
const { sweepStalledDocs } = require('../src/sweep');
const { QUEUE_STALE_MS } = require('../src/config');

const MINUTE = 60 * 1000;

function ago(minutes) {
  return new Date(Date.now() - minutes * MINUTE);
}

function doc(status, minutesAgo, generation = {}, extra = {}) {
  const when = new Date(Date.now() - minutesAgo * MINUTE);
  return {
    uId: 'u1',
    status,
    publishTime: when,
    updatedAt: when,
    description: [],
    generation: { engine: 'firebase', spendId: null, refunded: false, ...generation },
    ...extra,
  };
}

function spend(minutesAgo, fields = {}) {
  return {
    uid: 'u1',
    source: 'revenuecat',
    applied: true,
    chargeState: 'applied',
    settled: false,
    refunded: false,
    refundState: 'pending',
    refundAttempts: 0,
    createdAt: new Date(Date.now() - minutesAgo * MINUTE),
    ...fields,
  };
}

function fakeCredits() {
  const refunded = [];
  const settled = [];
  return {
    refunded,
    settled,
    async refundSpend(db, spendId) {
      if (refunded.includes(spendId)) return { refunded: false, reason: 'already_refunded' };
      refunded.push(spendId);
      return { refunded: true, source: 'revenuecat', uid: 'u1' };
    },
    async settleSpend(db, spendId) {
      settled.push(spendId);
      return { settled: true };
    },
  };
}

test('el barrido marca los atascados sin texto, reembolsa y no toca los recientes', async () => {
  const db = new FakeFirestore({
    sapere: {
      atascado: doc('generating_script', 50, { spendId: 'spend1' }),
      reciente: doc('pending', 40, { spendId: 'spend2' }),
      enTitulo: doc('generating_title', 46, { spendId: 'spend3' }),
      terminado: doc('completed', 90, { spendId: 'spend4' }),
    },
    generationLocks: { u1: { uid: 'u1', docId: 'atascado', acquiredAt: new Date(Date.now() - 50 * MINUTE) } },
  });
  const credits = fakeCredits();

  const result = await sweepStalledDocs(db, { credits });
  const docs = db.dump('sapere');

  assert.equal(result.marked, 2);
  assert.equal(result.refunded, 2);
  assert.deepEqual(credits.refunded.sort(), ['spend1', 'spend3']);

  assert.equal(docs.atascado.status, 'error');
  assert.match(docs.atascado.errorMessage, /no termino en 45 minutos/);
  assert.equal(docs.atascado.generation.refunded, true);

  assert.equal(docs.enTitulo.status, 'error');
  assert.equal(docs.reciente.status, 'pending', 'un documento con latido de hace 40 minutos sigue vivo');
  assert.equal(docs.terminado.status, 'completed', 'los completados no se tocan');
  assert.equal(db.dump('generationLocks').u1, undefined, 'el cerrojo del atascado se suelta');
});

test('un atascado que ya tiene texto legible se cierra en verde, sin reembolso', async () => {
  const db = new FakeFirestore({
    sapere: {
      leyendo: doc('generating_script', 50, { spendId: 'spend5' }, {
        readyToRead: true,
        description: ['Capitulo uno ya publicado.'],
      }),
    },
  });
  const credits = fakeCredits();

  const result = await sweepStalledDocs(db, { credits });
  const leyendo = db.dump('sapere').leyendo;

  assert.equal(result.closed, 1);
  assert.equal(result.marked, 0);
  assert.equal(leyendo.status, 'completed');
  assert.match(leyendo.errorMessage, /^parcial: /);
  assert.deepEqual(leyendo.description, ['Capitulo uno ya publicado.']);
  assert.deepEqual(credits.refunded, [], 'el contenido se entrego: no se devuelve el credito');
  assert.deepEqual(credits.settled, ['spend5']);
});

test('si el documento se completa entre la consulta y la escritura, el barrido no lo machaca', async () => {
  const db = new FakeFirestore({
    sapere: { carrera: doc('generating_script', 50, { spendId: 'spend6' }) },
  });
  const credits = fakeCredits();

  const originalTransaction = db.runTransaction.bind(db);
  let first = true;
  db.runTransaction = async (fn) => {
    if (first) {
      first = false;
      const current = db.store.get('sapere/carrera');
      db.store.set('sapere/carrera', { ...current, status: 'completed', description: ['Texto completo.'] });
    }
    return originalTransaction(fn);
  };

  const result = await sweepStalledDocs(db, { credits });
  const carrera = db.dump('sapere').carrera;

  assert.equal(result.marked, 0);
  assert.equal(carrera.status, 'completed');
  assert.deepEqual(credits.refunded, []);
});

test('conciliacion: reembolsa el gasto de un documento en error', async () => {
  const db = new FakeFirestore({
    sapere: {
      fallido: doc('error', 60, { spendId: 'spend9', refunded: false }),
      yaDevuelto: doc('error', 60, { spendId: 'spend8', refunded: true }),
    },
    creditSpends: {
      spend9: spend(60, { docId: 'fallido' }),
      spend8: spend(60, { docId: 'yaDevuelto', refunded: true, refundState: 'done' }),
    },
  });
  const credits = fakeCredits();

  const result = await sweepStalledDocs(db, { credits });

  assert.equal(result.marked, 0);
  assert.equal(result.refunded, 1);
  assert.deepEqual(credits.refunded, ['spend9']);
  assert.equal(db.dump('sapere').fallido.generation.refunded, true);
});

test('conciliacion: el gasto de un documento completado se liquida y nunca se reembolsa', async () => {
  const db = new FakeFirestore({
    sapere: { listo: doc('completed', 60, { spendId: 'spend7' }) },
    creditSpends: { spend7: spend(60, { docId: 'listo' }) },
  });
  const credits = fakeCredits();

  const result = await sweepStalledDocs(db, { credits });

  assert.equal(result.settled, 1);
  assert.deepEqual(credits.settled, ['spend7']);
  assert.deepEqual(credits.refunded, []);
});

test('conciliacion: un cobro sin documento (fallo entre cobro y creacion) se devuelve', async () => {
  const db = new FakeFirestore({
    creditSpends: {
      huerfano: spend(50, { docId: 'nuncaCreado' }),
      reciente: spend(5, { docId: 'enCamino' }),
    },
  });
  const credits = fakeCredits();

  const result = await sweepStalledDocs(db, { credits });

  assert.equal(result.refunded, 1);
  assert.deepEqual(credits.refunded, ['huerfano'], 'el de hace 5 minutos aun puede estar creandose');
});

test('conciliacion: un cargo sin confirmar queda para revision, no se devuelve a ciegas', async () => {
  const db = new FakeFirestore({
    sapere: { dudoso: doc('error', 60, { spendId: 'spend10' }) },
    creditSpends: { spend10: spend(60, { docId: 'dudoso', applied: false, chargeState: 'pending' }) },
  });
  const credits = fakeCredits();

  await sweepStalledDocs(db, { credits });

  assert.deepEqual(credits.refunded, []);
  assert.equal(db.dump('creditSpends').spend10.refundState, 'needs_review');
});

test('el barrido nunca reembolsa dos veces el mismo gasto', async () => {
  const db = new FakeFirestore({
    sapere: { atascado: doc('generating_script', 50, { spendId: 'spend1' }) },
  });
  const credits = fakeCredits();

  const primera = await sweepStalledDocs(db, { credits });
  const segunda = await sweepStalledDocs(db, { credits });

  assert.equal(primera.refunded, 1);
  assert.equal(segunda.refunded, 0);
  assert.deepEqual(credits.refunded, ['spend1']);
});

test('el barrido no cierra lo que solo espera turno en la cola (sin despachar o esperando reintento) hasta su propio tope', async () => {
  const queueMinutes = Math.round(QUEUE_STALE_MS / MINUTE);
  const db = new FakeFirestore({
    sapere: {
      sinDespachar: doc('pending', 60, { spendId: 'spend1' }),
      esperandoReintento: doc('generating_script', 60, { spendId: 'spend2', attemptStartedAt: ago(80), awaitingRetry: true }, {
        readyToRead: true,
        description: ['Seccion uno.'],
      }),
      atascado: doc('generating_script', 60, { spendId: 'spend3', attemptStartedAt: ago(80), awaitingRetry: false }),
      despachadoSinTitulo: doc('pending', 50, { spendId: 'spend4', attemptStartedAt: ago(50) }),
      colaEterna: doc('pending', queueMinutes + 5, { spendId: 'spend5' }),
    },
  });
  const credits = fakeCredits();

  const result = await sweepStalledDocs(db, { credits });
  const docs = db.dump('sapere');

  assert.equal(docs.sinDespachar.status, 'pending', 'una hora en cola no es un atasco');
  assert.equal(docs.esperandoReintento.status, 'generating_script', 'ni siquiera se cierra como parcial');
  assert.equal(docs.atascado.status, 'error');
  assert.equal(docs.despachadoSinTitulo.status, 'error');
  assert.equal(docs.colaEterna.status, 'error');
  assert.match(docs.colaEterna.errorMessage, new RegExp(`no termino en ${queueMinutes} minutos`));
  assert.equal(result.marked, 3);
  assert.equal(result.closed, 0);
  assert.deepEqual(credits.refunded.sort(), ['spend3', 'spend4', 'spend5']);
  assert.deepEqual(credits.settled, []);
});

test('al cerrar, el barrido deja constancia en el gasto: entrega si cierra en parcial, cierre en error si marca', async () => {
  const db = new FakeFirestore({
    sapere: {
      leyendo: doc('generating_script', 50, { spendId: 'spendL' }, { readyToRead: true, description: ['Uno.'] }),
      vacio: doc('generating_script', 50, { spendId: 'spendV' }),
    },
    creditSpends: {
      spendL: spend(50, { docId: 'leyendo' }),
      spendV: spend(50, { docId: 'vacio' }),
    },
  });

  await sweepStalledDocs(db, { credits: fakeCredits() });
  const spends = db.dump('creditSpends');

  assert.ok(spends.spendL.deliveredAt);
  assert.equal(spends.spendL.closedInErrorAt, undefined);
  assert.ok(spends.spendV.closedInErrorAt);
  assert.equal(spends.spendV.deliveredAt, undefined);
});

test('conciliacion: documento borrado tras la entrega -> se liquida; sin entrega o cerrado en error por el servidor -> se devuelve', async () => {
  const db = new FakeFirestore({
    creditSpends: {
      leidoYBorrado: spend(50, { docId: 'borradoTrasLeer', deliveredAt: ago(48) }),
      fallidoYReintentado: spend(50, { docId: 'borradoAlReintentar', deliveredAt: ago(48), closedInErrorAt: ago(46) }),
      borradoSinTexto: spend(50, { docId: 'borradoEnCola' }),
    },
  });
  const credits = fakeCredits();

  const result = await sweepStalledDocs(db, { credits });

  assert.deepEqual(credits.settled, ['leidoYBorrado'], 'contenido entregado: no se devuelve aunque ya no exista');
  assert.deepEqual(credits.refunded.sort(), ['borradoSinTexto', 'fallidoYReintentado']);
  assert.equal(result.settled, 1);
  assert.equal(result.refunded, 2);
});

test('un documento sin marca de tiempo no se marca como error', async () => {
  const db = new FakeFirestore({
    sapere: { raro: { uId: 'u1', status: 'pending', generation: { spendId: 'x', refunded: false } } },
  });
  const credits = fakeCredits();

  const result = await sweepStalledDocs(db, { credits });
  assert.equal(result.marked, 0);
  assert.equal(db.dump('sapere').raro.status, 'pending');
});
