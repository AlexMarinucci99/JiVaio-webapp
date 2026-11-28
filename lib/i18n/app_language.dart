import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const languageNames = <String, String>{
  'it': 'Italiano',
  'en': 'English',
  'de': 'Deutsch',
  'ar': 'العربية',
  'uk': 'Українська',
  'ru': 'Русский',
};

class AppLanguage extends ChangeNotifier {
  AppLanguage._(this.code, this._translations, this._notices);
  final Map<String, Map<String, String>> _notices;
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
    final rawNotices = await rootBundle.loadString('assets/i18n/notices.json');
    final notices = (jsonDecode(rawNotices) as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, Map<String, String>.from(value as Map)),
    );
    return AppLanguage._(code, maps, notices);
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
    (
      r'^Linea da verificare \(GTFS route_id (.+)\)$',
      'Linea da verificare (GTFS route_id {value})',
    ),
    (
      r'^Questo calendario include (\d+) varianti di percorso; ogni corsa conserva il proprio elenco di fermate\.$',
      'Questo calendario include {n} varianti di percorso; ogni corsa conserva il proprio elenco di fermate.',
    ),
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
    (r'^Ultima sincronizzazione: (.+)$', 'Ultima sincronizzazione: {value}'),
    (r'^Fine: (.+)$', 'Fine: {value}'),
  ].map((entry) => (RegExp(entry.$1), entry.$2)).toList(growable: false);

  // Never apply UI patterns or translate fragments of an operator's notice.
  String notice(String source, Map<String, Map<String, String>> translations) =>
      code == 'it'
      ? source
      : translations[code]?[source] ?? _notices[code]?[source] ?? source;

  static final _missingMetadata = RegExp(
    r'^Nel GTFS mancano i metadati di route_id (.+?)\. (\d+) corse lo usano(?:; i trip_headsign suggeriscono la linea (.+?), da confermare)?\.$',
  );

  String routeName(String name, String id) =>
      name == 'Linea $id' || name == 'Linea da verificare (GTFS route_id $id)'
      ? translate(name)
      : name;

  String translate(String value) {
    final dictionary = _translations[code];
    if (dictionary == null) return value;
    final exact = dictionary[value];
    if (exact != null) return exact;

    final metadata = _missingMetadata.firstMatch(value);
    if (metadata != null) {
      final warning =
          dictionary['Nel GTFS mancano i metadati di route_id {id}. {n} corse lo usano.']!
              .replaceAll('{id}', metadata[1]!)
              .replaceAll('{n}', metadata[2]!);
      final line = metadata[3];
      if (line == null) return warning;
      final hint =
          dictionary['I trip_headsign suggeriscono la linea {value}, da confermare.']!;
      return '$warning ${hint.replaceAll('{value}', line)}';
    }
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
      final localizeContent =
          template == 'Calendario {value}' ||
          template == 'Orari di partenza · {value}' ||
          template == 'Corsa delle {value}';
      final label = localizeContent ? translate(content) : content;
      return translated.replaceAll('{n}', content).replaceAll('{value}', label);
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
