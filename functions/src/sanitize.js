'use strict';

// Portado de sapere-backend/src/env.js.
// Lee valores de una sola linea (claves API) de forma tolerante: si alguien pega
// un .env entero como valor del secreto, se queda con la primera linea y elimina
// el prefijo "NOMBRE=" y las comillas.
function cleanEnvValue(raw, name) {
  if (!raw) return '';

  let value = String(raw).trim();
  const firstLine = value.split(/\r?\n/)[0].trim();
  const hadExtraLines = firstLine !== value;
  value = firstLine;

  const prefixed = value.match(/^[A-Z0-9_]+=(.*)$/);
  if (prefixed) value = prefixed[1].trim();

  if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
    value = value.slice(1, -1);
  }

  if (hadExtraLines || prefixed) {
    console.warn(`[env] ${name || 'valor'} contenia varias lineas o un prefijo NOMBRE=; se ha saneado. Corrige el secreto.`);
  }
  return value;
}

// Mensaje de error corto y sin secretos, apto para guardar en Firestore o
// devolver al cliente. Portado de sapere-backend/src/env.js y endurecido con
// los patrones de clave que usan los proveedores nuevos (Google, RevenueCat, HF).
function sanitizeError(error) {
  let msg = (error && error.message) ? String(error.message) : String(error);
  msg = msg.split(/\r?\n/)[0];
  msg = msg
    .replace(/-----BEGIN[\s\S]*?-----END[^-]*-----/g, '<redacted>')
    .replace(/\b(sk-[A-Za-z0-9_-]{8,}|sk_[A-Za-z0-9]{8,}|hf_[A-Za-z0-9_-]{8,}|AIza[A-Za-z0-9_-]{10,}|goog_[A-Za-z0-9_-]{8,}|proj[A-Za-z0-9_-]{8,})\b/g, '<redacted>')
    .replace(/(Bearer)\s+\S+/gi, '$1 <redacted>')
    .replace(/([?&](?:key|token|api[_-]?key|access_token)=)[^&\s]+/gi, '$1<redacted>')
    .replace(/\b[A-Z][A-Z0-9_]{2,}=\S+/g, '<redacted>');
  return msg.slice(0, 300);
}

module.exports = { cleanEnvValue, sanitizeError };
