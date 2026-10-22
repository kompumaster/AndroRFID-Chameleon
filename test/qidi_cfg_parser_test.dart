import 'package:flutter_test/flutter_test.dart';

import 'package:androrfid_chameleon/data/qidi/qidi_cfg_parser.dart';

void main() {
  const sample = '''
[fila1]
filament = PLA
min_temp = 190
max_temp = 240
box_min_temp = 0
box_max_temp = 0
type = PLA

[fila8]
filament = PLA Matte Basic
min_temp = 190
max_temp = 230
box_min_temp =
box_max_temp =
type = PLA

[fila9]
filament =
min_temp =
max_temp =
type =
''';

  test('QIDI CFG parser reads slots and skips empty fields', () {
    final slots = QidiCfgParser.parse(sample);

    expect(slots, hasLength(3));
    expect(slots[0].slot, 1);
    expect(slots[0].filament, 'PLA');
    expect(slots[0].minTemp, 190);
    expect(slots[1].slot, 8);
    expect(slots[1].boxMinTemp, isNull);
    expect(slots[1].isActive, isTrue);
    expect(slots[2].isActive, isFalse);
  });

  test('QIDI CFG parser exposes only active materials', () {
    final materials = QidiCfgParser.toMaterials(QidiCfgParser.parse(sample));

    expect(materials, hasLength(2));
    expect(materials[0].id, 1);
    expect(materials[0].name, 'PLA');
    expect(materials[1].id, 8);
    expect(materials[1].nozzleMax, 230);
  });

  test('QIDI CFG parser rejects files without sections', () {
    expect(
      () => QidiCfgParser.parse('filament = PLA'),
      throwsA(isA<FormatException>()),
    );
  });
}
