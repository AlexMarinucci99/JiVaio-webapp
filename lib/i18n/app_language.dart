import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const languageNames = <String, String>{
  'it': 'Italiano',
  'en': 'English',
  'ar': 'العربية',
  'uk': 'Українська',
  'ru': 'Русский',
};

class AppLanguage extends ChangeNotifier {
  AppLanguage._(this.code, this._translations);
  String code;
  final Map<String, Map<String, String>> _translations;
  static const _preferenceKey = 'jivaio_language';

  static Future<AppLanguage> load() async {
    final maps = <String, Map<String, String>>{};
    for (final code in languageNames.keys.where((code) => code != 'it')) {
      final raw = await rootBundle.loadString('assets/i18n/$code.json');
      maps[code] = Map<String, String>.from(jsonDecode(raw) as Map);
    }
    String code = 'it';
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_preferenceKey);
      if (saved != null && languageNames.containsKey(saved)) code = saved;
    } catch (_) {
      // The interface still works if browser storage is unavailable.
    }
    return AppLanguage._(code, maps);
  }

  // Compile dynamic label patterns once; route lists may contain many items.
  static final _patterns = <(String, String)>[
    (
      r'^Linea (.+?) · circolare · (\d+) fermate$',
      'Linea {value} · circolare · {n} fermate',
    ),
    (r'^Linea (.+?) · (\d+) fermate$', 'Linea {value} · {n} fermate'),
    (
      r'^Indica il nome della fermata alla riga (\d+)$',
      'Indica il nome della fermata alla riga {n}',
    ),
    (
      r'^Orario non valido alla riga (\d+): usa HH:MM$',
      'Orario non valido alla riga {n}: usa HH:MM',
    ),
    (r'^Eliminare la linea (.+)\?$', 'Eliminare la linea {value}?'),
    (r'^Modifica linea (.+)$', 'Modifica linea {value}'),
    (
      r'^Modifica percorso \((\d+) fermate\)$',
      'Modifica percorso ({n} fermate)',
    ),
    (r'^Parte da (.+?) · (\d+) fermate$', 'Parte da {value} · {n} fermate'),
    (r'^Parte da ([^·]+)$', 'Parte da {value}'),
    (r'^(\d+) gruppi circuito/orario$', '{n} gruppi circuito/orario'),
    (r'^(\d+) gruppi direzione/orario$', '{n} gruppi direzione/orario'),
    (
      r'^Non riesco a importare il backup: (.+)$',
      'Non riesco a importare il backup: {value}',
    ),
    (r'^(\d+) direzioni$', '{n} direzioni'),
    (r'^(\d+) fermate$', '{n} fermate'),
    (r'^(\d+) linee$', '{n} linee'),
    (r'^(\d+) avvisi$', '{n} avvisi'),
    (r'^Linea (.+)$', 'Linea {value}'),
    (r'^Orari di partenza · (.+)$', 'Orari di partenza · {value}'),
    (r'^Corsa delle (.+)$', 'Corsa delle {value}'),
    (r'^Dal (.+)$', 'Dal {value}'),
    (r'^Linee (.+)$', 'Linee {value}'),
    (r'^(.+) \(scolastica\)$', '{value} (scolastica)'),
    (r'^(.+) \(stimato\)$', '{value} (stimato)'),
    (r'^(.+)\norario previsto \(stima\)$', '{value}\norario previsto (stima)'),
    (r'^Calendario (.+)$', 'Calendario {value}'),
    (r'^Circuito ([^·]+)$', 'Circuito {value}'),
    (r'^Inizio: (.+)$', 'Inizio: {value}'),
    (r'^Fine: (.+)$', 'Fine: {value}'),
  ].map((entry) => (RegExp(entry.$1), entry.$2)).toList(growable: false);

  String translate(String value) {
    final dictionary = _translations[code];
    if (dictionary == null) return value;
    final exact = dictionary[value];
    if (exact != null) return exact;

    for (final (pattern, template) in _patterns) {
      final match = pattern.firstMatch(value);
      final translated = dictionary[template];
      if (match == null || translated == null) continue;
      if (template.contains('{value}') && template.contains('{n}')) {
        return translated
            .replaceAll('{value}', match[1]!)
            .replaceAll('{n}', match[2]!);
      }
      final content = match[1]!;
      return translated
          .replaceAll('{n}', content)
          .replaceAll('{value}', dictionary[content] ?? content);
    }
    // Combined labels can include a schedule name and place names. Translate
    // known fragments only, leaving names and user-authored content intact.
    for (final separator in [' · ', '\n']) {
      if (value.contains(separator)) {
        return value.split(separator).map(translate).join(separator);
      }
    }
    return value;
  }

  Future<void> select(String next) async {
    if (!languageNames.containsKey(next) || next == code) return;
    code = next;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_preferenceKey, next);
    } catch (_) {
      // Keep the selection for this session even if storage is unavailable.
    }
  }
}

class LanguageScope extends InheritedNotifier<AppLanguage> {
  const LanguageScope({
    required AppLanguage language,
    required super.child,
    super.key,
  }) : super(notifier: language);
  static AppLanguage of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()!.notifier!;
}

String tr(BuildContext context, String value) =>
    LanguageScope.of(context).translate(value);

String trFormat(
  BuildContext context,
  String template,
  Map<String, String> values,
) {
  var result = tr(context, template);
  for (final entry in values.entries) {
    result = result.replaceAll('{${entry.key}}', entry.value);
  }
  return result;
}

/// Localizes app-owned UI copy at the point it is presented.
class TText extends Text {
  const TText(
    super.data, {
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.semanticsIdentifier,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  });

  @override
  Widget build(BuildContext context) => Text(
    tr(context, data!),
    style: (style ?? const TextStyle()).copyWith(
      fontFamilyFallback: const ['NotoSansArabic'],
    ),
    strutStyle: strutStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    locale: locale,
    softWrap: softWrap,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel == null
        ? null
        : tr(context, semanticsLabel!),
    semanticsIdentifier: semanticsIdentifier,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    selectionColor: selectionColor,
  );
}

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});
  @override
  Widget build(BuildContext context) {
    final language = LanguageScope.of(context);
    return PopupMenuButton<String>(
      tooltip: tr(context, 'Lingua'),
      icon: const Icon(Icons.language),
      onSelected: language.select,
      itemBuilder: (context) => [
        for (final entry in languageNames.entries)
          PopupMenuItem(value: entry.key, child: Text(entry.value)),
      ],
    );
  }
}
