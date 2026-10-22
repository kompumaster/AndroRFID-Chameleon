import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:androrfid_chameleon/core/chameleon/bridge/chameleon.dart';
import 'package:androrfid_chameleon/core/chameleon/helpers/definitions.dart';
import 'package:androrfid_chameleon/data/qidi/qidi_data.dart';
import 'package:androrfid_chameleon/services/qidi_tag_service.dart';

class _FakeCommunicator extends ChameleonCommunicator {
  _FakeCommunicator(this.block)
      : super(Logger(level: Level.off));

  Uint8List block;
  bool writeResult = true;

  @override
  Future<bool> isReaderDeviceMode() async => true;

  @override
  Future<CardData?> scan14443aTag() async {
    return CardData(
      uid: Uint8List.fromList([0x12, 0x34, 0x56, 0x78]),
      sak: 0x08,
      atqa: Uint8List.fromList([0x04, 0x00]),
      ats: Uint8List(0),
    );
  }

  @override
  Future<Uint8List> mf1ReadBlock(
    int block,
    int keyType,
    Uint8List key,
  ) async {
    return Uint8List.fromList(this.block);
  }

  @override
  Future<bool> mf1WriteBlock(
    int block,
    int keyType,
    Uint8List key,
    Uint8List data,
  ) async {
    if (!writeResult) {
      return false;
    }
    this.block = Uint8List.fromList(data);
    return true;
  }
}

void main() {
  test('QidiTagService reads block 4', () async {
    final communicator = _FakeCommunicator(
      Uint8List.fromList([41, 1, 1, ...List<int>.filled(13, 0)]),
    );

    final data = await QidiTagService(communicator).read();

    expect(data.materialId, 41);
    expect(data.colorId, 1);
    expect(data.manufacturerId, 1);
  });

  test('QidiTagService writes and verifies payload', () async {
    final communicator = _FakeCommunicator(Uint8List(16));
    const payload = QidiTagData(
      materialId: 1,
      colorId: 2,
      manufacturerId: 0,
    );

    await QidiTagService(communicator).write(payload);

    expect(communicator.block.sublist(0, 3), [1, 2, 0]);
  });

  test('QidiTagService reports write rejection', () async {
    final communicator = _FakeCommunicator(Uint8List(16))
      ..writeResult = false;

    expect(
      () => QidiTagService(communicator).write(
        const QidiTagData(materialId: 1, colorId: 1, manufacturerId: 1),
      ),
      throwsA(isA<QidiTagException>()),
    );
  });

  test('QidiTagService rejects short read', () async {
    final communicator = _FakeCommunicator(Uint8List(8));

    expect(
      () => QidiTagService(communicator).read(),
      throwsA(isA<QidiTagException>()),
    );
  });
}
