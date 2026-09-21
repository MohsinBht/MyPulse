import 'package:flutter/material.dart';

/// The "itération 2" theme validated in the mockups: soft blush background,
/// deep clay-red accent, enough contrast to read at a glance.
class MyPulseColors {
  static const background = Color(0xFFFBF1EE);
  static const card = Color(0xFFFCE3E7);
  static const cardMuted = Color(0xFFF6E4E2);
  static const ink = Color(0xFF241B1D);
  static const inkSoft = Color(0xFF6B5D5A);
  static const inkFaint = Color(0xFF8A7873);
  static const accent = Color(0xFFE24560);
  static const border = Color(0xFFE9D6D3);
  static const white = Color(0xFFFFFFFF);
}

ThemeData buildMyPulseTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: MyPulseColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MyPulseColors.accent,
      background: MyPulseColors.background,
      primary: MyPulseColors.accent,
    ),
    fontFamily: 'Georgia',
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: MyPulseColors.ink, fontFamily: 'Roboto'),
    ),
  );
}
