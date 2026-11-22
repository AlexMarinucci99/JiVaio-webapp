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

  testWidgets('la ricerca vuota apre le linee', (tester) async {
    var opened = false;
    await pumpHomeHero(tester, width: 375, onOpenLines: () => opened = true);
    expect(
      find.text(HomeHeroContent.title.replaceAll('\n', ' ')),
      findsWidgets,
    );
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la ricerca rimane visibile su desktop', (tester) async {
    await pumpHomeHero(tester, width: 900, onOpenLines: () {});
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
