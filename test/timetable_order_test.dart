import 'package:flutter_test/flutter_test.dart';
import 'package:master_lines/services/timetable_order.dart';

void main() {
  test('ordina le corse mantenendo le posizioni originali e i duplicati', () {
    final times = [
      '07:30',
      '07:00',
      '07:23',
      '07:30',
      '7:10',
      '',
      '25:05',
      '23:50',
    ];
    expect(timetableOrder(times), [1, 4, 2, 0, 3, 7, 6, 5]);
    expect(times.first, '07:30');
  });
  test('ordina anche secondi e orari non validi', () {
    expect(timetableOrder(['8:00:30', '08:00', '48:00', 'errato']), [
      1,
      0,
      2,
      3,
    ]);
    expect(timetableOrder([]), isEmpty);
  });
}
