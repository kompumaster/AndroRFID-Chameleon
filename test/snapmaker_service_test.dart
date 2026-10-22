import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:androrfid_chameleon/data/openspool/openspool_data.dart';
import 'package:androrfid_chameleon/data/snapmaker/snapmaker_models.dart';
import 'package:androrfid_chameleon/services/snapmaker_service.dart';

void main() {
  test('SnapmakerService parses four toolheads', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/printer/objects/query');
      expect(request.url.queryParameters['filament_detect'], 'info');
      return http.Response(
        jsonEncode({
          'result': {
            'status': {
              'filament_detect': {
                'info': [
                  {'MAIN_TYPE': 'PLA', 'SUB_TYPE': 'Matte', 'RGB_1': 0xFF0000},
                  {'MAIN_TYPE': '', 'RGB_1': 0},
                  {'MAIN_TYPE': 'PETG', 'RGB_1': 0x00FF00},
                  {},
                ],
              },
            },
          },
        }),
        200,
      );
    });

    final heads = await SnapmakerService(
      host: '192.168.1.10',
      port: 7125,
      client: client,
    ).getToolHeads();

    expect(heads, hasLength(4));
    expect(heads[0].material, 'PLA');
    expect(heads[0].subtype, 'Matte');
    expect(heads[0].colorHex, '#FF0000');
    expect(heads[1].empty, isTrue);
    expect(heads[2].material, 'PETG');
  });

  test('SnapmakerService reads filament sensor', () async {
    final client = MockClient((request) async {
      final key = request.url.queryParameters.keys.first;
      expect(key, 'filament_motion_sensor e1_filament');
      expect(
        request.url.query,
        contains('filament_motion_sensor%20e1_filament=filament_detected'),
      );
      return http.Response(
        jsonEncode({
          'result': {
            'status': {
              key: {'filament_detected': true},
            },
          },
        }),
        200,
      );
    });

    final detected = await SnapmakerService(
      host: '192.168.1.10',
      port: 7125,
      client: client,
    ).getFilamentDetected(2);

    expect(detected, isTrue);
  });

  test('SnapmakerService sends tag payload', () async {
    Map<String, dynamic>? sent;
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/printer/filament_detect/set');
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('{}', 200);
    });

    const payload = SnapmakerTagPayload(
      vendor: 'Snapmaker',
      mainType: 'PETG',
      subtype: 'Matte',
      colorHex: '#A5FF52',
      alpha: 128,
      minTemp: 220,
      maxTemp: 250,
      bedTemp: 80,
      uid: null,
    );

    await SnapmakerService(
      host: '192.168.1.10',
      port: 7125,
      client: client,
    ).sendTag(3, payload);

    expect(sent!['channel'], 2);
    final info = sent!['info'] as Map<String, dynamic>;
    expect(info['VENDOR'], 'Snapmaker');
    expect(info['MAIN_TYPE'], 'PETG');
    expect(info['SUB_TYPE'], 'Matte');
    expect(info['RGB_1'], 0xA5FF52);
    expect(info['ALPHA'], 128);
    expect(info['HOTEND_MIN_TEMP'], 220);
    expect(info['BED_TEMP'], 80);
    expect(info['CARD_UID'], isEmpty);
  });

  test('SnapmakerTagPayload accepts OpenSpool UID', () {
    final payload = SnapmakerTagPayload.fromOpenSpool(
      OpenSpoolTagData(
        brand: 'QIDI',
        type: 'PLA',
        colorHex: '#FFFFFF',
        uid: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7]),
      ),
    );

    final json = payload.toJson(1);
    expect(json['channel'], 0);
    expect((json['info'] as Map)['CARD_UID'], [1, 2, 3, 4, 5, 6, 7]);
  });

  test('SnapmakerService reports bad HTTP status', () async {
    final client = MockClient((request) async {
      return http.Response('nope', 500);
    });

    expect(
      () => SnapmakerService(
        host: '192.168.1.10',
        port: 7125,
        client: client,
      ).getToolHeads(),
      throwsA(isA<SnapmakerException>()),
    );
  });
}
