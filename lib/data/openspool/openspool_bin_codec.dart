import 'dart:typed_data';

import '../../core/chameleon/helpers/utils.dart';
import 'openspool_data.dart';
import 'openspool_ndef_codec.dart';

class OpenSpoolBinException implements Exception {
  OpenSpoolBinException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OpenSpoolBinCodec {
  static const int totalPages = 135;
  static const int pageSize = 4;
  static const int dumpSize = totalPages * pageSize;
  static const int firstUserPage = 4;
  static const int lastUserPage = 129;
  static const int userAreaPages = lastUserPage - firstUserPage + 1;
  static const int userAreaSize = userAreaPages * pageSize;

  static const List<int> cc = [0xE1, 0x10, 0x3E, 0x00];

  static Uint8List encode(
    OpenSpoolTagData data, {
    OpenSpoolProfile profile = OpenSpoolProfile.standard,
    OpenSpoolTier tier = OpenSpoolTier.standard,
    Uint8List? existingDump,
  }) {
    if (existingDump != null) {
      if (existingDump.length != dumpSize) {
        throw OpenSpoolBinException(
          'Ожидался дамп $dumpSize байт, получено ${existingDump.length}.',
        );
      }
      final dump = Uint8List.fromList(existingDump);
      final tlv = OpenSpoolNdefCodec.build(
        data,
        profile: profile,
        tier: tier,
        maxLength: userAreaSize,
      );
      _writeUserArea(dump, tlv);
      return dump;
    }

    final dump = Uint8List(dumpSize);
    final uid = (data.uid?.length == 7) ? data.uid! : _uidFor(data);
    _writeHeader(dump, uid);

    final tlv = OpenSpoolNdefCodec.build(
      data,
      profile: profile,
      tier: tier,
      maxLength: userAreaSize,
    );
    _writeUserArea(dump, tlv);
    return dump;
  }

  static OpenSpoolTagData decode(Uint8List dump) {
    if (dump.length != dumpSize) {
      throw OpenSpoolBinException(
        'Ожидался .bin на $dumpSize байт (NTAG215, 135 страниц), '
        'получено ${dump.length}.',
      );
    }
    if (!_matches(dump.sublist(12, 16), cc)) {
      throw OpenSpoolBinException(
        'В дампе нет NTAG215 CC E1 10 3E 00.',
      );
    }

    final userArea = dump.sublist(
      firstUserPage * pageSize,
      (lastUserPage + 1) * pageSize,
    );
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
      uid: Uint8List.fromList(dump.sublist(0, 7)),
    );
  }

  static void _writeHeader(Uint8List dump, Uint8List uid) {
    dump[0] = uid[0];
    dump[1] = uid[1];
    dump[2] = uid[2];
    dump[3] = calculateBcc(Uint8List.fromList([0x88, uid[0], uid[1], uid[2]]));
    dump[4] = uid[3];
    dump[5] = uid[4];
    dump[6] = uid[5];
    dump[7] = uid[6];
    dump[8] = calculateBcc(
      Uint8List.fromList([0x88, uid[3], uid[4], uid[5], uid[6]]),
    );
    dump[9] = 0x48;
    dump[10] = 0x00;
    dump[11] = 0x00;
    dump.setRange(12, 16, cc);
  }

  static void _writeUserArea(Uint8List dump, Uint8List tlv) {
    final start = firstUserPage * pageSize;
    dump.setRange(start, start + tlv.length, tlv);
  }

  static Uint8List _uidFor(OpenSpoolTagData data) {
    var hash = 0x811C9DC5;
    for (final byte in [
      ...data.type.codeUnits,
      ...data.colorHex.codeUnits,
      ...(data.brand?.codeUnits ?? const <int>[]),
      ...(data.subtype?.codeUnits ?? const <int>[]),
    ]) {
      hash = ((hash ^ (byte & 0xFF)) * 0x01000193) & 0xFFFFFFFF;
    }
    return Uint8List.fromList([
      (hash >> 24) & 0xFF,
      (hash >> 16) & 0xFF,
      (hash >> 8) & 0xFF,
      hash & 0xFF,
      (hash >> 8) & 0xFF,
      (hash >> 16) & 0xFF,
      (hash >> 24) & 0xFF,
    ]);
  }

  static bool _matches(List<int> a, List<int> b) {
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
