'use strict';

// Interceptor de global.fetch: ninguna prueba sale a la red.
// Cada ruta es { match, respond }. match puede ser una subcadena de la URL o una
// funcion (url, init) -> boolean. respond devuelve (o es) un objeto con:
//   { status, json, text, body, headers }   respuesta normal
//   { stream: [trozos], hang, cut, delayMs } cuerpo en streaming (text/event-stream)
//   { hangHeaders: true }                   nunca responde (solo lo corta el AbortSignal)
// o un Error, que se lanza como fallo de red.

function toBytes(chunk) {
  if (chunk instanceof Uint8Array) return chunk;
  return new Uint8Array(Buffer.from(String(chunk), 'utf8'));
}

function abortReason(signal) {
  if (signal && signal.reason) return signal.reason;
  const error = new Error('This operation was aborted');
  error.name = 'AbortError';
  return error;
}

// hang: tras el ultimo trozo la conexion queda abierta sin datos.
// cut: tras el ultimo trozo la conexion se corta con un error de red.
function makeStream(chunks, { signal, hang = false, cut = false, delayMs = 0 } = {}) {
  let index = 0;
  return new ReadableStream({
    start(controller) {
      if (!signal) return;
      const onAbort = () => {
        try {
          controller.error(abortReason(signal));
        } catch (_) {
          // ya cerrado
        }
      };
      if (signal.aborted) onAbort();
      else signal.addEventListener('abort', onAbort, { once: true });
    },
    async pull(controller) {
      if (index < chunks.length) {
        if (delayMs) await new Promise((resolve) => setTimeout(resolve, delayMs));
        controller.enqueue(toBytes(chunks[index]));
        index += 1;
        return;
      }
      if (hang) {
        await new Promise(() => {});
        return;
      }
      if (cut) {
        controller.error(new TypeError('terminated'));
        return;
      }
      controller.close();
    },
  });
}

function makeResponse({
  status = 200,
  json,
  text,
  body,
  headers = {},
  stream,
  hang,
  cut,
  delayMs,
} = {}, init = {}) {
  const payload = json !== undefined
    ? JSON.stringify(json)
    : (text !== undefined ? text : (stream ? stream.map(String).join('') : ''));
  const headerMap = new Map(Object.entries(headers).map(([k, v]) => [k.toLowerCase(), v]));
  return {
    ok: status >= 200 && status < 300,
    status,
    statusText: `status ${status}`,
    headers: { get: (name) => headerMap.get(String(name).toLowerCase()) || null },
    body: stream ? makeStream(stream, { signal: init.signal, hang, cut, delayMs }) : null,
    async json() {
      if (json !== undefined) return json;
      return JSON.parse(payload);
    },
    async text() {
      return payload;
    },
    async arrayBuffer() {
      const buf = body !== undefined ? Buffer.from(body) : Buffer.from(payload);
      return buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength);
    },
  };
}

function installFetch(routes) {
  const original = global.fetch;
  const calls = [];

  global.fetch = async (input, init = {}) => {
    const url = typeof input === 'string' ? input : String(input && input.url ? input.url : input);
    calls.push({ url, init });
    for (const route of routes) {
      const hit = typeof route.match === 'function' ? route.match(url, init) : url.includes(route.match);
      if (!hit) continue;
      const result = typeof route.respond === 'function' ? await route.respond(url, init, calls) : route.respond;
      if (result instanceof Error) throw result;
      if (result && result.hangHeaders) {
        return new Promise((_, reject) => {
          const { signal } = init;
          if (!signal) return;
          if (signal.aborted) reject(abortReason(signal));
          else signal.addEventListener('abort', () => reject(abortReason(signal)), { once: true });
        });
      }
      return makeResponse(result, init);
    }
    throw new Error(`Peticion no esperada en el test: ${url}`);
  };

  return {
    calls,
    urls: () => calls.map((c) => c.url),
    restore() {
      global.fetch = original;
    },
  };
}

module.exports = { installFetch, makeResponse, makeStream };
