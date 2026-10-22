import 'dart:math' as math;
import 'dart:typed_data';

import '../../core/chameleon/bridge/chameleon.dart';
import '../data/openspool/openspool_data.dart';
import '../data/openspool/openspool_ndef_codec.dart';

class OpenSpoolTagException implements Exception {
  OpenSpoolTagException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OpenSpoolTagService {
  OpenSpoolTagService(this.communicator);

  static const int ccPage = 3;
  static const int firstUserPage = 4;
  static const int lastUserPage = 129;
  static const int userAreaPages = lastUserPage - firstUserPage + 1;
  static const int userAreaSize = userAreaPages * 4;
  static const List<int> cc = [0xE1, 0x10, 0x3E, 0x00];

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
      throw OpenSpoolTagException(
        'NTAG не вернул страницу $page.',
      );
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

  Future<Uint8List> _readUserArea() async {
    final user = Uint8List(userAreaSize);
    for (var page = firstUserPage; page <= lastUserPage; page += 4) {
      final chunk = await _readPageBlock(
        page,
        autoSelect: page == firstUserPage,
      );
      final take = math.min(16, (lastUserPage - page + 1) * 4);
      final offset = (page - firstUserPage) * 4;
      user.setRange(offset, offset + take, chunk);
    }
    return user;
  }

  Future<void> _ensureCc() async {
    final header = await _readHeader();
    final current = header.sublist(12, 16);
    if (_matches(current, cc)) {
      return;
    }

    await _writePage(ccPage, Uint8List.fromList(cc), autoSelect: true);
    final verify = await _readHeader();
    if (!_matches(verify.sublist(12, 16), cc)) {
      throw OpenSpoolTagException(
        'Не удалось установить NTAG215 CC E1 10 3E 00.',
      );
    }
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
      throw OpenSpoolTagException(
        'NTAG не подтвердил запись страницы $page.',
      );
    }
  }

  Future<OpenSpoolTagData> read() async {
    try {
      await _ensureReaderMode();
      final card = await communicator.scan14443aTag();
      if (card == null) {
        throw OpenSpoolTagException(
          'Метка не найдена. Приложите NTAG215 к Chameleon.',
        );
      }

      final header = await _readHeader();
      final userArea = await _readUserArea();
      final data = OpenSpoolNdefCodec.parse(userArea);
      return OpenSpoolTagData(
        type: data.type,
        colorHex: data.colorHex,
        brand: data.brand,
        subtype: data.subtype,
        alpha: data.alpha,
        minTemp: data.minTemp,
        maxTemp: data.maxTemp,
        bedMinTemp: data.bedMinTemp,
        bedMaxTemp: data.bedMaxTemp,
        weight: data.weight,
        diameter: data.diameter,
        additionalColorHexes: data.additionalColorHexes,
        rawJson: data.rawJson,
        uid: Uint8List.fromList(header.sublist(0, 7)),
      );
    } on OpenSpoolTagException {
      rethrow;
    } catch (e) {
      throw OpenSpoolTagException(
        'Не удалось прочитать OpenSpool-метку. Проверьте, что это NTAG215. '
        'Ошибка: $e',
      );
    }
  }

  Future<void> write(
    OpenSpoolTagData data, {
    OpenSpoolProfile profile = OpenSpoolProfile.standard,
    OpenSpoolTier tier = OpenSpoolTier.standard,
  }) async {
    try {
      await _ensureReaderMode();
      final card = await communicator.scan14443aTag();
      if (card == null) {
        throw OpenSpoolTagException(
          'Метка не найдена. Приложите NTAG215 к Chameleon.',
        );
      }

      await _ensureCc();
      final tlv = OpenSpoolNdefCodec.build(
        data,
        profile: profile,
        tier: tier,
        maxLength: userAreaSize,
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
          firstUserPage + index,
          page,
          autoSelect: index == 0,
        );
      }

      final readBack = await _readUserArea();
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
    } on OpenSpoolTagException {
      rethrow;
    } catch (e) {
      throw OpenSpoolTagException(
        'Не удалось записать OpenSpool-метку. Ошибка: $e',
      );
    }
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
