'use strict';

const { secrets, options, COVER_FETCH_TIMEOUT_MS } = require('./config');

// OpenAI solo se usa para la portada: el texto lo genera el Space DocuGenerator.
const IMAGE_ENDPOINT = 'https://api.openai.com/v1/images/generations';
// dall-e-3 se apago el 2026-05-12; gpt-image-1 se apaga el 2026-10-23 y
// gpt-image-1-mini y gpt-image-1.5 el 2026-12-01, todos con gpt-image-2 como
// sustituto (pagina de deprecaciones de OpenAI). gpt-image-2 es el modelo por
// defecto y el respaldo de cualquier otro que se configure.
const IMAGE_FALLBACK_MODEL = 'gpt-image-2';

function isEnabled() {
  return Boolean(secrets.openaiKey());
}

// Solo quedan modelos GPT Image: responden en b64_json sin response_format.
async function requestImage(key, model, prompt) {
  const body = {
    model,
    prompt,
    n: 1,
    size: '1024x1536',
    quality: 'medium',
  };

  const response = await fetch(IMAGE_ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${key}`,
    },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(COVER_FETCH_TIMEOUT_MS),
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const detail = (data && data.error && data.error.message) || response.statusText;
    throw new Error(`OpenAI imagen ${response.status} (${model}): ${String(detail).slice(0, 200)}`);
  }

  const item = data && Array.isArray(data.data) ? data.data[0] : null;
  if (item && item.b64_json) {
    return { buffer: Buffer.from(item.b64_json, 'base64'), contentType: 'image/png' };
  }
  if (item && item.url) {
    const img = await fetch(item.url, { signal: AbortSignal.timeout(COVER_FETCH_TIMEOUT_MS) });
    if (!img.ok) throw new Error(`OpenAI imagen: descarga fallida ${img.status}`);
    const bytes = Buffer.from(await img.arrayBuffer());
    if (!bytes.length) throw new Error('OpenAI imagen: descarga vacia');
    return { buffer: bytes, contentType: img.headers.get('content-type') || 'image/png' };
  }
  throw new Error('OpenAI imagen: respuesta sin imagen');
}

// Si el modelo principal falla (organizacion sin verificar, moderacion, tiempo) se
// reintenta una vez con IMAGE_FALLBACK_MODEL, salvo que ya sea ese.
async function generateImage(prompt) {
  const key = secrets.openaiKey();
  if (!key) throw new Error('OpenAI: falta OPENAI_API_KEY');
  const primary = options.openaiImageModel() || IMAGE_FALLBACK_MODEL;
  try {
    return await requestImage(key, primary, prompt);
  } catch (error) {
    if (primary === IMAGE_FALLBACK_MODEL) throw error;
    console.warn(`[cover] ${primary} fallo, reintentando con ${IMAGE_FALLBACK_MODEL}`);
    return requestImage(key, IMAGE_FALLBACK_MODEL, prompt);
  }
}

module.exports = {
  isEnabled,
  generateImage,
  IMAGE_ENDPOINT,
  IMAGE_FALLBACK_MODEL,
};
