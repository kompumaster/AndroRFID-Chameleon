import 'dart:typed_data';

import '../../core/chameleon/bridge/chameleon.dart';
import '../data/qidi/qidi_data.dart';

class QidiTagException implements Exception {
  QidiTagException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QidiTagService {
  QidiTagService(this.communicator);

  final ChameleonCommunicator communicator;

  Future<void> _ensureReaderMode() async {
    if (!await communicator.isReaderDeviceMode()) {
      await communicator.setReaderDeviceMode(true);
    }
  }

  Future<QidiTagData> read() async {
    try {
      await _ensureReaderMode();
      final card = await communicator.scan14443aTag();
      if (card == null) {
        throw QidiTagException(
          'Метка не найдена. Приложите QIDI-метку к Chameleon.',
        );
      }
      final block = await communicator.mf1ReadBlock(
        qidiDataBlock,
        0x60,
        Uint8List.fromList(qidiDefaultKeyA),
      );
      if (block.length < qidiBlockSize) {
        throw QidiTagException(
          'Метка вернула ${block.length} байт вместо $qidiBlockSize.',
        );
      }
      return QidiTagData.fromBlock(block, uid: card.uid);
    } on QidiTagException {
      rethrow;
    } catch (e) {
      throw QidiTagException(
        'Не удалось прочитать QIDI-метку. Проверьте, что это MIFARE Classic 1K '
        'и метка лежит на Chameleon. Ошибка: $e',
      );
    }
  }

  Future<void> write(QidiTagData data) async {
    final expected = data.toBlock();
    try {
      await _ensureReaderMode();
      final card = await communicator.scan14443aTag();
      if (card == null) {
        throw QidiTagException(
          'Метка не найдена. Приложите QIDI-метку к Chameleon.',
        );
      }
      final written = await communicator.mf1WriteBlock(
        qidiDataBlock,
        0x60,
        Uint8List.fromList(qidiDefaultKeyA),
        expected,
      );
      if (!written) {
        throw QidiTagException('Chameleon не подтвердил запись блока $qidiDataBlock.');
      }

      final readBack = await communicator.mf1ReadBlock(
        qidiDataBlock,
        0x60,
        Uint8List.fromList(qidiDefaultKeyA),
      );
      if (!_blockMatches(readBack, expected)) {
        throw QidiTagException('Проверка после записи не совпала.');
      }
    } on QidiTagException {
      rethrow;
    } catch (e) {
      throw QidiTagException(
        'Не удалось записать QIDI-метку. Ошибка: $e',
      );
    }
  }

  bool _blockMatches(Uint8List actual, Uint8List expected) {
    if (actual.length < expected.length) {
      return false;
    }
    for (var i = 0; i < expected.length; i++) {
      if (actual[i] != expected[i]) {
        return false;
      }
    }
    return true;
  }
}
