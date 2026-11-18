import 'package:flutter/material.dart';

import '../../../../theme/jivaio_theme.dart';
import '../home_hero_content.dart';
import '../home_hero_style.dart';

/// Banner principale della homepage con un'azione fornita dalla pagina ospite.
class HomeHero extends StatelessWidget {
  const HomeHero({required this.onOpenLines, super.key});

  final VoidCallback onOpenLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: HomeHeroStyle.padding,
      decoration: BoxDecoration(
        borderRadius: HomeHeroStyle.borderRadius,
        gradient: HomeHeroStyle.gradient,
        border: Border.all(color: HomeHeroStyle.borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < HomeHeroStyle.breakpoint;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                HomeHeroContent.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: compact
                      ? HomeHeroStyle.compactTitleFontSize
                      : HomeHeroStyle.wideTitleFontSize,
                ),
              ),
              const SizedBox(height: HomeHeroStyle.descriptionSpacing),
              Text(
                HomeHeroContent.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: HomeHeroStyle.descriptionFontSize,
                  color: JivaioColors.secondary,
                ),
              ),
              const SizedBox(height: HomeHeroStyle.actionSpacing),
              FilledButton.icon(
                onPressed: onOpenLines,
                icon: const Icon(Icons.directions_bus_outlined),
                label: const Text(HomeHeroContent.buttonLabel),
              ),
            ],
          );

          return Flex(
            key: const Key('home-hero-layout'),
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (compact) content else Expanded(child: content),
              if (!compact) ...[
                const SizedBox(width: HomeHeroStyle.wideArtworkSpacing),
                Semantics(
                  image: true,
                  label: 'JiVaio sopra L’Aquila',
                  child: ClipRRect(
                    borderRadius: HomeHeroStyle.artworkBorderRadius,
                    child: Image.asset(
                      HomeHeroStyle.artworkAssetPath,
                      key: const Key('home-hero-artwork'),
                      width: HomeHeroStyle.artworkWidth,
                      height: HomeHeroStyle.artworkHeight,
                      fit: HomeHeroStyle.artworkFit,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
