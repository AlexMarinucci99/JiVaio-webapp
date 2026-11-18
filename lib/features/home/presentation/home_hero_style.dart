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
  static const artworkBackgroundOpacity = .72;
  static const artworkBorderRadius = BorderRadius.all(Radius.circular(22));
  static const artworkBorderColor = Colors.white;

  static const routeAccentColor = Color(0xFF8BB5F3);
  static const routeIconSize = 48.0;
  static const routeIconTop = 28.0;
  static const routeIconLeft = 28.0;

  static const busCardWidth = 138.0;
  static const busCardHeight = 72.0;
  static const busCardBorderRadius = BorderRadius.all(Radius.circular(18));
  static const busCardBottom = 30.0;
  static const busCardRight = 30.0;
  static const busIconSize = 50.0;

  static const markerIconSize = 24.0;
  static const startMarkerLeft = 60.0;
  static const startMarkerBottom = 60.0;
  static const endMarkerRight = 52.0;
  static const endMarkerTop = 43.0;

  static const routeLineLeft = 91.0;
  static const routeLineTop = 64.0;
  static const routeLineWidth = 100.0;
  static const routeLineHeight = 2.0;
}
