import 'package:flutter_test/flutter_test.dart';
import 'package:master_lines/models/transit_models.dart';
import 'package:master_lines/services/upcoming_departures.dart';

TransitDirection direction(
  String service,
  List<String> times, {
  String origin = 'Terminal',
  String destination = 'Coppito',
}) => TransitDirection(
  id: service,
  originName: origin,
  destinationName: destination,
  departures: times,
  stops: const [],
  serviceId: service,
);

List<String> times(UpcomingDepartures result) =>
    result.departures.map((departure) => departure.time).toList();

void main() {
  group('partenze per il giorno corrente a L’Aquila', () {
    test('filtra il passato, include il minuto corrente, ordina e limita a quattro', () {
      final result = upcomingDepartures([
        direction('1', [
          '12:00',
          '08:59',
          '09:05',
          '09:00',
          '10:00',
          '11:00',
          '09:05',
        ]),
      ], DateTime.utc(2026, 11, 19, 8, 0, 45));
      expect(times(result), ['09:00', '09:05', '09:05', '10:00']);
    });

    test('sabato non mostra corse feriali, e dopo l’ultima corsa è vuoto', () {
      final feriale = direction('1', ['09:00', '12:00']);
      final sabato = upcomingDepartures([
        feriale,
      ], DateTime.utc(2026, 11, 21, 8));
      expect(sabato.departures, isEmpty);
      expect(sabato.emptyReason, UpcomingEmptyReason.noneToday);
      final tardi = upcomingDepartures([
        feriale,
      ], DateTime.utc(2026, 11, 20, 22));
      expect(tardi.departures, isEmpty);
      expect(tardi.emptyReason, UpcomingEmptyReason.noneToday);
    });

    test(
      'raggruppa i calendari della stessa direzione e usa quello attivo',
      () {
        final week = direction('1', ['10:00']);
        final sat = direction(
          '2',
          ['09:00'],
          origin: ' terminal ',
          destination: 'COPPITO',
        );
        final reverse = direction(
          '2',
          ['09:30'],
          origin: 'Coppito',
          destination: 'Terminal',
        );
        final line = TransitLine(
          id: 'x',
          code: 'X',
          name: 'X',
          stopCount: 1,
          directions: [week, sat, reverse],
        );
        final directions = directionsForCard(line, week);
        expect(directions, [week, sat]);
        expect(
          times(upcomingDepartures(directions, DateTime.utc(2026, 11, 21, 7))),
          ['09:00'],
        );
      },
    );

    test('le varianti circolari restano separate', () {
      final week = direction('1', ['10:00']);
      final sat = direction('2', ['09:00']);
      final line = TransitLine(
        id: 'x',
        code: 'X',
        name: 'X',
        stopCount: 1,
        directions: [week, sat],
        isCircular: true,
      );
      expect(directionsForCard(line, week), [week]);
    });

    test('calendari sconosciuti non diventano validi tutti i giorni', () {
      final unknown = upcomingDepartures([
        direction('', ['10:00']),
      ], DateTime.utc(2026, 11, 19, 8));
      expect(unknown.departures, isEmpty);
      expect(unknown.emptyReason, UpcomingEmptyReason.calendarUnknown);
      final noTimes = upcomingDepartures([
        direction('1', ['--:--', '99:99']),
      ], DateTime.utc(2026, 11, 19, 8));
      expect(noTimes.emptyReason, UpcomingEmptyReason.noTimes);
    });

    test('il calendario festivo settimanale comprende la domenica', () {
      final festivo = direction('FESTIVO', ['09:00']);
      expect(
        times(upcomingDepartures([festivo], DateTime.utc(2026, 11, 22, 7))),
        ['09:00'],
      );
      expect(
        upcomingDepartures([festivo], DateTime.utc(2026, 11, 21, 7)).departures,
        isEmpty,
      );
    });
  });

  group('servizio notturno e passaggio di giorno', () {
    final night = direction('NIGHT_THSAT', [
      '23:30',
      '00:40',
      '01:30',
      '21:30',
    ]);
    test('giovedì mattina non confonde la notte precedente', () {
      expect(
        times(upcomingDepartures([night], DateTime.utc(2026, 11, 18, 23, 10))),
        ['21:30', '23:30'],
      );
    });
    test('giovedì sera mostra solo le partenze del giorno', () {
      expect(
        times(upcomingDepartures([night], DateTime.utc(2026, 11, 19, 20))),
        ['21:30', '23:30'],
      );
    });
    test('venerdì e domenica dopo mezzanotte usa la notte precedente', () {
      expect(
        times(upcomingDepartures([night], DateTime.utc(2026, 11, 19, 23, 10))),
        ['00:40', '01:30'],
      );
      expect(
        times(upcomingDepartures([night], DateTime.utc(2026, 11, 21, 23, 10))),
        ['00:40', '01:30'],
      );
      expect(
        upcomingDepartures([night], DateTime.utc(2026, 11, 20, 20)).departures,
        isEmpty,
      );
    });
    test(
      'le ore GTFS oltre 24 valgono per il giorno di servizio precedente',
      () {
        final extended = direction('1', ['25:00', '09:00']);
        expect(
          times(
            upcomingDepartures([extended], DateTime.utc(2026, 11, 20, 23, 30)),
          ),
          ['25:00'],
        );
        expect(
          upcomingDepartures([
            extended,
          ], DateTime.utc(2026, 11, 19, 20)).departures,
          isEmpty,
        );
      },
    );
  });

  test('ora di Roma applica esattamente i cambi ora legale e solare', () {
    expect(
      romeWallTime(DateTime.utc(2026, 3, 29, 0, 59)),
      DateTime.utc(2026, 3, 29, 1, 59),
    );
    expect(
      romeWallTime(DateTime.utc(2026, 3, 29, 1)),
      DateTime.utc(2026, 3, 29, 3),
    );
    expect(
      romeWallTime(DateTime.utc(2026, 10, 25, 0, 59)),
      DateTime.utc(2026, 10, 25, 2, 59),
    );
    expect(
      romeWallTime(DateTime.utc(2026, 10, 25, 1)),
      DateTime.utc(2026, 10, 25, 2),
    );
  });
}
