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
      _readList('$_base/calendar_dates.json'),
    ]);

    final routes = loaded[0];
    final trips = loaded[1];
    final stops = {for (final row in loaded[2]) _text(row['stop_id']): _text(row['stop_name'])};
    final timesByTrip = <String, List<Map<String, dynamic>>>{};
    for (final row in loaded[3]) {
      timesByTrip.putIfAbsent(_text(row['trip_id']), () => []).add(row);
    }
    for (final rows in timesByTrip.values) {
      rows.sort((a, b) => _int(a['stop_sequence']).compareTo(_int(b['stop_sequence'])));
    }

    final activeServices = _activeServices(loaded[4], loaded[5], DateTime.now());
    final tripsByRoute = <String, List<Map<String, dynamic>>>{};
    for (final trip in trips) {
      tripsByRoute.putIfAbsent(_text(trip['route_id']), () => []).add(trip);
    }

    final result = <TransitLine>[];
    for (final route in routes) {
      final routeId = _text(route['route_id']);
      final allTrips = tripsByRoute[routeId] ?? const <Map<String, dynamic>>[];
      final activeTrips = allTrips.where((trip) => activeServices.contains(_text(trip['service_id']))).toList();
      final usableTrips = activeTrips.isNotEmpty ? activeTrips : allTrips;
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final trip in usableTrips) {
        final tripTimes = timesByTrip[_text(trip['trip_id'])] ?? const <Map<String, dynamic>>[];
        if (tripTimes.isEmpty) continue;
        final dir = _text(trip['direction_id']);
        final fallback = '${_text(tripTimes.first['stop_id'])}_${_text(tripTimes.last['stop_id'])}';
        grouped.putIfAbsent(dir.isEmpty ? fallback : dir, () => []).add(trip);
      }

      final directions = <TransitDirection>[];
      final keys = grouped.keys.toList()
        ..sort((a, b) => int.tryParse(a)?.compareTo(int.tryParse(b) ?? 0) ?? a.compareTo(b));
      for (final directionId in keys) {
        final directionTrips = grouped[directionId]!;
        directionTrips.sort((a, b) {
          final ta = _firstTime(timesByTrip[_text(a['trip_id'])] ?? const []);
          final tb = _firstTime(timesByTrip[_text(b['trip_id'])] ?? const []);
          return _timeMinutes(ta).compareTo(_timeMinutes(tb));
        });
        final representative = directionTrips.reduce((a, b) {
          final countA = (timesByTrip[_text(a['trip_id'])] ?? const []).length;
          final countB = (timesByTrip[_text(b['trip_id'])] ?? const []).length;
          return countA >= countB ? a : b;
        });
        final departures = directionTrips
            .map((trip) => _displayTime(_firstTime(timesByTrip[_text(trip['trip_id'])] ?? const [])))
            .where((time) => time.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => _timeMinutes(a).compareTo(_timeMinutes(b)));
        final timesToday = departures.where((time) => _timeMinutes(time) >= _currentMinutes()).toList();
        final visibleDepartures = (timesToday.isNotEmpty ? timesToday : departures).take(4).toList();
        final selectedDeparture = visibleDepartures.isEmpty ? '' : visibleDepartures.first;
        final matchingTrip = directionTrips.where((trip) {
          final firstTime = _firstTime(timesByTrip[_text(trip['trip_id'])] ?? const []);
          return _displayTime(firstTime) == selectedDeparture;
        });
        final displayTrip = matchingTrip.isEmpty ? representative : matchingTrip.first;
        final representativeTimes = timesByTrip[_text(displayTrip['trip_id'])] ?? const <Map<String, dynamic>>[];
        final stopRows = representativeTimes.map((row) {
          final stopId = _text(row['stop_id']);
          final rawTime = _text(row['arrival_time']).isNotEmpty
              ? _text(row['arrival_time'])
              : _text(row['departure_time']);
          return TransitStopTime(
            stopId: stopId,
            name: stops[stopId] ?? 'Fermata',
            time: _displayTime(rawTime),
          );
        }).toList();

        directions.add(TransitDirection(
          id: directionId,
          originName: stopRows.isEmpty ? _text(representative['trip_headsign']) : stopRows.first.name,
          destinationName: stopRows.isEmpty ? _text(representative['trip_headsign']) : stopRows.last.name,
          departures: visibleDepartures,
          stops: stopRows,
        ));
      }

      if (directions.isEmpty) continue;
      final stopCount = directions.map((direction) => direction.stops.length).fold<int>(0, (a, b) => a > b ? a : b);
      result.add(TransitLine(
        id: routeId,
        code: _text(route['route_short_name']).isEmpty ? routeId : _text(route['route_short_name']),
        name: _text(route['route_long_name']).isEmpty ? 'Linea $routeId' : _text(route['route_long_name']),
        stopCount: stopCount,
        directions: directions,
      ));
    }

    result.sort((a, b) => _naturalCompare(a.code, b.code));
    return result;
  }

  Future<List<Map<String, dynamic>>> _readList(String path) async {
    final source = await rootBundle.loadString(path);
    final decoded = jsonDecode(source);
    if (decoded is! List) throw FormatException('Il file $path non contiene una lista.');
    return decoded.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Set<String> _activeServices(
    List<Map<String, dynamic>> calendars,
    List<Map<String, dynamic>> exceptions,
    DateTime date,
  ) {
    final ids = <String>{};
    final today = DateTime(date.year, date.month, date.day);
    final weekdayField = switch (date.weekday) {
      DateTime.monday => 'monday',
      DateTime.tuesday => 'tuesday',
      DateTime.wednesday => 'wednesday',
      DateTime.thursday => 'thursday',
      DateTime.friday => 'friday',
      DateTime.saturday => 'saturday',
      _ => 'sunday',
    };
    for (final row in calendars) {
      final start = _gtfsDate(_text(row['start_date']));
      final end = _gtfsDate(_text(row['end_date']));
      if (start == null || end == null || today.isBefore(start) || today.isAfter(end)) continue;
      if (_text(row[weekdayField]) == '1') ids.add(_text(row['service_id']));
    }
    for (final row in exceptions) {
      if (_gtfsDate(_text(row['date'])) != today) continue;
      final serviceId = _text(row['service_id']);
      if (_text(row['exception_type']) == '1') {
        ids.add(serviceId);
      } else {
        ids.remove(serviceId);
      }
    }
    return ids;
  }

  static DateTime? _gtfsDate(String value) {
    if (value.length != 8) return null;
    return DateTime.tryParse('${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6, 8)}');
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

  static int _currentMinutes() {
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
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
