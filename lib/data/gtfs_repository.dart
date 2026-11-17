import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/transit_models.dart';

class GtfsRepository {
  const GtfsRepository();

  static const _base = 'assets/gtfs/raw';

  Future<List<TransitLine>> loadLines() async {
    final loaded = await Future.wait([
      _readList('$_base/routes.json'),
      _readList('$_base/trips.json'),
      _readList('$_base/stops.json'),
      _readList('$_base/stop_times.json'),
      _readList('$_base/calendar.json'),
    ]);

    final routes = loaded[0];
    final trips = loaded[1];
    final stops = {
      for (final row in loaded[2])
        _text(row['stop_id']): _text(row['stop_name']),
    };
    TransitStopTime toStopTime(Map<String, dynamic> row) {
      final stopId = _text(row['stop_id']);
      final rawTime = _text(row['arrival_time']).isNotEmpty
          ? _text(row['arrival_time'])
          : _text(row['departure_time']);
      return TransitStopTime(
        stopId: stopId,
        name: stops[stopId] ?? 'Fermata',
        time: _displayTime(rawTime),
      );
    }

    final calendars = {
      for (final row in loaded[4]) _text(row['service_id']): row,
    };
    final timesByTrip = <String, List<Map<String, dynamic>>>{};
    for (final row in loaded[3]) {
      timesByTrip.putIfAbsent(_text(row['trip_id']), () => []).add(row);
    }
    for (final rows in timesByTrip.values) {
      rows.sort(
        (a, b) => _int(a['stop_sequence']).compareTo(_int(b['stop_sequence'])),
      );
    }

    final tripsByRoute = <String, List<Map<String, dynamic>>>{};
    for (final trip in trips) {
      tripsByRoute.putIfAbsent(_text(trip['route_id']), () => []).add(trip);
    }

    final routesById = {for (final row in routes) _text(row['route_id']): row};
    final routeIds = <String>{...routesById.keys, ...tripsByRoute.keys}.toList()
      ..sort(_naturalCompare);

    final result = <TransitLine>[];
    for (final routeId in routeIds) {
      final route = routesById[routeId];
      final allTrips = tripsByRoute[routeId] ?? const <Map<String, dynamic>>[];
      final grouped = <String, Map<String, List<Map<String, dynamic>>>>{};
      for (final trip in allTrips) {
        final tripTimes =
            timesByTrip[_text(trip['trip_id'])] ??
            const <Map<String, dynamic>>[];
        if (tripTimes.isEmpty) continue;
        final dir = _text(trip['direction_id']);
        final fallback =
            '${_text(tripTimes.first['stop_id'])}_${_text(tripTimes.last['stop_id'])}';
        final directionId = dir.isEmpty ? fallback : dir;
        final serviceId = _text(trip['service_id']);
        grouped
            .putIfAbsent(directionId, () => {})
            .putIfAbsent(serviceId, () => [])
            .add(trip);
      }

      final directions = <TransitDirection>[];
      final keys = grouped.keys.toList()
        ..sort(
          (a, b) =>
              int.tryParse(a)?.compareTo(int.tryParse(b) ?? 0) ??
              a.compareTo(b),
        );
      for (final directionId in keys) {
        final serviceGroups = grouped[directionId]!.entries.toList()
          ..sort(
            (a, b) => _serviceOrder(a.key).compareTo(_serviceOrder(b.key)),
          );
        for (final serviceGroup in serviceGroups) {
          final serviceId = serviceGroup.key;
          final directionTrips = serviceGroup.value;
          directionTrips.sort((a, b) {
            final ta = _firstTime(timesByTrip[_text(a['trip_id'])] ?? const []);
            final tb = _firstTime(timesByTrip[_text(b['trip_id'])] ?? const []);
            return _timeMinutes(ta).compareTo(_timeMinutes(tb));
          });
          final representative = directionTrips.reduce((a, b) {
            final countA =
                (timesByTrip[_text(a['trip_id'])] ?? const []).length;
            final countB =
                (timesByTrip[_text(b['trip_id'])] ?? const []).length;
            return countA >= countB ? a : b;
          });
          final departures =
              directionTrips
                  .map(
                    (trip) => _displayTime(
                      _firstTime(
                        timesByTrip[_text(trip['trip_id'])] ?? const [],
                      ),
                    ),
                  )
                  .where((time) => time.isNotEmpty)
                  .toList()
                ..sort((a, b) => _timeMinutes(a).compareTo(_timeMinutes(b)));
          final transitTrips = directionTrips
              .map((trip) {
                final tripId = _text(trip['trip_id']);
                final rows =
                    timesByTrip[tripId] ?? const <Map<String, dynamic>>[];
                return TransitTrip(
                  id: tripId,
                  departureTime: _displayTime(_firstTime(rows)),
                  headsign: _text(trip['trip_headsign']),
                  stops: rows.map(toStopTime).toList(),
                );
              })
              .where((trip) => trip.departureTime.isNotEmpty)
              .toList();
          final representativeTimes =
              timesByTrip[_text(representative['trip_id'])] ??
              const <Map<String, dynamic>>[];
          final stopRows = representativeTimes.map(toStopTime).toList();
          final stopPatterns = directionTrips.map((trip) {
            final rows =
                timesByTrip[_text(trip['trip_id'])] ??
                const <Map<String, dynamic>>[];
            return rows.map((row) => _text(row['stop_id'])).join('|');
          }).toSet();

          directions.add(
            TransitDirection(
              id: '${directionId}_$serviceId',
              originName: stopRows.isEmpty
                  ? _text(representative['trip_headsign'])
                  : stopRows.first.name,
              destinationName: stopRows.isEmpty
                  ? _text(representative['trip_headsign'])
                  : stopRows.last.name,
              departures: departures,
              stops: stopRows,
              serviceId: serviceId,
              serviceLabel: _serviceLabel(serviceId, calendars[serviceId]),
              dataWarning: stopPatterns.length > 1
                  ? 'Questo calendario include ${stopPatterns.length} varianti di percorso; ogni corsa conserva il proprio elenco di fermate.'
                  : null,
              trips: transitTrips,
            ),
          );
        }
      }

      if (directions.isEmpty) continue;
      final stopCount = directions
          .map((direction) => direction.stops.length)
          .fold<int>(0, (a, b) => a > b ? a : b);
      final missingRoute = route == null;
      final inferredCode = missingRoute ? _inferredCode(allTrips) : null;
      final missingRouteTrips = allTrips.length;
      final routeCode = route == null ? '' : _text(route['route_short_name']);
      final routeName = route == null ? '' : _text(route['route_long_name']);
      final isCircular =
          const {'A', 'B', 'EST', 'OVEST'}.contains(routeCode.toUpperCase()) ||
          routeName.toUpperCase().contains('NAVETTA EST') ||
          routeName.toUpperCase().contains('NAVETTA OVEST');
      result.add(
        TransitLine(
          id: routeId,
          code: missingRoute
              ? (inferredCode == null ? '$routeId?' : '$inferredCode?')
              : (_text(route['route_short_name']).isEmpty
                    ? routeId
                    : _text(route['route_short_name'])),
          name: missingRoute
              ? 'Linea da verificare (GTFS route_id $routeId)'
              : (_text(route['route_long_name']).isEmpty
                    ? 'Linea $routeId'
                    : _text(route['route_long_name'])),
          stopCount: stopCount,
          directions: directions,
          dataWarning: missingRoute
              ? 'Nel GTFS mancano i metadati di route_id $routeId. $missingRouteTrips corse lo usano${inferredCode == null ? '.' : '; i trip_headsign suggeriscono la linea $inferredCode, da confermare.'}'
              : null,
          isCircular: isCircular,
        ),
      );
    }

    result.sort((a, b) => _naturalCompare(a.code, b.code));
    return result;
  }

  Future<List<Map<String, dynamic>>> _readList(String path) async {
    final source = await rootBundle.loadString(path);
    final decoded = jsonDecode(source);
    if (decoded is! List) {
      throw FormatException('Il file $path non contiene una lista.');
    }
    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static String _serviceLabel(
    String serviceId,
    Map<String, dynamic>? calendar,
  ) {
    if (calendar == null) return transitServiceLabel(serviceId);
    final days = <String>[
      if (_text(calendar['monday']) == '1') 'lun',
      if (_text(calendar['tuesday']) == '1') 'mar',
      if (_text(calendar['wednesday']) == '1') 'mer',
      if (_text(calendar['thursday']) == '1') 'gio',
      if (_text(calendar['friday']) == '1') 'ven',
      if (_text(calendar['saturday']) == '1') 'sab',
      if (_text(calendar['sunday']) == '1') 'dom',
    ];
    if (days.join(',') == 'lun,mar,mer,gio,ven') return 'Feriale (lun–ven)';
    if (days.join(',') == 'sab') return 'Sabato';
    if (days.join(',') == 'dom') return 'Festivo';
    if (days.join(',') == 'gio,sab') return 'Notturno (gio–sab)';
    return days.isEmpty ? transitServiceLabel(serviceId) : days.join(' · ');
  }

  static int _serviceOrder(String serviceId) => switch (serviceId) {
    '1' => 0,
    '2' => 1,
    'FESTIVO' => 2,
    'NIGHT_THSAT' => 3,
    _ => 4,
  };

  static String? _inferredCode(List<Map<String, dynamic>> trips) {
    final leadingNumbers = trips
        .map(
          (trip) =>
              RegExp(r'^\s*(\d+)')
                  .firstMatch(_text(trip['trip_headsign']))
                  ?.group(1),
        )
        .whereType<String>()
        .toSet();
    return leadingNumbers.length == 1 ? leadingNumbers.first : null;
  }

  static String _firstTime(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return '';
    return _text(rows.first['departure_time']).isNotEmpty
        ? _text(rows.first['departure_time'])
        : _text(rows.first['arrival_time']);
  }

  static String _displayTime(String value) {
    if (value.length < 5) return value;
    return value.substring(0, 5);
  }

  static int _timeMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
  static int _int(Object? value) => int.tryParse(_text(value)) ?? 0;

  static int _naturalCompare(String a, String b) {
    final numberA = int.tryParse(a);
    final numberB = int.tryParse(b);
    if (numberA != null && numberB != null) return numberA.compareTo(numberB);
    if (numberA != null) return -1;
    if (numberB != null) return 1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  }
}
