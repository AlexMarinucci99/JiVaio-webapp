import '../models/transit_models.dart';

/// Converts an instant to the civil clock used by the L'Aquila timetable.
/// The returned UTC value is a wall-clock representation, not a new instant.
DateTime romeWallTime(DateTime instant) {
  final utc = instant.toUtc();
  DateTime lastSunday(int month) {
    final lastDay = DateTime.utc(utc.year, month + 1, 0, 1);
    return lastDay.subtract(Duration(days: lastDay.weekday % 7));
  }

  final summer = !utc.isBefore(lastSunday(3)) && utc.isBefore(lastSunday(10));
  return utc.add(Duration(hours: summer ? 2 : 1));
}

class UpcomingDeparture {
  const UpcomingDeparture({required this.direction, required this.time});
  final TransitDirection direction;
  final String time;
}

enum UpcomingEmptyReason { noTimes, calendarUnknown, noneToday }

class UpcomingDepartures {
  const UpcomingDepartures({
    required this.departures,
    required this.emptyReason,
  });
  final List<UpcomingDeparture> departures;
  final UpcomingEmptyReason emptyReason;
}

/// Non-circular cards combine calendars with the same origin and destination.
/// Circular cards already represent a specific calendar and route variant.
List<TransitDirection> directionsForCard(
  TransitLine line,
  TransitDirection direction,
) {
  if (line.isCircular) return [direction];
  String normalized(String name) => name.trim().toLowerCase();
  return line.directions
      .where(
        (candidate) =>
            normalized(candidate.originName) ==
                normalized(direction.originName) &&
            normalized(candidate.destinationName) ==
                normalized(direction.destinationName),
      )
      .toList();
}

/// Returns only departures on the current Rome civil day, at or after the
/// current minute. Unrecognized calendars are never assumed to run daily.
UpcomingDepartures upcomingDepartures(
  Iterable<TransitDirection> directions,
  DateTime instant, {
  int limit = 4,
}) {
  final now = romeWallTime(instant);
  final today = DateTime.utc(now.year, now.month, now.day);
  final currentMinute = now.hour * 60 + now.minute;
  final matches = <({int minute, int order, UpcomingDeparture departure})>[];
  var hasTimes = false;
  var hasUnknownCalendar = false;
  var order = 0;

  for (final direction in directions) {
    final service = direction.serviceId.trim();
    for (final raw in direction.departures) {
      final time = raw.trim();
      final parsed = RegExp(r'^(\d{1,2}):([0-5]\d)(?::[0-5]\d)?$')
          .firstMatch(time);
      if (parsed == null) continue;
      final hour = int.parse(parsed.group(1)!);
      if (hour >= 48) continue;
      hasTimes = true;
      if (!_knownService(service)) {
        hasUnknownCalendar = true;
        continue;
      }
      final minute = (hour % 24) * 60 + int.parse(parsed.group(2)!);
      final previousDay = hour >= 24 || (service == 'NIGHT_THSAT' && hour < 12);
      final serviceDay = previousDay
          ? today.subtract(const Duration(days: 1))
          : today;
      if (minute < currentMinute || !_runsOn(service, serviceDay.weekday)) {
        continue;
      }
      matches.add((
        minute: minute,
        order: order++,
        departure: UpcomingDeparture(direction: direction, time: time),
      ));
    }
  }
  matches.sort((a, b) {
    final comparison = a.minute.compareTo(b.minute);
    return comparison == 0 ? a.order.compareTo(b.order) : comparison;
  });
  return UpcomingDepartures(
    departures: matches.take(limit).map((match) => match.departure).toList(),
    emptyReason: !hasTimes
        ? UpcomingEmptyReason.noTimes
        : hasUnknownCalendar
        ? UpcomingEmptyReason.calendarUnknown
        : UpcomingEmptyReason.noneToday,
  );
}

bool _knownService(String service) =>
    const {'1', '2', 'FESTIVO', 'NIGHT_THSAT'}.contains(service);

bool _runsOn(String service, int weekday) => switch (service) {
  '1' => weekday >= DateTime.monday && weekday <= DateTime.friday,
  '2' => weekday == DateTime.saturday,
  'FESTIVO' => weekday == DateTime.sunday,
  'NIGHT_THSAT' => weekday == DateTime.thursday || weekday == DateTime.saturday,
  _ => false,
};
