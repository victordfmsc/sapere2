'use strict';

const { normalizeForMatch } = require('./docugen');

const HEADING = /^[ \t]*#{1,6}[ \t]*(.+?)[ \t#]*$/;

// Notas meta que el modelo cuela en una seccion, con las palabras de
// clean_ai_notes del Space (app.py), que solo limpia su propia copia: el cliente
// recibe los deltas crudos. El Space borra desde cualquier 'nota:' hasta el final
// del parrafo; aqui solo cuenta una linea corta (hasta 240 caracteres) que EMPIECE
// por la nota, para no cortar narracion como 'Darwin tomo una nota: ... longitud'.
const AI_NOTE_PATTERNS = [
  /^(?=[^\n]{0,240}$)[ \t]*[*_(\[]*[ \t]*Nota[ \t]*:[^\n]*?(?:longitud|extensi[óo]n|continuar|l[íi]mite)[^\n]*\n?/gim,
  /^(?=[^\n]{0,240}$)[ \t]*[*_(\[]*[ \t]*Note[ \t]*:[^\n]*?(?:restrictions|continue|length)[^\n]*\n?/gim,
  /^\s*\[?Continuar[áa] en la siguiente secci[óo]n\.?\]?\s*$/gim,
  /^\s*\[?To be continued\.?\]?\s*$/gim,
];

function cleanAiNotes(raw) {
  return AI_NOTE_PATTERNS.reduce(
    (text, pattern) => text.replace(pattern, ''),
    String(raw || '').replace(/\r\n?/g, '\n'),
  );
}

// Limpieza del texto que se guarda en 'description': lo lee el TTS del
// dispositivo, asi que fuera markdown, notas meta y caracteres rotos. El texto de
// un encabezado ('## Seccion Uno: ...') se conserva como parrafo propio.
function cleanScript(raw) {
  const text = String(raw || '')
    .replace(/\r\n?/g, '\n')
    .replace(/```[a-z]*\n?/gi, '')
    .replace(/^[ \t]*#{1,6}[ \t]*(.+?)[ \t#]*$/gm, '\n$1\n')
    .replace(/^[ \t]*([-*_])(?:[ \t]*\1){2,}[ \t]*$/gm, '')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/[#*_`]/g, '')
    // Mojibake de UTF-8 leido como Latin-1. Una 'a' circunfleja suelta es texto
    // legitimo (portugues, frances, vietnamita) y no se toca.
    .replace(/â€”/g, '—')
    .replace(/â€“/g, '–')
    .replace(/â€™/g, '’')
    .replace(/â€œ/g, '“')
    .replace(/â€/g, '”')
    // [ \t] y no \s: \s se comeria el salto en blanco que separa los parrafos.
    .replace(/^[ \t]*[-•][ \t]+/gm, '')
    .replace(/^[ \t]*(cap[ií]tulo|chapter)[ \t]+\d+[ \t]*[:.\-–—]?[ \t]*$/gim, '');
  return cleanAiNotes(text).trim();
}

function toParagraphs(raw) {
  const script = cleanScript(raw);
  const parts = script
    .split(/\n\s*\n/)
    .map((p) => p.replace(/\s*\n\s*/g, ' ').trim())
    .filter((p) => p.length > 0);
  if (parts.length) return parts;
  return script ? [script] : [];
}

// Palabras con las que el Space (o el modelo) numera una seccion, en los idiomas
// de la app, ya normalizadas (sin tildes y en minusculas).
const SECTION_WORDS = [
  'seccion', 'section', 'abschnitt', 'partie', 'parte', 'sezione', 'deel', 'czesc', 'avsnitt', 'afsnit',
  'del', 'раздел', 'часть', 'глава', 'bolum', 'القسم', 'भाग', 'பகுதி', 'bagian', 'phan', 'seksyon',
  'bahagi', 'セクション', '第', '部分', '섹션', 'capitulo', 'chapter', 'kapitel', 'chapitre', 'capitolo',
  'hoofdstuk', 'rozdział', 'κεφάλαιο', 'ενότητα', 'episodio', 'episode',
].map((word) => ({ text: normalizeForMatch(word), cjk: /[\p{Script=Han}\p{Script=Katakana}\p{Script=Hangul}]/u.test(word) }));

function startsWithSectionWord(prefix) {
  return SECTION_WORDS.some(({ text, cjk }) => {
    if (!text) return false;
    if (cjk) return prefix.startsWith(text);
    return prefix === text || prefix.startsWith(`${text} `);
  });
}

// Titulo de la seccion a partir de su primer encabezado markdown.
// '## Seccion Uno: El hielo' -> 'El hielo'. Un titulo propio con dos puntos
// ('La expedicion: hielo y hambre') se deja entero.
function sectionTitle(raw, index) {
  const fallback = `Sección ${index + 1}`;
  const line = String(raw || '').replace(/\r\n?/g, '\n').split('\n').find((l) => HEADING.test(l));
  if (!line) return fallback;
  const heading = line.match(HEADING)[1].replace(/[*_`]/g, '').replace(/\s+/g, ' ').trim();
  if (!heading) return fallback;

  const colon = heading.search(/[:：]/);
  if (colon > 0) {
    const prefix = normalizeForMatch(heading.slice(0, colon));
    const rest = heading.slice(colon + 1).trim();
    const numbered = /\d/.test(prefix) || startsWithSectionWord(prefix);
    if (rest && numbered && prefix.split(' ').length <= 4) return rest.slice(0, 120);
  }
  return heading.slice(0, 120);
}

module.exports = {
  cleanAiNotes,
  cleanScript,
  toParagraphs,
  sectionTitle,
};
