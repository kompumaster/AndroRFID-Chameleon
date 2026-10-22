import 'dart:convert';
import 'dart:typed_data';

import 'openspool_data.dart';

class NdefTlv {
  const NdefTlv(this.offset, this.length);

  final int offset;
  final int length;
}

class OpenSpoolNdefCodec {
  static const int maxUserAreaLength = 504;

  static Uint8List build(
    OpenSpoolTagData data, {
    OpenSpoolProfile profile = OpenSpoolProfile.standard,
    OpenSpoolTier tier = OpenSpoolTier.standard,
    int maxLength = maxUserAreaLength,
  }) {
    final json = utf8.encode(data.toJsonString(profile: profile, tier: tier));
    final mime = ascii.encode('application/json');
    final shortRecord = json.length <= 255;
    final recordLength = 1 + 1 + (shortRecord ? 1 : 4) + mime.length + json.length;
    final shortTlv = recordLength <= 254;
    final totalLength =
        1 + (shortTlv ? 1 : 3) + recordLength + 1;

    if (totalLength > maxLength) {
      throw OpenSpoolFormatException(
        'NDEF не помещается в $maxLength байт: нужно $totalLength.',
      );
    }

    final out = Uint8List(totalLength);
    var p = 0;
    out[p++] = 0x03;
    if (shortTlv) {
      out[p++] = recordLength;
    } else {
      out[p++] = 0xFF;
      out[p++] = (recordLength >> 8) & 0xFF;
      out[p++] = recordLength & 0xFF;
    }

    out[p++] = shortRecord ? 0xD2 : 0xC2;
    out[p++] = mime.length;
    if (shortRecord) {
      out[p++] = json.length;
    } else {
      out[p++] = (json.length >> 24) & 0xFF;
      out[p++] = (json.length >> 16) & 0xFF;
      out[p++] = (json.length >> 8) & 0xFF;
      out[p++] = json.length & 0xFF;
    }
    out.setRange(p, p + mime.length, mime);
    p += mime.length;
    out.setRange(p, p + json.length, json);
    p += json.length;
    out[p] = 0xFE;
    return out;
  }

  static NdefTlv? findTlv(Uint8List userArea) {
    var i = 0;
    while (i < userArea.length) {
      final type = userArea[i];
      if (type == 0x00) {
        i++;
        continue;
      }
      if (type == 0xFE || i + 1 >= userArea.length) {
        return null;
      }
      final shortLength = userArea[i + 1];
      if (type == 0x03) {
        if (shortLength == 0xFF) {
          if (i + 3 >= userArea.length) {
            return null;
          }
          final length = (userArea[i + 2] << 8) | userArea[i + 3];
          final offset = i + 4;
          if (offset + length > userArea.length) {
            return null;
          }
          return NdefTlv(offset, length);
        }
        final offset = i + 2;
        if (offset + shortLength > userArea.length) {
          return null;
        }
        return NdefTlv(offset, shortLength);
      }

      final length = shortLength;
      if (length == 0xFF) {
        if (i + 3 >= userArea.length) {
          return null;
        }
        final longLength = (userArea[i + 2] << 8) | userArea[i + 3];
        i += 4 + longLength;
      } else {
        i += 2 + length;
      }
    }
    return null;
  }

  static OpenSpoolTagData parse(Uint8List userArea) {
    final tlv = findTlv(userArea);
    if (tlv == null) {
      throw const OpenSpoolFormatException('В области NTAG нет NDEF TLV.');
    }

    final ndef = userArea.sublist(tlv.offset, tlv.offset + tlv.length);
    if (ndef.length < 3) {
      throw const OpenSpoolFormatException('NDEF-запись слишком короткая.');
    }

    final header = ndef[0];
    final shortRecord = (header & 0x10) != 0;
    final hasId = (header & 0x08) != 0;
    final tnf = header & 0x07;
    if (tnf != 0x02) {
      throw const OpenSpoolFormatException('NDEF-запись не является MIME.');
    }

    var p = 1;
    final typeLength = ndef[p++];
    int payloadLength;
    if (shortRecord) {
      if (p >= ndef.length) {
        throw const OpenSpoolFormatException('Нет длины NDEF payload.');
      }
      payloadLength = ndef[p++];
    } else {
      if (p + 3 >= ndef.length) {
        throw const OpenSpoolFormatException('Нет длинной длины NDEF payload.');
      }
      payloadLength = (ndef[p] << 24) |
          (ndef[p + 1] << 16) |
          (ndef[p + 2] << 8) |
          ndef[p + 3];
      p += 4;
    }

    var idLength = 0;
    if (hasId) {
      if (p >= ndef.length) {
        throw const OpenSpoolFormatException('Нет длины NDEF ID.');
      }
      idLength = ndef[p++];
    }

    if (p + typeLength + idLength + payloadLength > ndef.length) {
      throw const OpenSpoolFormatException('NDEF payload выходит за границы.');
    }

    final mime = ascii.decode(ndef.sublist(p, p + typeLength));
    p += typeLength + idLength;
    if (mime != 'application/json') {
      throw OpenSpoolFormatException('Неизвестный MIME: $mime');
    }

    final payload = ndef.sublist(p, p + payloadLength);
    final text = utf8.decode(payload);
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const OpenSpoolFormatException('OpenSpool payload — не JSON-объект.');
    }
    return OpenSpoolTagData.fromJson(Map<String, dynamic>.from(decoded));
  }

  static String describeTlv(Uint8List userArea) {
    final tlv = findTlv(userArea);
    if (tlv == null) {
      return 'NDEF не найден';
    }
    return 'NDEF TLV: offset ${tlv.offset}, длина ${tlv.length}';
  }
}
