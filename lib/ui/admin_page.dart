import 'dart:convert';
import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/app_language.dart';

import 'package:web/web.dart' as web;

import '../data/jivaio_store.dart';
import '../data/cloud_transit_repository.dart';
import '../models/transit_models.dart';
import '../theme/jivaio_theme.dart';
import 'jivaio_app.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({required this.store, required this.onSignOut, super.key});
  final JivaioStore store;
  final VoidCallback onSignOut;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _tab = 0;
  bool _syncingAma = false;
  int _amaStatusVersion = 0;

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      store: widget.store,
      showBrandMark: false,
      flatNavigation: true,
      child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1228),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TText(
                                  'Gestione JiVaio',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                const SizedBox(height: 5),
                                TText(
                                  widget.store.usesCloud
                                      ? 'Modifica i dati condivisi tra i dispositivi.'
                                      : 'Modifica i dati di anteprima dal browser.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _chooseBackupFile,
                                  icon: const Icon(Icons.upload_file_outlined),
                                  label: const TText('Importa backup'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _exportSnapshot,
                                  icon: const Icon(Icons.download_outlined),
                                  label: const TText('Esporta backup'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: widget.onSignOut,
                                  icon: const Icon(Icons.logout),
                                  label: const TText('Esci'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _AdminNotice(usesCloud: widget.store.usesCloud),
                        const SizedBox(height: 20),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(
                              value: 0,
                              label: TText('Linee'),
                              icon: Icon(Icons.directions_bus_outlined),
                            ),
                            ButtonSegment(
                              value: 1,
                              label: TText('Avvisi'),
                              icon: Icon(Icons.campaign_outlined),
                            ),
                          ],
                          selected: {_tab},
                          onSelectionChanged: (value) =>
                              setState(() => _tab = value.first),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                if (_tab == 0)
                  ..._linesPanel(context)
                else
                  ..._alertsPanel(context),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    26,
                    24,
                    52 + MediaQuery.paddingOf(context).bottom,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            Navigator.of(context)
                                .pushReplacementNamed('/lines'),
                        icon: const Icon(Icons.open_in_new),
                        label: const TText('Apri anteprima pubblica'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _linesPanel(BuildContext context) {
    final lines = [...widget.store.lines]
      ..sort((a, b) => a.code.toLowerCase().compareTo(b.code.toLowerCase()));
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Expanded(
                child: TText(
                  '${lines.length} linee',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _editLine(),
                icon: const Icon(Icons.add),
                label: const TText('Nuova linea'),
              ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      if (lines.isEmpty)
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: _AdminEmpty(
              title: 'Non ci sono linee',
              text: 'Aggiungi la prima linea o importa il GTFS aggiornato.',
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: lines.length,
            itemBuilder: (context, i) => _AdminListItem(
              child: _LineAdminRow(
                line: lines[i],
                onEdit: () => _editLine(lines[i]),
                onDelete: () => _deleteLine(lines[i]),
                onToggleVisibility: () => _toggleVisibility(lines[i]),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _alertsPanel(BuildContext context) {
    final alerts = [...widget.store.alerts]
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Expanded(
                child: TText(
                  '${alerts.length} avvisi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _editAlert(),
                icon: const Icon(Icons.add),
                label: const TText('Nuovo avviso'),
              ),
            ],
          ),
        ),
      ),
      if (widget.store.usesCloud)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _syncingAma ? null : _syncAma,
                  icon: const Icon(Icons.sync),
                  label: TText(
                    _syncingAma
                        ? 'Sincronizzazione in corso'
                        : 'Sincronizza avvisi AMA',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showAmaUpdates,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const TText('Aggiornamenti AMA da verificare'),
                ),
              ],
            ),
          ),
        ),
      if (widget.store.usesCloud)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _AmaSyncStatus(key: ValueKey(_amaStatusVersion)),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      if (alerts.isEmpty)
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: _AdminEmpty(
              title: 'Nessun avviso',
              text: 'Crea un avviso quando il servizio subisce modifiche.',
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: alerts.length,
            itemBuilder: (context, i) => _AdminListItem(
              child: _AlertAdminRow(
                alert: alerts[i],
                onEdit: () => _editAlert(alerts[i]),
                onDelete: () => _deleteAlert(alerts[i]),
              ),
            ),
          ),
        ),
    ];
  }

  Future<void> _showAmaUpdates() async {
    try {
      final rows = await Supabase.instance.client.rpc(
        'jivaio_ama_pending_updates',
      );
      if (!mounted) return;
      final updates = List<Map<String, dynamic>>.from(rows as List);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const TText('Aggiornamenti AMA da verificare'),
          content: SizedBox(
            width: 650,
            child: updates.isEmpty
                ? const TText('Nessun aggiornamento da verificare.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: updates.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final update = updates[index];
                      final payload = Map<String, dynamic>.from(
                        update['source_payload'] as Map,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TText(
                            payload['title'] as String? ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(payload['details'] as String? ?? ''),
                          const SizedBox(height: 8),
                          SelectableText(payload['sourceUrl'] as String? ?? ''),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              try {
                                final acknowledged = await Supabase
                                    .instance
                                    .client
                                    .rpc(
                                      'jivaio_ama_ack_update',
                                      params: {
                                        'p_external_id': update['external_id'],
                                        'p_modified_at':
                                            update['source_modified_at'],
                                        'p_source_payload': payload,
                                      },
                                    );
                                if (!dialogContext.mounted) return;
                                Navigator.pop(dialogContext);
                                if (acknowledged != true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: TText(
                                        'La fonte è cambiata: riapri gli aggiornamenti.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: TText(
                                      'Operazione non riuscita. Riprova.',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const TText('Segna come verificato'),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const TText('Chiudi'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TText('Impossibile caricare gli aggiornamenti AMA.'),
        ),
      );
    }
  }

  Future<void> _syncAma() async {
    if (_syncingAma) return;
    setState(() => _syncingAma = true);
    try {
      await Supabase.instance.client.functions.invoke(
        'ama-sync',
        body: <String, dynamic>{},
      );
      await widget.store.refreshCloud(throwOnError: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TText(
            'Sincronizzazione completata. Controlla le bozze AMA.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TText('Sincronizzazione non riuscita. Riprova più tardi.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncingAma = false;
          _amaStatusVersion++;
        });
      }
    }
  }

  Future<void> _editLine([TransitLine? line]) async {
    final revision = line == null ? null : widget.store.lineRevision(line.id);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LineEditor(
        line: line,
        onSave: (result) => widget.store.saveLine(
          result,
          expectedRevision: revision,
          useSnapshot: true,
        ),
      ),
    );
  }

  Future<void> _editAlert([ServiceAlert? alert]) async {
    final revision = alert == null
        ? null
        : widget.store.alertRevision(alert.id);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AlertEditor(
        alert: alert,
        onSave: (result) => widget.store.saveAlert(
          result,
          expectedRevision: revision,
          useSnapshot: true,
        ),
      ),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      final message = error is CloudConflict
          ? error.toString()
          : 'Operazione non riuscita. Controlla la connessione e riprova.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: TText(message)));
    }
  }

  Future<void> _toggleVisibility(TransitLine line) async {
    final revision = widget.store.lineRevision(line.id);
    await _runAction(
      () => widget.store.saveLine(
        line.copyWith(isVisible: !line.isVisible),
        expectedRevision: revision,
        useSnapshot: true,
      ),
    );
  }

  Future<void> _deleteLine(TransitLine line) async {
    final revision = widget.store.lineRevision(line.id);
    final confirmed = await _confirm(
      'Eliminare la linea ${line.code}?',
      'La linea sarà rimossa dai dati condivisi.',
    );
    if (confirmed) {
      await _runAction(
        () => widget.store.removeLine(
          line.id,
          expectedRevision: revision,
          useSnapshot: true,
        ),
      );
    }
  }

  Future<void> _deleteAlert(ServiceAlert alert) async {
    final revision = widget.store.alertRevision(alert.id);
    final confirmed = await _confirm(
      'Eliminare questo avviso?',
      'L’avviso sarà rimosso dai dati condivisi.',
    );
    if (confirmed) {
      await _runAction(
        () => widget.store.removeAlert(
          alert.id,
          expectedRevision: revision,
          useSnapshot: true,
        ),
      );
    }
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: TText(title),
          content: TText(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const TText('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const TText('Conferma'),
            ),
          ],
        ),
      ) ??
      false;

  Future<TransitLine?> _chooseLine(
    List<TransitLine> lines, {
    required String title,
  }) {
    final sorted = [...lines]
      ..sort((a, b) => a.code.toLowerCase().compareTo(b.code.toLowerCase()));
    return showDialog<TransitLine>(
      context: context,
      builder: (context) => SimpleDialog(
        title: TText(title),
        children: [
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: TText('Nessuna linea disponibile.'),
            )
          else
            SizedBox(
              width: 500,
              height: (sorted.length * 56.0).clamp(56.0, 400.0),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final line = sorted[index];
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, line),
                    child: TText('${line.code} · ${line.name}'),
                  );
                },
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const TText('Annulla'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSnapshot() async {
    final mode = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const TText('Cosa vuoi esportare?'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'all'),
            child: const TText('Backup completo · tutte le linee e gli avvisi'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'line'),
            child: const TText('Una singola linea'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const TText('Annulla'),
          ),
        ],
      ),
    );
    if (!mounted || mode == null) return;
    TransitLine? selectedLine;
    if (mode == 'line') {
      selectedLine = await _chooseLine(
        widget.store.lines,
        title: 'Scegli la linea da esportare',
      );
      if (!mounted || selectedLine == null) return;
    }
    final selectedLines = selectedLine == null
        ? widget.store.lines
        : <TransitLine>[selectedLine];
    final selectedAlerts = selectedLine == null
        ? widget.store.alerts
        : <ServiceAlert>[];
    final json = const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'lines': selectedLines.map((line) => line.toJson()).toList(),
      'alerts': selectedAlerts.map((alert) => alert.toJson()).toList(),
    });
    final uri = Uri.dataFromString(
      json,
      mimeType: 'application/json',
      encoding: utf8,
    );
    final filenamePart = selectedLine == null
        ? 'completo'
        : 'linea-${selectedLine.code.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = uri.toString()
      ..download =
          'jivaio-backup-$filenamePart-${DateTime.now().toIso8601String().substring(0, 10)}.json';
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: TText('Backup JSON scaricato.')));
  }

  void _chooseBackupFile() {
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = '.json,application/json'
      ..style.display = 'none';
    web.document.body?.appendChild(input);
    input.addEventListener(
      'change',
      ((web.Event _) {
        final file = input.files?.item(0);
        input.remove();
        if (file != null) unawaited(_importBackupFile(file));
      }).toJS,
    );
    input.click();
  }

  Future<void> _importBackupFile(web.File file) async {
    try {
      final source = (await file.text().toDart).toDart;
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic> ||
          decoded['lines'] is! List ||
          decoded['alerts'] is! List) {
        throw const FormatException(
          'Il file non contiene un backup JiVaio con linee e avvisi.',
        );
      }

      final importedLines = <TransitLine>[];
      for (final row in decoded['lines'] as List<dynamic>) {
        if (row is! Map<String, dynamic>) {
          throw const FormatException('Una linea nel backup non è valida.');
        }
        final line = TransitLine.fromJson(row);
        if (line.id.trim().isEmpty) {
          throw const FormatException('Una linea non ha un identificativo.');
        }
        importedLines.add(line);
      }

      final importedAlerts = <ServiceAlert>[];
      for (final row in decoded['alerts'] as List<dynamic>) {
        if (row is! Map<String, dynamic>) {
          throw const FormatException('Un avviso nel backup non è valido.');
        }
        final alert = ServiceAlert.fromJson(row);
        if (alert.id.trim().isEmpty) {
          throw const FormatException('Un avviso non ha un identificativo.');
        }
        importedAlerts.add(alert);
      }
      if (importedLines.isEmpty && importedAlerts.isEmpty) {
        throw const FormatException(
          'Il backup non contiene dati da importare.',
        );
      }

      if (!mounted) return;
      final mode = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const TText('Cosa vuoi importare?'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'all'),
              child: TText(
                trFormat(
                  context,
                  'Tutto il contenuto · {lines} linee e {alerts} avvisi',
                  {
                    'lines': '${importedLines.length}',
                    'alerts': '${importedAlerts.length}',
                  },
                ),
              ),
            ),
            if (importedLines.isNotEmpty)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'line'),
                child: const TText('Una singola linea dal file'),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: const TText('Annulla'),
            ),
          ],
        ),
      );
      if (mode == null || !mounted) return;
      TransitLine? selectedLine;
      if (mode == 'line') {
        selectedLine = await _chooseLine(
          importedLines,
          title: 'Scegli la linea da importare',
        );
        if (!mounted || selectedLine == null) return;
      }
      final linesToImport = selectedLine == null
          ? importedLines
          : <TransitLine>[selectedLine];
      final alertsToImport = selectedLine == null
          ? importedAlerts
          : <ServiceAlert>[];
      final existingLineIds = widget.store.lines.map((line) => line.id).toSet();
      final existingAlertIds = widget.store.alerts
          .map((alert) => alert.id)
          .toSet();
      final matchingLines = linesToImport
          .where((line) => existingLineIds.contains(line.id))
          .length;
      final matchingAlerts = alertsToImport
          .where((alert) => existingAlertIds.contains(alert.id))
          .length;
      final lineRevisions = <String, int>{
        for (final line in linesToImport)
          if (widget.store.lineRevision(line.id) case final int revision)
            line.id: revision,
      };
      final alertRevisions = <String, int>{
        for (final alert in alertsToImport)
          if (widget.store.alertRevision(alert.id) case final int revision)
            alert.id: revision,
      };
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const TText('Importare il backup?'),
          content: TText(
            selectedLine == null
                ? trFormat(
                    context,
                    'Importi {lines} linee e {alerts} avvisi. Verranno sostituiti {matchingLines} linee e {matchingAlerts} avvisi già presenti con lo stesso ID. Gli altri dati e i preferiti resteranno.',
                    {
                      'lines': '${linesToImport.length}',
                      'alerts': '${alertsToImport.length}',
                      'matchingLines': '$matchingLines',
                      'matchingAlerts': '$matchingAlerts',
                    },
                  )
                : trFormat(
                    context,
                    'Importi la linea {code} · {name}. {status} Le altre linee, gli avvisi e i preferiti resteranno.',
                    {
                      'code': selectedLine.code,
                      'name': selectedLine.name,
                      'status': tr(
                        context,
                        matchingLines > 0
                            ? 'La linea esistente con lo stesso ID sarà sostituita.'
                            : 'La linea verrà aggiunta.',
                      ),
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const TText('Annulla'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.upload_file_outlined),
              label: const TText('Importa e unisci'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await widget.store.importBackup(
        importedLines: linesToImport,
        importedAlerts: alertsToImport,
        expectedLineRevisions: lineRevisions,
        expectedAlertRevisions: alertRevisions,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TText(
            widget.store.loadError == null ? 'Backup importato correttamente.' : 'Backup importato, ma non riesco ad aggiornare la schermata. Riprova.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TText('Non riesco a importare il backup: $error')),
      );
    }
  }
}

class _AmaSyncStatus extends StatefulWidget {
  const _AmaSyncStatus({super.key});

  @override
  State<_AmaSyncStatus> createState() => _AmaSyncStatusState();
}

class _AmaSyncStatusState extends State<_AmaSyncStatus> {
  Map<String, dynamic>? _status;
  bool _busy = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await Supabase.instance.client.rpc('jivaio_ama_status');
      if (mounted) {
        setState(() {
          _status = Map<String, dynamic>.from(result as Map);
          _error = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _setEnabled(bool value) async {
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.rpc(
        'jivaio_ama_set_enabled',
        params: {'p_enabled': value},
      );
      await _load();
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (_error) return const TText('Stato AMA non disponibile.');
    if (status == null) return const TText('Caricamento stato AMA…');
    final success = DateTime.tryParse(status['last_success'] as String? ?? '')
        ?.toLocal();
    final label = success == null
        ? 'Nessuna sincronizzazione completata'
        : 'Ultima sincronizzazione: ${_formatDate(success)} ${success.hour.toString().padLeft(2, '0')}:${success.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const TText('Sincronizzazione automatica AMA'),
          value: status['automatic_enabled'] == true,
          onChanged: _busy ? null : _setEnabled,
        ),
        TText(label),
        if (status['last_error'] != null)
          TText(
            status['last_error'] as String,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

class _AdminListItem extends StatelessWidget {
  const _AdminListItem({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: JivaioColors.surface,
      border: Border(bottom: BorderSide(color: JivaioColors.border)),
    ),
    child: child,
  );
}

class _AdminNotice extends StatelessWidget {
  const _AdminNotice({required this.usesCloud});
  final bool usesCloud;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF2DDAE)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.phonelink_outlined, color: Color(0xFF95620B)),
        const SizedBox(width: 11),
        Expanded(
          child: TText(
            usesCloud
                ? 'Le modifiche salvate sono condivise tra i browser. Esporta periodicamente un backup.'
                : 'Modalità anteprima: le modifiche sono salvate solo in questo browser.',
            style: const TextStyle(color: Color(0xFF755214), height: 1.45),
          ),
        ),
      ],
    ),
  );
}

class _LineAdminRow extends StatelessWidget {
  const _LineAdminRow({
    required this.line,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleVisibility,
  });
  final TransitLine line;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: JivaioColors.blueLight,
            borderRadius: BorderRadius.circular(13),
          ),
          child: TText(
            line.code,
            style: const TextStyle(
              color: JivaioColors.blue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TText(line.name, style: Theme.of(context).textTheme.titleMedium),
              TText(
                '${tr(context, '${line.directions.length} gruppi ${line.isCircular ? 'circuito' : 'direzione'}/orario')} · ${tr(context, '${line.stopCount} fermate')}${line.isManual ? ' · ${tr(context, 'inserita a mano')}' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TText(
                line.isVisible
                    ? 'Visibile al pubblico'
                    : 'Nascosta al pubblico',
                style: TextStyle(
                  color: line.isVisible
                      ? JivaioColors.success
                      : JivaioColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (line.dataWarning != null) ...[
                const SizedBox(height: 5),
                TText(
                  line.dataWarning!,
                  style: const TextStyle(
                    color: Color(0xFF95620B),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: tr(
            context,
            line.isVisible ? 'Nascondi linea' : 'Mostra linea',
          ),
          onPressed: onToggleVisibility,
          icon: Icon(
            line.isVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: line.isVisible ? JivaioColors.blue : JivaioColors.muted,
          ),
        ),
        IconButton(
          tooltip: tr(context, 'Modifica'),
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: tr(context, 'Elimina'),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: JivaioColors.danger),
        ),
      ],
    ),
  );
}

class _AlertAdminRow extends StatelessWidget {
  const _AlertAdminRow({
    required this.alert,
    required this.onEdit,
    required this.onDelete,
  });
  final ServiceAlert alert;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Icon(
          alert.isPublished ? Icons.campaign_outlined : Icons.drafts_outlined,
          color: alert.isPublished ? JivaioColors.blue : JivaioColors.muted,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TText(
                alert.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TText(
                '${alert.isPublished ? 'Pubblicato' : 'Bozza'} · ${alert.sourceName?.isNotEmpty == true ? alert.sourceName! : 'Manuale'} · ${alert.severity} · ${alert.affectedLines.isEmpty ? 'tutte le linee' : alert.affectedLines.join(', ')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: tr(context, 'Modifica'),
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: tr(context, 'Elimina'),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: JivaioColors.danger),
        ),
      ],
    ),
  );
}

class _LineEditor extends StatefulWidget {
  const _LineEditor({this.line, required this.onSave});
  final TransitLine? line;
  final Future<void> Function(TransitLine) onSave;
  @override
  State<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends State<_LineEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _stopCount;
  late final List<_DirectionFields> _directions;
  late bool _isCircular;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final line = widget.line;
    _code = TextEditingController(text: line?.code ?? '');
    _name = TextEditingController(text: line?.name ?? '');
    _stopCount = TextEditingController(
      text: line == null ? '' : '${line.stopCount}',
    );
    _isCircular = line?.isCircular ?? false;
    _directions = line != null && line.directions.isNotEmpty
        ? [
            for (var i = 0; i < line.directions.length; i++)
              _fieldsFromDirection(line.directions[i], i),
          ]
        : [
            _DirectionFields(
              id: 'manual-outbound',
              directionName: 'Andata',
              serviceId: '1',
              origin: '',
              destination: '',
              trips: const [],
            ),
            _DirectionFields(
              id: 'manual-return',
              directionName: 'Ritorno',
              serviceId: '1',
              origin: '',
              destination: '',
              trips: const [],
            ),
          ];
  }

  _DirectionFields _fieldsFromDirection(
    TransitDirection direction,
    int index,
  ) => _DirectionFields(
    id: direction.id,
    directionName: _isCircular
        ? 'Circuito ${index + 1}'
        : (direction.id.startsWith('0') ||
                  direction.id.contains('outbound') ||
                  (!direction.id.startsWith('1') && index.isEven)
              ? 'Andata'
              : 'Ritorno'),
    serviceId: direction.serviceId.isEmpty ? '1' : direction.serviceId,
    origin: direction.originName,
    destination: direction.destinationName,
    trips: direction.trips.isNotEmpty
        ? direction.trips.map(_TripFields.fromTrip).toList()
        : direction.departures.isEmpty
        ? (direction.stops.isEmpty
              ? const []
              : [
                  _TripFields(
                    id: '${direction.id}-legacy',
                    departureTime: '',
                    headsign: '',
                    stops: direction.stops,
                  ),
                ])
        : [
            for (var i = 0; i < direction.departures.length; i++)
              _TripFields(
                id: '${direction.id}-$i',
                departureTime: direction.departures[i],
                headsign: '',
                stops: i == 0 ? direction.stops : const [],
              ),
          ],
    dataWarning: direction.dataWarning,
  );

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _stopCount.dispose();
    for (final direction in _directions) {
      direction.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(18),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 840, maxHeight: 850),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TText(
                      widget.line == null
                          ? 'Nuova linea'
                          : 'Modifica linea ${widget.line!.code}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final fields = [
                        TextFormField(
                          controller: _code,
                          decoration: InputDecoration(
                            labelText: tr(context, 'Codice linea'),
                            hintText: tr(context, 'Es. 2U'),
                          ),
                          validator: (value) {
                            final error = _required(value);
                            return error == null ? null : tr(context, error);
                          },
                          onChanged: (value) {
                            if (_requiresCircular(value) && !_isCircular) {
                              setState(() => _isCircular = true);
                            }
                          },
                        ),
                        TextFormField(
                          controller: _name,
                          decoration: InputDecoration(
                            labelText: tr(context, 'Nome linea'),
                            hintText: tr(
                              context,
                              'Es. Terminalbus – L’Aquilone',
                            ),
                          ),
                          validator: (value) {
                            final error = _required(value);
                            return error == null ? null : tr(context, error);
                          },
                        ),
                        TextFormField(
                          controller: _stopCount,
                          decoration: InputDecoration(
                            labelText: tr(context, 'Numero fermate'),
                            hintText: tr(context, 'Es. 24'),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => int.tryParse(v ?? '') == null
                              ? tr(context, 'Inserisci un numero')
                              : null,
                        ),
                      ];
                      if (constraints.maxWidth < 580) {
                        return Column(
                          children: [
                            for (final field in fields)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: field,
                              ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < fields.length; i++)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: i == 2 ? 0 : 12,
                                ),
                                child: fields[i],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isCircular || _requiresCircular(_code.text),
                    title: const TText('Linea circolare / ad anello'),
                    subtitle: const TText(
                      'Usa un solo percorso per corsa: non viene richiesto il ritorno.',
                    ),
                    onChanged: (value) {
                      if (!value && _requiresCircular(_code.text)) return;
                      setState(() {
                        _isCircular = value;
                        if (value &&
                            widget.line == null &&
                            _directions.length > 1) {
                          final removed = _directions.removeAt(1);
                          removed.dispose();
                        }
                        for (var i = 0; i < _directions.length; i++) {
                          _directions[i].directionName = value
                              ? 'Circuito ${i + 1}'
                              : (i.isEven ? 'Andata' : 'Ritorno');
                        }
                        if (!value && _directions.length == 1) {
                          _directions.add(
                            _DirectionFields(
                              id: 'manual-return-${DateTime.now().microsecondsSinceEpoch}',
                              directionName: 'Ritorno',
                              serviceId: _directions.first.serviceId,
                              origin: _directions.first.destination.text,
                              destination: _directions.first.origin.text,
                              trips: const [],
                            ),
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 7),
                  TText(
                    _isCircular
                        ? 'Ogni partenza può avere un percorso diverso. Aggiungi una corsa e specifica tutte le fermate con il relativo orario intermedio.'
                        : 'Per ogni calendario inserisci andata e ritorno. Ogni partenza conserva il proprio percorso e i propri orari intermedi.',
                    style: const TextStyle(
                      color: JivaioColors.secondary,
                      height: 1.45,
                    ),
                  ),
                  if (widget.line?.dataWarning case final warning?) ...[
                    const SizedBox(height: 12),
                    _ReviewWarning(text: warning),
                  ],
                  const SizedBox(height: 18),
                  for (var i = 0; i < _directions.length; i++) ...[
                    _DirectionForm(
                      fields: _directions[i],
                      label: _directionDisplayLabel(i),
                      isCircular: _isCircular,
                      onToggleTrips: () => setState(
                        () => _directions[i].tripsCollapsed =
                            !_directions[i].tripsCollapsed,
                      ),
                      onAddTrip: () => _addTrip(_directions[i]),
                      onEditTripStops: (tripIndex) =>
                          _editTripStops(_directions[i], tripIndex),
                      onRemoveTrip: (tripIndex) =>
                          _removeTrip(_directions[i], tripIndex),
                      onServiceChanged: (serviceId) =>
                          setState(() => _directions[i].serviceId = serviceId),
                      onRemoveDirection:
                          _isCircular && _canRemoveCircuit(_directions[i])
                          ? () => _removeDirection(_directions[i])
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    onPressed: _addCalendarGroup,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: TText(
                      _isCircular
                          ? 'Aggiungi circuito per un altro calendario'
                          : 'Aggiungi andata e ritorno per un altro calendario',
                    ),
                  ),
                ],
              ),
            ),
            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: TText(
                  _saveError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const TText('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const TText('Salva linea'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final line = TransitLine(
      id: widget.line?.id ?? 'manual-${now.microsecondsSinceEpoch}',
      code: _code.text.trim(),
      name: _name.text.trim(),
      stopCount: int.parse(_stopCount.text),
      directions: _directions
          .map(
            (fields) => fields.toDirection(
              isCircular: _isCircular || _requiresCircular(_code.text),
            ),
          )
          .toList(),
      updatedAt: now,
      isManual: widget.line?.isManual ?? true,
      dataWarning: widget.line?.dataWarning,
      isCircular: _isCircular || _requiresCircular(_code.text),
      isVisible: widget.line?.isVisible ?? true,
    );
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(line);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(
          () => _saveError = error is CloudConflict
              ? 'Dati modificati in un altro browser. Copia le tue modifiche, annulla e riapri la linea.'
              : 'Salvataggio non riuscito. Le modifiche restano aperte; riprova.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _directionDisplayLabel(int index) {
    final direction = _directions[index];
    if (!_isCircular) {
      return '${direction.directionName} · ${direction.serviceLabel}';
    }
    final variant = _directions
        .take(index + 1)
        .where((item) => item.serviceId == direction.serviceId)
        .length;
    return 'Circuito $variant · ${direction.serviceLabel}';
  }

  bool _requiresCircular(String code) =>
      const {'A', 'B', 'EST', 'OVEST'}.contains(code.trim().toUpperCase());

  void _addTrip(_DirectionFields direction) {
    setState(() {
      direction.trips.add(
        _TripFields(
          id: 'manual-trip-${DateTime.now().microsecondsSinceEpoch}',
          departureTime: '',
          headsign: '',
          stops: const [],
        ),
      );
    });
  }

  Future<void> _editTripStops(_DirectionFields direction, int index) async {
    final trip = direction.trips[index];
    final result = await showDialog<_TripRoute>(
      context: context,
      builder: (_) => _TripStopsEditor(
        stops: trip.stops,
        departureTime: trip.departureTime.text,
        headsign: trip.headsign.text,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      trip.stops = result.stops;
      trip.headsign.text = result.headsign;
    });
  }

  void _removeTrip(_DirectionFields direction, int index) {
    setState(() => direction.trips.removeAt(index).dispose());
  }

  bool _canRemoveCircuit(_DirectionFields direction) =>
      _directions
          .where((item) => item.serviceId == direction.serviceId)
          .length >
      1;

  void _removeDirection(_DirectionFields direction) {
    setState(() {
      _directions.remove(direction);
      direction.dispose();
    });
  }

  Future<void> _addCalendarGroup() async {
    final serviceId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const TText('Aggiungi orari per'),
        children: [
          for (final option in _serviceOptions)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option.$1),
              child: TText(option.$2),
            ),
        ],
      ),
    );
    if (serviceId == null || !mounted) return;
    final suffix = DateTime.now().microsecondsSinceEpoch;
    setState(() {
      if (_isCircular) {
        _directions.add(
          _DirectionFields(
            id: 'manual-circuit-$suffix',
            directionName: 'Circuito',
            serviceId: serviceId,
            origin: '',
            destination: '',
            trips: const [],
          ),
        );
      } else {
        _directions.addAll([
          _DirectionFields(
            id: 'manual-outbound-$suffix',
            directionName: 'Andata',
            serviceId: serviceId,
            origin: '',
            destination: '',
            trips: const [],
          ),
          _DirectionFields(
            id: 'manual-return-$suffix',
            directionName: 'Ritorno',
            serviceId: serviceId,
            origin: '',
            destination: '',
            trips: const [],
          ),
        ]);
      }
    });
  }
}

class _DirectionFields {
  _DirectionFields({
    required this.id,
    required this.directionName,
    required this.serviceId,
    required String origin,
    required String destination,
    required List<_TripFields> trips,
    this.dataWarning,
  }) : origin = TextEditingController(text: origin),
       destination = TextEditingController(text: destination),
       trips = [...trips];
  final String id;
  String directionName;
  String serviceId;
  bool tripsCollapsed = false;
  final String? dataWarning;
  final TextEditingController origin;
  final TextEditingController destination;
  final List<_TripFields> trips;
  String get serviceLabel => transitServiceLabel(serviceId);
  void dispose() {
    origin.dispose();
    destination.dispose();
    for (final trip in trips) {
      trip.dispose();
    }
  }

  TransitDirection toDirection({required bool isCircular}) {
    final parsedTrips = trips.map((trip) => trip.toTransitTrip()).toList();
    final firstStops = parsedTrips
        .map((trip) => trip.stops)
        .firstWhere((stops) => stops.isNotEmpty, orElse: () => const []);
    final originName = origin.text.trim().isNotEmpty
        ? origin.text.trim()
        : (firstStops.isNotEmpty ? firstStops.first.name : '');
    final destinationName = destination.text.trim().isNotEmpty
        ? destination.text.trim()
        : (isCircular
              ? 'Percorso circolare'
              : (firstStops.isNotEmpty ? firstStops.last.name : ''));
    final parsedDepartures =
        parsedTrips
            .map((trip) => trip.departureTime)
            .where((time) => time.isNotEmpty)
            .toList()
          ..sort();
    return TransitDirection(
      id: id,
      originName: originName,
      destinationName: destinationName,
      departures: parsedDepartures,
      stops: firstStops,
      serviceId: serviceId,
      serviceLabel: serviceLabel,
      dataWarning: dataWarning,
      trips: parsedTrips,
    );
  }
}

class _TripFields {
  _TripFields({
    required this.id,
    required String departureTime,
    required String headsign,
    required List<TransitStopTime> stops,
    String note = '',
  }) : departureTime = TextEditingController(text: departureTime),
       headsign = TextEditingController(text: headsign),
       note = TextEditingController(text: note),
       stops = [...stops];

  factory _TripFields.fromTrip(TransitTrip trip) => _TripFields(
    id: trip.id,
    departureTime: trip.departureTime,
    headsign: trip.headsign,
    note: trip.note,
    stops: trip.stops,
  );

  final String id;
  final TextEditingController departureTime;
  final TextEditingController headsign;
  final TextEditingController note;
  List<TransitStopTime> stops;

  TransitTrip toTransitTrip() => TransitTrip(
    id: id,
    departureTime: _normalizeTime(departureTime.text),
    headsign: headsign.text.trim(),
    note: note.text.trim(),
    stops: stops,
  );

  void dispose() {
    departureTime.dispose();
    headsign.dispose();
    note.dispose();
  }
}

String _normalizeTime(String value) {
  final trimmed = value.trim();
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
  if (match == null) return trimmed;
  return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)}';
}

const _serviceOptions = [
  ('1', 'Feriale (lun–ven)'),
  ('2', 'Sabato'),
  ('FESTIVO', 'Festivo'),
  ('NIGHT_THSAT', 'Notti gio–ven e sab–dom'),
];

class _DirectionForm extends StatelessWidget {
  const _DirectionForm({
    required this.fields,
    required this.label,
    required this.isCircular,
    required this.onToggleTrips,
    required this.onAddTrip,
    required this.onEditTripStops,
    required this.onRemoveTrip,
    required this.onServiceChanged,
    this.onRemoveDirection,
  });
  final _DirectionFields fields;
  final String label;
  final bool isCircular;
  final VoidCallback onToggleTrips;
  final VoidCallback onAddTrip;
  final ValueChanged<int> onEditTripStops;
  final ValueChanged<int> onRemoveTrip;
  final ValueChanged<String> onServiceChanged;
  final VoidCallback? onRemoveDirection;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: JivaioColors.page,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: JivaioColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TText(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: tr(
                context,
                fields.tripsCollapsed ? 'Mostra corse' : 'Nascondi corse',
              ),
              onPressed: onToggleTrips,
              icon: Icon(
                fields.tripsCollapsed ? Icons.expand_more : Icons.expand_less,
              ),
            ),
            if (onRemoveDirection != null)
              IconButton(
                tooltip: tr(context, 'Rimuovi questo circuito'),
                onPressed: onRemoveDirection,
                icon: const Icon(
                  Icons.delete_outline,
                  color: JivaioColors.danger,
                ),
              ),
          ],
        ),
        if (fields.dataWarning case final warning?) ...[
          const SizedBox(height: 10),
          _ReviewWarning(text: warning),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue:
              _serviceOptions.any((option) => option.$1 == fields.serviceId)
              ? fields.serviceId
              : '1',
          decoration: InputDecoration(
            labelText: tr(context, 'Validità degli orari'),
          ),
          items: [
            for (final option in _serviceOptions)
              DropdownMenuItem(value: option.$1, child: TText(option.$2)),
          ],
          onChanged: (value) {
            if (value != null) onServiceChanged(value);
          },
        ),
        Offstage(
          offstage: fields.tripsCollapsed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              TText(
                isCircular
                    ? 'Ogni partenza del circuito può iniziare da una fermata diversa.'
                    : 'Ogni partenza può avere un percorso e orari intermedi diversi.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              if (fields.trips.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: TText('Nessuna corsa inserita per questo calendario.'),
                )
              else
                for (var i = 0; i < fields.trips.length; i++)
                  _TripAdminRow(
                    key: ValueKey('${fields.id}-${fields.trips[i].id}-$i'),
                    trip: fields.trips[i],
                    onEditStops: () => onEditTripStops(i),
                    onRemove: () => onRemoveTrip(i),
                  ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onAddTrip,
                  icon: const Icon(Icons.add),
                  label: const TText('Aggiungi partenza'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TripAdminRow extends StatelessWidget {
  const _TripAdminRow({
    super.key,
    required this.trip,
    required this.onEditStops,
    required this.onRemove,
  });
  final _TripFields trip;
  final VoidCallback onEditStops;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _TimeInput(
                  controller: trip.departureTime,
                  label: 'Ora di partenza',
                ),
              ),
              IconButton(
                tooltip: tr(context, 'Elimina partenza'),
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline,
                  color: JivaioColors.danger,
                ),
              ),
            ],
          ),
          if (trip.stops.isNotEmpty) ...[
            const SizedBox(height: 5),
            TText(
              'Parte da ${trip.stops.first.name} · ${trip.stops.length} fermate${trip.headsign.text.trim().isEmpty ? '' : ' · ${trip.headsign.text.trim()}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 10),
          TextFormField(
            controller: trip.note,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: tr(context, 'Nota per questa corsa (facoltativa)'),
              hintText: tr(context, 'Es. Corsa scolastica'),
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 7),
          OutlinedButton.icon(
            onPressed: onEditStops,
            icon: const Icon(Icons.route_outlined),
            label: TText(
              trip.stops.isEmpty
                  ? 'Aggiungi percorso e orari intermedi'
                  : 'Modifica percorso (${trip.stops.length} fermate)',
            ),
          ),
        ],
      ),
    ),
  );
}

class _TimeInput extends StatelessWidget {
  const _TimeInput({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  Future<void> _pickTime(BuildContext context) async {
    final match = RegExp(r'^(\d{1,2}):([0-5]\d)$')
        .firstMatch(controller.text.trim());
    final hour = match == null ? null : int.tryParse(match.group(1)!);
    final minute = match == null ? null : int.tryParse(match.group(2)!);
    final initialTime = hour != null && hour < 24 && minute != null
        ? TimeOfDay(hour: hour, minute: minute)
        : TimeOfDay.now();
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'SELEZIONA ORARIO',
      cancelText: 'Annulla',
      confirmText: 'Conferma',
      hourLabelText: 'Ora',
      minuteLabelText: 'Minuti',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (selected == null) return;
    controller.text =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: tr(context, label),
      hintText: tr(context, '07:15'),
      prefixIcon: const Icon(Icons.schedule),
      suffixIcon: IconButton(
        tooltip: tr(context, 'Scegli orario'),
        onPressed: () => _pickTime(context),
        icon: const Icon(Icons.access_time_filled, color: JivaioColors.blue),
      ),
    ),
    keyboardType: TextInputType.datetime,
    validator: (value) {
      final error = _validateOptionalTime(value);
      return error == null ? null : tr(context, error);
    },
  );
}

class _TripRoute {
  const _TripRoute({required this.stops, required this.headsign});
  final List<TransitStopTime> stops;
  final String headsign;
}

class _TripStopsEditor extends StatefulWidget {
  const _TripStopsEditor({
    required this.stops,
    required this.departureTime,
    required this.headsign,
  });
  final List<TransitStopTime> stops;
  final String departureTime;
  final String headsign;

  @override
  State<_TripStopsEditor> createState() => _TripStopsEditorState();
}

class _TripStopsEditorState extends State<_TripStopsEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stops;
  late final TextEditingController _headsign;

  @override
  void initState() {
    super.initState();
    _headsign = TextEditingController(text: widget.headsign);
    _stops = TextEditingController(
      text: widget.stops
          .map(
            (stop) =>
                '${stop.name} | ${stop.time == '--:--' ? '' : '${stop.isEstimated ? '~' : ''}${stop.time}'}',
          )
          .join('\n'),
    );
  }

  @override
  void dispose() {
    _stops.dispose();
    _headsign.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final parsedStops = <TransitStopTime>[];
    for (final line in _stops.text.split('\n')) {
      final value = line.trim();
      if (value.isEmpty) continue;
      final parts = value.split('|');
      final name = parts.first.trim();
      if (name.isEmpty) continue;
      final rawTime = parts.length > 1 ? parts[1].trim() : '';
      final isEstimated = rawTime.startsWith('~');
      final enteredTime = isEstimated ? rawTime.substring(1).trim() : rawTime;
      final time = enteredTime.isEmpty
          ? (parsedStops.isEmpty && widget.departureTime.trim().isNotEmpty
                ? _normalizeTime(widget.departureTime)
                : '--:--')
          : _normalizeTime(enteredTime);
      parsedStops.add(
        TransitStopTime(
          stopId: 'manual-${name.toLowerCase().hashCode}',
          name: name,
          time: time,
          isEstimated: isEstimated && time != '--:--',
        ),
      );
    }
    Navigator.pop(
      context,
      _TripRoute(stops: parsedStops, headsign: _headsign.text.trim()),
    );
  }

  Future<void> _editStopTimes() async {
    if (!_formKey.currentState!.validate()) return;
    final lines = _stops.text.split('\n');
    if (!lines.any((line) => line.trim().isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TText('Inserisci prima almeno una fermata.')),
      );
      return;
    }
    final updated = await showDialog<String>(
      context: context,
      builder: (_) => _StopTimesEditor(lines: lines),
    );
    if (updated == null || !mounted) return;
    setState(() => _stops.text = updated);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const TText('Percorso di questa partenza'),
    content: SizedBox(
      width: 620,
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            TText(
              'Inserisci tutte le fermate in ordine. La prima fermata può cambiare da una partenza all’altra.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _headsign,
              decoration: InputDecoration(
                labelText: tr(context, 'Destinazione mostrata (facoltativa)'),
                hintText: tr(context, 'Es. Ospedale'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stops,
              minLines: 9,
              maxLines: 16,
              decoration: InputDecoration(
                labelText: tr(context, 'Fermate e orari intermedi'),
                hintText: tr(
                  context,
                  'Terminalbus | 07:15\nPiazza Duomo | 07:22\nOspedale | 07:40',
                ),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                final error = _validateStopRows(value);
                return error == null ? null : tr(context, error);
              },
            ),
            const SizedBox(height: 8),
            TText(
              'Formato: Nome fermata | HH:MM, una fermata per riga. Usa ~ prima dell’orario se è stimato. Se lasci vuoto l’orario della prima fermata useremo quello di partenza.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _editStopTimes,
                icon: const Icon(Icons.schedule),
                label: const TText('Modifica orari delle fermate'),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const TText('Annulla'),
      ),
      FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.save_outlined),
        label: const TText('Salva percorso'),
      ),
    ],
  );
}

class _StopTimeFields {
  _StopTimeFields(String line)
    : original = line,
      name = line.split('|').first.trim(),
      isEstimated =
          line.contains('|') && line.split('|')[1].trim().startsWith('~'),
      time = TextEditingController(
        text: line.contains('|')
            ? (line.split('|')[1].trim() == '--:--'
                  ? ''
                  : line
                        .split('|')[1]
                        .trim()
                        .replaceFirst(RegExp(r'^~\s*'), ''))
            : '',
      );

  final String original;
  final String name;
  final TextEditingController time;
  bool isEstimated;
}

class _StopTimesEditor extends StatefulWidget {
  const _StopTimesEditor({required this.lines});
  final List<String> lines;

  @override
  State<_StopTimesEditor> createState() => _StopTimesEditorState();
}

class _StopTimesEditorState extends State<_StopTimesEditor> {
  final _formKey = GlobalKey<FormState>();
  late final List<_StopTimeFields> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.lines.map(_StopTimeFields.new).toList();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.time.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final text = _rows
        .map((row) {
          if (row.original.trim().isEmpty) return row.original;
          final time = row.time.text.trim();
          return '${row.name} | ${time.isEmpty ? '' : '${row.isEstimated ? '~' : ''}${_normalizeTime(time)}'}';
        })
        .join('\n');
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const TText('Orari delle fermate'),
    content: SizedBox(
      width: 620,
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            TText(
              'Scrivi l’orario o usa l’icona dell’orologio. Puoi lasciare vuoti gli orari che non conosci.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final row in _rows)
              if (row.original.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: JivaioColors.page,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: JivaioColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TText(
                          row.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _TimeInput(controller: row.time, label: 'Orario'),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const TText('Orario stimato'),
                          value: row.isEstimated,
                          onChanged: (value) =>
                              setState(() => row.isEstimated = value ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const TText('Annulla'),
      ),
      FilledButton(onPressed: _save, child: const TText('Applica orari')),
    ],
  );
}

class _ReviewWarning extends StatelessWidget {
  const _ReviewWarning({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF2DDAE)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFF95620B),
          size: 20,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: TText(
            text,
            style: const TextStyle(color: Color(0xFF755214), height: 1.4),
          ),
        ),
      ],
    ),
  );
}

String? _validateOptionalTime(String? value) {
  final time = (value ?? '').trim();
  if (time.isEmpty) return null;
  final match = RegExp(r'^(\d{1,2}):([0-5]\d)$').firstMatch(time);
  if (match == null || int.parse(match.group(1)!) > 99) {
    return 'Usa il formato HH:MM';
  }
  return null;
}

String? _validateStopRows(String? value) {
  final rows = (value ?? '').split('\n');
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i].trim();
    if (row.isEmpty) continue;
    final parts = row.split('|');
    if (parts.first.trim().isEmpty) {
      return 'Indica il nome della fermata alla riga ${i + 1}';
    }
    if (parts.length > 1) {
      final time = parts[1].trim().replaceFirst(RegExp(r'^~\s*'), '');
      if (time.isNotEmpty &&
          time != '--:--' &&
          _validateOptionalTime(time) != null) {
        return 'Orario non valido alla riga ${i + 1}: usa HH:MM';
      }
    }
  }
  return null;
}

class _AlertEditor extends StatefulWidget {
  const _AlertEditor({this.alert, required this.onSave});
  final ServiceAlert? alert;
  final Future<void> Function(ServiceAlert) onSave;
  @override
  State<_AlertEditor> createState() => _AlertEditorState();
}

class _AlertEditorState extends State<_AlertEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _summary;
  late final TextEditingController _details;
  late final TextEditingController _lines;
  late final TextEditingController _source;
  late final TextEditingController _sourceUrl;
  late DateTime _startsAt;
  DateTime? _endsAt;
  late String _severity;
  late bool _published;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final alert = widget.alert;
    _title = TextEditingController(text: alert?.title ?? '');
    _summary = TextEditingController(text: alert?.summary ?? '');
    _details = TextEditingController(text: alert?.details ?? '');
    _lines = TextEditingController(text: alert?.affectedLines.join(', ') ?? '');
    _source = TextEditingController(text: alert?.sourceName ?? '');
    _sourceUrl = TextEditingController(text: alert?.sourceUrl ?? '');
    _startsAt = alert?.startsAt ?? DateTime.now();
    _endsAt = alert?.endsAt;
    _severity = alert?.severity ?? 'info';
    _published = alert?.isPublished ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _details.dispose();
    _lines.dispose();
    _source.dispose();
    _sourceUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(18),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700, maxHeight: 850),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TText(
                      widget.alert == null ? 'Nuovo avviso' : 'Modifica avviso',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Titolo'),
                    ),
                    validator: (value) {
                      final error = _required(value);
                      return error == null ? null : tr(context, error);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _summary,
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Riepilogo'),
                    ),
                    validator: (value) {
                      final error = _required(value);
                      return error == null ? null : tr(context, error);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _details,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Dettagli'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _severity,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Priorità'),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'info',
                        child: TText('Informazione'),
                      ),
                      DropdownMenuItem(
                        value: 'warning',
                        child: TText('Modifica servizio'),
                      ),
                      DropdownMenuItem(
                        value: 'critical',
                        child: TText('Importante'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _severity = value ?? 'info'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(isStart: true),
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: TText('Inizio: ${_formatDate(_startsAt)}'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(isStart: false),
                        icon: const Icon(Icons.event_available_outlined),
                        label: TText(
                          _endsAt == null
                              ? 'Senza scadenza'
                              : 'Fine: ${_formatDate(_endsAt!)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lines,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Linee coinvolte'),
                      hintText: tr(context, 'Es. 12A, 13Z · vuoto = tutte'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _source,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Fonte / autore'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sourceUrl,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Link fonte'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const TText('Pubblica avviso'),
                    value: _published,
                    onChanged: (value) => setState(() => _published = value),
                  ),
                ],
              ),
            ),
            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: TText(
                  _saveError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const TText('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const TText('Salva avviso'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startsAt : (_endsAt ?? _startsAt);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    setState(() {
      if (isStart) {
        _startsAt = picked ?? _startsAt;
      } else {
        _endsAt = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final alert = ServiceAlert(
      id: widget.alert?.id ?? 'manual-alert-${now.microsecondsSinceEpoch}',
      title: _title.text.trim(),
      summary: _summary.text.trim(),
      details: _details.text.trim(),
      severity: _severity,
      startsAt: _startsAt,
      endsAt: _endsAt,
      sourceName: _source.text.trim().isEmpty ? null : _source.text.trim(),
      sourceUrl: _sourceUrl.text.trim().isEmpty ? null : _sourceUrl.text.trim(),
      affectedLines: _lines.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
      isPublished: _published,
    );
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(alert);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(
          () => _saveError = error is CloudConflict
              ? 'Avviso modificato in un altro browser. Copia le tue modifiche, annulla e riapri l’avviso.'
              : 'Salvataggio non riuscito. Le modifiche restano aperte; riprova.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _AdminEmpty extends StatelessWidget {
  const _AdminEmpty({required this.title, required this.text});
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, color: JivaioColors.muted, size: 32),
          const SizedBox(height: 9),
          TText(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          TText(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

String? _required(String? value) =>
    (value ?? '').trim().isEmpty ? 'Campo obbligatorio' : null;
String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
