enum OpenSpoolNtagType { ntag215, ntag216 }

extension OpenSpoolNtagTypeLabel on OpenSpoolNtagType {
  String get label => switch (this) {
    OpenSpoolNtagType.ntag215 => 'NTAG215',
    OpenSpoolNtagType.ntag216 => 'NTAG216',
  };
}

class OpenSpoolNtagLayout {
  const OpenSpoolNtagLayout({
    required this.type,
    required this.cc,
    required this.totalPages,
    required this.lastUserPage,
    required this.dumpSize,
    required this.userAreaSize,
  });

  static const int pageSize = 4;
  static const int firstUserPage = 4;
  static const int ccPage = 3;
  static const List<int> ntag213Cc = [0xE1, 0x10, 0x12, 0x00];

  static const OpenSpoolNtagLayout ntag215 = OpenSpoolNtagLayout(
    type: OpenSpoolNtagType.ntag215,
    cc: [0xE1, 0x10, 0x3E, 0x00],
    totalPages: 135,
    lastUserPage: 129,
    dumpSize: 540,
    userAreaSize: 504,
  );

  static const OpenSpoolNtagLayout ntag216 = OpenSpoolNtagLayout(
    type: OpenSpoolNtagType.ntag216,
    cc: [0xE1, 0x10, 0x6D, 0x00],
    totalPages: 231,
    lastUserPage: 225,
    dumpSize: 924,
    userAreaSize: 888,
  );

  static const List<OpenSpoolNtagLayout> supported = [ntag215, ntag216];

  final OpenSpoolNtagType type;
  final List<int> cc;
  final int totalPages;
  final int lastUserPage;
  final int dumpSize;
  final int userAreaSize;

  int get userAreaPages => lastUserPage - firstUserPage + 1;

  static OpenSpoolNtagLayout forType(OpenSpoolNtagType type) {
    return type == OpenSpoolNtagType.ntag215 ? ntag215 : ntag216;
  }

  static OpenSpoolNtagLayout? fromCc(List<int> cc) {
    if (cc.length < 4) {
      return null;
    }
    for (final layout in supported) {
      if (_matches(cc, layout.cc)) {
        return layout;
      }
    }
    return null;
  }

  static OpenSpoolNtagLayout? fromDumpSize(int size) {
    for (final layout in supported) {
      if (layout.dumpSize == size) {
        return layout;
      }
    }
    return null;
  }

  static bool isNtag213(List<int> cc) {
    return cc.length >= 4 && _matches(cc, ntag213Cc);
  }

  static bool _matches(List<int> a, List<int> b) {
    if (a.length < b.length) {
      return false;
    }
    for (var i = 0; i < b.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
