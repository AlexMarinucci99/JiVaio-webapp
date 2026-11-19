import 'package:flutter/material.dart';

abstract final class JivaioColors {
  static const page = Color(0xFFF4F7FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceBlue = Color(0xFFEAF2FF);
  static const navy = Color(0xFF191970);
  static const blue = Color(0xFF0754C5);
  static const blueLight = Color(0xFFE6F0FF);
  static const text = Color(0xFF111827);
  static const secondary = Color(0xFF5D6675);
  static const muted = Color(0xFF858FA0);
  static const border = Color(0xFFDCE5F2);
  static const warning = Color(0xFFE69A13);
  static const danger = Color(0xFFD94747);
  static const success = Color(0xFF208661);
}

ThemeData buildJivaioTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: JivaioColors.blue,
    primary: JivaioColors.blue,
    secondary: JivaioColors.navy,
    surface: JivaioColors.surface,
    error: JivaioColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: JivaioColors.page,
    fontFamily: 'Roboto',
    fontFamilyFallback: const ['NotoSansArabic'],
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 34,
        height: 1.12,
        fontWeight: FontWeight.w800,
        color: JivaioColors.navy,
      ),
      headlineSmall: TextStyle(
        fontSize: 27,
        height: 1.16,
        fontWeight: FontWeight.w800,
        color: JivaioColors.navy,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        height: 1.2,
        fontWeight: FontWeight.w800,
        color: JivaioColors.navy,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: JivaioColors.navy,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        color: JivaioColors.text,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: JivaioColors.secondary,
      ),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: JivaioColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: JivaioColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: JivaioColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: JivaioColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: JivaioColors.blue, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: JivaioColors.surface,
      elevation: 1,
      shadowColor: const Color(0x0C182B4D),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: JivaioColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: JivaioColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: JivaioColors.navy,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: JivaioColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: JivaioColors.border,
      thickness: 1,
      space: 1,
    ),
  );
}
