import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

import '../models/transit_models.dart';
import 'cloud_transit_repository.dart';
import 'gtfs_repository.dart';
import 'supabase_config.dart';

class JivaioStore extends ChangeNotifier {
  JivaioStore({GtfsRepository? repository})
    : _repository = repository ?? const GtfsRepository();

  static const _storageKey = 'jivaio-web-preview-v2';
  static const _favoritesKey = 'jivaio-web-favorites-v1';
  final GtfsRepository _repository;
  CloudTransitRepository? _cloud;
  Timer? _refreshTimer;
  int _generation = 0;
  bool _disposed = false;
  bool _writing = false;
  Map<String, int> _lineRevisions = {};
  Map<String, int> _alertRevisions = {};

  List<TransitLine> lines = [];
  List<ServiceAlert> alerts = [];
  final Set<String> favorites = {};
  bool isLoading = true;
  String? loadError;
  DateTime? lastSavedAt;
  bool get usesCloud => SupabaseConfig.isConfigured;
  int? lineRevision(String id) => _lineRevisions[id];
  int? alertRevision(String id) => _alertRevisions[id];

  List<TransitLine> get visibleLines =>
      lines.where((line) => line.isVisible).toList();

  List<ServiceAlert> get visibleAlerts =>
      alerts.where((alert) => alert.isCurrentOrUpcoming).toList()
        ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

  Future<void> load() async {
    try {
      final saved = web.window.localStorage.getItem(_storageKey);
      dynamic decoded;
      try {
        decoded = saved == null || saved.isEmpty ? null : jsonDecode(saved);
      } catch (_) {
        decoded = null;
      }
      final savedFavorites = web.window.localStorage.getItem(_favoritesKey);
      final favoriteData = savedFavorites == null
          ? (decoded is Map<String, dynamic> ? decoded['favorites'] : null)
          : _decodeFavorites(savedFavorites);
      if (favoriteData is List) {
        favorites.addAll(favoriteData.map((item) => item.toString()));
      }
      if (usesCloud) {
        if (!SupabaseConfig.isInitialized) {
          throw StateError(
            SupabaseConfig.initializationError ??
                'Connessione al database non configurata.',
          );
        }
        _cloud = CloudTransitRepository(Supabase.instance.client);
        _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
          if (!_writing) unawaited(_checkForChanges());
        });
        await refreshCloud(throwOnError: true);
      } else {
        lines = await _repository.loadLines();
        alerts = _seedAlerts();
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
          lastSavedAt = DateTime.tryParse(
            decoded['lastSavedAt'] as String? ?? '',
          );
        }
      }
    } catch (error) {
      loadError = usesCloud
          ? 'Connessione ai dati condivisi non riuscita. Riprova.'
          : 'Non riesco a caricare i dati di anteprima: $error';
      if (!usesCloud && alerts.isEmpty) alerts = _seedAlerts();
    } finally {
      isLoading = false;
      _notify();
    }
  }

  dynamic _decodeFavorites(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkForChanges() async {
    final cloud = _cloud;
    if (cloud == null) return;
    try {
      if (loadError != null ||
          await cloud.hasChanges(_lineRevisions, _alertRevisions)) {
        if (!_writing) await refreshCloud();
      }
    } catch (_) {
      loadError = 'Connessione ai dati condivisi non riuscita. Riprova.';
      _notify();
    }
  }

  Future<void> refreshCloud({bool throwOnError = false}) async {
    final cloud = _cloud;
    if (cloud == null) {
      if (throwOnError) throw StateError('Database condiviso non disponibile.');
      return;
    }
    final generation = ++_generation;
    try {
      final snapshot = await cloud.load();
      if (_disposed || generation != _generation) return;
      lines = snapshot.lines;
      alerts = snapshot.alerts;
      _lineRevisions = snapshot.lineRevisions;
      _alertRevisions = snapshot.alertRevisions;
      loadError = null;
      _notify();
    } catch (_) {
      if (!_disposed && generation == _generation) {
        loadError = 'Connessione ai dati condivisi non riuscita. Riprova.';
        _notify();
      }
      if (throwOnError) rethrow;
    }
  }

  void clearCloudSession() {
    if (!usesCloud) return;
    ++_generation;
    lines = lines.where((line) => line.isVisible).toList();
    alerts = alerts.where((alert) => alert.isCurrentOrUpcoming).toList();
    _lineRevisions.removeWhere((id, _) => !lines.any((line) => line.id == id));
    _alertRevisions.removeWhere(
      (id, _) => !alerts.any((alert) => alert.id == id),
    );
    _notify();
  }

  TransitLine? lineById(String id) {
    for (final line in lines) {
      if (line.id == id) return line;
    }
    return null;
  }

  TransitLine? visibleLineById(String id) {
    final line = lineById(id);
    return line != null && line.isVisible ? line : null;
  }

  bool isFavorite(String lineId) => favorites.contains(lineId);

  void toggleFavorite(String lineId) {
    if (!favorites.add(lineId)) favorites.remove(lineId);
    if (usesCloud) {
      web.window.localStorage.setItem(
        _favoritesKey,
        jsonEncode(favorites.toList()),
      );
      _notify();
    } else {
      _saveLocal();
    }
  }

  Future<T> _write<T>(
    Future<T> Function(CloudTransitRepository cloud) action,
  ) async {
    final cloud = _cloud;
    if (cloud == null) throw StateError('Database condiviso non disponibile.');
    if (_writing) throw StateError('Attendi il salvataggio in corso.');
    _writing = true;
    ++_generation;
    try {
      return await action(cloud);
    } finally {
      _writing = false;
    }
  }

  Future<void> saveLine(
    TransitLine updated, {
    int? expectedRevision,
    bool useSnapshot = false,
  }) async {
    if (usesCloud) {
      final revision = useSnapshot
          ? expectedRevision
          : _lineRevisions[updated.id];
      final newRevision = await _write(
        (cloud) => cloud.saveLine(updated, expectedRevision: revision),
      );
      _lineRevisions[updated.id] = newRevision;
    }
    final index = lines.indexWhere((line) => line.id == updated.id);
    if (index < 0) {
      lines = [...lines, updated];
    } else {
      final changed = [...lines];
      changed[index] = updated;
      lines = changed;
    }
    lines.sort((a, b) => a.code.toLowerCase().compareTo(b.code.toLowerCase()));
    if (usesCloud) {
      lastSavedAt = DateTime.now();
      _notify();
    } else {
      _saveLocal();
    }
  }

  Future<void> importBackup({
    required List<TransitLine> importedLines,
    required List<ServiceAlert> importedAlerts,
    Map<String, int>? expectedLineRevisions,
    Map<String, int>? expectedAlertRevisions,
  }) async {
    if (usesCloud) {
      final lineRevisions = Map<String, int>.from(
        expectedLineRevisions ?? _lineRevisions,
      );
      final alertRevisions = Map<String, int>.from(
        expectedAlertRevisions ?? _alertRevisions,
      );
      await _write(
        (cloud) => cloud.importBackup(
          lines: importedLines,
          alerts: importedAlerts,
          lineRevisions: lineRevisions,
          alertRevisions: alertRevisions,
        ),
      );
      await refreshCloud();
      lastSavedAt = DateTime.now();
      _notify();
      return;
    }
    final mergedLines = <String, TransitLine>{
      for (final line in lines) line.id: line,
    };
    for (final line in importedLines) {
      mergedLines[line.id] = line;
    }
    lines = mergedLines.values.toList()
      ..sort((a, b) => a.code.toLowerCase().compareTo(b.code.toLowerCase()));
    final mergedAlerts = <String, ServiceAlert>{
      for (final alert in alerts) alert.id: alert,
    };
    for (final alert in importedAlerts) {
      mergedAlerts[alert.id] = alert;
    }
    alerts = mergedAlerts.values.toList();
    _saveLocal();
  }

  Future<void> removeLine(
    String lineId, {
    int? expectedRevision,
    bool useSnapshot = false,
  }) async {
    if (usesCloud) {
      await _write(
        (cloud) => cloud.remove(
          'app_lines',
          lineId,
          useSnapshot ? expectedRevision : _lineRevisions[lineId],
        ),
      );
      _lineRevisions.remove(lineId);
    }
    lines = lines.where((line) => line.id != lineId).toList();
    favorites.remove(lineId);
    if (usesCloud) {
      web.window.localStorage.setItem(
        _favoritesKey,
        jsonEncode(favorites.toList()),
      );
      _notify();
    } else {
      _saveLocal();
    }
  }

  Future<void> saveAlert(
    ServiceAlert alert, {
    int? expectedRevision,
    bool useSnapshot = false,
  }) async {
    if (usesCloud) {
      final revision = useSnapshot
          ? expectedRevision
          : _alertRevisions[alert.id];
      final newRevision = await _write(
        (cloud) => cloud.saveAlert(alert, expectedRevision: revision),
      );
      _alertRevisions[alert.id] = newRevision;
    }
    final index = alerts.indexWhere((item) => item.id == alert.id);
    if (index < 0) {
      alerts = [...alerts, alert];
    } else {
      final changed = [...alerts];
      changed[index] = alert;
      alerts = changed;
    }
    if (usesCloud) {
      lastSavedAt = DateTime.now();
      _notify();
    } else {
      _saveLocal();
    }
  }

  Future<void> removeAlert(
    String alertId, {
    int? expectedRevision,
    bool useSnapshot = false,
  }) async {
    if (usesCloud) {
      await _write(
        (cloud) => cloud.remove(
          'app_alerts',
          alertId,
          useSnapshot ? expectedRevision : _alertRevisions[alertId],
        ),
      );
      _alertRevisions.remove(alertId);
    }
    alerts = alerts.where((alert) => alert.id != alertId).toList();
    if (usesCloud) {
      _notify();
    } else {
      _saveLocal();
    }
  }

  void _saveLocal() {
    lastSavedAt = DateTime.now();
    web.window.localStorage.setItem(
      _storageKey,
      jsonEncode({
        'lines': lines.map((line) => line.toJson()).toList(),
        'alerts': alerts.map((alert) => alert.toJson()).toList(),
        'favorites': favorites.toList(),
        'lastSavedAt': lastSavedAt!.toIso8601String(),
      }),
    );
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _refreshTimer?.cancel();
    super.dispose();
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
