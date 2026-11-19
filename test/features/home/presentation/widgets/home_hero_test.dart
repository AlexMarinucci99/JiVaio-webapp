import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_lines/features/home/presentation/home_hero_content.dart';
import 'package:master_lines/features/home/presentation/widgets/home_hero.dart';
import 'package:master_lines/theme/jivaio_theme.dart';
import 'package:master_lines/i18n/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppLanguage language;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    language = await AppLanguage.load();
  });
  Future<void> pumpHomeHero(
    WidgetTester tester, {
    required double width,
    required VoidCallback onOpenLines,
  }) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      LanguageScope(
        language: language,
        child: MaterialApp(
          theme: buildJivaioTheme(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: HomeHero(onOpenLines: onOpenLines),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('mostra i testi configurati e invoca l’azione del pulsante', (
    tester,
  ) async {
    var openedLines = false;
    await pumpHomeHero(
      tester,
      width: 375,
      onOpenLines: () => openedLines = true,
    );

    expect(find.text(HomeHeroContent.title), findsWidgets);
    expect(find.text(HomeHeroContent.description), findsWidgets);
    expect(find.text(HomeHeroContent.buttonLabel), findsWidgets);
    expect(find.byType(Icon), findsNothing);

    await tester.tap(find.byType(FilledButton));
    expect(openedLines, isTrue);
  });

  testWidgets('usa il layout verticale compatto su larghezza mobile', (
    tester,
  ) async {
    await pumpHomeHero(tester, width: 375, onOpenLines: () {});

    final layout = tester.widget<Flex>(
      find.byKey(const Key('home-hero-layout')),
    );

    expect(layout.direction, Axis.vertical);
  });

  testWidgets('mantiene il layout orizzontale su desktop', (tester) async {
    await pumpHomeHero(tester, width: 900, onOpenLines: () {});

    final layout = tester.widget<Flex>(
      find.byKey(const Key('home-hero-layout')),
    );

    expect(layout.direction, Axis.horizontal);
    expect(find.byKey(const Key('home-hero-artwork')), findsNothing);
  });
}
