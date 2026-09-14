'use strict';

const openai = require('./openai');
const { COVER_FETCH_TIMEOUT_MS } = require('./config');
const { buildCoverPrompt } = require('./prompts');
const { sanitizeError } = require('./sanitize');

const POLLINATIONS_BASE = 'https://image.pollinations.ai/prompt/';

// El tope cubre tambien la lectura del cuerpo: una imagen colgada no retiene la tarea.
async function pollinations(prompt) {
  const url = `${POLLINATIONS_BASE}${encodeURIComponent(prompt)}?width=768&height=1024&nologo=true`;
  const response = await fetch(url, { signal: AbortSignal.timeout(COVER_FETCH_TIMEOUT_MS) });
  if (!response.ok) throw new Error(`Pollinations ${response.status}`);
  const buffer = Buffer.from(await response.arrayBuffer());
  if (!buffer.length) throw new Error('Pollinations devolvio una imagen vacia');
  return { buffer, contentType: response.headers.get('content-type') || 'image/jpeg' };
}

// Portada: OpenAI (gpt-image-1 -> dall-e-3) y, si no hay clave o falla,
// Pollinations, que no necesita credenciales.
async function generateCover(visualPrompt) {
  const prompt = buildCoverPrompt(visualPrompt);

  if (openai.isEnabled()) {
    try {
      const image = await openai.generateImage(prompt);
      return { ...image, provider: 'openai', prompt };
    } catch (error) {
      console.warn(`[cover] OpenAI fallo: ${sanitizeError(error)}`);
    }
  }

  const image = await pollinations(prompt);
  return { ...image, provider: 'pollinations', prompt };
}

module.exports = { generateCover, pollinations, POLLINATIONS_BASE };
