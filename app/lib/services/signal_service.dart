import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One entry in "Échanges récents" — read-only, mirrors couples/{id}/signals.
class SignalEvent {
  final String senderUid;
  final String templateId;
  final DateTime sentAt;

  SignalEvent({required this.senderUid, required this.templateId, required this.sentAt});

  factory SignalEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SignalEvent(
      senderUid: data['senderUid'] as String,
      templateId: data['templateId'] as String,
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Talks to the sendSignal Cloud Function and reads the couple-level data.
/// Deliberately thin: cooldown, the counter and the notification all live
/// server-side (functions/src/sendSignal.ts) — this class never re-implements
/// any of that logic locally, it just surfaces what the server decided.
class SignalService {
  SignalService({FirebaseFunctions? functions, FirebaseFirestore? firestore})
      : _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  /// Throws a [FirebaseFunctionsException] with code 'failed-precondition'
  /// when the 5s cooldown hasn't elapsed yet — the UI greys out all 6
  /// buttons together on that error, it never predicts the cooldown itself.
  Future<void> sendSignal(String templateId) async {
    await _functions.httpsCallable('sendSignal').call({'templateId': templateId});
  }

  /// Couple-level total only — there is no per-person equivalent by design.
  Stream<int> watchTotalSignals(String coupleId) {
    return _firestore.doc('couples/$coupleId').snapshots().map(
          (doc) => (doc.data()?['totalSignals'] as num?)?.toInt() ?? 0,
        );
  }

  Stream<List<SignalEvent>> watchRecentSignals(String coupleId, {int limit = 20}) {
    return _firestore
        .collection('couples/$coupleId/signals')
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(SignalEvent.fromDoc).toList());
  }

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;
}
