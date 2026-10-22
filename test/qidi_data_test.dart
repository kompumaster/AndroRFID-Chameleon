import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:androrfid_chameleon/data/qidi/qidi_data.dart';

void main() {
  test('QIDI block roundtrip keeps payload in first three bytes', () {
    const data = QidiTagData(
      materialId: 41,
      colorId: 1,
      manufacturerId: 1,
    );

    final block = data.toBlock();

    expect(block.length, 16);
    expect(block.sublist(0, 3), [41, 1, 1]);
    expect(block.sublist(3), everyElement(0));
  });

  test('QIDI block parser reads material, color and manufacturer', () {
    final block = Uint8List.fromList([
      30,
      18,
      1,
      ...List<int>.filled(13, 0),
    ]);

    final data = QidiTagData.fromBlock(block);

    expect(data.materialId, 30);
    expect(data.colorId, 18);
    expect(data.manufacturerId, 1);
    expect(data.toBlock(), block);
  });

  test('QIDI tables have expected sizes and different Plus4/Q2 names', () {
    expect(qidiPlus4Materials, hasLength(32));
    expect(qidiQ2Materials, hasLength(42));
    expect(qidiColors, hasLength(24));
    expect(qidiManufacturers, hasLength(2));

    expect(qidiMaterialById(1, QidiPrinterModel.plus4)?.name, 'PLA');
    expect(qidiMaterialById(1, QidiPrinterModel.q2)?.name, 'PLA Rapido');
    expect(qidiMaterialById(11, QidiPrinterModel.plus4)?.name, 'ABS');
    expect(qidiMaterialById(11, QidiPrinterModel.q2)?.name, 'ABS Rapido');
  });

  test('QIDI colors use the same RGB565 to hex conversion as BoxRFID', () {
    expect(qidiColorById(1)?.hex, '#FFFFFF');
    expect(qidiColorById(4)?.hex, '#A4FF52');
    expect(qidiColorById(18)?.hex, '#E63431');
    expect(qidiColorById(24)?.hex, '#A42829');
  });
}
