import '../models/transit_models.dart';

/// Searches all stored routes, including individual trip variants.
bool lineHasMatchingStop(TransitLine line, String query) {
  final term = query.trim().toLowerCase();
  if (term.isEmpty) return false;
  bool matches(TransitStopTime stop) => stop.name.toLowerCase().contains(term);
  return line.directions.any(
    (direction) =>
        direction.stops.any(matches) ||
        direction.trips.any((trip) => trip.stops.any(matches)),
  );
}
