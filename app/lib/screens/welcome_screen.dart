import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';

/// First-launch screen: just a first name, no password. Shown once, before
/// the user has a displayName on their (already anonymous) Firebase account.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.uid});

  final String uid;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _authService = AuthService();
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await _authService.setDisplayName(widget.uid, name);
      // No navigation call needed: main.dart's _AuthGate watches the user
      // profile stream and swaps this screen out once displayName is set.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
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
              const Text('Comment tu t\'appelles ?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: MyPulseColors.ink), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                "C'est ce que ton/ta partenaire verra sur MyPulse.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: MyPulseColors.inkSoft, height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                autofocus: true,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(fontSize: 18, color: MyPulseColors.ink),
                decoration: InputDecoration(
                  hintText: 'Prénom',
                  filled: true,
                  fillColor: MyPulseColors.card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: MyPulseColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: MyPulseColors.white))
                      : const Text('Commencer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
