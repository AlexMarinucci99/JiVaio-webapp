import 'package:flutter/material.dart';

/// Valori locali del banner home e della sua illustrazione.
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
  static const wideArtworkSpacing = 30.0;

  static const artworkWidth = 270.0;
  static const artworkHeight = 180.0;
  static const artworkAssetPath = 'assets/images/home_hero.jpg';
  static const artworkFit = BoxFit.cover;
  static const artworkBorderRadius = BorderRadius.all(Radius.circular(22));
}
