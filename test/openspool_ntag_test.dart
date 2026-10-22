import 'package:flutter_test/flutter_test.dart';

import 'package:androrfid_chameleon/data/openspool/openspool_ntag.dart';

void main() {
  test('OpenSpool NTAG layouts expose the expected capacity', () {
    expect(OpenSpoolNtagLayout.ntag215.cc, [0xE1, 0x10, 0x3E, 0x00]);
    expect(OpenSpoolNtagLayout.ntag215.totalPages, 135);
    expect(OpenSpoolNtagLayout.ntag215.lastUserPage, 129);
    expect(OpenSpoolNtagLayout.ntag215.userAreaSize, 504);
    expect(OpenSpoolNtagLayout.ntag215.dumpSize, 540);

    expect(OpenSpoolNtagLayout.ntag216.cc, [0xE1, 0x10, 0x6D, 0x00]);
    expect(OpenSpoolNtagLayout.ntag216.totalPages, 231);
    expect(OpenSpoolNtagLayout.ntag216.lastUserPage, 225);
    expect(OpenSpoolNtagLayout.ntag216.userAreaSize, 888);
    expect(OpenSpoolNtagLayout.ntag216.dumpSize, 924);
  });

  test('OpenSpool NTAG layout is detected from CC and dump size', () {
    expect(
      OpenSpoolNtagLayout.fromCc([0xE1, 0x10, 0x3E, 0x00]),
      same(OpenSpoolNtagLayout.ntag215),
    );
    expect(
      OpenSpoolNtagLayout.fromCc([0xE1, 0x10, 0x6D, 0x00]),
      same(OpenSpoolNtagLayout.ntag216),
    );
    expect(OpenSpoolNtagLayout.fromCc([0xE1, 0x10, 0x12, 0x00]), isNull);
    expect(OpenSpoolNtagLayout.isNtag213([0xE1, 0x10, 0x12, 0x00]), isTrue);
    expect(
      OpenSpoolNtagLayout.fromDumpSize(540),
      same(OpenSpoolNtagLayout.ntag215),
    );
    expect(
      OpenSpoolNtagLayout.fromDumpSize(924),
      same(OpenSpoolNtagLayout.ntag216),
    );
    expect(OpenSpoolNtagLayout.fromDumpSize(500), isNull);
  });
}
