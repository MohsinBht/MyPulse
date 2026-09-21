import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String? coupleId;
  final String displayName;
  final bool silentMode;
  final bool soundEnabled;

  UserProfile({
    required this.coupleId,
    required this.displayName,
    required this.silentMode,
    required this.soundEnabled,
  });

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      coupleId: data['coupleId'] as String?,
      displayName: (data['displayName'] as String?) ?? '',
      silentMode: (data['silentMode'] as bool?) ?? false,
      soundEnabled: (data['soundEnabled'] as bool?) ?? true,
    );
  }
}

/// Reads/writes the fields the client IS allowed to touch on its own user
/// document (silentMode, soundEnabled) — see firestore.rules: users/{uid} is
/// writable by that uid, unlike couples/signals/pairingCodes.
class UserService {
  UserService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<UserProfile> watchProfile(String uid) {
    return _firestore.doc('users/$uid').snapshots().map(UserProfile.fromDoc);
  }

  Future<void> setSilentMode(String uid, bool enabled) {
    return _firestore.doc('users/$uid').update({'silentMode': enabled});
  }

  Future<void> setSoundEnabled(String uid, bool enabled) {
    return _firestore.doc('users/$uid').update({'soundEnabled': enabled});
  }

  /// The partner's display name — resolved via the couple doc's
  /// memberUids, never assumed to be "the other name in profile" some
  /// other way. Used wherever the UI needs "Avec <partner>".
  Stream<String> watchPartnerName(String coupleId, String selfUid) {
    return _firestore.doc('couples/$coupleId').snapshots().asyncExpand((coupleDoc) {
      final memberUids = (coupleDoc.data()?['memberUids'] as List?)?.cast<String>() ?? const [];
      final partnerUid = memberUids.firstWhere((id) => id != selfUid, orElse: () => '');
      if (partnerUid.isEmpty) return Stream.value('');
      return _firestore.doc('users/$partnerUid').snapshots().map((doc) => (doc.data()?['displayName'] as String?) ?? '');
    });
  }
}
