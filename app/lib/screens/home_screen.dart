import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../models/signal_template.dart';
import '../services/signal_service.dart';
import '../theme.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.coupleId, required this.partnerName});

  final String coupleId;
  final String partnerName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _signalService = SignalService();

  // Cooldown is enforced server-side (sendSignal); this is purely the local
  // countdown that greys out ALL 6 buttons together — never just the one
  // that was tapped, otherwise the anti-spam rule visually falls apart.
  Duration _cooldownRemaining = Duration.zero;
  Timer? _cooldownTicker;

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    super.dispose();
  }

  bool get _inCooldown => _cooldownRemaining > Duration.zero;

  Future<void> _send(String templateId) async {
    if (_inCooldown) return;
    try {
      await _signalService.sendSignal(templateId);
      _startCooldown(const Duration(seconds: 5));
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        // Server rejected it as too soon — trust it over our local timer.
        _startCooldown(const Duration(seconds: 5));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Impossible d'envoyer le signe.")),
        );
      }
    }
  }

  void _startCooldown(Duration duration) {
    _cooldownTicker?.cancel();
    setState(() => _cooldownRemaining = duration);
    _cooldownTicker = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      final remaining = _cooldownRemaining - const Duration(milliseconds: 200);
      if (remaining <= Duration.zero) {
        timer.cancel();
        setState(() => _cooldownRemaining = Duration.zero);
      } else {
        setState(() => _cooldownRemaining = remaining);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = _signalService.currentUid;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: MyPulseColors.accent, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'MyPulse',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: MyPulseColors.ink),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SettingsScreen(coupleId: widget.coupleId, partnerName: widget.partnerName)),
                    ),
                    icon: const Icon(Icons.settings_outlined, color: MyPulseColors.accent),
                    style: IconButton.styleFrom(backgroundColor: MyPulseColors.card),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AVEC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: MyPulseColors.inkFaint)),
                  Text(widget.partnerName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: MyPulseColors.ink)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: StreamBuilder<int>(
                stream: _signalService.watchTotalSignals(widget.coupleId),
                builder: (context, snapshot) {
                  final total = snapshot.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: MyPulseColors.card, borderRadius: BorderRadius.circular(16)),
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 14, color: MyPulseColors.ink),
                        // Couple-level total only — never split by sender, on purpose.
                        children: [
                          const TextSpan(text: 'Vous vous êtes envoyé '),
                          TextSpan(text: '$total signes', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: ' au total'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ENVOYER UN SIGNE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: MyPulseColors.inkFaint)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: kSignalTemplates.map((t) => _SignalButton(
                      template: t,
                      disabled: _inCooldown,
                      cooldownSeconds: _inCooldown ? (_cooldownRemaining.inMilliseconds / 1000).ceil() : null,
                      onTap: () => _send(t.id),
                    )).toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ÉCHANGES RÉCENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: MyPulseColors.inkFaint)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: StreamBuilder<List<SignalEvent>>(
                        stream: _signalService.watchRecentSignals(widget.coupleId),
                        builder: (context, snapshot) {
                          final events = snapshot.data ?? const [];
                          return ListView.builder(
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final e = events[index];
                              final template = kSignalTemplates.firstWhere((t) => t.id == e.templateId, orElse: () => kSignalTemplates.first);
                              final isMe = e.senderUid == uid;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: MyPulseColors.card,
                                  child: Icon(template.icon, color: MyPulseColors.accent, size: 16),
                                ),
                                title: Text.rich(TextSpan(children: [
                                  TextSpan(text: isMe ? 'Toi' : widget.partnerName, style: const TextStyle(fontWeight: FontWeight.bold, color: MyPulseColors.ink)),
                                  TextSpan(text: ' · ${template.label}', style: const TextStyle(color: MyPulseColors.ink)),
                                ])),
                                subtitle: Text(_relativeTime(e.sentAt), style: const TextStyle(color: MyPulseColors.inkSoft, fontSize: 12)),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return "Aujourd'hui, ${dt.hour}h${dt.minute.toString().padLeft(2, '0')}";
  return 'Le ${dt.day}/${dt.month}';
}

class _SignalButton extends StatelessWidget {
  const _SignalButton({
    required this.template,
    required this.disabled,
    required this.cooldownSeconds,
    required this.onTap,
  });

  final SignalTemplate template;
  final bool disabled;
  final int? cooldownSeconds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: disabled ? MyPulseColors.cardMuted : MyPulseColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: disabled ? null : onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(template.icon, color: disabled ? MyPulseColors.inkFaint : MyPulseColors.accent, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    template.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: disabled ? MyPulseColors.inkFaint : MyPulseColors.ink),
                  ),
                ],
              ),
            ),
            if (disabled && cooldownSeconds != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: MyPulseColors.white, borderRadius: BorderRadius.circular(999)),
                  child: Text('${cooldownSeconds}s', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: MyPulseColors.inkFaint)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
