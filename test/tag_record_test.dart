import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:androrfid_chameleon/data/openspool/openspool_data.dart';
import 'package:androrfid_chameleon/data/openspool/openspool_ntag.dart';
import 'package:androrfid_chameleon/data/qidi/qidi_data.dart';
import 'package:androrfid_chameleon/data/records/tag_record.dart';

void main() {
  test('TagRecord serializes and restores QIDI data', () {
    final now = DateTime(2026, 10, 22, 12, 30);
    final record = TagRecord(
      id: '42',
      name: 'QIDI Plus 4 PLA White',
      type: TagRecordType.qidi,
      createdAt: now,
      updatedAt: now,
      qidiModel: QidiPrinterModel.plus4,
      qidiData: QidiTagData(
        materialId: 1,
        colorId: 1,
        manufacturerId: 1,
        rawBlock: Uint8List.fromList([1, 1, 1, ...List<int>.filled(13, 0)]),
      ),
    );

    final restored = TagRecord.fromJson(record.toJson());

    expect(restored, isNotNull);
    expect(restored!.id, '42');
    expect(restored.name, 'QIDI Plus 4 PLA White');
    expect(restored.type, TagRecordType.qidi);
    expect(restored.qidiModel, QidiPrinterModel.plus4);
    expect(restored.qidiData!.materialId, 1);
    expect(restored.qidiData!.colorId, 1);
    expect(restored.qidiData!.manufacturerId, 1);
    expect(restored.qidiData!.rawBlock, record.qidiData!.rawBlock);
  });

  test('TagRecord rejects unknown type', () {
    final restored = TagRecord.fromJson({
      'id': '1',
      'name': 'Unknown',
      'type': 'other',
    });

    expect(restored, isNull);
  });

  test('TagRecord serializes and restores OpenSpool data', () {
    final now = DateTime(2026, 10, 22, 13);
    final record = TagRecord(
      id: 'os1',
      name: 'OpenSpool Snapmaker PETG Matte',
      type: TagRecordType.openspool,
      createdAt: now,
      updatedAt: now,
      openspoolProfile: OpenSpoolProfile.u1,
      openspoolTier: OpenSpoolTier.all,
      openspoolData: OpenSpoolTagData(
        brand: 'Snapmaker',
        type: 'PETG',
        subtype: 'Matte',
        colorHex: '#A5FF52',
        id: 'u1-1',
        alpha: '80',
        minTemp: 220,
        maxTemp: 250,
        bedMinTemp: 70,
        bedMaxTemp: 80,
        weight: 750,
        diameter: 1.75,
        additionalColorHexes: const ['#FFFFFF'],
        ntagType: OpenSpoolNtagType.ntag216,
      ),
    );

    final restored = TagRecord.fromJson(record.toJson());

    expect(restored, isNotNull);
    expect(restored!.type, TagRecordType.openspool);
    expect(restored.openspoolProfile, OpenSpoolProfile.u1);
    expect(restored.openspoolTier, OpenSpoolTier.all);
    expect(restored.openspoolData!.brand, 'Snapmaker');
    expect(restored.openspoolData!.type, 'PETG');
    expect(restored.openspoolData!.subtype, 'Matte');
    expect(restored.openspoolData!.colorHex, '#A5FF52');
    expect(restored.openspoolData!.id, 'u1-1');
    expect(restored.openspoolData!.weight, 750);
    expect(restored.openspoolData!.additionalColorHexes, ['#FFFFFF']);
    expect(restored.openspoolData!.ntagType, OpenSpoolNtagType.ntag216);
  });
}
