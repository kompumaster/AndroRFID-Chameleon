import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:androrfid_chameleon/data/openspool/openspool_data.dart';
import 'package:androrfid_chameleon/data/openspool/openspool_ndef_codec.dart';

void main() {
  test('OpenSpool default subtypes match BoxRFID-Touch', () {
    expect(openSpoolDefaultSubtypes, [
      '',
      'Basic',
      'Matte',
      'SnapSpeed',
      'Silk',
      'Support',
      'HF',
      '95A',
      '95A HF',
    ]);
  });

  test('OpenSpool writes color_hex without a hash', () {
    const data = OpenSpoolTagData(
      type: 'PLA',
      colorHex: '#FF0000',
      additionalColorHexes: ['#FFFFFF', '#000000'],
    );

    final standard = data.toJson();
    expect(standard['color_hex'], 'FF0000');

    final u1 = data.toJson(
      profile: OpenSpoolProfile.u1,
      tier: OpenSpoolTier.all,
    );
    expect(u1['color_hex'], 'FF0000');
    expect(u1['additional_color_hexes'], ['FFFFFF', '000000']);
  });

  test('OpenSpool standard NDEF roundtrip', () {
    const data = OpenSpoolTagData(
      brand: 'QIDI',
      type: 'PLA',
      colorHex: '#ff0000',
      minTemp: 190,
      maxTemp: 220,
    );

    final tlv = OpenSpoolNdefCodec.build(data);

    expect(tlv.first, 0x03);
    expect(tlv.last, 0xFE);

    final padded = Uint8List(OpenSpoolNdefCodec.maxUserAreaLength)
      ..setRange(0, tlv.length, tlv);
    final parsed = OpenSpoolNdefCodec.parse(padded);

    expect(parsed.brand, 'QIDI');
    expect(parsed.type, 'PLA');
    expect(parsed.colorHex, '#FF0000');
    expect(parsed.minTemp, 190);
    expect(parsed.maxTemp, 220);
  });

  test('OpenSpool U1 all fields roundtrip', () {
    const data = OpenSpoolTagData(
      brand: 'Snapmaker',
      type: 'PETG',
      subtype: 'Matte',
      colorHex: '#A5FF52',
      alpha: '80',
      minTemp: 220,
      maxTemp: 250,
      bedMinTemp: 70,
      bedMaxTemp: 80,
      weight: 750,
      diameter: 1.75,
      additionalColorHexes: ['#FFFFFF', '#000000'],
    );

    final tlv = OpenSpoolNdefCodec.build(
      data,
      profile: OpenSpoolProfile.u1,
      tier: OpenSpoolTier.all,
    );
    final parsed = OpenSpoolNdefCodec.parse(
      Uint8List(OpenSpoolNdefCodec.maxUserAreaLength)
        ..setRange(0, tlv.length, tlv),
    );

    expect(parsed.type, 'PETG');
    expect(parsed.subtype, 'Matte');
    expect(parsed.alpha, '80');
    expect(parsed.bedMinTemp, 70);
    expect(parsed.bedMaxTemp, 80);
    expect(parsed.weight, 750);
    expect(parsed.diameter, 1.75);
    expect(parsed.additionalColorHexes, ['#FFFFFF', '#000000']);
  });

  test('OpenSpool can use long NDEF records and long TLV', () {
    final data = OpenSpoolTagData(
      type: 'PLA',
      colorHex: '#FFFFFF',
      subtype: List.filled(300, 'X').join(),
    );

    final tlv = OpenSpoolNdefCodec.build(
      data,
      profile: OpenSpoolProfile.u1,
      tier: OpenSpoolTier.standard,
    );

    expect(tlv[1], 0xFF);
    final parsed = OpenSpoolNdefCodec.parse(
      Uint8List(OpenSpoolNdefCodec.maxUserAreaLength)
        ..setRange(0, tlv.length, tlv),
    );
    expect(parsed.subtype, List.filled(300, 'X').join());
  });

  test('OpenSpool TLV can be found after null padding', () {
    const data = OpenSpoolTagData(type: 'ABS', colorHex: '#123456');
    final tlv = OpenSpoolNdefCodec.build(data);
    final area = Uint8List(120)..setRange(8, 8 + tlv.length, tlv);

    final parsed = OpenSpoolNdefCodec.parse(area);

    expect(parsed.type, 'ABS');
    expect(parsed.colorHex, '#123456');
  });

  test('OpenSpool rejects foreign JSON protocol', () {
    final area = Uint8List(128);
    const payload = '{"protocol":"other","version":"1.0","type":"PLA"}';
    final mime = 'application/json';
    var p = 0;
    area[p++] = 0x03;
    area[p++] = 1 + 1 + 1 + mime.length + payload.length;
    area[p++] = 0xD2;
    area[p++] = mime.length;
    area[p++] = payload.length;
    area.setRange(p, p + mime.length, mime.codeUnits);
    p += mime.length;
    area.setRange(p, p + payload.length, payload.codeUnits);
    p += payload.length;
    area[p] = 0xFE;

    expect(
      () => OpenSpoolNdefCodec.parse(area),
      throwsA(isA<OpenSpoolFormatException>()),
    );
  });

  test('OpenSpool rejects oversized NDEF', () {
    final data = OpenSpoolTagData(
      type: 'PLA',
      colorHex: '#FFFFFF',
      subtype: List.filled(600, 'X').join(),
    );

    expect(
      () => OpenSpoolNdefCodec.build(data, profile: OpenSpoolProfile.u1),
      throwsA(isA<OpenSpoolFormatException>()),
    );
  });
}
