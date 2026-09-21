import 'package:flutter/material.dart';

import '../theme.dart';
import 'enter_code_screen.dart';
import 'generate_code_screen.dart';

class PairingChoiceScreen extends StatelessWidget {
  const PairingChoiceScreen({super.key});

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
                    const Text('Lier vos comptes', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: MyPulseColors.ink), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text(
                      "L'un de vous génère un code à 6 chiffres, l'autre le saisit. Une seule fois suffit.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: MyPulseColors.inkSoft, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    _ChoiceTile(
                      icon: Icons.tag,
                      title: 'Générer un code',
                      subtitle: 'Je crée le code, mon/ma partenaire le saisit',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GenerateCodeScreen())),
                    ),
                    const SizedBox(height: 12),
                    _ChoiceTile(
                      icon: Icons.dialpad,
                      title: "J'ai un code",
                      subtitle: "Mon/ma partenaire me l'a envoyé",
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EnterCodeScreen())),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 28),
              child: Text('MyPulse relie deux personnes — sans restriction.', style: TextStyle(fontSize: 12, color: MyPulseColors.inkFaint)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MyPulseColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: MyPulseColors.white, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: MyPulseColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: MyPulseColors.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: MyPulseColors.inkSoft)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: MyPulseColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}
