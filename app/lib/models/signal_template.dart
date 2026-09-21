import 'package:flutter/material.dart';

/// The 6 predefined V1 signals. No free text — this is the whole catalog,
/// mirrored server-side in functions/src/templates.ts so a client can never
/// send anything outside this list.
class SignalTemplate {
  final String id;
  final String label;
  final IconData icon;
  final bool filledIcon;

  const SignalTemplate({
    required this.id,
    required this.label,
    required this.icon,
    this.filledIcon = false,
  });
}

const List<SignalTemplate> kSignalTemplates = [
  SignalTemplate(id: 'coeur', label: 'Cœur', icon: Icons.favorite, filledIcon: true),
  SignalTemplate(id: 'je_taime', label: "Je t'aime", icon: Icons.favorite_border),
  SignalTemplate(id: 'tu_me_manques', label: 'Tu me manques', icon: Icons.nightlight_round),
  SignalTemplate(id: 'pensee_pour_toi', label: 'Pensée pour toi', icon: Icons.star_border),
  SignalTemplate(id: 'calin', label: 'Câlin', icon: Icons.emoji_people),
  SignalTemplate(id: 'bisou', label: 'Bisou', icon: Icons.sentiment_satisfied_alt),
];
