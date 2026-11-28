import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_lines/i18n/app_language.dart';
import 'package:master_lines/models/transit_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(rootBundle.clear);
  testWidgets('language choice persists and translates dynamic labels', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final language = await AppLanguage.load();
    for (final code in languageNames.keys.where((code) => code != 'it')) {
      await language.select(code);
      expect(language.translate('Esplora le linee'), isNot('Esplora le linee'));
      expect(language.translate('JiVaio'), 'JiVaio');
      expect(language.translate('3 fermate'), isNot('3 fermate'));
    }
    await language.select('uk');
    expect(language.translate('3 fermate'), 'Зупинок: 3');
    await language.select('de');
    final restored = await AppLanguage.load();
    expect(restored.code, 'de');
  });

  testWidgets(
    'language menu switches complete notices without translating unknown fragments',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final language = await AppLanguage.load();
      final catalog = jsonDecode(
        await rootBundle.loadString('assets/i18n/notices.json'),
      ) as Map;
      final italian = (catalog['en'] as Map).keys.cast<String>().toList();
      final alert = ServiceAlert.fromJson({
        'title': 'Linea 3 · Terminalbus',
        'translations': {
          'de': {'Linea 3 · Terminalbus': 'Linie 3 · Terminalbus'},
          'ru': 7,
        },
      });
      final restored = ServiceAlert.fromJson(alert.toJson());
      await tester.pumpWidget(
        LanguageScope(
          language: language,
          child: const MaterialApp(home: Scaffold(body: LanguageButton())),
        ),
      );
      for (final locale in [
        ...languageNames.keys.where((c) => c != 'it'),
        'it',
      ]) {
        await tester.tap(find.byIcon(Icons.language));
        await tester.pumpAndSettle();
        await tester.tap(find.text(languageNames[locale]!));
        await tester.pumpAndSettle();
        expect(language.code, locale);
        for (final source in italian) {
          expect(
            language.notice(source, const {}),
            locale == 'it' ? source : catalog[locale][source],
          );
        }
        expect(
          language.notice(restored.title, restored.translations),
          locale == 'de' ? 'Linie 3 · Terminalbus' : restored.title,
        );
        expect(
          language.notice('Linea 3 · Terminalbus 17:10', restored.translations),
          'Linea 3 · Terminalbus 17:10',
        );
      }
    },
  );
}
