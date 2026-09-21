import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// V1 identity: no password, no email — an anonymous Firebase Auth account
/// tied to the device, plus a first name. Simplest thing that lets two
/// people pair and send signals; trades away account recovery on reinstall
/// (documented in app/README.md) for zero-friction onboarding.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Ensures an anonymous session exists, creating one if this is the first
  /// launch on this device. Safe to call on every app start.
  Future<String> ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;
    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }

  /// Creates the user's Firestore profile the first time they pick a name.
  /// Never overwrites coupleId or preferences if the doc already exists
  /// (merge: true) — this only runs once per device in practice, but stays
  /// safe to call again.
  Future<void> setDisplayName(String uid, String displayName) {
    return _firestore.doc('users/$uid').set({
      'displayName': displayName,
      'silentMode': false,
      'soundEnabled': true,
      'fcmTokens': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
