'use strict';

const { randomUUID } = require('node:crypto');

// Sube el fichero con un token de descarga permanente y devuelve la URL publica
// del estilo que ya usa la app (firebasestorage.googleapis.com/...?alt=media&token=).
// Asi no depende de ACL publicas ni de URLs firmadas que caducan.
async function uploadWithDownloadToken(bucket, path, buffer, contentType) {
  const token = randomUUID();
  const file = bucket.file(path);
  await file.save(buffer, {
    resumable: false,
    contentType,
    metadata: {
      contentType,
      cacheControl: 'public, max-age=31536000',
      metadata: { firebaseStorageDownloadTokens: token },
    },
  });
  return downloadUrl(bucket.name, path, token);
}

function downloadUrl(bucketName, path, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

function coverPath(docId) {
  return `covers/${docId}.png`;
}

async function uploadCover(bucket, docId, buffer, contentType) {
  return uploadWithDownloadToken(bucket, coverPath(docId), buffer, contentType || 'image/png');
}

module.exports = { uploadWithDownloadToken, uploadCover, coverPath, downloadUrl };
