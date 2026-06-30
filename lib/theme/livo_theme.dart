import 'package:flutter/material.dart';

/// LIVO design tokens — mirrors the `C` palette from the design system.
/// Original branding (violet accent, live red), dark surfaces.
class LivoColors {
  LivoColors._();

  static const bg = Color(0xFF0C0C0F);
  static const surface = Color(0xFF161619);
  static const surface2 = Color(0xFF1F1F24);
  static const line = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const text = Color(0xFFFFFFFF);
  static const sub = Color(0xFF9A9AA3);
  static const faint = Color(0xFF6A6A73);
  static const accent = Color(0xFF7C5CFF);
  static const accentSoft = Color(0x297C5CFF); // rgba(124,92,255,0.16)
  static const live = Color(0xFFFF3B5C);

  // Social brand colors
  static const kakao = Color(0xFFFEE500);
  static const naver = Color(0xFF03C75A);
  static const facebook = Color(0xFF1877F2);
}

/// The app theme: a dark Material 3 base re-skinned to the LIVO palette.
ThemeData buildLivoTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: LivoColors.bg,
    canvasColor: LivoColors.bg,
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: LivoColors.accent,
      onPrimary: Colors.white,
      secondary: LivoColors.live,
      surface: LivoColors.surface,
      onSurface: LivoColors.text,
      surfaceContainerHighest: LivoColors.surface2,
    ),
    splashColor: LivoColors.accentSoft,
    highlightColor: LivoColors.accentSoft,
    textTheme: base.textTheme.apply(
      bodyColor: LivoColors.text,
      displayColor: LivoColors.text,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xF21E1E24),
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
