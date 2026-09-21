import 'package:flutter/material.dart';

import '../services/signal_service.dart';
import '../services/user_service.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.coupleId, required this.partnerName});

  final String coupleId;
  final String partnerName;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userService = UserService();
  final _signalService = SignalService();

  @override
  Widget build(BuildContext context) {
    final uid = _signalService.currentUid;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: MyPulseColors.accent),
                  style: IconButton.styleFrom(backgroundColor: MyPulseColors.card),
                ),
                const SizedBox(width: 12),
                const Text('Réglages', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: MyPulseColors.ink)),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<int>(
              stream: _signalService.watchTotalSignals(widget.coupleId),
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: MyPulseColors.card, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('VOTRE LIEN, EN CHIFFRES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: MyPulseColors.inkFaint)),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.favorite, color: MyPulseColors.accent, size: 18),
                        const SizedBox(width: 8),
                        Text('$total signes échangés', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: MyPulseColors.ink)),
                      ]),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 26),
            const Text('PRÉFÉRENCES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: MyPulseColors.inkFaint)),
            if (uid != null)
              StreamBuilder<UserProfile>(
                stream: _userService.watchProfile(uid),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  return Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: MyPulseColors.accent,
                        title: const Text('Mode silencieux', style: TextStyle(fontWeight: FontWeight.bold, color: MyPulseColors.ink)),
                        subtitle: const Text('Les signes reçus s\'accumulent sans notification', style: TextStyle(color: MyPulseColors.inkSoft, fontSize: 13)),
                        value: profile?.silentMode ?? false,
                        onChanged: (v) => _userService.setSilentMode(uid, v),
                      ),
                      const Divider(color: MyPulseColors.border),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: MyPulseColors.accent,
                        title: const Text('Notifications sonores', style: TextStyle(fontWeight: FontWeight.bold, color: MyPulseColors.ink)),
                        value: profile?.soundEnabled ?? true,
                        onChanged: (v) => _userService.setSoundEnabled(uid, v),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 10),
            const Text('JUMELAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: MyPulseColors.inkFaint)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Lié·e à ${widget.partnerName}', style: const TextStyle(fontWeight: FontWeight.bold, color: MyPulseColors.ink)),
              trailing: TextButton(
                // Unpairing is destructive (breaks a shared history for two
                // people) — wire a confirmation dialog before calling any
                // unpair Cloud Function, never a bare tap-to-unlink.
                onPressed: () {},
                child: const Text('Gérer', style: TextStyle(color: MyPulseColors.accent, fontWeight: FontWeight.bold)),
              ),
            ),
            const Divider(color: MyPulseColors.border),
            const SizedBox(height: 10),
            const Text('À PROPOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: MyPulseColors.inkFaint)),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('MyPulse', style: TextStyle(fontWeight: FontWeight.bold, color: MyPulseColors.ink)),
              trailing: Text('Version 1.0', style: TextStyle(color: MyPulseColors.inkFaint)),
            ),
          ],
        ),
      ),
    );
  }
}
