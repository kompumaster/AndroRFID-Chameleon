import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chameleon/bridge/chameleon.dart';
import '../chameleon/connector/serial_abstract.dart';
import '../chameleon/connector/serial_ble.dart';
import '../chameleon/helpers/utils.dart';

enum BleStatus { idle, scanning, connecting, connected, error }

class ConnectionService extends ChangeNotifier {
  static const String _autoScanKey = 'ble_auto_scan';
  static const String _autoConnectLastKey = 'ble_auto_connect_last';
  static const String _lastDevicePortKey = 'ble_last_device_port';
  static const String _lastDeviceNameKey = 'ble_last_device_name';
  static const String _lastDeviceTypeKey = 'ble_last_device_type';

  final Logger log = Logger(level: Level.debug);
  BLESerial? _serialInstance;
  BLESerial get _serial => _serialInstance ??= BLESerial(log: log);

  ChameleonCommunicator? _communicator;
  List<Chameleon> _devices = const [];
  BleStatus _status = BleStatus.idle;
  String? _error;
  String? _firmware;
  Chameleon? _current;
  Chameleon? _lastDevice;
  bool _disposed = false;
  bool _permissionDenied = false;
  bool _manualDisconnect = false;
  bool _autoScanSetting = true;
  bool _autoScanActive = false;
  bool _autoConnectLast = true;
  int _autoScanToken = 0;
  Future<void>? _loadFuture;

  List<Chameleon> get devices => _devices;
  BleStatus get status => _status;
  String? get error => _error;
  String? get firmware => _firmware;
  Chameleon? get current => _current;
  bool get permissionDenied => _permissionDenied;
  bool get isConnected => _status == BleStatus.connected;
  bool get autoScanSetting => _autoScanSetting;
  bool get autoScanActive => _autoScanActive;
  bool get autoConnectLast => _autoConnectLast;
  ChameleonCommunicator? get communicator => _communicator;

  String? get lastDeviceName {
    final name = _lastDevice?.name;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return _lastDevice?.port?.toString();
  }

  Future<void> ensureLoaded() => _loadFuture ??= _loadSettings();

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoScanSetting = prefs.getBool(_autoScanKey) ?? true;
      _autoConnectLast = prefs.getBool(_autoConnectLastKey) ?? true;
      final port = prefs.getString(_lastDevicePortKey);
      final name = prefs.getString(_lastDeviceNameKey);
      final typeName = prefs.getString(_lastDeviceTypeKey);
      if (port != null) {
        final type =
            ChameleonDevice.values
                .where((value) => value.name == typeName)
                .firstOrNull ??
            ChameleonDevice.ultra;
        _lastDevice = Chameleon(
          port: port,
          device: type,
          type: ConnectionType.ble,
          dfu: false,
          name: name,
        );
      }
    } catch (e) {
      debugPrint('Could not load BLE settings: $e');
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _persistSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoScanKey, _autoScanSetting);
      await prefs.setBool(_autoConnectLastKey, _autoConnectLast);
    } catch (e) {
      debugPrint('Could not save BLE settings: $e');
    }
  }

  Future<void> setAutoScanSetting(bool value) async {
    await ensureLoaded();
    if (_disposed || _autoScanSetting == value) {
      return;
    }
    _autoScanSetting = value;
    unawaited(_persistSettings());
    if (!value) {
      stopAutoScan();
    } else if (!isConnected) {
      startAutoScan();
    }
    notifyListeners();
  }

  Future<void> setAutoConnectLast(bool value) async {
    await ensureLoaded();
    if (_disposed || _autoConnectLast == value) {
      return;
    }
    _autoConnectLast = value;
    unawaited(_persistSettings());
    notifyListeners();
  }

  Future<void> _rememberDevice(Chameleon device) async {
    _lastDevice = device;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastDevicePortKey, device.port.toString());
      final name = device.name;
      if (name == null || name.isEmpty) {
        await prefs.remove(_lastDeviceNameKey);
      } else {
        await prefs.setString(_lastDeviceNameKey, name);
      }
      await prefs.setString(_lastDeviceTypeKey, device.device.name);
    } catch (e) {
      debugPrint('Could not save last BLE device: $e');
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final sdk = _androidSdk();
    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      if (sdk == null || sdk < 31) Permission.locationWhenInUse,
    ];

    final statuses = await permissions.request();
    final nearbyGranted =
        (statuses[Permission.bluetoothScan]?.isGranted ?? false) &&
        (statuses[Permission.bluetoothConnect]?.isGranted ?? false);
    final locationGranted =
        statuses[Permission.locationWhenInUse]?.isGranted ?? false;
    final granted =
        nearbyGranted && (sdk == null || sdk >= 31 || locationGranted);

    _permissionDenied = !granted;
    if (!granted) {
      final details = statuses.entries
          .map((entry) => '${entry.key}: ${entry.value.name}')
          .join(', ');
      _error =
          'Нет разрешений Bluetooth. Разрешите «Устройства поблизости» '
          'в настройках приложения. ($details)';
      _status = BleStatus.error;
      notifyListeners();
    }
    return granted;
  }

  Future<void> scan() async {
    if (_status == BleStatus.scanning || _status == BleStatus.connecting) {
      return;
    }
    if (!await ensurePermissions()) {
      return;
    }

    _error = null;
    _permissionDenied = false;
    _devices = const [];
    _status = BleStatus.scanning;
    notifyListeners();

    try {
      _devices = await _serial.availableChameleons(false);
      _status = BleStatus.idle;
    } catch (e) {
      log.e('BLE scan failed: $e');
      _error = 'Ошибка поиска BLE: $e';
      _status = BleStatus.error;
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  void startAutoScan() {
    if (_disposed || _manualDisconnect || isConnected || _autoScanActive) {
      return;
    }
    _autoScanActive = true;
    final token = ++_autoScanToken;
    notifyListeners();
    unawaited(_autoScanLoop(token));
  }

  void stopAutoScan() {
    if (!_autoScanActive) {
      return;
    }
    _autoScanActive = false;
    _autoScanToken++;
    notifyListeners();
  }

  Future<void> _autoScanLoop(int token) async {
    await ensureLoaded();
    try {
      while (_autoScanActive &&
          token == _autoScanToken &&
          !_disposed &&
          !isConnected) {
        if (_status == BleStatus.connecting) {
          break;
        }
        if (_status != BleStatus.scanning) {
          await scan();
        }
        if (!_autoScanActive ||
            token != _autoScanToken ||
            _disposed ||
            isConnected) {
          break;
        }
        if (_status == BleStatus.error) {
          _autoScanActive = false;
          notifyListeners();
          break;
        }
        if (_devices.isNotEmpty) {
          if (_autoConnectLast && _lastDevice != null) {
            final lastPort = _lastDevice!.port.toString();
            Chameleon? match;
            for (final device in _devices) {
              if (device.port.toString() == lastPort) {
                match = device;
                break;
              }
            }
            if (match != null) {
              final connected = await connect(match);
              if (connected) {
                return;
              }
              if (!_autoScanActive || token != _autoScanToken) {
                break;
              }
            }
          }
          _autoScanActive = false;
          notifyListeners();
          break;
        }
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    } finally {
      if (token == _autoScanToken) {
        if (_autoScanActive && !_disposed) {
          _autoScanActive = false;
          notifyListeners();
        }
      }
    }
  }

  Future<bool> connect(Chameleon device) async {
    if (_status == BleStatus.connecting) {
      return false;
    }

    await ensureLoaded();
    if (_disposed) {
      return false;
    }
    stopAutoScan();
    _error = null;
    _current = device;
    _status = BleStatus.connecting;
    notifyListeners();

    try {
      final connected = await _serial.connectSpecificDevice(device.port);
      if (!connected) {
        _error = 'Не удалось подключиться к Chameleon.';
        _status = BleStatus.error;
        notifyListeners();
        return false;
      }

      _serial.connectionStateCallback = _onSerialStateChanged;

      final communicator = ChameleonCommunicator(log, port: _serial);
      _communicator = communicator;

      var deviceName = chameleonDeviceName(device.device);
      try {
        final version = await communicator.getFirmwareVersion();
        final type = await communicator.getDeviceType();
        deviceName = chameleonDeviceName(type);
        _firmware = '$deviceName ${numToVerCode(version.version)}';
      } catch (e) {
        log.w('Could not read firmware info: $e');
        _firmware = deviceName;
      }

      _status = BleStatus.connected;
      unawaited(_rememberDevice(device));
      notifyListeners();
      return true;
    } catch (e) {
      log.e('BLE connect failed: $e');
      _error = 'Ошибка подключения: $e';
      _status = BleStatus.error;
      notifyListeners();
      await _serial.performDisconnect();
      return false;
    }
  }

  Future<void> disconnect() async {
    stopAutoScan();
    _manualDisconnect = true;
    try {
      await _serial.performDisconnect();
    } finally {
      _communicator = null;
      _current = null;
      _firmware = null;
      _error = null;
      _status = BleStatus.idle;
      notifyListeners();
      _manualDisconnect = false;
    }
  }

  int? _androidSdk() {
    final match = RegExp(r'API (\d+)')
        .firstMatch(Platform.operatingSystemVersion);
    return match == null ? null : int.parse(match.group(1)!);
  }

  void _onSerialStateChanged() {
    if (_disposed || _manualDisconnect || _serial.connected) {
      return;
    }
    if (_status != BleStatus.connected) {
      return;
    }
    _communicator = null;
    _current = null;
    _firmware = null;
    _error = 'Соединение с Chameleon потеряно.';
    _status = BleStatus.error;
    notifyListeners();
    if (_autoScanSetting) {
      startAutoScan();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _autoScanActive = false;
    _autoScanToken++;
    final serial = _serialInstance;
    if (serial != null) {
      serial.connectionStateCallback = null;
      unawaited(serial.performDisconnect());
    }
    super.dispose();
  }
}
