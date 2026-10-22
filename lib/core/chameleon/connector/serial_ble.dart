import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../helpers/utils.dart';
import 'serial_abstract.dart';

final Guid nrfServiceUuid = Guid('6E400001-B5A3-F393-E0A9-E50E24DCCA9E');
final Guid uartRxUuid = Guid('6E400002-B5A3-F393-E0A9-E50E24DCCA9E');
final Guid uartTxUuid = Guid('6E400003-B5A3-F393-E0A9-E50E24DCCA9E');

class BLESerial extends AbstractSerial {
  BluetoothDevice? _device;

  BluetoothCharacteristic? _rxCharacteristic;
  StreamSubscription<List<int>>? _valueSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  Map<String, Chameleon> chameleonMap = {};
  bool inSearch = false;

  BLESerial({required super.log});

  Future<List<ScanResult>> availableDevices() async {
    if (inSearch) {
      log.w('Multiple BLE searches at once are not allowed');
      return [];
    }

    inSearch = true;
    final found = <String, ScanResult>{};
    StreamSubscription<List<ScanResult>>? subscription;

    try {
      await performDisconnect();
      subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          found[result.device.remoteId.str] = result;
        }
      });

      await FlutterBluePlus.startScan(
        withServices: [nrfServiceUuid],
        timeout: const Duration(seconds: 4),
        androidScanMode: AndroidScanMode.lowLatency,
      );
      await Future<void>.delayed(const Duration(milliseconds: 3500));
      await FlutterBluePlus.stopScan();
    } catch (e) {
      log.e('BLE scan failed: $e');
      rethrow;
    } finally {
      await subscription?.cancel();
      inSearch = false;
    }

    log.d('Found BLE devices: ${found.length}');
    return found.values.toList();
  }

  @override
  bool isManualConnectionSupported() {
    return false;
  }

  @override
  Future<List<Chameleon>> availableChameleons(bool onlyDFU) async {
    if (onlyDFU) {
      return [];
    }

    final output = <Chameleon>[];
    for (final result in await availableDevices()) {
      final name = result.device.advName.isNotEmpty
          ? result.device.advName
          : result.advertisementData.advName;

      final ChameleonDevice device;
      if (name.startsWith('ChameleonUltra')) {
        device = ChameleonDevice.ultra;
      } else if (name.startsWith('ChameleonLite')) {
        device = ChameleonDevice.lite;
      } else {
        continue;
      }

      final chameleon = Chameleon(
        port: result.device.remoteId.str,
        device: device,
        type: ConnectionType.ble,
        dfu: false,
        name: name,
      );
      chameleonMap[result.device.remoteId.str] = chameleon;
      output.add(chameleon);
      log.d('Found Chameleon ${chameleonDeviceName(device)}!');
    }

    return output;
  }

  @override
  Future<bool> connectSpecificDevice(dynamic devicePort) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final connected = await connectSpecificInternal(devicePort);
      if (connected) {
        return true;
      }
    }
    return false;
  }

  Future<bool> connectSpecificInternal(dynamic devicePort) async {
    await performDisconnect();

    final deviceId = devicePort.toString();
    final btDevice = BluetoothDevice.fromId(deviceId);

    try {
      pendingConnection = true;
      await btDevice.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 12),
      );

      final services = await btDevice.discoverServices();
      BluetoothService? uartService;
      for (final service in services) {
        if (service.serviceUuid == nrfServiceUuid) {
          uartService = service;
          break;
        }
      }
      if (uartService == null) {
        log.e('Chameleon UART service not found');
        await btDevice.disconnect();
        pendingConnection = false;
        return false;
      }

      BluetoothCharacteristic? tx;
      BluetoothCharacteristic? rx;
      for (final characteristic in uartService.characteristics) {
        if (characteristic.characteristicUuid == uartTxUuid) {
          tx = characteristic;
        } else if (characteristic.characteristicUuid == uartRxUuid) {
          rx = characteristic;
        }
      }
      if (tx == null || rx == null) {
        log.e('Chameleon UART characteristics not found');
        await btDevice.disconnect();
        pendingConnection = false;
        return false;
      }

      _device = btDevice;
      _rxCharacteristic = rx;

      await tx.setNotifyValue(true);
      _valueSubscription = tx.onValueReceived.listen(
        _onValueReceived,
        onError: (Object error) {
          log.e('BLE notification error: $error');
        },
      );

      _connectionSubscription = btDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnected();
        }
      });

      // Magic handshake used by ChameleonUltraGUI after UART subscription.
      await rx.write(
        [0x11, 0xef, 0x03, 0xfb, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00],
        withoutResponse: false,
      );

      connected = true;
      pendingConnection = false;
      portName = deviceId;
      activeDevicePort = deviceId;
      device = chameleonMap[deviceId]?.device ?? ChameleonDevice.none;
      connectionType = ConnectionType.ble;
      isDFU = false;
      notifyConnectionStateChanged();
      return true;
    } catch (e) {
      log.e('BLE connect error: $e');
      pendingConnection = false;
      await performDisconnect();
      return false;
    }
  }

  Future<void> _onValueReceived(List<int> data) async {
    if (messageCallback == null) {
      return;
    }
    try {
      await messageCallback(Uint8List.fromList(data));
    } catch (e) {
      log.w('Received unexpected data: ${bytesToHex(Uint8List.fromList(data))}');
    }
  }

  void _handleDisconnected() {
    resetConnectionState();
    _rxCharacteristic = null;
    _device = null;
    notifyConnectionStateChanged();
  }

  @override
  Future<bool> performDisconnect() async {
    final hadState = hasConnectionState || _device != null;

    await _valueSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _valueSubscription = null;
    _connectionSubscription = null;

    final device = _device;
    _rxCharacteristic = null;
    _device = null;

    resetConnectionState();

    if (device != null) {
      try {
        await device.disconnect();
      } catch (e) {
        log.w('BLE disconnect error: $e');
      }
    }

    if (hadState) {
      notifyConnectionStateChanged();
    }
    return hadState;
  }

  @override
  Future<bool> write(Uint8List command, {bool firmware = false}) async {
    if (firmware) {
      return false;
    }
    final rx = _rxCharacteristic;
    if (rx == null) {
      return false;
    }
    await rx.write(command, withoutResponse: false);
    return true;
  }
}
