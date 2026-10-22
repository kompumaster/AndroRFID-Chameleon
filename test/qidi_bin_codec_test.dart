import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:androrfid_chameleon/core/chameleon/helpers/utils.dart';
import 'package:androrfid_chameleon/data/qidi/qidi_bin_codec.dart';
import 'package:androrfid_chameleon/data/qidi/qidi_data.dart';

void main() {
  test('QIDI bin has 1K structure, UID, block 4 and trailers', () {
    final dump = QidiBinCodec.encode(
      QidiTagData(
        materialId: 41,
        colorId: 18,
        manufacturerId: 1,
        uid: Uint8List.fromList([0x12, 0x34, 0x56, 0x78]),
      ),
    );

    expect(dump, hasLength(1024));
    expect(dump.sublist(0, 4), [0x12, 0x34, 0x56, 0x78]);
    expect(dump[4], calculateBcc(Uint8List.fromList([0x12, 0x34, 0x56, 0x78])));
    expect(dump[5], 0x08);
    expect(dump.sublist(6, 8), [0x00, 0x04]);
    expect(dump.sublist(64, 67), [41, 18, 1]);

    for (final trailer in [3, 7, 11, 63]) {
      final offset = trailer * 16;
      expect(
        dump.sublist(offset, offset + 16),
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x07, 0x80, 0x69,
          0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
      );
    }
  });

  test('QIDI bin roundtrip restores IDs and UID', () {
    final original = QidiTagData(
      materialId: 30,
      colorId: 1,
      manufacturerId: 0,
      uid: Uint8List.fromList([1, 2, 3, 4]),
    );

    final restored = QidiBinCodec.decode(QidiBinCodec.encode(original));

    expect(restored.materialId, 30);
    expect(restored.colorId, 1);
    expect(restored.manufacturerId, 0);
    expect(restored.uid, original.uid);
  });

  test('QIDI bin generation is deterministic without UID', () {
    const data = QidiTagData(materialId: 1, colorId: 2, manufacturerId: 1);

    expect(QidiBinCodec.encode(data).sublist(0, 4),
        QidiBinCodec.encode(data).sublist(0, 4));
  });

  test('QIDI bin rejects wrong size and empty block 4', () {
    expect(
      () => QidiBinCodec.decode(Uint8List(512)),
      throwsA(isA<QidiBinException>()),
    );
    expect(
      () => QidiBinCodec.decode(Uint8List(1024)),
      throwsA(isA<QidiBinException>()),
    );
  });
}
