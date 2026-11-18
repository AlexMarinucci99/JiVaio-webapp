import 'package:flutter/material.dart';

/// Valori locali del banner home.
abstract final class HomeHeroStyle {
  static const padding = EdgeInsets.all(30);
  static const borderRadius = BorderRadius.all(Radius.circular(26));
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEAF2FF), Color(0xFFDCEAFF)],
  );
  static const borderColor = Color(0xFFD5E4F9);

  static const breakpoint = 640.0;
  static const compactTitleFontSize = 34.0;
  static const wideTitleFontSize = 42.0;
  static const descriptionFontSize = 17.0;
  static const descriptionSpacing = 12.0;
  static const actionSpacing = 22.0;
  // Inserisci qui il percorso dell'immagine dopo averla dichiarata in pubspec.yaml.
  static const String? backgroundAssetPath = null;
  static const backgroundFit = BoxFit.cover;
  static const backgroundOverlayColor = Color(0xBFEAF2FF);
}
