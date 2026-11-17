import 'package:flutter_test/flutter_test.dart';
import 'package:master_lines/models/transit_models.dart';

void main() {
  test('una nota di corsa sopravvive al salvataggio e al caricamento', () {
    const trip = TransitTrip(
      id: 'trip-1',
      departureTime: '07:40',
      headsign: 'Corsa scolastica',
      note: 'Parte solo nei giorni di scuola',
      stops: [],
    );

    final restored = TransitTrip.fromJson(trip.toJson());

    expect(restored.note, 'Parte solo nei giorni di scuola');
    expect(restored.headsign, 'Corsa scolastica');
    expect(restored.departureTime, '07:40');
  });

  test('un backup precedente senza note resta leggibile', () {
    final restored = TransitTrip.fromJson({
      'id': 'trip-old',
      'departureTime': '08:10',
      'headsign': '',
      'stops': <dynamic>[],
    });

    expect(restored.note, isEmpty);
    expect(restored.departureTime, '08:10');
  });

  test('le note restano associate a corse con identificativi duplicati', () {
    const first = TransitTrip(
      id: 'repeated',
      departureTime: '07:40',
      note: 'Prima corsa',
      stops: [],
    );
    const second = TransitTrip(
      id: 'repeated',
      departureTime: '07:40',
      note: 'Seconda corsa',
      stops: [],
    );
    const direction = TransitDirection(
      id: 'out',
      originName: 'Terminalbus',
      destinationName: 'Terminalbus',
      serviceId: '1',
      departures: ['07:40', '07:40'],
      stops: [],
      trips: [first, second],
    );

    final merged = mergeCircularDirections([direction]).single.trips;

    expect(merged.map((trip) => trip.id).toSet(), hasLength(2));
    expect(merged.map((trip) => trip.note).toSet(), {
      'Prima corsa',
      'Seconda corsa',
    });
  });
}
