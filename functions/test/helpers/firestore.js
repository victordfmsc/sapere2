'use strict';

const { FieldValue } = require('firebase-admin/firestore');

// Doble minimo de Firestore: lo justo que usan credits.js, story.js y sweep.js
// (get/set/update/add, where con == e in, limit y runTransaction).
// No hay red ni emulador: todo vive en un Map en memoria.

function clone(value) {
  if (value === null || typeof value !== 'object') return value;
  if (value instanceof Date) return new Date(value.getTime());
  if (Array.isArray(value)) return value.map(clone);
  const out = {};
  for (const [k, v] of Object.entries(value)) out[k] = clone(v);
  return out;
}

function resolveSentinels(value) {
  if (value instanceof FieldValue) return new Date();
  if (value === null || typeof value !== 'object') return value;
  if (value instanceof Date) return new Date(value.getTime());
  if (Array.isArray(value)) return value.map(resolveSentinels);
  const out = {};
  for (const [k, v] of Object.entries(value)) out[k] = resolveSentinels(v);
  return out;
}

function setPath(target, path, value) {
  const parts = path.split('.');
  let node = target;
  for (let i = 0; i < parts.length - 1; i += 1) {
    const key = parts[i];
    if (node[key] === null || typeof node[key] !== 'object' || Array.isArray(node[key])) node[key] = {};
    node = node[key];
  }
  node[parts[parts.length - 1]] = value;
}

function getPath(source, path) {
  return path.split('.').reduce((node, key) => (node === undefined || node === null ? undefined : node[key]), source);
}

function deepMerge(target, source) {
  for (const [key, value] of Object.entries(source)) {
    if (value && typeof value === 'object' && !Array.isArray(value) && !(value instanceof Date)) {
      if (!target[key] || typeof target[key] !== 'object' || Array.isArray(target[key])) target[key] = {};
      deepMerge(target[key], value);
    } else {
      target[key] = value;
    }
  }
  return target;
}

function matches(data, [field, op, value]) {
  const actual = getPath(data, field);
  if (op === '==') return actual === value;
  if (op === '!=') return actual !== value;
  if (op === 'in') return Array.isArray(value) && value.includes(actual);
  if (op === 'not-in') return Array.isArray(value) && !value.includes(actual);
  throw new Error(`Operador no soportado en el doble de Firestore: ${op}`);
}

class FakeFirestore {
  constructor(seed = {}) {
    this.store = new Map();
    this.counter = 0;
    this.writes = 0;
    for (const [collection, docs] of Object.entries(seed)) {
      for (const [id, data] of Object.entries(docs)) {
        this.store.set(`${collection}/${id}`, clone(data));
      }
    }
  }

  nextId(prefix) {
    this.counter += 1;
    return `${prefix}${String(this.counter).padStart(3, '0')}`;
  }

  collection(name) {
    return new FakeCollection(this, name);
  }

  doc(path) {
    const [collection, id] = path.split('/');
    return new FakeDocRef(this, collection, id);
  }

  dump(collection) {
    const out = {};
    for (const [key, value] of this.store.entries()) {
      const [col, id] = key.split('/');
      if (col === collection) out[id] = clone(value);
    }
    return out;
  }

  async runTransaction(fn) {
    const tx = new FakeTransaction(this);
    const result = await fn(tx);
    tx.commit();
    return result;
  }
}

class FakeCollection {
  constructor(db, name, filters = [], limit = 0) {
    this.db = db;
    this.name = name;
    this.filters = filters;
    this._limit = limit;
  }

  doc(id) {
    return new FakeDocRef(this.db, this.name, id || this.db.nextId('doc'));
  }

  where(field, op, value) {
    return new FakeCollection(this.db, this.name, [...this.filters, [field, op, value]], this._limit);
  }

  limit(n) {
    return new FakeCollection(this.db, this.name, this.filters, n);
  }

  async add(data) {
    const ref = this.doc(this.db.nextId('spend'));
    await ref.set(data);
    return ref;
  }

  async get() {
    const docs = [];
    for (const [key, value] of this.db.store.entries()) {
      const [col, id] = key.split('/');
      if (col !== this.name) continue;
      if (!this.filters.every((f) => matches(value, f))) continue;
      docs.push(new FakeSnapshot(this.db, this.name, id, value));
      if (this._limit && docs.length >= this._limit) break;
    }
    return { docs, empty: docs.length === 0, size: docs.length };
  }
}

class FakeDocRef {
  constructor(db, collection, id) {
    this.db = db;
    this.collection_ = collection;
    this.id = id;
    this.path = `${collection}/${id}`;
  }

  get ref() {
    return this;
  }

  async get() {
    return new FakeSnapshot(this.db, this.collection_, this.id, this.db.store.get(this.path));
  }

  async set(data, opts = {}) {
    this.db.writes += 1;
    const resolved = resolveSentinels(data);
    if (opts.merge) {
      const current = this.db.store.get(this.path) || {};
      this.db.store.set(this.path, deepMerge(clone(current), resolved));
    } else {
      this.db.store.set(this.path, clone(resolved));
    }
    return this;
  }

  async update(data) {
    this.db.writes += 1;
    const current = this.db.store.get(this.path);
    if (!current) {
      const err = new Error(`No document to update: ${this.path}`);
      err.code = 5;
      throw err;
    }
    const next = clone(current);
    for (const [key, value] of Object.entries(resolveSentinels(data))) {
      if (key.includes('.')) setPath(next, key, value);
      else next[key] = value;
    }
    this.db.store.set(this.path, next);
    return this;
  }

  async delete() {
    this.db.store.delete(this.path);
  }
}

class FakeSnapshot {
  constructor(db, collection, id, value) {
    this.db = db;
    this.id = id;
    this._value = value;
    this.exists = value !== undefined;
    this.ref = new FakeDocRef(db, collection, id);
  }

  data() {
    return this._value === undefined ? undefined : clone(this._value);
  }

  get(field) {
    return getPath(this._value || {}, field);
  }
}

class FakeTransaction {
  constructor(db) {
    this.db = db;
    this.pending = [];
  }

  async get(ref) {
    return ref.get();
  }

  update(ref, data) {
    this.pending.push(() => {
      const current = this.db.store.get(ref.path);
      if (!current) throw new Error(`No document to update: ${ref.path}`);
      const next = clone(current);
      for (const [key, value] of Object.entries(resolveSentinels(data))) {
        if (key.includes('.')) setPath(next, key, value);
        else next[key] = value;
      }
      this.db.store.set(ref.path, next);
      this.db.writes += 1;
    });
  }

  set(ref, data, opts = {}) {
    this.pending.push(() => {
      const resolved = resolveSentinels(data);
      if (opts.merge) {
        const current = this.db.store.get(ref.path) || {};
        this.db.store.set(ref.path, deepMerge(clone(current), resolved));
      } else {
        this.db.store.set(ref.path, clone(resolved));
      }
      this.db.writes += 1;
    });
  }

  delete(ref) {
    this.pending.push(() => this.db.store.delete(ref.path));
  }

  commit() {
    for (const op of this.pending) op();
    this.pending = [];
  }
}

module.exports = { FakeFirestore, clone };
