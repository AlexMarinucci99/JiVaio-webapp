import 'package:flutter_test/flutter_test.dart';
import 'package:master_lines/models/transit_models.dart';

void main() {
  const line = TransitLine(
    id: '1',
    code: 'A',
    name: 'Linea A',
    stopCount: 0,
    directions: [],
  );

  test('una linea nascosta resta nascosta nel backup', () {
    final hidden = line.copyWith(isVisible: false);
    final restored = TransitLine.fromJson(hidden.toJson());
    expect(restored.isVisible, isFalse);
    expect(restored.copyWith(name: 'Nuovo nome').isVisible, isFalse);
    expect(restored.copyWith(isVisible: true).isVisible, isTrue);
  });

  test('le linee nei backup precedenti restano visibili', () {
    final old = line.toJson()..remove('isVisible');
    expect(TransitLine.fromJson(old).isVisible, isTrue);
  });
}
