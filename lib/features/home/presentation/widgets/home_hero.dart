import 'package:flutter/material.dart';

import '../../../../theme/jivaio_theme.dart';
import '../../../../i18n/app_language.dart';
import '../home_hero_content.dart';
import '../home_hero_style.dart';

/// Banner principale della homepage con un'azione fornita dalla pagina ospite.
class HomeHero extends StatelessWidget {
  const HomeHero({required this.onOpenLines, super.key});

  final VoidCallback onOpenLines;

  @override
  Widget build(BuildContext context) {
    final backgroundAssetPath = HomeHeroStyle.backgroundAssetPath;
    return Container(
      padding: HomeHeroStyle.padding,
      decoration: BoxDecoration(
        borderRadius: HomeHeroStyle.borderRadius,
        gradient: backgroundAssetPath == null ? HomeHeroStyle.gradient : null,
        image: backgroundAssetPath == null
            ? null
            : DecorationImage(
                image: AssetImage(backgroundAssetPath),
                fit: HomeHeroStyle.backgroundFit,
                colorFilter: const ColorFilter.mode(
                  HomeHeroStyle.backgroundOverlayColor,
                  BlendMode.srcOver,
                ),
              ),
        border: Border.all(color: HomeHeroStyle.borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < HomeHeroStyle.breakpoint;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TText(
                HomeHeroContent.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: compact
                      ? switch (LanguageScope.of(context).code) {
                          'uk' || 'ru' => 27,
                          'ar' => 29,
                          _ => HomeHeroStyle.compactTitleFontSize,
                        }
                      : HomeHeroStyle.wideTitleFontSize,
                ),
              ),
              const SizedBox(height: HomeHeroStyle.descriptionSpacing),
              TText(
                HomeHeroContent.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: HomeHeroStyle.descriptionFontSize,
                  color: JivaioColors.secondary,
                ),
              ),
              const SizedBox(height: HomeHeroStyle.actionSpacing),
              FilledButton(
                onPressed: onOpenLines,
                child: const TText(HomeHeroContent.buttonLabel),
              ),
            ],
          );

          return Flex(
            key: const Key('home-hero-layout'),
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [if (compact) content else Expanded(child: content)],
          );
        },
      ),
    );
  }
}
