import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:androrfid_chameleon/core/ble/connection_service.dart';

void main() {
  test('BLE options default to enabled', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ConnectionService();
    await service.ensureLoaded();

    expect(service.autoScanSetting, isTrue);
    expect(service.autoConnectLast, isTrue);
    expect(service.lastDeviceName, isNull);

    service.dispose();
  });

  test('BLE options and last device are restored', () async {
    SharedPreferences.setMockInitialValues({
      'ble_auto_scan': false,
      'ble_auto_connect_last': false,
      'ble_last_device_port': 'AA:BB:CC:DD:EE:FF',
      'ble_last_device_name': 'ChameleonUltra',
      'ble_last_device_type': 'ultra',
    });
    final service = ConnectionService();
    await service.ensureLoaded();

    expect(service.autoScanSetting, isFalse);
    expect(service.autoConnectLast, isFalse);
    expect(service.lastDeviceName, 'ChameleonUltra');

    service.dispose();
  });
}
