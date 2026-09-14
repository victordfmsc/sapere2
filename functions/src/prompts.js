'use strict';

// El texto del documental lo escribe el Space DocuGenerator con su propio prompt
// de sistema (src/docugen.js). Aqui solo queda el prompt de la portada.

// La portada nunca debe llevar texto: la app dibuja el titulo encima.
const COVER_NEGATIVE = 'strictly NO text, NO typography, NO letters, NO watermark';

function buildCoverPrompt(visualPrompt) {
  const base = String(visualPrompt || '').trim() || 'cinematic documentary poster, dramatic lighting, rich colors';
  return `${base}. Vertical book cover illustration, cinematic lighting, high detail, ${COVER_NEGATIVE}.`;
}

// Prompt visual sin modelo de texto: titulo + tema. Sin comillas alrededor del
// titulo para que el modelo de imagen no intente escribirlo en la escena.
function buildVisualPrompt({ title, prompt } = {}) {
  const clean = (value, max) => String(value || '').replace(/["“”«»]/g, '').replace(/\s+/g, ' ').trim().slice(0, max);
  const name = clean(title, 120);
  const theme = clean(prompt, 240);
  const repeated = name && theme.toLowerCase().startsWith(name.toLowerCase());
  const subject = (repeated ? [theme] : [name, theme]).filter(Boolean).join(' — ') || 'a mystery';
  return `Cinematic documentary cover evoking ${subject}, dramatic lighting, atmospheric, rich color grading`;
}

module.exports = { buildCoverPrompt, buildVisualPrompt, COVER_NEGATIVE };
