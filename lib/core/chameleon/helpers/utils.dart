import 'dart:typed_data';

import '../connector/serial_abstract.dart';
import 'definitions.dart';

Future<void> asyncSleep(int milliseconds) async {
  await Future<void>.delayed(Duration(milliseconds: milliseconds));
}

String bytesToHex(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

String bytesToHexSpace(Uint8List bytes) {
  return bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join(' ')
      .toUpperCase();
}

Uint8List hexToBytes(String hex) {
  hex = hex.replaceAll(' ', '');
  final bytes = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return Uint8List.fromList(bytes);
}

int bytesToU8(Uint8List byteArray) {
  return byteArray.buffer.asByteData().getUint8(0);
}

int bytesToU16(Uint8List byteArray) {
  return byteArray.buffer.asByteData().getUint16(0, Endian.big);
}

int bytesToU32(Uint8List byteArray) {
  return byteArray.buffer.asByteData().getUint32(0, Endian.big);
}

int bytesToU64(Uint8List byteArray) {
  return byteArray.buffer.asByteData().getUint64(0, Endian.big);
}

int parityToInt(int ntParErr) {
  return int.parse([
    (ntParErr >> 3) & 1,
    (ntParErr >> 2) & 1,
    (ntParErr >> 1) & 1,
    ntParErr & 1,
  ].join());
}

int _swapEndian(int x) {
  x = (x >> 8 & 0xff00ff) | (x & 0xff00ff) << 8;
  x = (x >> 16) | (x << 16);
  return x & 0xffffffff;
}

int prngSuccessor(int x, int n) {
  x = _swapEndian(x);

  while (n > 0) {
    x = (x >> 1) | (((x >> 16) ^ (x >> 18) ^ (x >> 19) ^ (x >> 21)) << 31);
    x = x & 0xffffffff;
    n--;
  }

  return _swapEndian(x);
}

int reconstructFullNt(Uint8List responseData, int offset) {
  final nt = bytesToU16(responseData.sublist(offset, offset + 2));
  return (nt << 16) | prngSuccessor(nt, 16);
}

Uint8List u8ToBytes(int u8) {
  final byteData = ByteData(1)..setUint8(0, u8);
  return byteData.buffer.asUint8List();
}

Uint8List u16ToBytes(int u16) {
  final byteData = ByteData(2)..setUint16(0, u16);
  return byteData.buffer.asUint8List();
}

Uint8List u32ToBytes(int u32) {
  final byteData = ByteData(4)..setUint32(0, u32);
  return byteData.buffer.asUint8List();
}

Uint8List u64ToBytes(int u64) {
  final byteData = ByteData(8)..setUint64(0, u64, Endian.big);
  return byteData.buffer.asUint8List();
}

bool isValidHexString(String hexString) {
  return RegExp(r'^[A-Fa-f0-9]+$').hasMatch(hexString);
}

int calculateCRC32(List<int> toTransmit, int crc) {
  final crcTable = Uint32List(256);

  for (var i = 0; i < 256; i++) {
    var c = i;
    for (var j = 0; j < 8; j++) {
      if ((c & 1) != 0) {
        c = 0xEDB88320 ^ (c >> 1);
      } else {
        c = c >> 1;
      }
    }
    crcTable[i] = c;
  }

  crc = 0xFFFFFFFF - crc;

  for (final byte in toTransmit) {
    crc = (crc >> 8) ^ crcTable[(crc ^ byte) & 0xFF];
  }

  return crc ^ 0xFFFFFFFF;
}

TagType numberToChameleonTag(int type) {
  for (final value in TagType.values) {
    if (value.value == type) {
      return value;
    }
  }
  return TagType.unknown;
}

List<TagType> getTagTypes() {
  return TagType.values;
}

TagType getTagTypeByValue(int value) {
  return TagType.values.firstWhere(
    (element) => element.value == value,
    orElse: () => TagType.unknown,
  );
}

TagFrequency chameleonTagToFrequency(TagType tag) {
  if (getTagTypesByFrequency(TagFrequency.lf).contains(tag)) {
    return TagFrequency.lf;
  }
  return TagFrequency.hf;
}

int calculateBcc(Uint8List data) {
  var bcc = 0;
  for (final byte in data) {
    bcc ^= byte;
  }
  return bcc;
}

int getBlockCountForTagType(TagType tagType) {
  switch (tagType) {
    case TagType.mifareMini:
      return 20;
    case TagType.mifare1K:
      return 64;
    case TagType.mifare2K:
      return 128;
    case TagType.mifare4K:
      return 256;
    case TagType.ultralight:
    case TagType.ultralightC:
      return 16;
    case TagType.ultralight11:
    case TagType.ultralight21:
      return 20;
    case TagType.ntag210:
      return 16;
    case TagType.ntag212:
      return 41;
    case TagType.ntag213:
      return 45;
    case TagType.ntag215:
      return 135;
    case TagType.ntag216:
      return 231;
    default:
      return 64;
  }
}

int getMemorySizeForTagType(TagType tagType) {
  switch (tagType) {
    case TagType.ultralight:
    case TagType.ultralightC:
      return 64;
    case TagType.ultralight11:
    case TagType.ultralight21:
      return 80;
    case TagType.ntag210:
      return 64;
    case TagType.ntag212:
      return 164;
    case TagType.ntag213:
      return 180;
    case TagType.ntag215:
      return 540;
    case TagType.ntag216:
      return 924;
    default:
      return 64;
  }
}

String chameleonDeviceName(ChameleonDevice device) {
  return (device == ChameleonDevice.ultra) ? 'Ultra' : 'Lite';
}

ButtonConfig getButtonConfigType(int value) {
  if (value == 1) {
    return ButtonConfig.cycleForward;
  } else if (value == 2) {
    return ButtonConfig.cycleBackward;
  } else if (value == 3) {
    return ButtonConfig.cloneUID;
  } else if (value == 4) {
    return ButtonConfig.chargeStatus;
  }
  return ButtonConfig.disable;
}

AnimationSetting getAnimationModeType(int value) {
  if (value == 0) {
    return AnimationSetting.full;
  } else if (value == 1) {
    return AnimationSetting.minimal;
  } else if (value == 2) {
    return AnimationSetting.none;
  } else if (value == 3) {
    return AnimationSetting.symmetric;
  }
  return AnimationSetting.none;
}

List<TagType> getTagTypesByFrequency(TagFrequency frequency) {
  if (frequency == TagFrequency.hf) {
    return [
      TagType.mifare1K,
      TagType.mifare2K,
      TagType.mifare4K,
      TagType.mifareMini,
      TagType.ntag210,
      TagType.ntag212,
      TagType.ntag213,
      TagType.ntag215,
      TagType.ntag216,
      TagType.ultralight,
      TagType.ultralightC,
      TagType.ultralight11,
      TagType.ultralight21,
      TagType.hf14a4,
    ];
  } else if (frequency == TagFrequency.lf) {
    return [
      TagType.em410X,
      TagType.em410X16,
      TagType.em410X32,
      TagType.em410X64,
      TagType.em410XElectra,
      TagType.hidProx,
      TagType.viking,
      TagType.pac,
      TagType.ioProx,
      TagType.idteck,
    ];
  }
  return [TagType.unknown];
}

int evenParity32(int n) {
  var ret = 0;
  for (var i = 0; i < 32; i++) {
    if ((n & (1 << i)) != 0) {
      ret++;
    }
  }
  return ret % 2;
}

TagType getTagTypeByDumpSize(int size) {
  switch (size) {
    case 320:
      return TagType.mifareMini;
    case 1024:
    case 1088:
    case 1152:
      return TagType.mifare1K;
    case 2048:
      return TagType.mifare2K;
    case 4096:
      return TagType.mifare4K;
    case 64:
      return TagType.ultralight;
    case 192:
      return TagType.ultralightC;
    case 80:
      return TagType.ultralight11;
    case 164:
      return TagType.ultralight21;
    case 180:
      return TagType.ntag213;
    case 540:
      return TagType.ntag215;
    case 924:
      return TagType.ntag216;
  }
  return TagType.unknown;
}

String numToVerCode(int versionCode) {
  final major = (versionCode >> 8) & 0xFF;
  final minor = versionCode & 0xFF;
  return '$major.$minor';
}

int uidSizeForLfTag(TagType type) {
  if (type == TagType.em410XElectra) {
    return 13;
  } else if (isEM410X(type)) {
    return 5;
  } else if (type == TagType.hidProx) {
    return 5;
  } else if (type == TagType.viking) {
    return 4;
  } else if (type == TagType.pac) {
    return 8;
  } else if (type == TagType.ioProx) {
    return 16;
  } else if (type == TagType.idteck) {
    return 8;
  }
  return 0;
}

bool isEM410X(TagType type) {
  return [
    TagType.em410X,
    TagType.em410X16,
    TagType.em410X32,
    TagType.em410X64,
    TagType.em410XElectra,
  ].contains(type);
}

String getNameForHIDProxType(int type) {
  return [
    'HID H10301 26-bit',
    'Indala 26-bit',
    'Indala 27-bit',
    'Indala ASC 27-bit',
    'Tecom 27-bit',
    '2804 Wiegand 28-bit',
    'Indala 29-bit',
    'ATS Wiegand 30-bit',
    'HID ADT 31-bit',
    'HID Check Point 32-bit',
    'HID Hewlett-Packard 32-bit',
    'Kastle 32-bit',
    'Indala/Kantech KFS 32-bit',
    'Wiegand 32-bit',
    'HID D10202 33-bit',
    'HID H10306 34-bit',
    'Honeywell/Northern N10002 34-bit',
    'Indala Optus 34-bit',
    'Cardkey Smartpass 34-bit',
    'BQT 34-bit',
    'HID Corporate 1000 35-bit Std',
    'HID KeyScan 36-bit',
    'HID Simplex 36-bit',
    'HID 36-bit Siemens',
    'HID H10320 37-bit BCD',
    'HID H10302 37-bit huge ID',
    'HID H10304 37-bit',
    'HID P10004 37-bit PCSC',
    'HID Generic 37-bit',
    'PointGuard MDI 37-bit',
  ][type - 1];
}

