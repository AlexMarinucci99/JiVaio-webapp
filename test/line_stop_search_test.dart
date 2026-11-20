import 'package:flutter_test/flutter_test.dart';
import 'package:master_lines/models/transit_models.dart';
import 'package:master_lines/services/line_stop_search.dart';

void main() {
  const line = TransitLine(
    id: '1',
    code: 'A',
    name: 'Linea A',
    stopCount: 2,
    directions: [
      TransitDirection(
        id: '1',
        originName: 'Centro',
        destinationName: 'Stazione',
        departures: [],
        stops: [TransitStopTime(stopId: '1', name: 'Via Roma', time: '')],
        trips: [
          TransitTrip(
            id: '1',
            departureTime: '',
            stops: [TransitStopTime(stopId: '2', name: 'Via Verdi', time: '')],
          ),
        ],
      ),
    ],
  );
  test('cerca nelle fermate della direzione e nelle varianti delle corse', () {
    expect(lineHasMatchingStop(line, '  ROMA '), isTrue);
    expect(lineHasMatchingStop(line, 'verdi'), isTrue);
    expect(lineHasMatchingStop(line, 'milano'), isFalse);
    expect(lineHasMatchingStop(line, ''), isFalse);
  });
}
