import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transit_models.dart';

class CloudSnapshot {
  const CloudSnapshot({
    required this.lines,
    required this.alerts,
    required this.lineRevisions,
    required this.alertRevisions,
  });

  final List<TransitLine> lines;
  final List<ServiceAlert> alerts;
  final Map<String, int> lineRevisions;
  final Map<String, int> alertRevisions;
}

class CloudConflict implements Exception {
  const CloudConflict();
  @override
  String toString() =>
      'I dati sono cambiati in un altro browser. Ricarica e confronta le modifiche prima di salvare.';
}

class CloudTransitRepository {
  CloudTransitRepository(this.client);
  final SupabaseClient client;

  Future<CloudSnapshot> load() async {
    final rows = await Future.wait([
      client.from('app_lines').select('id,payload,revision'),
      client.from('app_alerts').select('id,payload,revision'),
    ]);
    final lines = <TransitLine>[];
    final alerts = <ServiceAlert>[];
    final lineRevisions = <String, int>{};
    final alertRevisions = <String, int>{};
    for (final row in rows[0]) {
      final line = TransitLine.fromJson(
        Map<String, dynamic>.from(row['payload'] as Map),
      );
      lines.add(line);
      lineRevisions[line.id] = (row['revision'] as num).toInt();
    }
    for (final row in rows[1]) {
      final alert = ServiceAlert.fromJson(
        Map<String, dynamic>.from(row['payload'] as Map),
      );
      alerts.add(alert);
      alertRevisions[alert.id] = (row['revision'] as num).toInt();
    }
    lines.sort((a, b) => a.code.toLowerCase().compareTo(b.code.toLowerCase()));
    return CloudSnapshot(
      lines: lines,
      alerts: alerts,
      lineRevisions: lineRevisions,
      alertRevisions: alertRevisions,
    );
  }

  Future<bool> hasChanges(
    Map<String, int> lines,
    Map<String, int> alerts,
  ) async {
    final rows = await Future.wait([
      client.from('app_lines').select('id,revision'),
      client.from('app_alerts').select('id,revision'),
    ]);
    bool differs(
      List<Map<String, dynamic>> records,
      Map<String, int> revisions,
    ) =>
        records.length != revisions.length ||
        records.any(
          (row) => revisions[row['id']] != (row['revision'] as num).toInt(),
        );
    return differs(rows[0], lines) || differs(rows[1], alerts);
  }

  Future<int> saveLine(TransitLine line, {required int? expectedRevision}) =>
      _save('app_lines', {
        'id': line.id,
        'payload': line.toJson(),
        'is_visible': line.isVisible,
      }, expectedRevision);

  Future<int> saveAlert(ServiceAlert alert, {required int? expectedRevision}) =>
      _save('app_alerts', {
        'id': alert.id,
        'payload': alert.toJson(),
        'is_published': alert.isPublished,
        'ends_at': alert.endsAt?.toUtc().toIso8601String(),
      }, expectedRevision);

  Future<int> _save(
    String table,
    Map<String, Object?> values,
    int? revision,
  ) async {
    if (revision == null) {
      try {
        final row = await client
            .from(table)
            .insert(values)
            .select('revision')
            .single();
        return (row['revision'] as num).toInt();
      } on PostgrestException catch (error) {
        if (error.code == '23505') throw const CloudConflict();
        rethrow;
      }
    }
    final rows = await client
        .from(table)
        .update(values)
        .eq('id', values['id'] as String)
        .eq('revision', revision)
        .select('revision');
    if (rows.length != 1) throw const CloudConflict();
    return (rows.single['revision'] as num).toInt();
  }

  Future<void> remove(String table, String id, int? revision) async {
    if (revision == null) throw const CloudConflict();
    final rows = await client
        .from(table)
        .delete()
        .eq('id', id)
        .eq('revision', revision)
        .select('id');
    if (rows.length != 1) throw const CloudConflict();
  }

  Future<void> importBackup({
    required List<TransitLine> lines,
    required List<ServiceAlert> alerts,
    required Map<String, int> lineRevisions,
    required Map<String, int> alertRevisions,
  }) async {
    try {
      await client.rpc(
        'jivaio_import_backup',
        params: {
          'p_lines': [
            for (final line in lines)
              {
                'payload': line.toJson(),
                'expectedRevision': lineRevisions[line.id],
              },
          ],
          'p_alerts': [
            for (final alert in alerts)
              {
                'payload': {
                  ...alert.toJson(),
                  'endsAt': alert.endsAt?.toUtc().toIso8601String(),
                },
                'expectedRevision': alertRevisions[alert.id],
              },
          ],
        },
      );
    } on PostgrestException catch (error) {
      if (error.code == '40001' || error.code == '23505') {
        throw const CloudConflict();
      }
      rethrow;
    }
  }
}
