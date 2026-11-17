import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../data/jivaio_store.dart';
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

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      store: widget.store,
      child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => PageFrame(
          width: 1180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestione JiVaio',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Modifica i dati di anteprima dal browser.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _exportSnapshot,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Esporta backup'),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.onSignOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Esci'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _AdminNotice(),
              const SizedBox(height: 20),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Linee'),
                    icon: Icon(Icons.directions_bus_outlined),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Avvisi'),
                    icon: Icon(Icons.campaign_outlined),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (value) =>
                    setState(() => _tab = value.first),
              ),
              const SizedBox(height: 18),
              if (_tab == 0) _linesPanel(context) else _alertsPanel(context),
              const SizedBox(height: 26),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/lines'),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Apri anteprima pubblica'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _resetPreview,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Ripristina dati iniziali'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linesPanel(BuildContext context) {
    final lines = [...widget.store.lines]
      ..sort((a, b) => a.code.toLowerCase().compareTo(b.code.toLowerCase()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${lines.length} linee',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _editLine(),
              icon: const Icon(Icons.add),
              label: const Text('Nuova linea'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (lines.isEmpty) ...[
          const _AdminEmpty(
            title: 'Non ci sono linee',
            text: 'Aggiungi la prima linea o importa il GTFS aggiornato.',
          ),
        ] else ...[
          Card(
            child: Column(
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  _LineAdminRow(
                    line: lines[i],
                    onEdit: () => _editLine(lines[i]),
                    onDelete: () => _deleteLine(lines[i]),
                  ),
                  if (i != lines.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _alertsPanel(BuildContext context) {
    final alerts = [...widget.store.alerts]
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${alerts.length} avvisi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _editAlert(),
              icon: const Icon(Icons.add),
              label: const Text('Nuovo avviso'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (alerts.isEmpty) ...[
          const _AdminEmpty(
            title: 'Nessun avviso',
            text: 'Crea un avviso quando il servizio subisce modifiche.',
          ),
        ] else ...[
          Card(
            child: Column(
              children: [
                for (var i = 0; i < alerts.length; i++) ...[
                  _AlertAdminRow(
                    alert: alerts[i],
                    onEdit: () => _editAlert(alerts[i]),
                    onDelete: () => _deleteAlert(alerts[i]),
                  ),
                  if (i != alerts.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _editLine([TransitLine? line]) async {
    final result = await showDialog<TransitLine>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LineEditor(line: line),
    );
    if (result != null) widget.store.saveLine(result);
  }

  Future<void> _editAlert([ServiceAlert? alert]) async {
    final result = await showDialog<ServiceAlert>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AlertEditor(alert: alert),
    );
    if (result != null) widget.store.saveAlert(result);
  }

  Future<void> _deleteLine(TransitLine line) async {
    final confirmed = await _confirm(
      'Eliminare la linea ${line.code}?',
      'La rimozione vale solo per questa anteprima nel browser.',
    );
    if (confirmed) widget.store.removeLine(line.id);
  }

  Future<void> _deleteAlert(ServiceAlert alert) async {
    final confirmed = await _confirm(
      'Eliminare questo avviso?',
      'La rimozione vale solo per questa anteprima nel browser.',
    );
    if (confirmed) widget.store.removeAlert(alert.id);
  }

  Future<void> _resetPreview() async {
    final confirmed = await _confirm(
      'Ripristinare i dati iniziali?',
      'Le modifiche salvate in questo browser verranno rimosse.',
    );
    if (confirmed) {
      widget.store.resetPreview();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anteprima ripristinata.')),
        );
      }
    }
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Conferma'),
            ),
          ],
        ),
      ) ??
      false;

  void _exportSnapshot() {
    final json = const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'lines': widget.store.lines.map((line) => line.toJson()).toList(),
      'alerts': widget.store.alerts.map((alert) => alert.toJson()).toList(),
    });
    final uri = Uri.dataFromString(
      json,
      mimeType: 'application/json',
      encoding: utf8,
    );
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = uri.toString()
      ..download =
          'jivaio-backup-${DateTime.now().toIso8601String().substring(0, 10)}.json';
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Backup JSON scaricato.')));
  }
}

class _AdminNotice extends StatelessWidget {
  const _AdminNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF2DDAE)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.phonelink_outlined, color: Color(0xFF95620B)),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'Modalità anteprima: le modifiche sono salvate solo in questo browser. L’accesso è riservato agli account abilitati; il database condiviso verrà collegato in una fase successiva.',
            style: TextStyle(color: Color(0xFF755214), height: 1.45),
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
  });
  final TransitLine line;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
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
          child: Text(
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
              Text(line.name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${line.directions.length} gruppi ${line.isCircular ? 'circuito' : 'direzione'}/orario · ${line.stopCount} fermate${line.isManual ? ' · inserita a mano' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (line.dataWarning != null) ...[
                const SizedBox(height: 5),
                Text(
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
          tooltip: 'Modifica',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Elimina',
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
              Text(alert.title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${alert.isPublished ? 'Pubblicato' : 'Bozza'} · ${alert.severity} · ${alert.affectedLines.isEmpty ? 'tutte le linee' : alert.affectedLines.join(', ')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Modifica',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Elimina',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: JivaioColors.danger),
        ),
      ],
    ),
  );
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
  late bool _isCircular;

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
                    child: Text(
                      widget.line == null
                          ? 'Nuova linea'
                          : 'Modifica linea ${widget.line!.code}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
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
                          decoration: const InputDecoration(
                            labelText: 'Codice linea',
                            hintText: 'Es. 2U',
                          ),
                          validator: _required,
                          onChanged: (value) {
                            if (_requiresCircular(value) && !_isCircular) {
                              setState(() => _isCircular = true);
                            }
                          },
                        ),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Nome linea',
                            hintText: 'Es. Terminalbus – L’Aquilone',
                          ),
                          validator: _required,
                        ),
                        TextFormField(
                          controller: _stopCount,
                          decoration: const InputDecoration(
                            labelText: 'Numero fermate',
                            hintText: 'Es. 24',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => int.tryParse(v ?? '') == null
                              ? 'Inserisci un numero'
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
                    title: const Text('Linea circolare / ad anello'),
                    subtitle: const Text(
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
                  Text(
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
                    label: Text(
                      _isCircular
                          ? 'Aggiungi circuito per un altro calendario'
                          : 'Aggiungi andata e ritorno per un altro calendario',
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salva linea'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    );
    Navigator.pop(context, line);
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
        title: const Text('Aggiungi orari per'),
        children: [
          for (final option in _serviceOptions)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option.$1),
              child: Text(option.$2),
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
  }) : departureTime = TextEditingController(text: departureTime),
       headsign = TextEditingController(text: headsign),
       stops = [...stops];

  factory _TripFields.fromTrip(TransitTrip trip) => _TripFields(
    id: trip.id,
    departureTime: trip.departureTime,
    headsign: trip.headsign,
    stops: trip.stops,
  );

  final String id;
  final TextEditingController departureTime;
  final TextEditingController headsign;
  List<TransitStopTime> stops;

  TransitTrip toTransitTrip() => TransitTrip(
    id: id,
    departureTime: _normalizeTime(departureTime.text),
    headsign: headsign.text.trim(),
    stops: stops,
  );

  void dispose() {
    departureTime.dispose();
    headsign.dispose();
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
  ('NIGHT_THSAT', 'Notturno (gio–sab)'),
];

class _DirectionForm extends StatelessWidget {
  const _DirectionForm({
    required this.fields,
    required this.label,
    required this.isCircular,
    required this.onAddTrip,
    required this.onEditTripStops,
    required this.onRemoveTrip,
    required this.onServiceChanged,
    this.onRemoveDirection,
  });
  final _DirectionFields fields;
  final String label;
  final bool isCircular;
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
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (onRemoveDirection != null)
              IconButton(
                tooltip: 'Rimuovi questo circuito',
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
          decoration: const InputDecoration(labelText: 'Validità degli orari'),
          items: [
            for (final option in _serviceOptions)
              DropdownMenuItem(value: option.$1, child: Text(option.$2)),
          ],
          onChanged: (value) {
            if (value != null) onServiceChanged(value);
          },
        ),
        const SizedBox(height: 16),
        Text(
          isCircular
              ? 'Ogni partenza del circuito può iniziare da una fermata diversa.'
              : 'Ogni partenza può avere un percorso e orari intermedi diversi.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        if (fields.trips.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Nessuna corsa inserita per questo calendario.'),
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
            label: const Text('Aggiungi partenza'),
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
                child: TextFormField(
                  controller: trip.departureTime,
                  decoration: const InputDecoration(
                    labelText: 'Ora di partenza',
                    hintText: '07:15',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  keyboardType: TextInputType.datetime,
                  validator: _validateOptionalTime,
                ),
              ),
              IconButton(
                tooltip: 'Elimina partenza',
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
            Text(
              'Parte da ${trip.stops.first.name} · ${trip.stops.length} fermate${trip.headsign.text.trim().isEmpty ? '' : ' · ${trip.headsign.text.trim()}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 7),
          OutlinedButton.icon(
            onPressed: onEditStops,
            icon: const Icon(Icons.route_outlined),
            label: Text(
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
            (stop) => '${stop.name} | ${stop.time == '--:--' ? '' : stop.time}',
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
      final enteredTime = parts.length > 1 ? parts[1].trim() : '';
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
        ),
      );
    }
    Navigator.pop(
      context,
      _TripRoute(stops: parsedStops, headsign: _headsign.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Percorso di questa partenza'),
    content: SizedBox(
      width: 620,
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Inserisci tutte le fermate in ordine. La prima fermata può cambiare da una partenza all’altra.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _headsign,
              decoration: const InputDecoration(
                labelText: 'Destinazione mostrata (facoltativa)',
                hintText: 'Es. Ospedale',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stops,
              minLines: 9,
              maxLines: 16,
              decoration: const InputDecoration(
                labelText: 'Fermate e orari intermedi',
                hintText: 'Terminalbus | 07:15\nPiazza Duomo | 07:22\nOspedale | 07:40',
                alignLabelWithHint: true,
              ),
              validator: _validateStopRows,
            ),
            const SizedBox(height: 8),
            Text(
              'Formato: Nome fermata | HH:MM, una fermata per riga. Se lasci vuoto l’orario della prima fermata useremo quello di partenza.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Salva percorso'),
      ),
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
          child: Text(
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
      final time = parts[1].trim();
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
                    child: Text(
                      widget.alert == null ? 'Nuovo avviso' : 'Modifica avviso',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
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
                    decoration: const InputDecoration(labelText: 'Titolo'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _summary,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Riepilogo'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _details,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: 'Dettagli'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _severity,
                    decoration: const InputDecoration(labelText: 'Priorità'),
                    items: const [
                      DropdownMenuItem(
                        value: 'info',
                        child: Text('Informazione'),
                      ),
                      DropdownMenuItem(
                        value: 'warning',
                        child: Text('Modifica servizio'),
                      ),
                      DropdownMenuItem(
                        value: 'critical',
                        child: Text('Importante'),
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
                        label: Text('Inizio: ${_formatDate(_startsAt)}'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(isStart: false),
                        icon: const Icon(Icons.event_available_outlined),
                        label: Text(
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
                    decoration: const InputDecoration(
                      labelText: 'Linee coinvolte',
                      hintText: 'Es. 12A, 13Z · vuoto = tutte',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _source,
                    decoration: const InputDecoration(
                      labelText: 'Fonte / autore',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sourceUrl,
                    decoration: const InputDecoration(labelText: 'Link fonte'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pubblica avviso'),
                    value: _published,
                    onChanged: (value) => setState(() => _published = value),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salva avviso'),
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    Navigator.pop(
      context,
      ServiceAlert(
        id: widget.alert?.id ?? 'manual-alert-${now.microsecondsSinceEpoch}',
        title: _title.text.trim(),
        summary: _summary.text.trim(),
        details: _details.text.trim(),
        severity: _severity,
        startsAt: _startsAt,
        endsAt: _endsAt,
        sourceName: _source.text.trim().isEmpty ? null : _source.text.trim(),
        sourceUrl: _sourceUrl.text.trim().isEmpty
            ? null
            : _sourceUrl.text.trim(),
        affectedLines: _lines.text
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
        isPublished: _published,
      ),
    );
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
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          Text(
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
