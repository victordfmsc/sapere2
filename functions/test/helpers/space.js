'use strict';

// Simulador del Space Bukbuk/DocuGenerator sobre installFetch: nada sale a la red.

const SPACE = 'https://bukbuk-docugenerator.hf.space';
const RUNTIME = 'https://huggingface.co/api/spaces/Bukbuk/DocuGenerator/runtime';
const RESTART = 'https://huggingface.co/api/spaces/Bukbuk/DocuGenerator/restart';

function sse(events) {
  return events.map((event) => `data: ${JSON.stringify(event)}\n\n`);
}

// Parte el stream en trozos de `size` bytes: corta caracteres multibyte y lineas.
function splitBytes(chunks, size = 7) {
  const buffer = Buffer.from(chunks.join(''), 'utf8');
  const out = [];
  for (let i = 0; i < buffer.length; i += size) out.push(new Uint8Array(buffer.subarray(i, i + size)));
  return out;
}

function sectionText(number, total) {
  return `## Sección ${number}: Parte ${number} de ${total}\n\nPárrafo A de la sección ${number}.\n\nPárrafo B de la sección ${number}.`;
}

function sectionStream(content, { reasoning = 'RAZONAMIENTO-OCULTO', size = 7 } = {}) {
  const half = Math.ceil(content.length / 2);
  return splitBytes(sse([
    { type: 'reasoning', reasoning },
    { type: 'content', content: content.slice(0, half) },
    { type: 'content', content: content.slice(half) },
    { type: 'done', conversation_id: 'x', estimated_minutes: 5.2, usage: { total_tokens: 100 } },
  ]), size);
}

// Numero de seccion que pide una llamada, leido de la linea de posicion del extra.
function requestedSection(messages) {
  const system = messages.find((m) => m.role === 'system');
  const match = system && system.content.match(/sección (\d+) de (\d+)/);
  const assistants = messages.filter((m) => m.role === 'assistant').length;
  return match
    ? { number: Number(match[1]), total: Number(match[2]) }
    : { number: assistants + 1, total: assistants + 1 };
}

function pick(value, ...args) {
  return typeof value === 'function' ? value(...args) : value;
}

// title/outline: respuesta fija o funcion (indiceDeLlamada). section: funcion
// (call, log) que devuelve una respuesta de installFetch, o undefined para la
// seccion valida por defecto. generate: igual que section para POST /generate.
// runtime: lista de respuestas (la ultima se repite).
function createSpace({
  title = { status: 200, json: { title: 'Hielo y hambre' } },
  outline = { status: 200, json: { outline: '1. El barco\n2. El hielo\n3. La huida', sections: 6, duration_minutes: 30 } },
  section = null,
  generate = null,
  runtime = [{ status: 200, json: { stage: 'RUNNING' } }],
  restart = { status: 200, json: {} },
} = {}) {
  const log = { titles: [], outlines: [], sections: [], generates: [], deletes: [], runtimes: 0, restarts: 0 };

  const routes = [
    {
      match: (url) => url === RUNTIME,
      respond: () => {
        const response = runtime[Math.min(log.runtimes, runtime.length - 1)];
        log.runtimes += 1;
        return pick(response);
      },
    },
    {
      match: (url) => url === RESTART,
      respond: (url, init) => {
        log.restarts += 1;
        log.restartHeaders = init.headers;
        return pick(restart);
      },
    },
    {
      match: (url) => url === `${SPACE}/generate/title`,
      respond: (url, init) => {
        log.titles.push(JSON.parse(init.body));
        return pick(title, log.titles.length - 1);
      },
    },
    {
      match: (url) => url === `${SPACE}/generate/outline`,
      respond: (url, init) => {
        log.outlines.push(JSON.parse(init.body));
        return pick(outline, log.outlines.length - 1);
      },
    },
    {
      match: (url) => url === `${SPACE}/generate`,
      respond: (url, init) => {
        const call = { body: JSON.parse(init.body), headers: init.headers };
        log.generates.push(call);
        const custom = generate ? generate(call, log) : undefined;
        if (custom !== undefined) return custom;
        return { status: 200, stream: sectionStream(sectionText(1, 1)) };
      },
    },
    {
      match: (url, init) => url.startsWith(`${SPACE}/conversations/`) && init.method === 'DELETE',
      respond: (url) => {
        log.deletes.push(decodeURIComponent(url.slice(`${SPACE}/conversations/`.length)));
        return { status: 200, json: { status: 'success' } };
      },
    },
    {
      match: (url) => url.startsWith(`${SPACE}/documentary/`),
      respond: (url, init) => {
        const body = JSON.parse(init.body);
        const call = {
          area: decodeURIComponent(url.slice(`${SPACE}/documentary/`.length)),
          body,
          headers: init.headers,
          ...requestedSection(body.messages),
        };
        log.sections.push(call);
        const custom = section ? section(call, log) : undefined;
        if (custom !== undefined) return custom;
        return { status: 200, stream: sectionStream(sectionText(call.number, call.total)) };
      },
    },
  ];

  return { routes, log };
}

module.exports = {
  SPACE,
  RUNTIME,
  RESTART,
  sse,
  splitBytes,
  sectionText,
  sectionStream,
  createSpace,
};
