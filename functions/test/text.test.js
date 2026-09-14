'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { toParagraphs, cleanScript, sectionTitle } = require('../src/text');

test('toParagraphs limpia markdown y separa por lineas en blanco', () => {
  const raw = '## Capitulo 1\n\n**Primer** parrafo con *enfasis*.\n\n- Segundo parrafo.\n\n\n';
  assert.deepEqual(toParagraphs(raw), ['Primer parrafo con enfasis.', 'Segundo parrafo.']);
  assert.ok(!cleanScript('```json\nhola\n```').includes('```'));
});

test('el encabezado de una seccion se conserva como parrafo propio, sin marcadores', () => {
  const raw = '## Sección Uno: El hielo\nEl barco crujía.\nNadie dormía.\n\nSegundo **párrafo**.\r\n\r\n---\r\n\r\nTercero.';
  assert.deepEqual(toParagraphs(raw), [
    'Sección Uno: El hielo',
    'El barco crujía. Nadie dormía.',
    'Segundo párrafo.',
    'Tercero.',
  ]);
});

test('una a circunfleja legitima (portugues, frances, vietnamita) no se toca; el mojibake si', () => {
  const text = 'Tôi cần hiểu sâu hơn. A câmera filmou o château.';
  assert.deepEqual(toParagraphs(text), [text]);
  assert.equal(cleanScript('uno â€” dos'), 'uno — dos');
});

test('sectionTitle toma el titulo del encabezado sin el prefijo de numeracion', () => {
  assert.equal(sectionTitle('## Sección Uno: El hielo\n\nTexto', 0), 'El hielo');
  assert.equal(sectionTitle('## Section Two: The Ice\nText', 1), 'The Ice');
  assert.equal(sectionTitle('### Abschnitt 3: Das Eis', 2), 'Das Eis');
  assert.equal(sectionTitle('## 第一部分：冰', 0), '冰');
  assert.equal(sectionTitle('## La expedición: hielo y hambre', 0), 'La expedición: hielo y hambre');
  assert.equal(sectionTitle('## Delfines: el mar abierto', 0), 'Delfines: el mar abierto');
  assert.equal(sectionTitle('## **El final**', 5), 'El final');
  assert.equal(sectionTitle('Sin encabezado.', 4), 'Sección 5');
});
