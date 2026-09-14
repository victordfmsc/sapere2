'use strict';

// Convierte a milisegundos cualquiera de las formas en que llega una marca de
// tiempo: Timestamp de Firestore, Date o cadena ISO. 0 si no hay nada legible.
function toMillis(value) {
  if (!value) return 0;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (value instanceof Date) return value.getTime();
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? 0 : d.getTime();
}

module.exports = { toMillis };
