import 'package:flutter/material.dart';

import '../data/jivaio_store.dart';
import '../models/transit_models.dart';
import '../theme/jivaio_theme.dart';
import 'jivaio_app.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.store, super.key});
  final JivaioStore store;

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      store: store,
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) => PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PreviewNotice(store: store),
              const SizedBox(height: 28),
              _HomeHero(
                onOpenLines: () => Navigator.of(context).pushNamed('/lines'),
              ),
              const SizedBox(height: 28),
              if (store.visibleAlerts.isNotEmpty) ...[
                _SectionTitle(
                  title: 'Avvisi di servizio',
                  action: 'Tutti gli avvisi',
                  onTap: () => Navigator.of(context).pushNamed('/alerts'),
                ),
                const SizedBox(height: 14),
                AlertCard(alert: store.visibleAlerts.first, compact: true),
                const SizedBox(height: 30),
              ],
              _SectionTitle(
                title: 'Esplora le linee',
                action: 'Elenco completo',
                onTap: () => Navigator.of(context).pushNamed('/lines'),
              ),
              const SizedBox(height: 14),
              if (store.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (store.visibleLines.isEmpty)
                const _EmptyState(
                  title: 'Nessuna linea disponibile',
                  subtitle: 'Aggiungi una linea dal gestionale per iniziare.',
                  icon: Icons.directions_bus_outlined,
                )
              else
                _LineGrid(
                  pairs: _directionPairs(store.visibleLines).take(4).toList(),
                  store: store,
                ),
              const SizedBox(height: 24),
              const _LocalDataCaption(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.onOpenLines});
  final VoidCallback onOpenLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF2FF), Color(0xFFDCEAFF)],
        ),
        border: Border.all(color: const Color(0xFFD5E4F9)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              ExpandedIfWide(
                wide: !compact,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Muoviti meglio\ncon JiVaio',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontSize: compact ? 34 : 42),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Consulta linee, orari e avvisi del trasporto pubblico a L’Aquila.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 17,
                        color: JivaioColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: onOpenLines,
                      icon: const Icon(Icons.directions_bus_outlined),
                      label: const Text('Consulta le linee'),
                    ),
                  ],
                ),
              ),
              if (!compact) const SizedBox(width: 30),
              if (!compact) const _HeroArtwork(),
            ],
          );
        },
      ),
    );
  }
}

class ExpandedIfWide extends StatelessWidget {
  const ExpandedIfWide({required this.wide, required this.child, super.key});
  final bool wide;
  final Widget child;
  @override
  Widget build(BuildContext context) => wide ? Expanded(child: child) : child;
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 28,
            left: 28,
            child: Icon(
              Icons.route_outlined,
              color: Color(0xFF8BB5F3),
              size: 48,
            ),
          ),
          Positioned(
            bottom: 30,
            right: 30,
            child: Container(
              width: 138,
              height: 72,
              decoration: BoxDecoration(
                color: JivaioColors.blue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
          const Positioned(
            left: 60,
            bottom: 60,
            child: Icon(Icons.location_on, color: JivaioColors.navy, size: 24),
          ),
          const Positioned(
            right: 52,
            top: 43,
            child: Icon(Icons.location_on, color: JivaioColors.blue, size: 24),
          ),
          Positioned(
            left: 91,
            top: 64,
            child: Container(
              width: 100,
              height: 2,
              color: const Color(0xFF8BB5F3),
            ),
          ),
        ],
      ),
    );
  }
}

class LinesPage extends StatefulWidget {
  const LinesPage({required this.store, super.key});
  final JivaioStore store;

  @override
  State<LinesPage> createState() => _LinesPageState();
}

class _LinesPageState extends State<LinesPage> {
  late final TextEditingController _search = TextEditingController();
  bool _savedOnly = false;
  bool _routeArgumentRead = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgumentRead) return;
    _routeArgumentRead = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String) _search.text = arg;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      store: widget.store,
      child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final pairs = _directionPairs(widget.store.visibleLines).where((
            pair,
          ) {
            final query = _search.text.trim().toLowerCase();
            final matchesSearch =
                query.isEmpty ||
                '${pair.line.code} ${pair.line.name} ${pair.direction.originName} ${pair.direction.destinationName}'
                    .toLowerCase()
                    .contains(query);
            return matchesSearch &&
                (!_savedOnly || widget.store.isFavorite(pair.line.id));
          }).toList();
          return PageFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeading(
                  title: 'Elenco linee',
                  subtitle: 'Consulta le linee disponibili e apri il dettaglio completo.',
                ),
                const SizedBox(height: 24),
                PreviewNotice(store: widget.store),
                const SizedBox(height: 18),
                _LineFilters(
                  controller: _search,
                  savedOnly: _savedOnly,
                  onSavedChanged: (value) => setState(() => _savedOnly = value),
                  onSearchChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                if (widget.store.isLoading) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else if (pairs.isEmpty) ...[
                  _EmptyState(
                    title: _savedOnly
                        ? 'Nessuna linea salvata'
                        : 'Nessuna linea trovata',
                    subtitle: _savedOnly
                        ? 'Tocca il cuore su una linea per ritrovarla qui.'
                        : 'Prova a cambiare la ricerca.',
                    icon: Icons.search_off,
                  ),
                ] else ...[
                  Text(
                    '${pairs.length} direzioni',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _LineGrid(pairs: pairs, store: widget.store),
                ],
                const SizedBox(height: 24),
                const _LocalDataCaption(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LineFilters extends StatelessWidget {
  const _LineFilters({
    required this.controller,
    required this.savedOnly,
    required this.onSavedChanged,
    required this.onSearchChanged,
  });
  final TextEditingController controller;
  final bool savedOnly;
  final ValueChanged<bool> onSavedChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          controller: controller,
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Cerca linea, fermata o destinazione',
          ),
        );
        final toggle = SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Tutte'),
              icon: Icon(Icons.format_list_bulleted),
            ),
            ButtonSegment(
              value: true,
              label: Text('Salvate'),
              icon: Icon(Icons.favorite_border),
            ),
          ],
          selected: {savedOnly},
          onSelectionChanged: (values) => onSavedChanged(values.first),
          showSelectedIcon: false,
        );
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [search, const SizedBox(height: 12), toggle],
          );
        }
        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 16),
            toggle,
          ],
        );
      },
    );
  }
}

class _LineGrid extends StatelessWidget {
  const _LineGrid({required this.pairs, required this.store});
  final List<_LineDirectionPair> pairs;
  final JivaioStore store;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000 ? 2 : 1;
        final width = columns == 2
            ? (constraints.maxWidth - 18) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            for (final pair in pairs)
              SizedBox(
                width: width,
                child: _LineCard(pair: pair, store: store),
              ),
          ],
        );
      },
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({required this.pair, required this.store});
  final _LineDirectionPair pair;
  final JivaioStore store;

  @override
  Widget build(BuildContext context) {
    final line = pair.line;
    final direction = pair.direction;
    final directionIndex = _publicDirections(line).indexOf(direction);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 58,
                    minHeight: 58,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: JivaioColors.blue,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Text(
                    line.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Linea ${line.code}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 7),
                      _SmallPill(
                        icon: Icons.location_on,
                        label:
                            '${direction.stops.isEmpty ? line.stopCount : direction.stops.length} fermate',
                      ),
                      if (direction.serviceLabel.isNotEmpty ||
                          line.isCircular) ...[
                        const SizedBox(height: 6),
                        _SmallPill(
                          icon: Icons.calendar_month_outlined,
                          label: _directionServiceTitle(
                            line,
                            direction,
                            directionIndex,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: store.isFavorite(line.id)
                      ? 'Rimuovi dai preferiti'
                      : 'Salva linea',
                  onPressed: () => store.toggleFavorite(line.id),
                  icon: Icon(
                    store.isFavorite(line.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: store.isFavorite(line.id)
                        ? JivaioColors.danger
                        : JivaioColors.muted,
                    size: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DirectionBox(
              origin: direction.originName,
              destination: direction.destinationName,
              circular: line.isCircular,
            ),
            const SizedBox(height: 12),
            Text(
              'Prossime partenze',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: JivaioColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            if (direction.departures.isEmpty)
              const Text(
                'Orari da aggiornare',
                style: TextStyle(color: JivaioColors.secondary, fontSize: 14),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: direction.departures
                    .take(4)
                    .map(
                      (time) => _TimePill(
                        time: _departureLabel(line, direction, time),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(
                  '/line/${Uri.encodeComponent(line.id)}',
                  arguments: direction.id,
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Apri linea completa'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LineDetailPage extends StatefulWidget {
  const LineDetailPage({required this.store, required this.lineId, super.key});
  final JivaioStore store;
  final String lineId;

  @override
  State<LineDetailPage> createState() => _LineDetailPageState();
}

class _LineDetailPageState extends State<LineDetailPage> {
  final _selectedTrips = ValueNotifier<Map<String, int>>({});

  @override
  void didUpdateWidget(LineDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lineId != widget.lineId) _selectedTrips.value = {};
  }

  @override
  void dispose() {
    _selectedTrips.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      store: widget.store,
      child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final line = widget.store.visibleLineById(widget.lineId);
          if (line == null) {
            return PageFrame(
              child: _EmptyState(
                title: 'Linea non trovata',
                subtitle: 'Potrebbe essere stata rimossa dal gestionale.',
                icon: Icons.route_outlined,
              ),
            );
          }
          final requestedDirection =
              ModalRoute.of(context)?.settings.arguments as String?;
          final directions = _publicDirections(line);
          final initial = directions.indexWhere(
            (d) => d.id == requestedDirection,
          );
          return DefaultTabController(
            length: directions.length,
            initialIndex: initial < 0 ? 0 : initial,
            child: PageFrame(
              width: 1040,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Torna alle linee'),
                  ),
                  const SizedBox(height: 12),
                  PreviewNotice(store: widget.store),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: JivaioColors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          line.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              line.isCircular
                                  ? 'Linea ${line.code} · circolare · ${line.stopCount} fermate'
                                  : 'Linea ${line.code} · ${line.stopCount} fermate',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            _SelectedTripNote(
                              directions: directions,
                              selectedTrips: _selectedTrips,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => widget.store.toggleFavorite(line.id),
                        tooltip: 'Salva linea',
                        icon: Icon(
                          widget.store.isFavorite(line.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: JivaioColors.danger,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (line.dataWarning != null) ...[
                    _PublicDataWarning(text: line.dataWarning!),
                    const SizedBox(height: 16),
                  ],
                  if (directions.isEmpty)
                    const _EmptyState(
                      title: 'Orari non disponibili',
                      subtitle: 'Gli orari della linea sono in aggiornamento.',
                      icon: Icons.schedule_outlined,
                    )
                  else
                    Builder(
                      builder: (context) {
                        final tabs = [
                          for (var i = 0; i < directions.length; i++)
                            Tab(
                              text: line.isCircular
                                  ? _directionServiceTitle(
                                      line,
                                      directions[i],
                                      i,
                                    )
                                  : (directions[i].serviceLabel.isEmpty
                                        ? '${directions[i].originName} → ${directions[i].destinationName}'
                                        : '${directions[i].originName} → ${directions[i].destinationName}\n${directions[i].serviceLabel}'),
                            ),
                        ];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TabBar(isScrollable: true, tabs: tabs),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 680,
                              child: TabBarView(
                                children: directions
                                    .map(
                                      (direction) => _DirectionDetail(
                                        key: ValueKey(direction.id),
                                        direction: direction,
                                        line: line,
                                        isCircular: line.isCircular,
                                        initialTripIndex:
                                            _selectedTrips.value[direction
                                                .id] ??
                                            0,
                                        onTripSelected: (index) {
                                          _selectedTrips.value = {
                                            ..._selectedTrips.value,
                                            direction.id: index,
                                          };
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SelectedTripNote extends StatelessWidget {
  const _SelectedTripNote({
    required this.directions,
    required this.selectedTrips,
  });

  final List<TransitDirection> directions;
  final ValueNotifier<Map<String, int>> selectedTrips;

  @override
  Widget build(BuildContext context) {
    final tabs = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([tabs, selectedTrips]),
      builder: (context, _) {
        if (directions.isEmpty) return const SizedBox.shrink();
        final direction =
            directions[tabs.index.clamp(0, directions.length - 1)];
        if (direction.trips.isEmpty) return const SizedBox.shrink();
        final index = (selectedTrips.value[direction.id] ?? 0).clamp(
          0,
          direction.trips.length - 1,
        );
        final note = direction.trips[index].note.trim();
        if (note.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            note,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: JivaioColors.blue,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

class _DirectionDetail extends StatefulWidget {
  const _DirectionDetail({
    required this.direction,
    required this.line,
    required this.isCircular,
    required this.initialTripIndex,
    required this.onTripSelected,
    super.key,
  });
  final TransitDirection direction;
  final TransitLine line;
  final bool isCircular;
  final int initialTripIndex;
  final ValueChanged<int> onTripSelected;

  @override
  State<_DirectionDetail> createState() => _DirectionDetailState();
}

class _DirectionDetailState extends State<_DirectionDetail> {
  late int _selectedTripIndex;

  @override
  void initState() {
    super.initState();
    _selectedTripIndex = widget.initialTripIndex;
  }

  @override
  Widget build(BuildContext context) {
    final direction = widget.direction;
    final trips = direction.trips;
    final selectedTrip = trips.isEmpty
        ? null
        : trips[_selectedTripIndex.clamp(0, trips.length - 1).toInt()];
    final stops = selectedTrip?.stops ?? direction.stops;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  direction.serviceLabel.isEmpty
                      ? 'Orari di partenza'
                      : 'Orari di partenza · ${direction.serviceLabel}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                if (trips.isEmpty && direction.departures.isEmpty)
                  const Text('Nessun orario disponibile per questa direzione.')
                else
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: trips.isEmpty
                        ? direction.departures
                              .map(
                                (time) => _TimePill(
                                  time: _departureLabel(
                                    widget.line,
                                    direction,
                                    time,
                                  ),
                                  large: true,
                                ),
                              )
                              .toList()
                        : [
                            for (var i = 0; i < trips.length; i++)
                              ChoiceChip(
                                label: Text(
                                  _tripDepartureLabel(
                                    widget.line,
                                    direction,
                                    trips[i],
                                  ),
                                ),
                                selected: i == _selectedTripIndex,
                                onSelected: (_) {
                                  setState(() => _selectedTripIndex = i);
                                  widget.onTripSelected(i);
                                },
                              ),
                          ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          selectedTrip == null || selectedTrip.departureTime.isEmpty
              ? 'Percorso e orari di una corsa'
              : 'Corsa delle ${_tripDepartureLabel(widget.line, direction, selectedTrip)}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (selectedTrip != null && _isSchoolTrip(selectedTrip)) ...[
          const SizedBox(height: 6),
          Text(
            selectedTrip.headsign,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 12),
        if (direction.dataWarning != null &&
            !_hideLineAReviewWarning(widget.line, direction.dataWarning!)) ...[
          _PublicDataWarning(text: direction.dataWarning!),
          const SizedBox(height: 12),
        ],
        if (stops.isEmpty)
          const _EmptyState(
            title: 'Fermate non disponibili',
            subtitle: 'Aggiungi il percorso dal gestionale.',
            icon: Icons.location_off_outlined,
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < stops.length; i++)
                  _StopRow(
                    stop: stops[i],
                    first: i == 0,
                    last: i == stops.length - 1,
                    timeLabel: _stopTimeLabel(
                      widget.line,
                      direction,
                      selectedTrip,
                      stops[i],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(
          widget.isCircular
              ? 'Il percorso selezionato segue il circuito per questa partenza. Verifica sempre l’ultima pubblicazione AMA prima di partire.'
              : 'Il percorso selezionato corrisponde alla partenza scelta. Verifica sempre l’ultima pubblicazione AMA prima di partire.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class AlertsPage extends StatelessWidget {
  const AlertsPage({required this.store, super.key});
  final JivaioStore store;

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      store: store,
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) => PageFrame(
          width: 1000,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeading(
                title: 'Avvisi di servizio',
                subtitle: 'Aggiornamenti e variazioni del servizio pubblicati da JiVaio.',
              ),
              const SizedBox(height: 22),
              PreviewNotice(store: store),
              const SizedBox(height: 20),
              if (store.visibleAlerts.isEmpty)
                const _EmptyState(
                  title: 'Nessun avviso attivo',
                  subtitle: 'Al momento non risultano comunicazioni in corso.',
                  icon: Icons.campaign_outlined,
                )
              else
                ...store.visibleAlerts.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AlertCard(alert: alert),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  const AlertCard({required this.alert, super.key, this.compact = false});
  final ServiceAlert alert;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final critical = alert.severity == 'critical';
    final color = critical
        ? JivaioColors.danger
        : alert.severity == 'warning'
        ? JivaioColors.warning
        : JivaioColors.blue;
    final label = critical
        ? 'Importante'
        : alert.severity == 'warning'
        ? 'Modifica servizio'
        : 'Informazione';
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(alert.startsAt);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                critical
                    ? Icons.priority_high_rounded
                    : Icons.campaign_outlined,
                color: color,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 9,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        alert.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      _SmallPill(icon: Icons.circle, label: label, tint: color),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    alert.summary,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(fontSize: 15),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 11),
                    Text(
                      alert.details,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 11),
                  Wrap(
                    spacing: 12,
                    runSpacing: 7,
                    children: [
                      Text(
                        'Dal $date',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (alert.affectedLines.isNotEmpty)
                        Text(
                          'Linee ${alert.affectedLines.join(', ')}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      if (alert.sourceName != null)
                        Text(
                          alert.sourceName!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                  if (alert.sourceUrl != null && !compact) ...[
                    const SizedBox(height: 7),
                    SelectableText(
                      alert.sourceUrl!,
                      style: const TextStyle(
                        color: JivaioColors.blue,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionBox extends StatelessWidget {
  const _DirectionBox({
    required this.origin,
    required this.destination,
    this.circular = false,
  });
  final String origin;
  final String destination;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    if (circular) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: JivaioColors.border),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          children: [
            Icon(Icons.sync, color: JivaioColors.blue, size: 25),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Percorso circolare',
                    style: TextStyle(
                      color: JivaioColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'La fermata di partenza è indicata per ogni corsa',
                    style: TextStyle(
                      color: JivaioColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        border: Border.all(color: JivaioColors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Partenza',
                  style: TextStyle(
                    color: JivaioColors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  origin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: JivaioColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: JivaioColors.blueLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward, color: JivaioColors.blue),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Capolinea',
                  style: TextStyle(
                    color: JivaioColors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: JivaioColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.icon,
    required this.label,
    this.tint = JivaioColors.secondary,
  });
  final IconData icon;
  final String label;
  final Color tint;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: tint.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: tint.withValues(alpha: .16)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: tint),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: tint,
          ),
        ),
      ],
    ),
  );
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.time, this.large = false});
  final String time;
  final bool large;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: large ? 14 : 12,
      vertical: large ? 9 : 8,
    ),
    decoration: BoxDecoration(
      color: JivaioColors.blue,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      time,
      style: TextStyle(
        color: Colors.white,
        fontSize: large ? 15 : 14,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.first,
    required this.last,
    this.timeLabel,
  });
  final TransitStopTime stop;
  final bool first;
  final bool last;
  final String? timeLabel;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!first)
                  Positioned(
                    top: 0,
                    bottom: 29,
                    child: Container(width: 2, color: JivaioColors.border),
                  ),
                if (!last)
                  Positioned(
                    top: 29,
                    bottom: 0,
                    child: Container(width: 2, color: JivaioColors.border),
                  ),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: first || last ? JivaioColors.blue : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: JivaioColors.blue, width: 2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              stop.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: JivaioColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            timeLabel ?? stop.time,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              color: JivaioColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton(onPressed: onTap, child: Text(action)),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: JivaioColors.border),
    ),
    child: Column(
      children: [
        Icon(icon, size: 34, color: JivaioColors.muted),
        const SizedBox(height: 10),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

class _LocalDataCaption extends StatelessWidget {
  const _LocalDataCaption();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Text(
          'JiVaio è un progetto indipendente. Verifica sempre gli orari ufficiali AMA prima di partire.',
          style: TextStyle(color: JivaioColors.muted, fontSize: 12),
        ),
      ),
    ],
  );
}

class _LineDirectionPair {
  const _LineDirectionPair(this.line, this.direction);
  final TransitLine line;
  final TransitDirection direction;
}

bool _isLineAWeekday(TransitLine line, TransitDirection direction) =>
    line.code.trim().toUpperCase() == 'A' &&
    (direction.serviceId == '1' || direction.serviceId.isEmpty);

String _serviceTimeLabel(TransitDirection direction, String time) {
  if (direction.serviceId != 'NIGHT_THSAT') return time;
  final match = RegExp(r'^(\d{1,2}):([0-5]\d)$').firstMatch(time.trim());
  if (match == null) return time;
  final hour = int.parse(match.group(1)!);
  if (hour < 24 || hour > 47) return time;
  return '${(hour - 24).toString().padLeft(2, '0')}:${match.group(2)}';
}

String _departureLabel(
  TransitLine line,
  TransitDirection direction,
  String time,
) =>
    _isLineAWeekday(line, direction) &&
        (time.trim() == '06:30' || time.trim() == '6:30')
    ? '$time (6S)'
    : _serviceTimeLabel(direction, time);

bool _isSchoolTrip(TransitTrip trip) =>
    trip.headsign.trim().toLowerCase().startsWith('corsa scolastica');

String _tripDepartureLabel(
  TransitLine line,
  TransitDirection direction,
  TransitTrip trip,
) {
  final time = _departureLabel(line, direction, trip.departureTime);
  return _isSchoolTrip(trip) ? '$time (scolastica)' : time;
}

bool _hideLineAReviewWarning(TransitLine line, String warning) =>
    line.code.trim().toUpperCase() == 'A' &&
    warning.contains('La corsa delle 06:30 ha un orario stimato:');

String _stopTimeLabel(
  TransitLine line,
  TransitDirection direction,
  TransitTrip? trip,
  TransitStopTime stop,
) {
  final isLineAEstimate =
      _isLineAWeekday(line, direction) &&
      (trip?.departureTime == '06:30' || trip?.departureTime == '6:30') &&
      (direction.dataWarning?.contains('S.S. 80 alle 06:47') ?? false) &&
      stop.name.toUpperCase().replaceAll(' ', '').contains('S.S.80') &&
      stop.time == '06:47';
  final time = _serviceTimeLabel(direction, stop.time);
  if (stop.isEstimated &&
      (line.code.trim().toUpperCase() == 'NB' ||
          direction.serviceId == 'NIGHT_THSAT')) {
    return '$time\norario previsto (stima)';
  }
  return stop.isEstimated || isLineAEstimate ? '$time (stimato)' : time;
}

List<_LineDirectionPair> _directionPairs(List<TransitLine> lines) => [
  for (final line in lines) ..._uniqueDirectionPairs(line),
];

List<_LineDirectionPair> _uniqueDirectionPairs(TransitLine line) {
  if (line.isCircular) {
    return _publicDirections(line)
        .map((direction) => _LineDirectionPair(line, direction))
        .toList();
  }
  final seen = <String>{};
  return [
    for (final direction in line.directions)
      if (seen.add(
        '${direction.originName.trim().toLowerCase()}|${direction.destinationName.trim().toLowerCase()}',
      ))
        _LineDirectionPair(line, direction),
  ];
}

List<TransitDirection> _publicDirections(TransitLine line) {
  if (line.code.trim().toUpperCase() != 'B') return line.directions;
  return line.directions.where((direction) {
    final serviceId = direction.serviceId.trim();
    final label = direction.serviceLabel.trim().toLowerCase();
    return serviceId.isNotEmpty && label != 'orari generali';
  }).toList();
}

String _directionServiceTitle(
  TransitLine line,
  TransitDirection direction,
  int directionIndex,
) {
  final sameCalendar = _publicDirections(line)
      .asMap()
      .entries
      .where((entry) => entry.value.serviceId == direction.serviceId)
      .toList();
  final variant =
      sameCalendar.indexWhere((entry) => entry.key == directionIndex) + 1;
  final calendar = direction.serviceLabel.isEmpty
      ? 'Orari generali'
      : direction.serviceLabel;
  return sameCalendar.length > 1
      ? 'Circuito $variant · $calendar'
      : 'Circuito · $calendar';
}

class _PublicDataWarning extends StatelessWidget {
  const _PublicDataWarning({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF2DDAE)),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Color(0xFF755214), height: 1.4),
    ),
  );
}
