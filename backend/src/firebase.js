const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function initFirebase() {
  if (admin.apps.length) return admin;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

  let cert = null;

  if (serviceAccountPath) {
    const fullPath = path.isAbsolute(serviceAccountPath)
      ? serviceAccountPath
      : path.join(process.cwd(), serviceAccountPath);
    const raw = fs.readFileSync(fullPath, 'utf8');
    cert = JSON.parse(raw);
  } else if (serviceAccountJson) {
    cert = JSON.parse(serviceAccountJson);
  } else {
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    let privateKey = process.env.FIREBASE_PRIVATE_KEY;

    if (privateKey) {
      privateKey = privateKey.replace(/\\n/g, '\n');
    }

    if (projectId && clientEmail && privateKey) {
      cert = { projectId, clientEmail, privateKey };
    }
  }

  if (!cert) {
    const err = new Error(
      'Missing Firebase credentials. Provide FIREBASE_SERVICE_ACCOUNT_PATH or FIREBASE_SERVICE_ACCOUNT_JSON (or FIREBASE_PROJECT_ID + FIREBASE_CLIENT_EMAIL + FIREBASE_PRIVATE_KEY).'
    );
    err.statusCode = 500;
    throw err;
  }

  admin.initializeApp({
    credential: admin.credential.cert(cert),
  });

  return admin;
}

function getDb() {
  const fb = initFirebase();
  return fb.firestore();
}

module.exports = { initFirebase, getDb };
