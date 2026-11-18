import 'package:flutter/material.dart';

import '../../../../theme/jivaio_theme.dart';
import '../home_hero_style.dart';

/// Illustrazione decorativa del banner home, composta da forme e icone.
class HeroArtwork extends StatelessWidget {
  const HeroArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HomeHeroStyle.artworkWidth,
      height: HomeHeroStyle.artworkHeight,
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: HomeHeroStyle.artworkBackgroundOpacity,
        ),
        borderRadius: HomeHeroStyle.artworkBorderRadius,
        border: Border.all(color: HomeHeroStyle.artworkBorderColor),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: HomeHeroStyle.routeIconTop,
            left: HomeHeroStyle.routeIconLeft,
            child: Icon(
              Icons.route_outlined,
              color: HomeHeroStyle.routeAccentColor,
              size: HomeHeroStyle.routeIconSize,
            ),
          ),
          Positioned(
            bottom: HomeHeroStyle.busCardBottom,
            right: HomeHeroStyle.busCardRight,
            child: Container(
              width: HomeHeroStyle.busCardWidth,
              height: HomeHeroStyle.busCardHeight,
              decoration: BoxDecoration(
                color: JivaioColors.blue,
                borderRadius: HomeHeroStyle.busCardBorderRadius,
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: HomeHeroStyle.busIconSize,
              ),
            ),
          ),
          const Positioned(
            left: HomeHeroStyle.startMarkerLeft,
            bottom: HomeHeroStyle.startMarkerBottom,
            child: Icon(
              Icons.location_on,
              color: JivaioColors.navy,
              size: HomeHeroStyle.markerIconSize,
            ),
          ),
          const Positioned(
            right: HomeHeroStyle.endMarkerRight,
            top: HomeHeroStyle.endMarkerTop,
            child: Icon(
              Icons.location_on,
              color: JivaioColors.blue,
              size: HomeHeroStyle.markerIconSize,
            ),
          ),
          Positioned(
            left: HomeHeroStyle.routeLineLeft,
            top: HomeHeroStyle.routeLineTop,
            child: Container(
              width: HomeHeroStyle.routeLineWidth,
              height: HomeHeroStyle.routeLineHeight,
              color: HomeHeroStyle.routeAccentColor,
            ),
          ),
        ],
      ),
    );
  }
}
