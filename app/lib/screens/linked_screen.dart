import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../theme.dart';
import 'home_screen.dart';

class LinkedScreen extends StatelessWidget {
  const LinkedScreen({super.key, required this.coupleId});

  final String coupleId;

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
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: MyPulseColors.card, borderRadius: BorderRadius.circular(26)),
                child: const Icon(Icons.favorite, color: MyPulseColors.accent, size: 40),
              ),
              const SizedBox(height: 28),
              const Text('Vous êtes liés !', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: MyPulseColors.ink), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              const Text(
                'Vous pouvez maintenant vous envoyer des signes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: MyPulseColors.inkSoft, height: 1.4),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: MyPulseColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    final partnerName = uid == null ? '' : await UserService().watchPartnerName(coupleId, uid).first;
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => HomeScreen(coupleId: coupleId, partnerName: partnerName)),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text("Aller à l'accueil", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
