import 'package:flutter/material.dart';

import '../services/pairing_service.dart';
import '../theme.dart';
import 'enter_code_screen.dart';

class GenerateCodeScreen extends StatefulWidget {
  const GenerateCodeScreen({super.key});

  @override
  State<GenerateCodeScreen> createState() => _GenerateCodeScreenState();
}

class _GenerateCodeScreenState extends State<GenerateCodeScreen> {
  final _pairingService = PairingService();
  PairingResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _pairingService.generateCode();
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = "Impossible de générer un code, réessaie.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: MyPulseColors.accent),
                    style: IconButton.styleFrom(backgroundColor: MyPulseColors.card),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(color: MyPulseColors.card, borderRadius: BorderRadius.circular(22)),
                      child: const Icon(Icons.favorite, color: MyPulseColors.accent, size: 32),
                    ),
                    const SizedBox(height: 24),
                    const Text('Votre code', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: MyPulseColors.ink), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text(
                      'Donnez ce code à votre partenaire pour connecter vos deux téléphones. Il expire dans 10 minutes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: MyPulseColors.inkSoft, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    if (_loading) const CircularProgressIndicator(color: MyPulseColors.accent),
                    if (_error != null) Text(_error!, style: const TextStyle(color: MyPulseColors.accent)),
                    if (_result != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _result!.code.split('').map((digit) => Container(
                          width: 46,
                          height: 58,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: MyPulseColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MyPulseColors.border, width: 1.5),
                          ),
                          child: Text(digit, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: MyPulseColors.ink)),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: _generate,
                        icon: const Icon(Icons.refresh, size: 15, color: MyPulseColors.accent),
                        label: const Text('Régénérer le code', style: TextStyle(fontWeight: FontWeight.w600, color: MyPulseColors.accent)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const EnterCodeScreen())),
                child: RichText(
                  text: const TextSpan(children: [
                    TextSpan(text: 'Vous avez plutôt un code ? ', style: TextStyle(fontSize: 13, color: MyPulseColors.inkSoft)),
                    TextSpan(text: 'Entrez-le', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MyPulseColors.accent)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
