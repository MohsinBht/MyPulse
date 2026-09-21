import 'package:cloud_functions/cloud_functions.dart';

class PairingResult {
  final String code;
  final DateTime expiresAt;
  PairingResult({required this.code, required this.expiresAt});
}

/// Wraps generatePairingCode / redeemPairingCode. Both are Cloud Functions,
/// not direct Firestore writes — see docs/ARCHITECTURE.md for why (atomic
/// checks a security rule can't express: code not expired, not self-redeemed,
/// neither side already paired).
class PairingService {
  PairingService({FirebaseFunctions? functions}) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<PairingResult> generateCode() async {
    final result = await _functions.httpsCallable('generatePairingCode').call<Map<String, dynamic>>();
    final data = result.data;
    return PairingResult(
      code: data['code'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch((data['expiresAt'] as num).toInt()),
    );
  }

  /// Throws FirebaseFunctionsException on an invalid, expired, self-issued
  /// or already-used code — the UI surfaces `.message` directly.
  Future<String> redeemCode(String code) async {
    final result = await _functions.httpsCallable('redeemPairingCode').call<Map<String, dynamic>>({'code': code});
    return result.data['coupleId'] as String;
  }
}
