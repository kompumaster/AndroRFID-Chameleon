import 'dart:typed_data';

import '../../core/chameleon/helpers/utils.dart';
import 'qidi_data.dart';

class QidiBinException implements Exception {
  QidiBinException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QidiBinCodec {
  static const int dumpSize = 1024;
  static const int blockSize = 16;

  static const List<int> _sectorTrailer = [
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0x07, 0x80, 0x69,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
  ];

  static Uint8List encode(QidiTagData data) {
    final dump = Uint8List(dumpSize);
    final uid = (data.uid?.length == 4) ? data.uid! : _uidFor(data);

    final block0 = Uint8List(blockSize);
    block0.setRange(0, 4, uid);
    block0[4] = calculateBcc(uid);
    block0[5] = 0x08;
    block0[6] = 0x00;
    block0[7] = 0x04;
    block0.setRange(8, 16, const [0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69]);
    dump.setRange(0, blockSize, block0);

    final dataOffset = qidiDataBlock * blockSize;
    dump.setRange(dataOffset, dataOffset + blockSize, data.toBlock());

    for (var sector = 0; sector < 16; sector++) {
      final offset = (sector * 4 + 3) * blockSize;
      dump.setRange(offset, offset + blockSize, _sectorTrailer);
    }

    return dump;
  }

  static QidiTagData decode(Uint8List dump) {
    if (dump.length != dumpSize) {
      throw QidiBinException(
        'Ожидался .bin на $dumpSize байт (MIFARE Classic 1K), '
        'получено ${dump.length}.',
      );
    }

    final uid = dump.sublist(0, 4);
    final block = dump.sublist(
      qidiDataBlock * blockSize,
      (qidiDataBlock + 1) * blockSize,
    );
    final data = QidiTagData.fromBlock(block, uid: uid);

    if (data.materialId == 0 || data.colorId == 0) {
      throw QidiBinException(
        'В блоке 4 нет QIDI-данных: материал или цвет равен 0.',
      );
    }
    if (data.colorId < 1 || data.colorId > 24) {
      throw QidiBinException(
        'Неизвестный ID цвета QIDI: ${data.colorId}.',
      );
    }

    return data;
  }

  static Uint8List _uidFor(QidiTagData data) {
    var hash = 0x811C9DC5;
    for (final byte in [data.materialId, data.colorId, data.manufacturerId]) {
      hash = ((hash ^ (byte & 0xFF)) * 0x01000193) & 0xFFFFFFFF;
    }
    return Uint8List.fromList([
      (hash >> 24) & 0xFF,
      (hash >> 16) & 0xFF,
      (hash >> 8) & 0xFF,
      hash & 0xFF,
    ]);
  }
}
