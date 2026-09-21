import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

const CODE_TTL_MS = 10 * 60 * 1000;

function randomSixDigitCode(): string {
  return String(Math.floor(100000 + Math.random() * 900000));
}

export const generatePairingCode = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }

  const db = admin.firestore();
  const userSnap = await db.doc(`users/${uid}`).get();
  if (userSnap.data()?.coupleId) {
    throw new HttpsError("failed-precondition", "Already paired.");
  }

  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromMillis(now.toMillis() + CODE_TTL_MS);

  // A handful of retries is enough at 6-digit / short-TTL scale; a genuine
  // collision on an unexpired, unused code is rare.
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = randomSixDigitCode();
    const ref = db.doc(`pairingCodes/${code}`);
    const created = await db.runTransaction(async (tx) => {
      const existing = await tx.get(ref);
      if (existing.exists) {
        const data = existing.data()!;
        const stillActive = !data.used && (data.expiresAt as admin.firestore.Timestamp).toMillis() > now.toMillis();
        if (stillActive) return false;
      }
      tx.set(ref, { creatorUid: uid, createdAt: now, expiresAt, used: false });
      return true;
    });
    if (created) {
      return { code, expiresAt: expiresAt.toMillis() };
    }
  }
  throw new HttpsError("resource-exhausted", "Could not allocate a pairing code, try again.");
});

export const redeemPairingCode = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }
  const code = request.data?.code;
  if (typeof code !== "string" || !/^\d{6}$/.test(code)) {
    throw new HttpsError("invalid-argument", "A 6-digit code is required.");
  }

  const db = admin.firestore();
  const codeRef = db.doc(`pairingCodes/${code}`);
  const userRef = db.doc(`users/${uid}`);

  const coupleId = await db.runTransaction(async (tx) => {
    const [codeSnap, userSnap] = await Promise.all([tx.get(codeRef), tx.get(userRef)]);
    const codeData = codeSnap.data();
    if (!codeData) throw new HttpsError("not-found", "Invalid code.");
    if (codeData.used) throw new HttpsError("failed-precondition", "Code already used.");
    if ((codeData.expiresAt as admin.firestore.Timestamp).toMillis() < Date.now()) {
      throw new HttpsError("deadline-exceeded", "Code expired.");
    }
    if (codeData.creatorUid === uid) {
      throw new HttpsError("invalid-argument", "You cannot redeem your own code.");
    }
    if (userSnap.data()?.coupleId) {
      throw new HttpsError("failed-precondition", "Already paired.");
    }
    const creatorRef = db.doc(`users/${codeData.creatorUid}`);
    const creatorSnap = await tx.get(creatorRef);
    if (creatorSnap.data()?.coupleId) {
      throw new HttpsError("failed-precondition", "Partner already paired with someone else.");
    }

    const newCoupleRef = db.collection("couples").doc();
    tx.set(newCoupleRef, {
      memberUids: [codeData.creatorUid, uid],
      totalSignals: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(creatorRef, { coupleId: newCoupleRef.id });
    tx.update(userRef, { coupleId: newCoupleRef.id });
    tx.update(codeRef, { used: true });
    return newCoupleRef.id;
  });

  return { coupleId };
});

// Housekeeping only — no product logic lives here.
export const cleanupExpiredPairingCodes = onSchedule("every 60 minutes", async () => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const expired = await db
    .collection("pairingCodes")
    .where("used", "==", false)
    .where("expiresAt", "<", now)
    .get();
  const batch = db.batch();
  expired.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
});
