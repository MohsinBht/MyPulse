import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { isValidTemplateId } from "./templates";

const COOLDOWN_MS = 5_000;

export const sendSignal = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }

  const templateId = request.data?.templateId;
  if (!isValidTemplateId(templateId)) {
    throw new HttpsError("invalid-argument", "Unknown signal template.");
  }

  const db = admin.firestore();
  const userSnap = await db.doc(`users/${uid}`).get();
  const coupleId = userSnap.data()?.coupleId as string | undefined;
  if (!coupleId) {
    throw new HttpsError("failed-precondition", "Not paired with a partner yet.");
  }

  const signalsRef = db.collection(`couples/${coupleId}/signals`);

  // Server-side cooldown: the one place the 5s anti-spam rule actually holds.
  // The UI may also grey the buttons out, but that's cosmetic — this check is
  // what a modified client or a replayed request can't get around.
  const lastOwnSignal = await signalsRef
    .where("senderUid", "==", uid)
    .orderBy("sentAt", "desc")
    .limit(1)
    .get();
  if (!lastOwnSignal.empty) {
    const lastSentAt = lastOwnSignal.docs[0].data().sentAt as admin.firestore.Timestamp;
    const elapsedMs = Date.now() - lastSentAt.toMillis();
    if (elapsedMs < COOLDOWN_MS) {
      throw new HttpsError(
        "failed-precondition",
        `Cooldown active, retry in ${COOLDOWN_MS - elapsedMs}ms.`
      );
    }
  }

  const coupleRef = db.doc(`couples/${coupleId}`);
  await db.runTransaction(async (tx) => {
    const coupleSnap = await tx.get(coupleRef);
    const memberUids = (coupleSnap.data()?.memberUids ?? []) as string[];
    if (!memberUids.includes(uid)) {
      throw new HttpsError("permission-denied", "Not a member of this couple.");
    }
    tx.set(signalsRef.doc(), {
      senderUid: uid,
      templateId,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // The only counter the app ever reads: couple-level, never per-person —
    // that's a schema-level guarantee against the "never compare partners" rule.
    tx.update(coupleRef, {
      totalSignals: admin.firestore.FieldValue.increment(1),
    });
  });

  const coupleSnap = await coupleRef.get();
  const memberUids = (coupleSnap.data()?.memberUids ?? []) as string[];
  const partnerUid = memberUids.find((id) => id !== uid);
  if (partnerUid) {
    await notifyPartner(db, partnerUid, uid, templateId);
  }

  return { ok: true };
});

async function notifyPartner(
  db: admin.firestore.Firestore,
  partnerUid: string,
  senderUid: string,
  templateId: string
) {
  const [partnerSnap, senderSnap] = await Promise.all([
    db.doc(`users/${partnerUid}`).get(),
    db.doc(`users/${senderUid}`).get(),
  ]);
  const partner = partnerSnap.data();
  if (!partner) return;

  // Mode silencieux: the signal is already stored above, so it shows up in
  // "Échanges récents" whenever the partner next opens the app — accumulate
  // without disturbing, never drop it.
  if (partner.silentMode === true) return;

  const tokens: string[] = partner.fcmTokens ?? [];
  if (tokens.length === 0) return;

  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title: senderSnap.data()?.displayName ?? "MyPulse",
      body: "vous a envoyé un signe.",
    },
    data: { type: "signal", templateId, senderUid },
    android: { priority: "high" },
    apns: { headers: { "apns-priority": "10" } },
  });
}
