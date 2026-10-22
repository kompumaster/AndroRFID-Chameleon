import 'dart:typed_data';

import '../../core/chameleon/helpers/utils.dart';
import 'openspool_data.dart';
import 'openspool_ndef_codec.dart';
import 'openspool_ntag.dart';

class OpenSpoolBinException implements Exception {
  OpenSpoolBinException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OpenSpoolBinCodec {
  static const int ntag215DumpSize = 540;
  static const int ntag216DumpSize = 924;

  /// Legacy alias for NTAG215 export size.
  static const int dumpSize = ntag215DumpSize;

  static bool isSupportedDumpSize(int size) {
    return OpenSpoolNtagLayout.fromDumpSize(size) != null;
  }

  static Uint8List encode(
    OpenSpoolTagData data, {
    OpenSpoolProfile profile = OpenSpoolProfile.standard,
    OpenSpoolTier tier = OpenSpoolTier.standard,
    OpenSpoolNtagType? ntagType,
    Uint8List? existingDump,
  }) {
    final OpenSpoolNtagLayout layout;
    final Uint8List dump;
    if (existingDump != null) {
      layout = _layoutForDump(existingDump);
      dump = Uint8List.fromList(existingDump);
    } else {
      layout = OpenSpoolNtagLayout.forType(ntagType ?? data.ntagType);
      dump = Uint8List(layout.dumpSize);
      final uid = (data.uid?.length == 7) ? data.uid! : _uidFor(data);
      _writeHeader(dump, uid, layout);
    }

    final payload =
        profile == OpenSpoolProfile.u1 &&
            (data.id == null || data.id!.trim().isEmpty)
        ? data.withId(newOpenSpoolTagId())
        : data;
    final tlv = OpenSpoolNdefCodec.build(
      payload,
      profile: profile,
      tier: tier,
      maxLength: layout.userAreaSize,
    );
    _writeUserArea(dump, tlv, layout);
    return dump;
  }

  static OpenSpoolTagData decode(Uint8List dump) {
    final layout = _layoutForDump(dump);
    final userArea = dump.sublist(
      OpenSpoolNtagLayout.firstUserPage * OpenSpoolNtagLayout.pageSize,
      (layout.lastUserPage + 1) * OpenSpoolNtagLayout.pageSize,
    );
    final data = OpenSpoolNdefCodec.parse(userArea);
    return data
        .withNtagType(layout.type)
        .withUid(Uint8List.fromList(dump.sublist(0, 7)));
  }

  static OpenSpoolNtagLayout _layoutForDump(Uint8List dump) {
    final layout = OpenSpoolNtagLayout.fromDumpSize(dump.length);
    if (layout == null) {
      throw OpenSpoolBinException(
        'Ожидался .bin на $ntag215DumpSize байт (NTAG215) '
        'или $ntag216DumpSize байт (NTAG216), получено ${dump.length}.',
      );
    }
    if (!_matches(dump.sublist(12, 16), layout.cc)) {
      throw OpenSpoolBinException(
        'В дампе нет ${layout.type.label} CC '
        '${layout.cc.map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}.',
      );
    }
    return layout;
  }

  static void _writeHeader(
    Uint8List dump,
    Uint8List uid,
    OpenSpoolNtagLayout layout,
  ) {
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
    dump.setRange(12, 16, layout.cc);
  }

  static void _writeUserArea(
    Uint8List dump,
    Uint8List tlv,
    OpenSpoolNtagLayout layout,
  ) {
    final start =
        OpenSpoolNtagLayout.firstUserPage * OpenSpoolNtagLayout.pageSize;
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
