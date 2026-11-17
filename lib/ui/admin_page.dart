import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../data/jivaio_store.dart';
import '../models/transit_models.dart';
import '../theme/jivaio_theme.dart';
import 'jivaio_app.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({required this.store, super.key});
  final JivaioStore store;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      store: widget.store,
      child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => PageFrame(width: 1180, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Gestione JiVaio', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 5), Text('Modifica i dati di anteprima dal browser.', style: Theme.of(context).textTheme.bodyLarge)])),
            OutlinedButton.icon(onPressed: _exportSnapshot, icon: const Icon(Icons.download_outlined), label: const Text('Esporta backup')),
          ]),
          const SizedBox(height: 18),
          const _AdminNotice(),
          const SizedBox(height: 20),
          SegmentedButton<int>(
            segments: const [ButtonSegment(value: 0, label: Text('Linee'), icon: Icon(Icons.directions_bus_outlined)), ButtonSegment(value: 1, label: Text('Avvisi'), icon: Icon(Icons.campaign_outlined))],
            selected: {_tab},
            onSelectionChanged: (value) => setState(() => _tab = value.first),
          ),
          const SizedBox(height: 18),
          if (_tab == 0) _linesPanel(context) else _alertsPanel(context),
          const SizedBox(height: 26),
          Row(children: [
            TextButton.icon(onPressed: () => Navigator.of(context).pushReplacementNamed('/lines'), icon: const Icon(Icons.open_in_new), label: const Text('Apri anteprima pubblica')),
            const Spacer(),
            TextButton.icon(onPressed: _resetPreview, icon: const Icon(Icons.restart_alt), label: const Text('Ripristina dati iniziali')),
          ]),
        ])),
      ),
    );
  }

  Widget _linesPanel(BuildContext context) {
    final lines = [...widget.store.lines]..sort((a, b) => a.code.toLowerCase().compareTo(b.code.toLowerCase()));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Text('${lines.length} linee', style: Theme.of(context).textTheme.titleMedium)), FilledButton.icon(onPressed: () => _editLine(), icon: const Icon(Icons.add), label: const Text('Nuova linea'))]),
      const SizedBox(height: 12),
      if (lines.isEmpty) ...[
        const _AdminEmpty(title: 'Non ci sono linee', text: 'Aggiungi la prima linea o importa il GTFS aggiornato.'),
      ] else ...[
        Card(child: Column(children: [
          for (var i = 0; i < lines.length; i++) ...[
            _LineAdminRow(line: lines[i], onEdit: () => _editLine(lines[i]), onDelete: () => _deleteLine(lines[i])),
            if (i != lines.length - 1) const Divider(height: 1),
          ],
        ])),
      ],
    ]);
  }

  Widget _alertsPanel(BuildContext context) {
    final alerts = [...widget.store.alerts]..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Text('${alerts.length} avvisi', style: Theme.of(context).textTheme.titleMedium)), FilledButton.icon(onPressed: () => _editAlert(), icon: const Icon(Icons.add), label: const Text('Nuovo avviso'))]),
      const SizedBox(height: 12),
      if (alerts.isEmpty) ...[
        const _AdminEmpty(title: 'Nessun avviso', text: 'Crea un avviso quando il servizio subisce modifiche.'),
      ] else ...[
        Card(child: Column(children: [
          for (var i = 0; i < alerts.length; i++) ...[
            _AlertAdminRow(alert: alerts[i], onEdit: () => _editAlert(alerts[i]), onDelete: () => _deleteAlert(alerts[i])),
            if (i != alerts.length - 1) const Divider(height: 1),
          ],
        ])),
      ],
    ]);
  }

  Future<void> _editLine([TransitLine? line]) async {
    final result = await showDialog<TransitLine>(context: context, barrierDismissible: false, builder: (_) => _LineEditor(line: line));
    if (result != null) widget.store.saveLine(result);
  }

  Future<void> _editAlert([ServiceAlert? alert]) async {
    final result = await showDialog<ServiceAlert>(context: context, barrierDismissible: false, builder: (_) => _AlertEditor(alert: alert));
    if (result != null) widget.store.saveAlert(result);
  }

  Future<void> _deleteLine(TransitLine line) async {
    final confirmed = await _confirm('Eliminare la linea ${line.code}?', 'La rimozione vale solo per questa anteprima nel browser.');
    if (confirmed) widget.store.removeLine(line.id);
  }

  Future<void> _deleteAlert(ServiceAlert alert) async {
    final confirmed = await _confirm('Eliminare questo avviso?', 'La rimozione vale solo per questa anteprima nel browser.');
    if (confirmed) widget.store.removeAlert(alert.id);
  }

  Future<void> _resetPreview() async {
    final confirmed = await _confirm('Ripristinare i dati iniziali?', 'Le modifiche salvate in questo browser verranno rimosse.');
    if (confirmed) {
      widget.store.resetPreview();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anteprima ripristinata.')));
    }
  }

  Future<bool> _confirm(String title, String message) async => await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Conferma'))]),
  ) ?? false;

  void _exportSnapshot() {
    final json = const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'lines': widget.store.lines.map((line) => line.toJson()).toList(),
      'alerts': widget.store.alerts.map((alert) => alert.toJson()).toList(),
    });
    final uri = Uri.dataFromString(json, mimeType: 'application/json', encoding: utf8);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = uri.toString()
      ..download = 'jivaio-backup-${DateTime.now().toIso8601String().substring(0, 10)}.json';
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup JSON scaricato.')));
  }
}

class _AdminNotice extends StatelessWidget {
  const _AdminNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: const Color(0xFFFFF7E8), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF2DDAE))),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.phonelink_outlined, color: Color(0xFF95620B)),
      SizedBox(width: 11),
      Expanded(child: Text('Modalità locale: le modifiche sono salvate solo in questo browser e non sono visibili agli utenti. Questa pagina non ha ancora autenticazione. Prima della pubblicazione collegheremo Supabase Auth e le regole di accesso.', style: TextStyle(color: Color(0xFF755214), height: 1.45))),
    ]),
  );
}

class _LineAdminRow extends StatelessWidget {
  const _LineAdminRow({required this.line, required this.onEdit, required this.onDelete});
  final TransitLine line;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
    Container(width: 48, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: JivaioColors.blueLight, borderRadius: BorderRadius.circular(13)), child: Text(line.code, style: const TextStyle(color: JivaioColors.blue, fontWeight: FontWeight.w800))),
    const SizedBox(width: 13),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(line.name, style: Theme.of(context).textTheme.titleMedium), Text('${line.directions.length} direzioni · ${line.stopCount} fermate${line.isManual ? ' · inserita a mano' : ''}', style: Theme.of(context).textTheme.bodyMedium)])),
    IconButton(tooltip: 'Modifica', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
    IconButton(tooltip: 'Elimina', onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: JivaioColors.danger)),
  ]));
}

class _AlertAdminRow extends StatelessWidget {
  const _AlertAdminRow({required this.alert, required this.onEdit, required this.onDelete});
  final ServiceAlert alert;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
    Icon(alert.isPublished ? Icons.campaign_outlined : Icons.drafts_outlined, color: alert.isPublished ? JivaioColors.blue : JivaioColors.muted),
    const SizedBox(width: 13),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(alert.title, style: Theme.of(context).textTheme.titleMedium), Text('${alert.isPublished ? 'Pubblicato' : 'Bozza'} · ${alert.severity} · ${alert.affectedLines.isEmpty ? 'tutte le linee' : alert.affectedLines.join(', ')}', style: Theme.of(context).textTheme.bodyMedium)])),
    IconButton(tooltip: 'Modifica', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
    IconButton(tooltip: 'Elimina', onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: JivaioColors.danger)),
  ]));
}

class _LineEditor extends StatefulWidget {
  const _LineEditor({this.line});
  final TransitLine? line;
  @override
  State<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends State<_LineEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _stopCount;
  late final List<_DirectionFields> _directions;

  @override
  void initState() {
    super.initState();
    final line = widget.line;
    _code = TextEditingController(text: line?.code ?? '');
    _name = TextEditingController(text: line?.name ?? '');
    _stopCount = TextEditingController(text: line == null ? '' : '${line.stopCount}');
    _directions = List.generate(2, (index) {
      final direction = line != null && line.directions.length > index ? line.directions[index] : null;
      return _DirectionFields(
        origin: direction?.originName ?? '',
        destination: direction?.destinationName ?? '',
        departures: direction?.departures.join(', ') ?? '',
        stops: direction?.stops.map((stop) => '${stop.name} | ${stop.time}').join('\n') ?? '',
      );
    });
  }

  @override
  void dispose() {
    _code.dispose(); _name.dispose(); _stopCount.dispose();
    for (final direction in _directions) { direction.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(18),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 840, maxHeight: 850),
      child: Form(key: _formKey, child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(24, 20, 12, 10), child: Row(children: [Expanded(child: Text(widget.line == null ? 'Nuova linea' : 'Modifica linea ${widget.line!.code}', style: Theme.of(context).textTheme.titleLarge)), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))])),
        const Divider(height: 1),
        Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [
          LayoutBuilder(builder: (context, constraints) {
            final fields = [
              TextFormField(controller: _code, decoration: const InputDecoration(labelText: 'Codice linea', hintText: 'Es. 2U'), validator: _required),
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nome linea', hintText: 'Es. Terminalbus – L’Aquilone'), validator: _required),
              TextFormField(controller: _stopCount, decoration: const InputDecoration(labelText: 'Numero fermate', hintText: 'Es. 24'), keyboardType: TextInputType.number, validator: (v) => int.tryParse(v ?? '') == null ? 'Inserisci un numero' : null),
            ];
            if (constraints.maxWidth < 580) return Column(children: [for (final field in fields) Padding(padding: const EdgeInsets.only(bottom: 12), child: field)]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var i = 0; i < fields.length; i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i == 2 ? 0 : 12), child: fields[i]))]);
          }),
          const SizedBox(height: 7),
          const Text('Inserisci andata e ritorno. Gli orari di partenza sono separati da virgole; le fermate di riferimento una per riga nel formato “Nome fermata | HH:MM”.', style: TextStyle(color: JivaioColors.secondary, height: 1.45)),
          const SizedBox(height: 18),
          for (var i = 0; i < _directions.length; i++) ...[
            _DirectionForm(fields: _directions[i], label: i == 0 ? 'Andata' : 'Ritorno'),
            const SizedBox(height: 16),
          ],
        ])),
        const Divider(height: 1),
        Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')), const SizedBox(width: 8), FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Salva linea'))])),
      ])),
    ),
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final line = TransitLine(
      id: widget.line?.id ?? 'manual-${now.microsecondsSinceEpoch}',
      code: _code.text.trim(),
      name: _name.text.trim(),
      stopCount: int.parse(_stopCount.text),
      directions: _directions.map((fields) => fields.toDirection()).toList(),
      updatedAt: now,
      isManual: widget.line?.isManual ?? true,
    );
    Navigator.pop(context, line);
  }
}

class _DirectionFields {
  _DirectionFields({required String origin, required String destination, required String departures, required String stops})
      : origin = TextEditingController(text: origin),
        destination = TextEditingController(text: destination),
        departures = TextEditingController(text: departures),
        stops = TextEditingController(text: stops);
  final TextEditingController origin;
  final TextEditingController destination;
  final TextEditingController departures;
  final TextEditingController stops;
  void dispose() { origin.dispose(); destination.dispose(); departures.dispose(); stops.dispose(); }

  TransitDirection toDirection() {
    final parsedDepartures = departures.text.split(RegExp(r'[,;\s]+')).map((value) => value.trim()).where((value) => RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value)).toList();
    final parsedStops = stops.text.split('\n').map((line) {
      final parts = line.split('|');
      final name = parts.first.trim();
      if (name.isEmpty) return null;
      return TransitStopTime(stopId: 'manual-${name.hashCode}', name: name, time: parts.length > 1 ? parts.last.trim() : '--:--');
    }).whereType<TransitStopTime>().toList();
    if (parsedStops.isEmpty) {
      parsedStops.addAll([
        TransitStopTime(stopId: 'manual-origin-${origin.text.hashCode}', name: origin.text.trim(), time: parsedDepartures.isEmpty ? '--:--' : parsedDepartures.first),
        TransitStopTime(stopId: 'manual-destination-${destination.text.hashCode}', name: destination.text.trim(), time: '--:--'),
      ]);
    }
    return TransitDirection(id: 'manual-${DateTime.now().microsecondsSinceEpoch}', originName: origin.text.trim(), destinationName: destination.text.trim(), departures: parsedDepartures, stops: parsedStops);
  }
}

class _DirectionForm extends StatelessWidget {
  const _DirectionForm({required this.fields, required this.label});
  final _DirectionFields fields;
  final String label;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: JivaioColors.page, borderRadius: BorderRadius.circular(18), border: Border.all(color: JivaioColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 12),
    Row(children: [Expanded(child: TextFormField(controller: fields.origin, decoration: const InputDecoration(labelText: 'Partenza'), validator: _required)), const SizedBox(width: 12), Expanded(child: TextFormField(controller: fields.destination, decoration: const InputDecoration(labelText: 'Capolinea'), validator: _required))]),
    const SizedBox(height: 12),
    TextFormField(controller: fields.departures, decoration: const InputDecoration(labelText: 'Partenze', hintText: '06:30, 07:10, 07:45'), validator: (value) => (value ?? '').trim().isEmpty ? 'Inserisci almeno una partenza' : null),
    const SizedBox(height: 12),
    TextFormField(controller: fields.stops, minLines: 3, maxLines: 7, decoration: const InputDecoration(labelText: 'Fermate di riferimento', hintText: 'Terminalbus | 06:30\nPiazza Duomo | 06:38\nCapolinea | 07:05')),
  ]));
}

class _AlertEditor extends StatefulWidget {
  const _AlertEditor({this.alert});
  final ServiceAlert? alert;
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
  void dispose() { _title.dispose(); _summary.dispose(); _details.dispose(); _lines.dispose(); _source.dispose(); _sourceUrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(18),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700, maxHeight: 850), child: Form(key: _formKey, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(24, 20, 12, 10), child: Row(children: [Expanded(child: Text(widget.alert == null ? 'Nuovo avviso' : 'Modifica avviso', style: Theme.of(context).textTheme.titleLarge)), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))])),
      const Divider(height: 1),
      Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [
        TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Titolo'), validator: _required),
        const SizedBox(height: 12),
        TextFormField(controller: _summary, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Riepilogo'), validator: _required),
        const SizedBox(height: 12),
        TextFormField(controller: _details, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Dettagli')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: _severity, decoration: const InputDecoration(labelText: 'Priorità'), items: const [DropdownMenuItem(value: 'info', child: Text('Informazione')), DropdownMenuItem(value: 'warning', child: Text('Modifica servizio')), DropdownMenuItem(value: 'critical', child: Text('Importante'))], onChanged: (value) => setState(() => _severity = value ?? 'info')),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 8, children: [
          OutlinedButton.icon(onPressed: () => _pickDate(isStart: true), icon: const Icon(Icons.calendar_today_outlined), label: Text('Inizio: ${_formatDate(_startsAt)}')),
          OutlinedButton.icon(onPressed: () => _pickDate(isStart: false), icon: const Icon(Icons.event_available_outlined), label: Text(_endsAt == null ? 'Senza scadenza' : 'Fine: ${_formatDate(_endsAt!)}')),
        ]),
        const SizedBox(height: 12),
        TextFormField(controller: _lines, decoration: const InputDecoration(labelText: 'Linee coinvolte', hintText: 'Es. 12A, 13Z · vuoto = tutte')),
        const SizedBox(height: 12),
        TextFormField(controller: _source, decoration: const InputDecoration(labelText: 'Fonte / autore')),
        const SizedBox(height: 12),
        TextFormField(controller: _sourceUrl, decoration: const InputDecoration(labelText: 'Link fonte')),
        const SizedBox(height: 8),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Pubblica avviso'), value: _published, onChanged: (value) => setState(() => _published = value)),
      ])),
      const Divider(height: 1),
      Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')), const SizedBox(width: 8), FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Salva avviso'))])),
    ]))),
  );

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startsAt : (_endsAt ?? _startsAt);
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (!mounted) return;
    setState(() { if (isStart) { _startsAt = picked ?? _startsAt; } else { _endsAt = picked; } });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    Navigator.pop(context, ServiceAlert(
      id: widget.alert?.id ?? 'manual-alert-${now.microsecondsSinceEpoch}',
      title: _title.text.trim(), summary: _summary.text.trim(), details: _details.text.trim(), severity: _severity,
      startsAt: _startsAt, endsAt: _endsAt,
      sourceName: _source.text.trim().isEmpty ? null : _source.text.trim(),
      sourceUrl: _sourceUrl.text.trim().isEmpty ? null : _sourceUrl.text.trim(),
      affectedLines: _lines.text.split(',').map((value) => value.trim()).where((value) => value.isNotEmpty).toList(),
      isPublished: _published,
    ));
  }
}

class _AdminEmpty extends StatelessWidget {
  const _AdminEmpty({required this.title, required this.text});
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(30), child: Column(children: [const Icon(Icons.inbox_outlined, color: JivaioColors.muted, size: 32), const SizedBox(height: 9), Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 5), Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)])));
}

String? _required(String? value) => (value ?? '').trim().isEmpty ? 'Campo obbligatorio' : null;
String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
