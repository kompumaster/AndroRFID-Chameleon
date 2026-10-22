import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:androrfid_chameleon/core/chameleon/bridge/chameleon.dart';
import 'package:androrfid_chameleon/core/chameleon/helpers/definitions.dart';
import 'package:androrfid_chameleon/data/openspool/openspool_data.dart';
import 'package:androrfid_chameleon/services/openspool_tag_service.dart';

class _FakeNtagCommunicator extends ChameleonCommunicator {
  _FakeNtagCommunicator() : super(Logger(level: Level.off)) {
    pages[3] = Uint8List.fromList([0xE1, 0x10, 0x3E, 0x00]);
    pages[0] = Uint8List.fromList([0x04, 0x11, 0x22, 0x33]);
    pages[1] = Uint8List.fromList([0x44, 0x55, 0x66, 0x77]);
  }

  final List<Uint8List> pages = List.generate(135, (_) => Uint8List(4));
  bool present = true;

  @override
  Future<bool> isReaderDeviceMode() async => true;

  @override
  Future<CardData?> scan14443aTag() async {
    if (!present) {
      return null;
    }
    return CardData(
      uid: Uint8List.fromList([0x04, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66]),
      sak: 0x00,
      atqa: Uint8List.fromList([0x44, 0x00]),
      ats: Uint8List(0),
    );
  }

  @override
  Future<Uint8List> send14ARaw(
    Uint8List data, {
    int respTimeoutMs = 100,
    int? bitLen,
    bool activateRfField = true,
    bool waitResponse = true,
    bool appendCrc = true,
    bool autoSelect = true,
    bool keepRfField = false,
    bool checkResponseCrc = true,
  }) async {
    if (data.isEmpty) {
      return Uint8List(0);
    }
    if (data[0] == 0x30 && data.length >= 2) {
      final page = data[1];
      final out = <int>[];
      for (var i = 0; i < 4; i++) {
        out.addAll(pages[page + i]);
      }
      return Uint8List.fromList(out);
    }
    if (data[0] == 0xA2 && data.length >= 6) {
      final page = data[1];
      pages[page] = Uint8List.fromList(data.sublist(2, 6));
      return Uint8List.fromList([0x0A]);
    }
    return Uint8List(0);
  }
}

void main() {
  test('OpenSpoolTagService writes and reads NDEF on NTAG pages', () async {
    final communicator = _FakeNtagCommunicator();
    final service = OpenSpoolTagService(communicator);
    const data = OpenSpoolTagData(
      type: 'PLA',
      colorHex: '#FF0000',
      brand: 'QIDI',
      minTemp: 190,
      maxTemp: 220,
    );

    await service.write(data);
    final restored = await service.read();

    expect(communicator.pages[3], [0xE1, 0x10, 0x3E, 0x00]);
    expect(restored.type, 'PLA');
    expect(restored.colorHex, '#FF0000');
    expect(restored.brand, 'QIDI');
    expect(restored.uid, [0x04, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66]);
  });

  test('OpenSpoolTagService reports missing tag', () async {
    final communicator = _FakeNtagCommunicator()..present = false;
    final service = OpenSpoolTagService(communicator);

    expect(
      () => service.read(),
      throwsA(isA<OpenSpoolTagException>()),
    );
  });
}
