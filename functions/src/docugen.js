'use strict';

const { DOCUGEN, MAX_SYSTEM_PROMPT_CHARS } = require('./config');
const { sanitizeError } = require('./sanitize');

// Cliente del Space privado Bukbuk/DocuGenerator (FastAPI + deepseek-reasoner).
// Es el UNICO generador de texto: sin respaldo silencioso a otro modelo.

const AREAS = Object.freeze([
  'general', 'ciencia', 'historia', 'tecnologia', 'salud_biologia', 'economia', 'sociedad_politica',
  'filosofia_ideas', 'arte_cultura', 'naturaleza_medioambiente', 'espacio_universo', 'psicologia_mente',
  'biografias', 'derecho_normativa', 'gastronomia', 'deporte',
]);

// ---------------------------------------------------------------- errores

// FATAL: no se reintenta (status 'error' + reembolso). REINTENTABLE: se lanza
// para que Cloud Tasks reintente y la tarea se reanude desde chaptersMeta.
class DocugenError extends Error {
  constructor(message, { status = null } = {}) {
    super(message);
    this.name = this.constructor.name;
    this.status = status;
  }
}

class FatalError extends DocugenError {
  constructor(message, opts) {
    super(message, opts);
    this.fatal = true;
  }
}

class RetryableError extends DocugenError {
  constructor(message, opts) {
    super(message, opts);
    this.fatal = false;
  }
}

// Interna: el Space no contesta (red, 404, 502, 503, 504) -> se consulta su estado.
class UnavailableError extends RetryableError {
  constructor(message, opts) {
    super(message, opts);
    this.unavailable = true;
  }
}

function isFatal(error) {
  return Boolean(error && error.fatal === true);
}

function short(text, max = 200) {
  return String(text || '').replace(/\s+/g, ' ').trim().slice(0, max);
}

// Errores de DeepSeek que llegan dentro del texto del Space (evento SSE 'error'
// o detail de un HTTP 500/503). null si no es ninguno de los fatales conocidos.
function classifyDetail(detail, status = null) {
  const text = String(detail || '');
  if (status === 402 || /insufficient.?balance/i.test(text) || /(error code|status|http)\D{0,4}402\b/i.test(text)) {
    return new FatalError('DeepSeek sin saldo (Insufficient Balance): hay que recargar la cuenta de DeepSeek del Space', { status });
  }
  if (/DEEPSEEK_API_KEY/.test(text)) {
    return new FatalError('DEEPSEEK_API_KEY no configurada en el Space', { status });
  }
  if (/(error code|status|http)\D{0,4}401\b/i.test(text) || /authentication.?(error|fails)/i.test(text)
    || /invalid.{0,20}api.?key/i.test(text)) {
    return new FatalError(`Clave de DeepSeek invalida en el Space: ${short(text, 120)}`, { status });
  }
  // Peticion rechazada por DeepSeek (formato, parametros, contexto): repetirla
  // falla igual. 429 y 5xx siguen siendo reintentables.
  if (/(error code|status|http)\D{0,4}(400|422)\b/i.test(text)) {
    return new FatalError(`DeepSeek rechazo la peticion: ${short(text, 120)}`, { status });
  }
  return null;
}

async function readDetail(response) {
  let text = '';
  try {
    text = await response.text();
  } catch (_) {
    return '';
  }
  try {
    const data = JSON.parse(text);
    const detail = data && (data.detail || data.error || data.message);
    if (detail) return typeof detail === 'string' ? detail : JSON.stringify(detail);
  } catch (_) {
    // no es JSON: se usa el texto tal cual
  }
  return text.slice(0, 500);
}

async function errorFromResponse(response, label) {
  const { status } = response;
  const detail = await readDetail(response);
  const known = classifyDetail(detail, status);
  if (known) return known;
  if (status === 401 || status === 403) {
    return new FatalError(`HF_TOKEN sin acceso al Space ${DOCUGEN.spaceId} (${status})`, { status });
  }
  if ([404, 502, 503, 504].includes(status)) {
    return new UnavailableError(`${label}: Space no disponible (${status})`, { status });
  }
  if (status === 400 || status === 422) {
    return new FatalError(`${label}: el Space rechazo la peticion (${status}): ${short(detail)}`, { status });
  }
  if (status === 408 || status === 429 || status >= 500) {
    return new RetryableError(`${label}: el Space respondio ${status}: ${short(detail)}`, { status });
  }
  return new FatalError(`${label}: respuesta inesperada del Space (${status}): ${short(detail)}`, { status });
}

// ---------------------------------------------------------------- idioma

const LANGUAGE_NAMES = Object.freeze({
  es_ES: 'español',
  es_MX: 'español de México',
  es_AR: 'español de Argentina',
  es_CO: 'español de Colombia',
  en_US: 'inglés',
  en_GB: 'inglés británico',
  fr_FR: 'francés',
  de_DE: 'alemán',
  pt_PT: 'portugués',
  pt_BR: 'portugués de Brasil',
  it_IT: 'italiano',
  nl_NL: 'neerlandés',
  pl_PL: 'polaco',
  sv_SE: 'sueco',
  no_NO: 'noruego',
  da_DK: 'danés',
  el_GR: 'griego',
  ru_RU: 'ruso',
  tr_TR: 'turco',
  ar_AR: 'árabe',
  hi_IN: 'hindi',
  ta_IN: 'tamil',
  id_ID: 'indonesio',
  vi_VN: 'vietnamita',
  tl_PH: 'filipino',
  ja_JP: 'japonés',
  ko_KR: 'coreano',
  zh_CN: 'chino simplificado',
  zh_TW: 'chino tradicional',
});

const BASE_LANGUAGE_NAMES = Object.freeze({
  es: 'español', en: 'inglés', fr: 'francés', de: 'alemán', pt: 'portugués', it: 'italiano',
  nl: 'neerlandés', pl: 'polaco', sv: 'sueco', no: 'noruego', nb: 'noruego', nn: 'noruego',
  da: 'danés', el: 'griego', ru: 'ruso', tr: 'turco', ar: 'árabe', hi: 'hindi', ta: 'tamil',
  id: 'indonesio', vi: 'vietnamita', tl: 'filipino', fil: 'filipino', ja: 'japonés', ko: 'coreano',
  zh: 'chino simplificado',
});

// Nombre en espanol del idioma de salida para el campo `language` del Space.
function languageName(languageCode) {
  const [rawBase = '', rawRegion = ''] = String(languageCode || '').trim().split(/[_-]/);
  const base = rawBase.toLowerCase();
  const region = rawRegion.toUpperCase();
  const exact = LANGUAGE_NAMES[`${base}_${region}`];
  if (exact) return exact;
  if (base === 'zh' && ['TW', 'HK', 'MO', 'HANT'].includes(region)) return 'chino tradicional';
  return BASE_LANGUAGE_NAMES[base] || 'español';
}

// ---------------------------------------------------------------- area

const CATEGORY_AREAS = Object.freeze({
  '0Wm8Jabc33BRlzDPPz94': 'arte_cultura', // Artes
  '7VXB5mEUW9okmxbbIhZ9': 'tecnologia', // Imagina el futuro
  HyoQuHiHOpCJNX4aKVcn: 'psicologia_mente', // Formas de aprender
  KGF9MTtz4v4RSOj93Y1l: 'psicologia_mente', // Crecimiento y mentalidad
  SSc7UwgbUf5eAb6TmCkz: 'biografias', // Historias Humanas
  T0rSe6AITj3lL9DYDeCU: 'general', // Explora el mundo
  ay9mWgYmMMPVqhtUy7Gb: 'general', // Aprende Algo Nuevo
  dqpZObGn0lcaVQZnLSHG: 'historia', // Historia
});

// El orden importa: gana la primera area con alguna coincidencia. Humanidades va
// antes que ciencia ('sciences humaines', 'العلوم الإنسانية', '人文科学').
// Las 7 categorias de gamificacion estan en los 29 idiomas de assets/csv.
const AREA_KEYWORDS = [
  ['filosofia_ideas', [
    'humanities', 'humanidades', 'geisteswissenschaften', 'humanités', 'sciences humaines', 'umanistiche',
    'scienze umane', 'geesteswetenschappen', 'humanistyka', 'nauki humanistyczne', 'humaniora',
    'гуманитарные науки', 'العلوم الإنسانية', '人文科学', '人文', '인문학', 'ανθρωπιστικές επιστήμες',
    'beşeri bilimler', 'मानविकी', 'மானுடவியல்', 'khoa học nhân văn',
    'philosophy', 'filosofía', 'philosophie', 'filosofie', 'filozofia', 'filosofi', 'философия', 'felsefe',
    'فلسفة', '哲学', '철학', 'ideas', 'ideologías', 'mitología', 'mythology', 'religión', 'religion',
  ]],
  ['espacio_universo', [
    'espacio', 'space', 'universo', 'universe', 'astronomía', 'astronomy', 'astronomie', 'cosmos', 'cosmología',
    'weltraum', 'espace', 'spazio', 'космос', '宇宙', '우주',
  ]],
  ['psicologia_mente', [
    'psicología', 'psychology', 'psychologie', 'psicologia', 'mente', 'mind', 'mentalidad', 'mindset',
    'neurociencia', 'neuroscience', 'психология', '心理学', '심리학', 'aprendizaje', 'learning',
  ]],
  ['biografias', ['biografía', 'biografías', 'biography', 'biographies', 'biographie', 'biografia', 'historias humanas', 'biyografi']],
  ['economia', [
    'economía', 'economy', 'economics', 'wirtschaft', 'économie', 'economia', 'finanzas', 'finance', 'dinero',
    'money', 'negocios', 'business', 'экономика', '经济', '経済', '경제',
  ]],
  ['derecho_normativa', ['derecho', 'law', 'ley', 'leyes', 'legal', 'justicia', 'justice', 'recht', 'droit', 'diritto', 'direito', 'право']],
  ['gastronomia', ['gastronomía', 'gastronomy', 'cocina', 'cooking', 'food', 'comida', 'küche', 'cuisine', 'cucina', 'culinaria', '料理', '요리']],
  ['deporte', ['deporte', 'deportes', 'sport', 'sports', 'fútbol', 'football', 'soccer', 'esporte', 'desporto', 'спорт', 'スポーツ', '体育', '스포츠']],
  ['arte_cultura', [
    'arte', 'artes', 'art', 'arts', 'kunst', 'cultura', 'culture', 'kultur', 'música', 'music', 'musik',
    'cine', 'cinema', 'film', 'literatura', 'literature', 'teatro', 'theatre', 'arquitectura', 'architecture',
    'искусство', '艺术', '芸術', '예술',
  ]],
  ['salud_biologia', [
    'health', 'salud', 'gesundheit', 'santé', 'saúde', 'salute', 'gezondheid', 'zdrowie', 'hälsa', 'helse',
    'sundhed', 'υγεία', 'здоровье', 'sağlık', 'الصحة', 'صحة', 'स्वास्थ्य', 'ஆரோக்கியம்', 'kesehatan',
    'sức khỏe', 'kalusugan', '健康', '건강',
    'biología', 'biology', 'biologie', 'biologia', 'medicina', 'medicine', 'medizin', 'médecine', 'nutrición', 'nutrition',
  ]],
  ['naturaleza_medioambiente', [
    'nature', 'naturaleza', 'natur', 'natura', 'natureza', 'natuur', 'przyroda', 'φύση', 'природа', 'doğa',
    'الطبيعة', 'طبيعة', 'प्रकृति', 'இயற்கை', 'alam', 'thiên nhiên', 'kalikasan', '自然', '자연',
    'medio ambiente', 'medioambiente', 'environment', 'umwelt', 'environnement', 'ambiente', 'ecología', 'ecology',
  ]],
  ['historia', [
    'history', 'historia', 'geschichte', 'histoire', 'história', 'storia', 'geschiedenis', 'historie',
    'ιστορία', 'история', 'tarih', 'التاريخ', 'تاريخ', 'इतिहास', 'வரலாறு', 'sejarah', 'lịch sử',
    'kasaysayan', '歴史', '历史', '歷史', '역사',
  ]],
  ['sociedad_politica', [
    'society', 'sociedad', 'gesellschaft', 'société', 'sociedade', 'società', 'samenleving', 'społeczeństwo',
    'samhälle', 'samfunn', 'samfund', 'κοινωνία', 'общество', 'toplum', 'المجتمع', 'مجتمع', 'समाज',
    'சமூகம்', 'masyarakat', 'xã hội', 'lipunan', '社会', '社會', '사회',
    'política', 'politics', 'politik', 'politique', 'politica', 'polityka', 'политика', 'geopolítica', 'geopolitics',
  ]],
  ['tecnologia', [
    'technology', 'tecnología', 'technologie', 'tecnologia', 'technologia', 'teknik', 'teknologi',
    'τεχνολογία', 'технологии', 'технология', 'teknoloji', 'التكنولوجيا', 'تكنولوجيا', 'प्रौद्योगिकी',
    'தொழில்நுட்பம்', 'công nghệ', 'teknolohiya', '技術', '技术', '科技', '기술',
    'futuro', 'future', 'inteligencia artificial', 'artificial intelligence', 'informática', 'computing', 'robótica', 'robotics',
  ]],
  ['ciencia', [
    'science', 'sciences', 'ciencia', 'ciencias', 'wissenschaft', 'ciência', 'scienza', 'wetenschap', 'nauka',
    'vetenskap', 'vitenskap', 'videnskab', 'επιστήμη', 'наука', 'bilim', 'العلم', 'العلوم', 'विज्ञान',
    'அறிவியல்', 'sains', 'khoa học', 'agham', '科学', '科學', '과학',
    'física', 'physics', 'química', 'chemistry', 'matemáticas', 'mathematics',
  ]],
];

const CJK = /[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Hangul}]/u;

// Sin tildes, sin emojis, en minusculas y con un solo espacio entre palabras.
// Se aplica igual al texto y a las palabras clave, asi que los alfabetos con
// signos combinantes (devanagari, tamil, hangul) siguen coincidiendo.
function normalizeForMatch(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\p{M}\p{Cf}]/gu, '')
    .replace(/\p{Extended_Pictographic}/gu, ' ')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim();
}

const NORMALIZED_KEYWORDS = AREA_KEYWORDS.map(([area, words]) => [
  area,
  words.map((word) => ({ text: normalizeForMatch(word), cjk: CJK.test(word) })).filter((k) => k.text),
]);

// Palabra o frase completa; en chino, japones y coreano no hay espacios y basta
// con que aparezca.
function containsKeyword(text, keyword) {
  if (keyword.cjk) return text.includes(keyword.text);
  return ` ${text} `.includes(` ${keyword.text} `);
}

function validArea(area) {
  return AREAS.includes(area) ? area : 'general';
}

function matchArea(value) {
  const text = normalizeForMatch(value);
  if (!text) return null;
  for (const [area, keywords] of NORMALIZED_KEYWORDS) {
    if (keywords.some((keyword) => containsKeyword(text, keyword))) return validArea(area);
  }
  return null;
}

// Area del Space: id de categoria conocido; si no, palabras clave en genre,
// bukbukCategoryNames (todos los idiomas) y gamificationSubject; si no, general.
function resolveArea(data = {}) {
  const byId = CATEGORY_AREAS[data.bukbukCategoryId];
  if (byId) return validArea(byId);

  const names = data.bukbukCategoryNames && typeof data.bukbukCategoryNames === 'object'
    && !Array.isArray(data.bukbukCategoryNames)
    ? Object.values(data.bukbukCategoryNames)
    : [];
  for (const value of [data.genre, ...names, data.gamificationSubject]) {
    if (typeof value !== 'string') continue;
    const area = matchArea(value);
    if (area) return area;
  }
  return 'general';
}

// ---------------------------------------------------------------- SSE

// Parser de text/event-stream por lineas. Aguanta trozos partidos en cualquier
// punto (incluido un \r\n partido en dos). onData recibe el campo data de cada
// evento; si lanza, el error sale por push().
function createSseParser(onData) {
  let buffer = '';
  let dataLines = [];
  let skipLeadingLf = false;

  const dispatch = () => {
    if (!dataLines.length) return;
    const data = dataLines.join('\n');
    dataLines = [];
    onData(data);
  };

  const processLine = (line) => {
    if (line === '') {
      dispatch();
      return;
    }
    if (line[0] === ':') return;
    const colon = line.indexOf(':');
    const field = colon === -1 ? line : line.slice(0, colon);
    if (field !== 'data') return;
    let value = colon === -1 ? '' : line.slice(colon + 1);
    if (value[0] === ' ') value = value.slice(1);
    dataLines.push(value);
  };

  return {
    push(chunk) {
      let text = String(chunk || '');
      if (!text) return;
      if (skipLeadingLf) {
        skipLeadingLf = false;
        if (text[0] === '\n') text = text.slice(1);
      }
      buffer += text;
      let start = 0;
      for (let i = 0; i < buffer.length; i += 1) {
        const code = buffer.charCodeAt(i);
        if (code !== 10 && code !== 13) continue;
        const line = buffer.slice(start, i);
        if (code === 13) {
          if (i + 1 < buffer.length) {
            if (buffer.charCodeAt(i + 1) === 10) i += 1;
          } else {
            skipLeadingLf = true;
          }
        }
        start = i + 1;
        processLine(line);
      }
      buffer = buffer.slice(start);
    },
    end() {
      if (buffer) processLine(buffer);
      buffer = '';
      dispatch();
    },
  };
}

// Acumula una seccion a partir de bytes o texto del stream. push() devuelve true
// cuando ya llego 'done'. finish() exige 'done' y contenido no vacio.
// El razonamiento ('reasoning') se descarta: nunca se guarda ni se reenvia.
function createSectionReader() {
  const decoder = new TextDecoder('utf-8');
  let content = '';
  let done = null;

  const parser = createSseParser((raw) => {
    if (done) return;
    let event;
    try {
      event = JSON.parse(raw);
    } catch (_) {
      return;
    }
    if (!event || typeof event !== 'object') return;
    if (event.type === 'content' && typeof event.content === 'string') {
      content += event.content;
    } else if (event.type === 'error') {
      throw classifyDetail(event.detail)
        || new RetryableError(`El Space devolvio un error: ${short(event.detail)}`);
    } else if (event.type === 'done') {
      done = event;
    }
  });

  return {
    push(chunk) {
      parser.push(typeof chunk === 'string' ? chunk : decoder.decode(chunk, { stream: true }));
      return done !== null;
    },
    finish() {
      parser.push(decoder.decode());
      parser.end();
      if (!done) throw new RetryableError('Stream del Space cortado sin evento done');
      if (!content.trim()) throw new RetryableError('El Space devolvio una seccion vacia');
      const minutes = Number(done.estimated_minutes);
      return {
        content,
        estimatedMinutes: Number.isFinite(minutes) ? minutes : null,
        usage: done.usage || null,
      };
    },
  };
}

// ---------------------------------------------------------------- historial

// Contexto propio de la llamada que el Space mete en su prompt de sistema:
// marco del tipo (solo si lo eligio el usuario, no los marcos aleatorios),
// escaleta y la posicion de la seccion. La linea de posicion nunca se recorta.
function buildExtra({
  framework,
  systemPromptSource,
  outline,
  index,
  total,
  maxChars = DOCUGEN.maxExtraChars,
}) {
  const isLast = total > 1 && index === total - 1;
  const position = `Esta es la sección ${index + 1} de ${total}.${isLast ? ' Es la última: cierra el documental.' : ''}`;
  const parts = [];
  let budget = maxChars - position.length;

  const useFramework = (systemPromptSource === 'type' || systemPromptSource === 'gamification_client')
    && typeof framework === 'string' && framework.trim();
  if (useFramework) {
    const text = framework.trim().slice(0, Math.max(0, Math.min(MAX_SYSTEM_PROMPT_CHARS, budget - 2)));
    if (text) {
      parts.push(text);
      budget -= text.length + 2;
    }
  }

  if (typeof outline === 'string' && outline.trim()) {
    const header = 'Escaleta del documental (síguela):\n';
    const room = budget - header.length - 2;
    if (room > 0) {
      const text = outline.trim().slice(0, room);
      parts.push(header + text);
    }
  }

  parts.push(position);
  return parts.join('\n\n');
}

function continuationMessage(sectionNumber, total) {
  if (sectionNumber >= total) {
    return `Continúa con la sección ${sectionNumber} de ${total}, la última: cierra el documental con una conclusión memorable, sin repetir lo ya contado.`;
  }
  return `Continúa con la sección ${sectionNumber} de ${total}, sin repetir lo ya contado.`;
}

// [system extra] + [user tema] + por cada seccion ya escrita
// [assistant texto bruto, user 'Continua con la seccion K de N']. Siempre acaba
// en 'user' (si no, el Space reordena el historial).
function buildSectionMessages({ topic, extra, previous = [], index, total }) {
  const messages = [];
  if (typeof extra === 'string' && extra.trim()) messages.push({ role: 'system', content: extra });
  messages.push({ role: 'user', content: String(topic || '').trim() });
  for (let k = 0; k < index; k += 1) {
    messages.push({ role: 'assistant', content: String(previous[k] || '') });
    messages.push({ role: 'user', content: continuationMessage(k + 2, total) });
  }
  return messages;
}

let conversationSequence = 0;

// Un conversation_id NUEVO por llamada: si se repitiera, el Space anadiria los
// mensajes al historial que ya guarda en memoria y duplicaria el contexto.
function conversationId({ docId, index, attempt = 0, now = Date.now() }) {
  conversationSequence = (conversationSequence + 1) % 1679616;
  return `sapere-${docId}-s${index + 1}-a${attempt}-${Number(now).toString(36)}-${conversationSequence.toString(36)}`;
}

// ---------------------------------------------------------------- titulo

function cleanTitle(value) {
  const unquote = (text) => text.replace(/^["'«“”‘’\s]+|["'»“”‘’\s]+$/g, '');
  const text = unquote(String(value || '').replace(/[#*_`]/g, '').replace(/\s+/g, ' ').trim())
    .replace(/^(t[ií]tulo|title)\s*:\s*/i, '');
  return unquote(text)
    .replace(/[.。]+$/, '')
    .slice(0, 120)
    .trim();
}

// Titulo de respaldo: el tema recortado en una frontera de palabra.
function fallbackTitle(topic, max = 60) {
  const text = String(topic || '').replace(/\s+/g, ' ').trim() || 'Documental';
  let title = text;
  if (text.length > max) {
    const cut = text.slice(0, max);
    const space = cut.lastIndexOf(' ');
    title = (space >= max / 2 ? cut.slice(0, space) : cut).replace(/[\s,;:.\-–—]+$/, '');
  }
  return title.charAt(0).toUpperCase() + title.slice(1);
}

// ---------------------------------------------------------------- cliente

const READY_STAGES = ['RUNNING', 'RUNNING_BUILDING', 'RUNNING_APP_STARTING'];
const WAKE_STAGES = ['SLEEPING', 'STOPPED'];
const BROKEN_STAGES = ['PAUSED', 'RUNTIME_ERROR', 'BUILD_ERROR', 'CONFIG_ERROR', 'NO_APP_FILE', 'DELETING'];

function defaultSleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

// Un cliente por ejecucion de la tarea: recuerda el primer error FATAL para no
// volver a llamar al Space (ni esperar a que despierte) cuando ya no tiene arreglo.
// fetchImpl, sleep, now y config se inyectan en las pruebas.
function createClient({
  token = '',
  fetchImpl = (...args) => globalThis.fetch(...args),
  sleep = defaultSleep,
  now = Date.now,
  config = {},
} = {}) {
  const cfg = { ...DOCUGEN, ...config };
  const pendingDeletes = new Set();
  let fatal = null;

  const authHeaders = (extra = {}) => ({ Authorization: `Bearer ${token}`, ...extra });

  function remember(error) {
    if (isFatal(error) && !fatal) fatal = error;
    return error;
  }

  function requireToken() {
    if (!token) throw remember(new FatalError(`Falta HF_TOKEN: no hay credencial para el Space ${cfg.spaceId}`));
  }

  function guard() {
    if (fatal) throw fatal;
    requireToken();
  }

  async function postJson(path, payload, { timeoutMs, label }) {
    guard();
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    const timeout = () => new RetryableError(`${label}: sin respuesta en ${Math.round(timeoutMs / 1000)} s`);
    try {
      let response;
      try {
        response = await fetchImpl(`${cfg.baseUrl}${path}`, {
          method: 'POST',
          headers: authHeaders({ 'Content-Type': 'application/json', Accept: 'application/json' }),
          body: JSON.stringify(payload),
          signal: controller.signal,
        });
      } catch (error) {
        if (controller.signal.aborted) throw timeout();
        throw new UnavailableError(`${label}: error de red (${sanitizeError(error)})`);
      }
      if (!response.ok) throw await errorFromResponse(response, label);
      let text;
      try {
        text = await response.text();
      } catch (error) {
        if (controller.signal.aborted) throw timeout();
        throw new RetryableError(`${label}: respuesta cortada (${sanitizeError(error)})`);
      }
      try {
        return JSON.parse(text);
      } catch (_) {
        throw new RetryableError(`${label}: el Space no devolvio JSON`);
      }
    } finally {
      clearTimeout(timer);
    }
  }

  async function getRuntime() {
    requireToken();
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), cfg.runtimeTimeoutMs);
    try {
      let response;
      try {
        response = await fetchImpl(cfg.runtimeUrl, {
          headers: authHeaders({ Accept: 'application/json' }),
          signal: controller.signal,
        });
      } catch (error) {
        throw new RetryableError(`No se pudo consultar el estado del Space ${cfg.spaceId}: ${sanitizeError(error)}`);
      }
      if ([401, 403, 404].includes(response.status)) {
        throw remember(new FatalError(
          `HF_TOKEN sin acceso al Space ${cfg.spaceId} (runtime ${response.status})`,
          { status: response.status },
        ));
      }
      if (!response.ok) {
        throw new RetryableError(`Estado del Space ${cfg.spaceId}: HTTP ${response.status}`, { status: response.status });
      }
      const data = await response.json().catch(() => ({}));
      return { stage: String((data && data.stage) || '').toUpperCase(), data };
    } finally {
      clearTimeout(timer);
    }
  }

  // Con un token de solo lectura el reinicio da 401/403: se ignora y se sondea.
  async function restart() {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), cfg.runtimeTimeoutMs);
    try {
      const response = await fetchImpl(cfg.restartUrl, {
        method: 'POST',
        headers: authHeaders(),
        signal: controller.signal,
      });
      if (!response.ok) console.warn(`[docugen] reinicio del Space rechazado (${response.status}); se sigue sondeando`);
      return response.ok;
    } catch (error) {
      console.warn(`[docugen] no se pudo pedir el reinicio del Space: ${sanitizeError(error)}`);
      return false;
    } finally {
      clearTimeout(timer);
    }
  }

  // Espera a que el Space este RUNNING. Lanza FATAL si no hay acceso o esta
  // pausado/roto, y REINTENTABLE si no arranca a tiempo.
  async function ensureAvailable() {
    const startedAt = now();
    let restarted = false;
    for (;;) {
      let stage = '';
      let lastError = null;
      try {
        ({ stage } = await getRuntime());
      } catch (error) {
        if (isFatal(error)) throw error;
        lastError = error;
      }
      if (READY_STAGES.includes(stage)) return stage;
      if (BROKEN_STAGES.includes(stage)) {
        throw remember(new FatalError(`El Space ${cfg.spaceId} esta en estado ${stage}: hay que revisarlo en Hugging Face`));
      }
      if (WAKE_STAGES.includes(stage) && !restarted) {
        restarted = true;
        console.warn(`[docugen] Space ${cfg.spaceId} en ${stage}: se pide el reinicio`);
        await restart();
      }
      if (now() - startedAt >= cfg.wakeMaxMs) {
        const why = stage ? `estado ${stage}` : (lastError ? sanitizeError(lastError) : 'estado desconocido');
        throw new RetryableError(`El Space ${cfg.spaceId} no arranco en ${Math.round(cfg.wakeMaxMs / 1000)} s (${why})`);
      }
      await sleep(cfg.wakePollMs);
    }
  }

  // Ante red caida, 404, 502, 503 o 504: estado del Space, despertar si hace
  // falta y un unico reintento de la llamada. Con `deadline`, solo si antes del
  // plazo de la invocacion caben el despertar, la llamada (retryNeedsMs) y la
  // reserva final; si no, REINTENTABLE para seguir en otro intento.
  async function withWake(label, attempt, { deadline = null, retryNeedsMs = 0 } = {}) {
    if (fatal) throw fatal;
    try {
      return await attempt();
    } catch (error) {
      remember(error);
      if (!error || !error.unavailable) throw error;
      if (deadline && deadline - now() < cfg.wakeMaxMs + retryNeedsMs + cfg.deadlineMarginMs) {
        throw new RetryableError(
          `${label}: ${error.message}; sin tiempo para despertar el Space en esta invocacion`,
          { status: error.status },
        );
      }
      console.warn(`[docugen] ${label}: ${error.message}; se consulta el estado del Space`);
      await ensureAvailable();
      try {
        return await attempt();
      } catch (retryError) {
        remember(retryError);
        if (retryError && retryError.unavailable) {
          throw new RetryableError(
            `${label}: el Space sigue sin responder tras comprobar su estado (${retryError.message})`,
            { status: retryError.status },
          );
        }
        throw retryError;
      }
    }
  }

  // El Space guarda cada conversacion en memoria: se borra tras cada llamada, en
  // segundo plano, con tope de tiempo y sin lanzar nunca.
  function deleteConversation(id) {
    if (!id || !token) return Promise.resolve(false);
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), cfg.deleteTimeoutMs);
    const task = Promise.resolve()
      .then(() => fetchImpl(`${cfg.baseUrl}/conversations/${encodeURIComponent(id)}`, {
        method: 'DELETE',
        headers: authHeaders(),
        signal: controller.signal,
      }))
      .then(async (response) => {
        await response.text().catch(() => '');
        return Boolean(response.ok);
      })
      .catch(() => false)
      .finally(() => {
        clearTimeout(timer);
        pendingDeletes.delete(task);
      });
    pendingDeletes.add(task);
    return task;
  }

  // Espera a los borrados pendientes (cada uno acotado a deleteTimeoutMs).
  async function flush() {
    await Promise.allSettled([...pendingDeletes]);
  }

  async function generateTitle({ topic, area, language }) {
    const data = await withWake('titulo', () => postJson(
      '/generate/title',
      { input: topic, area: validArea(area), language },
      { timeoutMs: cfg.titleTimeoutMs, label: 'titulo' },
    ));
    const title = cleanTitle(data && data.title);
    if (!title) throw new RetryableError('titulo: el Space devolvio un titulo vacio');
    return title;
  }

  async function generateOutline({ topic, area, language, durationMinutes }) {
    const data = await withWake('escaleta', () => postJson(
      '/generate/outline',
      { input: topic, area: validArea(area), level: cfg.level, language, duration_minutes: durationMinutes },
      { timeoutMs: cfg.outlineTimeoutMs, label: 'escaleta' },
    ));
    const outline = data && typeof data.outline === 'string' ? data.outline.trim().slice(0, cfg.maxOutlineChars) : '';
    if (!outline) throw new RetryableError('escaleta: el Space devolvio una escaleta vacia');
    const sections = Number(data.sections);
    return { outline, sections: Number.isFinite(sections) ? sections : null };
  }

  async function streamSection({ id, area, language, durationMinutes, messages, label, deadline = null }) {
    guard();
    const controller = new AbortController();
    let reason = null;
    const abort = (why) => {
      if (reason) return;
      reason = why;
      controller.abort();
    };
    const idleMessage = `sin recibir datos en ${Math.round(cfg.idleTimeoutMs / 1000)} s`;
    // Tope total: el de una seccion o, si es menor, lo que queda de invocacion
    // menos la reserva final, para que la plataforma no corte la tarea antes de
    // guardar la seccion o cerrar el documento.
    const untilDeadline = deadline ? deadline - now() - cfg.deadlineMarginMs : Infinity;
    const totalMs = Math.max(0, Math.min(cfg.sectionTimeoutMs, untilDeadline));
    const totalMessage = totalMs < cfg.sectionTimeoutMs
      ? `sin terminar antes del plazo de la invocacion (${Math.round(totalMs / 1000)} s)`
      : `sin terminar en ${Math.round(cfg.sectionTimeoutMs / 1000)} s`;
    const totalTimer = setTimeout(() => abort(totalMessage), totalMs);
    let idleTimer = setTimeout(() => abort(idleMessage), cfg.idleTimeoutMs);
    const touch = () => {
      clearTimeout(idleTimer);
      idleTimer = setTimeout(() => abort(idleMessage), cfg.idleTimeoutMs);
    };
    const timeoutError = () => new RetryableError(`${label}: ${reason}`);

    try {
      let response;
      try {
        response = await fetchImpl(`${cfg.baseUrl}/documentary/${encodeURIComponent(area)}`, {
          method: 'POST',
          headers: authHeaders({ 'Content-Type': 'application/json', Accept: 'text/event-stream' }),
          body: JSON.stringify({
            messages,
            conversation_id: id,
            stream: true,
            language,
            level: cfg.level,
            duration_minutes: durationMinutes,
            max_tokens: cfg.maxTokens,
          }),
          signal: controller.signal,
        });
      } catch (error) {
        if (reason) throw timeoutError();
        throw new UnavailableError(`${label}: error de red (${sanitizeError(error)})`);
      }
      touch();
      if (!response.ok) {
        const error = await errorFromResponse(response, label);
        if (reason && !error.fatal) throw timeoutError();
        throw error;
      }

      const section = createSectionReader();
      if (!response.body || typeof response.body.getReader !== 'function') {
        section.push(await response.text());
        return section.finish();
      }

      const reader = response.body.getReader();
      try {
        for (;;) {
          let step;
          try {
            step = await reader.read();
          } catch (error) {
            if (reason) throw timeoutError();
            throw new RetryableError(`${label}: stream cortado (${sanitizeError(error)})`);
          }
          if (step.done) break;
          touch();
          if (section.push(step.value)) break;
        }
      } finally {
        reader.cancel().catch(() => {});
      }
      return section.finish();
    } finally {
      clearTimeout(totalTimer);
      clearTimeout(idleTimer);
    }
  }

  // Una seccion = una llamada a POST /documentary/{area} con stream y un
  // conversation_id nuevo (tambien en el reintento tras despertar el Space).
  // `deadline` (ms de reloj) es el plazo de la invocacion de la tarea.
  async function generateSection({
    docId,
    index,
    total,
    attempt = 0,
    area,
    language,
    durationMinutes,
    messages,
    deadline = null,
  }) {
    const label = `seccion ${index + 1}/${total}`;
    if (!AREAS.includes(area)) throw new FatalError(`${label}: area no valida (${area})`);
    const last = Array.isArray(messages) ? messages[messages.length - 1] : null;
    if (!last || last.role !== 'user') throw new FatalError(`${label}: el historial debe terminar en un mensaje user`);

    return withWake(label, async () => {
      const id = conversationId({ docId, index, attempt, now: now() });
      try {
        const result = await streamSection({ id, area, language, durationMinutes, messages, label, deadline });
        return { ...result, conversationId: id };
      } finally {
        deleteConversation(id);
      }
    }, { deadline, retryNeedsMs: cfg.sectionTimeoutMs });
  }

  return {
    generateTitle,
    generateOutline,
    generateSection,
    deleteConversation,
    ensureAvailable,
    getRuntime,
    flush,
    get fatal() {
      return fatal;
    },
  };
}

module.exports = {
  AREAS,
  LANGUAGE_NAMES,
  CATEGORY_AREAS,
  AREA_KEYWORDS,
  DocugenError,
  FatalError,
  RetryableError,
  UnavailableError,
  isFatal,
  classifyDetail,
  errorFromResponse,
  languageName,
  normalizeForMatch,
  resolveArea,
  createSseParser,
  createSectionReader,
  buildExtra,
  buildSectionMessages,
  continuationMessage,
  conversationId,
  cleanTitle,
  fallbackTitle,
  createClient,
};
