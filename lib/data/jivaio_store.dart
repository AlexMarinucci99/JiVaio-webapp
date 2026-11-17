import 'dart:convert';

import 'package:web/web.dart' as web;

import 'package:flutter/foundation.dart';

import '../models/transit_models.dart';
import 'gtfs_repository.dart';

class JivaioStore extends ChangeNotifier {
  JivaioStore({this._repository = const GtfsRepository()});

  static const _storageKey = 'jivaio-web-preview-v2';
  final GtfsRepository _repository;

  List<TransitLine> lines = [];
  List<ServiceAlert> alerts = [];
  final Set<String> favorites = {};
  bool isLoading = true;
  String? loadError;
  DateTime? lastSavedAt;

  List<ServiceAlert> get visibleAlerts => alerts
      .where((alert) => alert.isCurrentOrUpcoming)
      .toList()
    ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

  Future<void> load() async {
    try {
      lines = await _repository.loadLines();
      alerts = _seedAlerts();
      final saved = web.window.localStorage.getItem(_storageKey);
      if (saved != null && saved.isNotEmpty) {
        final decoded = jsonDecode(saved);
        if (decoded is Map<String, dynamic>) {
          final savedLines = decoded['lines'];
          if (savedLines is List && savedLines.isNotEmpty) {
            lines = savedLines
                .whereType<Map<String, dynamic>>()
                .map(TransitLine.fromJson)
                .toList();
          }
          final savedAlerts = decoded['alerts'];
          if (savedAlerts is List) {
            alerts = savedAlerts
                .whereType<Map<String, dynamic>>()
                .map(ServiceAlert.fromJson)
                .toList();
          }
          final savedFavorites = decoded['favorites'];
          if (savedFavorites is List) {
            favorites.addAll(savedFavorites.map((item) => item.toString()));
          }
          lastSavedAt = DateTime.tryParse(decoded['lastSavedAt'] as String? ?? '');
        }
      }
    } catch (error) {
      loadError = 'Non riesco a caricare i dati di anteprima: $error';
      if (lines.isEmpty) lines = [];
      if (alerts.isEmpty) alerts = _seedAlerts();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  TransitLine? lineById(String id) {
    for (final line in lines) {
      if (line.id == id) return line;
    }
    return null;
  }

  bool isFavorite(String lineId) => favorites.contains(lineId);

  void toggleFavorite(String lineId) {
    if (!favorites.add(lineId)) favorites.remove(lineId);
    _save();
  }

  void saveLine(TransitLine updated) {
    final index = lines.indexWhere((line) => line.id == updated.id);
    if (index < 0) {
      lines = [...lines, updated];
    } else {
      final changed = [...lines];
      changed[index] = updated;
      lines = changed;
    }
    lines.sort((a, b) => a.code.toLowerCase().compareTo(b.code.toLowerCase()));
    _save();
  }

  void removeLine(String lineId) {
    lines = lines.where((line) => line.id != lineId).toList();
    favorites.remove(lineId);
    _save();
  }

  void saveAlert(ServiceAlert alert) {
    final index = alerts.indexWhere((item) => item.id == alert.id);
    if (index < 0) {
      alerts = [...alerts, alert];
    } else {
      final changed = [...alerts];
      changed[index] = alert;
      alerts = changed;
    }
    _save();
  }

  void removeAlert(String alertId) {
    alerts = alerts.where((alert) => alert.id != alertId).toList();
    _save();
  }

  void resetPreview() {
    web.window.localStorage.removeItem(_storageKey);
    favorites.clear();
    alerts = _seedAlerts();
    loadError = null;
    unawaitedReloadLines();
  }

  Future<void> unawaitedReloadLines() async {
    lines = await _repository.loadLines();
    lastSavedAt = null;
    notifyListeners();
  }

  void _save() {
    lastSavedAt = DateTime.now();
    web.window.localStorage.setItem(_storageKey, jsonEncode({
      'lines': lines.map((line) => line.toJson()).toList(),
      'alerts': alerts.map((alert) => alert.toJson()).toList(),
      'favorites': favorites.toList(),
      'lastSavedAt': lastSavedAt!.toIso8601String(),
    }));
    notifyListeners();
  }

  List<ServiceAlert> _seedAlerts() => [
    ServiceAlert(
      id: 'ama-strike-2026-11-20',
      title: 'Sciopero generale del 20 novembre 2026',
      summary: 'Servizio non garantito per l’intera giornata, con fasce di garanzia 06:30–08:30 e 13:10–17:10.',
      details: 'AMA comunica l’adesione allo sciopero generale per venerdì 20 novembre 2026. Le fasce di garanzia sono 06:30–08:30 e 13:10–17:10. La ripresa del servizio potrebbe non essere immediata.',
      severity: 'critical',
      startsAt: DateTime(2026, 11, 20),
      endsAt: DateTime(2026, 11, 21),
      sourceName: 'AMA · 13 novembre 2026',
      sourceUrl: 'https://www.ama.laquila.it/trasporto-pubblico-locale-sciopero-generale-del-20-novembre-2026/',
      isPublished: true,
    ),
    ServiceAlert(
      id: 'ama-weekday-change-2026-11-16',
      title: 'Modifiche al servizio feriale dal 16 novembre 2026',
      summary: 'Linea 13Z: partenza dal Terminalbus anticipata dalle 13:55 alle 13:50. Linea 12A: la corsa delle 07:05 prosegue per le scuole di Colle Sapone.',
      details: 'La corsa della linea 13Z in partenza dal Terminalbus alle 13:55 è anticipata alle 13:50. La corsa della linea 12A in partenza dal Bivio di Foce di Sassa alle 07:05, da via De Gasperi prosegue per via Urbani, via Colle Sapone e le scuole di Colle Sapone.',
      severity: 'warning',
      startsAt: DateTime(2026, 11, 16),
      sourceName: 'AMA · 13 novembre 2026',
      sourceUrl: 'https://www.ama.laquila.it/modifiche-servizio-feriali-dal-16-11-2026/',
      affectedLines: const ['13Z', '12A'],
      isPublished: true,
    ),
  ];
}
