import 'dart:math' as math;
import 'dart:typed_data';

import '../../core/chameleon/bridge/chameleon.dart';
import '../data/openspool/openspool_data.dart';
import '../data/openspool/openspool_ndef_codec.dart';
import '../data/openspool/openspool_ntag.dart';

class OpenSpoolTagException implements Exception {
  OpenSpoolTagException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OpenSpoolTagService {
  OpenSpoolTagService(this.communicator);

  final ChameleonCommunicator communicator;

  Future<void> _ensureReaderMode() async {
    if (!await communicator.isReaderDeviceMode()) {
      await communicator.setReaderDeviceMode(true);
    }
  }

  Future<Uint8List> _readPageBlock(int page, {bool autoSelect = false}) async {
    final response = await communicator.send14ARaw(
      Uint8List.fromList([0x30, page]),
      keepRfField: true,
      autoSelect: autoSelect,
    );
    if (response.length < 4) {
      throw OpenSpoolTagException('NTAG не вернул страницу $page.');
    }
    return response;
  }

  Future<Uint8List> _readHeader() async {
    final header = await _readPageBlock(0, autoSelect: true);
    if (header.length < 16) {
      throw OpenSpoolTagException('NTAG вернул неполный заголовок.');
    }
    return header.sublist(0, 16);
  }

  Future<OpenSpoolNtagLayout> _detectLayout() async {
    final response = await _readPageBlock(
      OpenSpoolNtagLayout.ccPage,
      autoSelect: true,
    );
    final cc = response.sublist(0, 4);
    final layout = OpenSpoolNtagLayout.fromCc(cc);
    if (layout != null) {
      return layout;
    }
    if (OpenSpoolNtagLayout.isNtag213(cc)) {
      throw OpenSpoolTagException(
        'NTAG213 не поддерживается. Используйте NTAG215 или NTAG216.',
      );
    }
    throw OpenSpoolTagException(
      'Не удалось определить тип метки. '
      'Ожидается NTAG215/216, CC: ${_hex(cc)}.',
    );
  }

  Future<Uint8List> _readUserArea(OpenSpoolNtagLayout layout) async {
    final user = Uint8List(layout.userAreaSize);
    for (
      var page = OpenSpoolNtagLayout.firstUserPage;
      page <= layout.lastUserPage;
      page += 4
    ) {
      final chunk = await _readPageBlock(
        page,
        autoSelect: page == OpenSpoolNtagLayout.firstUserPage,
      );
      final take = math.min(16, (layout.lastUserPage - page + 1) * 4);
      final offset = (page - OpenSpoolNtagLayout.firstUserPage) * 4;
      user.setRange(offset, offset + take, chunk);
    }
    return user;
  }

  Future<void> _writePage(
    int page,
    Uint8List data, {
    bool autoSelect = false,
  }) async {
    if (data.length != 4) {
      throw ArgumentError('NTAG page must be 4 bytes');
    }

    Future<bool> attempt(bool select) async {
      final response = await communicator.send14ARaw(
        Uint8List.fromList([0xA2, page, ...data]),
        keepRfField: true,
        checkResponseCrc: false,
        autoSelect: select,
      );
      return response.isNotEmpty && response[0] == 0x0A;
    }

    var ok = await attempt(autoSelect);
    if (!ok) {
      ok = await attempt(true);
    }
    if (!ok) {
      throw OpenSpoolTagException('NTAG не подтвердил запись страницы $page.');
    }
  }

  Future<OpenSpoolTagData> read() async {
    try {
      await _ensureReaderMode();
      final card = await communicator.scan14443aTag();
      if (card == null) {
        throw OpenSpoolTagException(
          'Метка не найдена. Приложите NTAG215/216 к Chameleon.',
        );
      }

      final layout = await _detectLayout();
      final header = await _readHeader();
      final userArea = await _readUserArea(layout);
      final data = OpenSpoolNdefCodec.parse(userArea);
      return data
          .withNtagType(layout.type)
          .withUid(Uint8List.fromList(header.sublist(0, 7)));
    } on OpenSpoolTagException {
      rethrow;
    } catch (e) {
      throw OpenSpoolTagException(
        'Не удалось прочитать OpenSpool-метку. Проверьте, что это NTAG215/216. '
        'Ошибка: $e',
      );
    }
  }

  Future<OpenSpoolNtagType> write(
    OpenSpoolTagData data, {
    OpenSpoolProfile profile = OpenSpoolProfile.standard,
    OpenSpoolTier tier = OpenSpoolTier.standard,
  }) async {
    try {
      await _ensureReaderMode();
      final card = await communicator.scan14443aTag();
      if (card == null) {
        throw OpenSpoolTagException(
          'Метка не найдена. Приложите NTAG215/216 к Chameleon.',
        );
      }

      final layout = await _detectLayout();
      final tlv = OpenSpoolNdefCodec.build(
        data,
        profile: profile,
        tier: tier,
        maxLength: layout.userAreaSize,
      );

      final pageCount = (tlv.length + 3) ~/ 4;
      for (var index = 0; index < pageCount; index++) {
        final offset = index * 4;
        final page = Uint8List(4);
        for (var i = 0; i < 4; i++) {
          final source = offset + i;
          page[i] = source < tlv.length ? tlv[source] : 0;
        }
        await _writePage(
          OpenSpoolNtagLayout.firstUserPage + index,
          page,
          autoSelect: index == 0,
        );
      }

      final readBack = await _readUserArea(layout);
      final tlvReadBack = OpenSpoolNdefCodec.findTlv(readBack);
      final expectedTlv = OpenSpoolNdefCodec.findTlv(tlv);
      if (tlvReadBack == null ||
          expectedTlv == null ||
          tlvReadBack.length != expectedTlv.length ||
          !_matches(
            readBack.sublist(
              tlvReadBack.offset,
              tlvReadBack.offset + tlvReadBack.length,
            ),
            tlv.sublist(
              expectedTlv.offset,
              expectedTlv.offset + expectedTlv.length,
            ),
          )) {
        throw OpenSpoolTagException(
          'Проверка после записи OpenSpool не совпала.',
        );
      }
      return layout.type;
    } on OpenSpoolTagException {
      rethrow;
    } catch (e) {
      throw OpenSpoolTagException(
        'Не удалось записать OpenSpool-метку. Ошибка: $e',
      );
    }
  }

  static String _hex(List<int> bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  bool _matches(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
