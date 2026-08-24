import admin from 'firebase-admin';
import { env } from './env.js';
import { logger } from './logger.js';

export const initializeFirebase = () => {
  if (admin.apps.length > 0) return admin.app();

  const hasInlineCredentials =
    env.firebase.projectId && env.firebase.clientEmail && env.firebase.privateKey;

  try {
    if (hasInlineCredentials) {
      return admin.initializeApp({
        credential: admin.credential.cert({
          projectId: env.firebase.projectId,
          clientEmail: env.firebase.clientEmail,
          privateKey: env.firebase.privateKey
        }),
        storageBucket: env.firebase.storageBucket
      });
    }

    return admin.initializeApp({
      storageBucket: env.firebase.storageBucket
    });
  } catch (error) {
    logger.warn({ err: error }, 'Firebase Admin skipped; configure credentials to enable Firebase verification and FCM.');
    return null;
  }
};

export const firebaseApp = initializeFirebase();
export const firebaseAuth = firebaseApp ? admin.auth() : null;
export const firebaseMessaging = firebaseApp ? admin.messaging() : null;
export const firebaseStorage = firebaseApp ? admin.storage() : null;

