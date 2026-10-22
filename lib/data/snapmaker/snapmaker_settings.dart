import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SnapmakerSettingsStore extends ChangeNotifier {
  static const String defaultHost = '192.168.1.10';
  static const int defaultPort = 7125;
  static const String _hostKey = 'snapmaker_host';
  static const String _portKey = 'snapmaker_port';

  String _host = defaultHost;
  int _port = defaultPort;
  Future<void>? _loadFuture;
  bool _loaded = false;

  String get host => _host;
  int get port => _port;
  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() {
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _host = prefs.getString(_hostKey) ?? defaultHost;
    _port = prefs.getInt(_portKey) ?? defaultPort;
    _loaded = true;
    notifyListeners();
  }

  Future<void> save({required String host, required int port}) async {
    final trimmed = host.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Host не может быть пустым');
    }
    if (port < 1 || port > 65535) {
      throw ArgumentError('Порт должен быть от 1 до 65535');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, trimmed);
    await prefs.setInt(_portKey, port);
    _host = trimmed;
    _port = port;
    _loaded = true;
    notifyListeners();
  }
}
