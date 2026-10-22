import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'qidi_cfg_parser.dart';
import 'qidi_data.dart';

class QidiListsStore extends ChangeNotifier {
  static const String _cfgTextKey = 'qidi_cfg_text';
  static const String _cfgNameKey = 'qidi_cfg_name';

  List<QidiCfgSlot>? _slots;
  String? _cfgName;
  Future<void>? _loadFuture;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  bool get hasCfg => _slots != null && _slots!.any((slot) => slot.isActive);
  String? get cfgName => _cfgName;
  List<QidiCfgSlot> get slots => List.unmodifiable(_slots ?? const []);

  Future<void> ensureLoaded() {
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(_cfgTextKey);
      _cfgName = prefs.getString(_cfgNameKey);
      if (text != null && text.trim().isNotEmpty) {
        _slots = QidiCfgParser.parse(text);
      }
    } catch (e) {
      debugPrint('Could not load QIDI CFG: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  List<QidiMaterial> materialsFor(QidiPrinterModel model) {
    final slots = _slots;
    if (slots != null) {
      final materials = QidiCfgParser.toMaterials(slots);
      if (materials.isNotEmpty) {
        return materials;
      }
    }
    return qidiMaterialsFor(model);
  }

  QidiMaterial? materialById(int id, QidiPrinterModel model) {
    for (final material in materialsFor(model)) {
      if (material.id == id) {
        return material;
      }
    }
    return null;
  }

  Future<void> importCfg(String text, {String? name}) async {
    final slots = QidiCfgParser.parse(text);
    if (!slots.any((slot) => slot.isActive)) {
      throw const FormatException('В CFG нет активных материалов');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cfgTextKey, text);
    if (name != null && name.trim().isNotEmpty) {
      await prefs.setString(_cfgNameKey, name.trim());
      _cfgName = name.trim();
    }
    _slots = slots;
    notifyListeners();
  }

  Future<void> clearCfg() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cfgTextKey);
    await prefs.remove(_cfgNameKey);
    _slots = null;
    _cfgName = null;
    notifyListeners();
  }
}
