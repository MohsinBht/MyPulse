import * as admin from "firebase-admin";

admin.initializeApp();

export { sendSignal } from "./sendSignal";
export { generatePairingCode, redeemPairingCode, cleanupExpiredPairingCodes } from "./pairing";
