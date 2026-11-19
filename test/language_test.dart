import 'package:flutter_test/flutter_test.dart';
import 'package:master_lines/i18n/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('language choice persists and translates dynamic labels', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final language = await AppLanguage.load();
    for (final code in ['en', 'ar', 'uk', 'ru']) {
      await language.select(code);
      expect(language.translate('Esplora le linee'), isNot('Esplora le linee'));
      expect(language.translate('JiVaio'), 'JiVaio');
      expect(language.translate('3 fermate'), isNot('3 fermate'));
    }
    await language.select('uk');
    expect(language.translate('3 fermate'), 'Зупинок: 3');
    final restored = await AppLanguage.load();
    expect(restored.code, 'uk');
  });
}
