import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:androrfid_chameleon/data/openspool/openspool_bin_codec.dart';
import 'package:androrfid_chameleon/data/openspool/openspool_data.dart';

void main() {
  test('OpenSpool bin has 540 bytes, NTAG215 CC and header', () {
    const data = OpenSpoolTagData(
      type: 'PLA',
      colorHex: '#FF0000',
      brand: 'Generic',
      minTemp: 190,
      maxTemp: 220,
    );

    final dump = OpenSpoolBinCodec.encode(data);

    expect(dump, hasLength(540));
    expect(dump.sublist(12, 16), [0xE1, 0x10, 0x3E, 0x00]);
    expect(dump[16], 0x03);

    final restored = OpenSpoolBinCodec.decode(dump);
    expect(restored.type, 'PLA');
    expect(restored.colorHex, '#FF0000');
    expect(restored.brand, 'Generic');
    expect(restored.minTemp, 190);
    expect(restored.maxTemp, 220);
    expect(restored.uid, hasLength(7));
  });

  test('OpenSpool bin export reuses an existing dump header', () {
    final original = OpenSpoolBinCodec.encode(
      const OpenSpoolTagData(type: 'PLA', colorHex: '#FFFFFF'),
    );
    final changed = OpenSpoolBinCodec.encode(
      const OpenSpoolTagData(type: 'PETG', colorHex: '#000000'),
      existingDump: original,
    );

    expect(changed.sublist(0, 12), original.sublist(0, 12));
    final parsed = OpenSpoolBinCodec.decode(changed);
    expect(parsed.type, 'PETG');
  });

  test('OpenSpool bin rejects non-NTAG215 dump', () {
    final dump = Uint8List(540);

    expect(
      () => OpenSpoolBinCodec.decode(dump),
      throwsA(isA<OpenSpoolBinException>()),
    );
  });
}
