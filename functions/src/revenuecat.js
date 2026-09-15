'use strict';

const { secrets, options } = require('./config');

// Portado de sapere-backend/src/revenuecat.js (API v2, moneda virtual).
// Necesita REVENUECAT_SECRET_KEY (secret key con Customer Purchases Configuration
// y Customer Configuration en lectura/escritura) y REVENUECAT_PROJECT_ID.
const BASE = 'https://api.revenuecat.com/v2';

// Tope de cada llamada: sin el, fetch espera hasta 300 s por las cabeceras con el
// cerrojo de startStory tomado, o se come la pasada entera del barrido.
const REQUEST_TIMEOUT_MS = 10 * 1000;
// El ajuste de saldo tiene mas margen que una lectura, sin que startStory pase de los
// 60 s de la app (lo comprueba credits.test.js). Cortarlo no dice si se aplico: el
// cobro lo confirma releyendo el saldo y el reembolso se reintenta con la misma
// Idempotency-Key, que RevenueCat ejecuta como mucho una vez.
const WRITE_TIMEOUT_MS = 20 * 1000;

function config() {
  return {
    key: secrets.revenuecatKey(),
    project: secrets.revenuecatProject(),
    currency: options.revenuecatCurrency() || 'CRD',
  };
}

function isEnabled() {
  const c = config();
  return Boolean(c.key && c.project);
}

async function request(path, init = {}, timeoutMs = REQUEST_TIMEOUT_MS) {
  const { key, project } = config();
  let response;
  let text;
  try {
    response = await fetch(`${BASE}/projects/${project}${path}`, {
      ...init,
      signal: AbortSignal.timeout(timeoutMs),
      headers: {
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
        ...(init.headers || {}),
      },
    });
    text = await response.text();
  } catch (error) {
    // La unica senal es la del tope: cualquier aborto es un timeout.
    if (error && (error.name === 'TimeoutError' || error.name === 'AbortError')) {
      const err = new Error(`RevenueCat API timeout: sin respuesta tras ${timeoutMs} ms`);
      err.status = 'timeout';
      throw err;
    }
    throw error;
  }
  let data = {};
  try {
    data = text ? JSON.parse(text) : {};
  } catch (_) {
    data = { raw: text };
  }
  if (!response.ok) {
    const detail = String(data.message || data.raw || response.statusText).slice(0, 200);
    const err = new Error(`RevenueCat API ${response.status}: ${detail}`);
    err.status = response.status;
    throw err;
  }
  return data;
}

function extractBalance(data, code) {
  const items = Array.isArray(data.items) ? data.items : [];
  for (const item of items) {
    const itemCode = (item.currency && item.currency.code) || item.code || item.currency_code;
    if (itemCode === code) return Number(item.balance || 0);
  }
  if (data.code === code && data.balance !== undefined) return Number(data.balance || 0);
  return 0;
}

async function getBalance(customerId) {
  const { currency } = config();
  try {
    const data = await request(`/customers/${encodeURIComponent(customerId)}/virtual_currencies`);
    return extractBalance(data, currency);
  } catch (err) {
    if (err.status === 404) return 0; // cliente aun no existe en RevenueCat
    throw err;
  }
}

async function adjustBalance(customerId, delta, { idempotencyKey, timeoutMs = WRITE_TIMEOUT_MS } = {}) {
  const { currency } = config();
  return request(`/customers/${encodeURIComponent(customerId)}/virtual_currencies/transactions`, {
    method: 'POST',
    body: JSON.stringify({ adjustments: { [currency]: delta } }),
    headers: idempotencyKey ? { 'Idempotency-Key': idempotencyKey } : {},
  }, timeoutMs);
}

module.exports = {
  REQUEST_TIMEOUT_MS,
  WRITE_TIMEOUT_MS,
  isEnabled,
  request,
  getBalance,
  adjustBalance,
  extractBalance,
};
