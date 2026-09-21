import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../services/pairing_service.dart';
import '../theme.dart';
import 'linked_screen.dart';

class EnterCodeScreen extends StatefulWidget {
  const EnterCodeScreen({super.key});

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  final _pairingService = PairingService();
  String _digits = '';
  bool _submitting = false;
  String? _error;

  void _tapDigit(String d) {
    if (_digits.length >= 6 || _submitting) return;
    setState(() {
      _digits += d;
      _error = null;
    });
    if (_digits.length == 6) _submit();
  }

  void _backspace() {
    if (_digits.isEmpty || _submitting) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final coupleId = await _pairingService.redeemCode(_digits);
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LinkedScreen(coupleId: coupleId)));
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _error = e.message ?? 'Code invalide.';
        _digits = '';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text('Entrer le code', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: MyPulseColors.ink), textAlign: TextAlign.center),
                  SizedBox(height: 8),
                  Text(
                    'Demandez à votre partenaire le code à 6 chiffres affiché sur son téléphone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: MyPulseColors.inkSoft, height: 1.4),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: MyPulseColors.accent, fontSize: 13)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _digits.length;
                  return Container(
                    width: 46,
                    height: 58,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: MyPulseColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: filled ? MyPulseColors.accent : MyPulseColors.border, width: 1.5),
                    ),
                    child: filled ? Text(_digits[i], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: MyPulseColors.ink)) : null,
                  );
                }),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ...List.generate(9, (i) => _KeypadButton(label: '${i + 1}', onTap: () => _tapDigit('${i + 1}'))),
                    const SizedBox(),
                    _KeypadButton(label: '0', onTap: () => _tapDigit('0')),
                    _KeypadButton(icon: Icons.backspace_outlined, onTap: _backspace, muted: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({this.label, this.icon, required this.onTap, this.muted = false});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: muted ? MyPulseColors.cardMuted : MyPulseColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(
          child: label != null
              ? Text(label!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MyPulseColors.ink))
              : Icon(icon, color: MyPulseColors.inkSoft),
        ),
      ),
    );
  }
}
