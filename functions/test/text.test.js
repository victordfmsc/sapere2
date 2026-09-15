'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  toParagraphs,
  cleanScript,
  cleanAiNotes,
  sectionTitle,
} = require('../src/text');

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

test('las notas meta del modelo (patrones de clean_ai_notes del Space) no se guardan ni las lee el TTS', () => {
  const raw = [
    '## Sección 3: El faro',
    '',
    'El faro medía más de cien metros.',
    '',
    '[Continuará en la siguiente sección]',
    '',
    '*Nota: por límite de extensión, continuaré en la siguiente sección.*',
  ].join('\n');
  assert.deepEqual(toParagraphs(raw), ['Sección 3: El faro', 'El faro medía más de cien metros.']);
  assert.deepEqual(
    toParagraphs('The lighthouse fell.\r\n\r\nNote: due to length restrictions I will continue later.\r\n\r\nTo be continued.'),
    ['The lighthouse fell.'],
  );
  assert.equal(cleanAiNotes('Texto.\n\nNOTA: POR LÍMITE DE EXTENSIÓN sigo'), 'Texto.\n\n', 'sin salto final y sin distinguir mayusculas');
  assert.deepEqual(toParagraphs('Una nota de color: el faro era blanco.'), ['Una nota de color: el faro era blanco.']);
});

test("una 'nota:' dentro de la narracion no es una nota meta: solo cuenta una linea corta que empiece por ella", () => {
  const legit = [
    'Darwin tomó una nota: los picos de los pinzones variaban en longitud según la isla, y esa observación cambió la biología.',
    'Historians take note: the length of the Great Wall is disputed, but its purpose is not.',
    'Beethoven dejó escrita una sola nota: continuar el tema en la siguiente sinfonía.',
    `Nota: ${'la longitud del faro superaba la de cualquier torre conocida, '.repeat(5)}y los viajeros lo contaban.`,
  ];
  for (const paragraph of legit) {
    assert.deepEqual(toParagraphs(`Primero.\n\n${paragraph}\n\nÚltimo.`), ['Primero.', paragraph, 'Último.'], paragraph);
    assert.equal(cleanAiNotes(paragraph), paragraph, paragraph);
  }
  assert.deepEqual(
    toParagraphs('Primero.\n\n(Nota: continuaré con la caída del faro en la siguiente sección.)\n\nÚltimo.'),
    ['Primero.', 'Último.'],
  );
});
