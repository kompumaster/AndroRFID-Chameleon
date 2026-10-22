import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:androrfid_chameleon/core/chameleon/bridge/chameleon.dart';
import 'package:androrfid_chameleon/core/chameleon/helpers/definitions.dart';
import 'package:androrfid_chameleon/data/openspool/openspool_data.dart';
import 'package:androrfid_chameleon/data/openspool/openspool_ntag.dart';
import 'package:androrfid_chameleon/services/openspool_tag_service.dart';

class _FakeNtagCommunicator extends ChameleonCommunicator {
  _FakeNtagCommunicator({
    OpenSpoolNtagType ntagType = OpenSpoolNtagType.ntag215,
  }) : ntagType = ntagType,
       pages = List.generate(
         OpenSpoolNtagLayout.forType(ntagType).totalPages,
         (_) => Uint8List(4),
       ),
       super(Logger(level: Level.off)) {
    pages[3] = Uint8List.fromList(OpenSpoolNtagLayout.forType(ntagType).cc);
    pages[0] = Uint8List.fromList([0x04, 0x11, 0x22, 0x33]);
    pages[1] = Uint8List.fromList([0x44, 0x55, 0x66, 0x77]);
  }

  final OpenSpoolNtagType ntagType;
  final List<Uint8List> pages;
  bool present = true;
  bool shortUserReads = false;

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
      if (shortUserReads && page >= 4) {
        return Uint8List.fromList(out.sublist(0, 4));
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

  test('OpenSpoolTagService reads and writes NTAG216', () async {
    final communicator = _FakeNtagCommunicator(
      ntagType: OpenSpoolNtagType.ntag216,
    );
    final service = OpenSpoolTagService(communicator);
    final data = OpenSpoolTagData(
      type: 'PETG',
      colorHex: '#A5FF52',
      brand: 'Snapmaker',
      subtype: List.filled(600, 'X').join(),
      minTemp: 220,
      maxTemp: 250,
      bedMinTemp: 70,
      bedMaxTemp: 80,
      weight: 750,
      diameter: 1.75,
    );

    final result = await service.write(data, profile: OpenSpoolProfile.u1);
    final restored = await service.read();

    expect(result.ntagType, OpenSpoolNtagType.ntag216);
    expect(communicator.pages[3], [0xE1, 0x10, 0x6D, 0x00]);
    expect(restored.ntagType, OpenSpoolNtagType.ntag216);
    expect(restored.subtype, List.filled(600, 'X').join());
    expect(restored.id, isNotEmpty);
  });

  test('OpenSpoolTagService rejects NTAG213', () async {
    final communicator = _FakeNtagCommunicator();
    communicator.pages[3] = Uint8List.fromList([0xE1, 0x10, 0x12, 0x00]);
    final service = OpenSpoolTagService(communicator);

    expect(
      () => service.read(),
      throwsA(
        isA<OpenSpoolTagException>().having(
          (error) => error.message,
          'message',
          contains('NTAG213'),
        ),
      ),
    );
  });

  test('OpenSpoolTagService rejects a short page block', () async {
    final communicator = _FakeNtagCommunicator()..shortUserReads = true;
    final service = OpenSpoolTagService(communicator);

    expect(
      () => service.read(),
      throwsA(
        isA<OpenSpoolTagException>().having(
          (error) => error.message,
          'message',
          contains('вместо'),
        ),
      ),
    );
  });

  test('OpenSpoolTagService reports missing tag', () async {
    final communicator = _FakeNtagCommunicator()..present = false;
    final service = OpenSpoolTagService(communicator);

    expect(() => service.read(), throwsA(isA<OpenSpoolTagException>()));
  });
}
