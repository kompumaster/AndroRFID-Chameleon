import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/openspool/openspool_data.dart';
import 'data/qidi/qidi_data.dart';

enum TagMode { qidi, openspool }

enum AppLanguage { ru, en }

const Set<String> _russianDefaultCountryCodes = {
  'RU',
  'UA',
  'BY',
  'KZ',
  'UZ',
  'AZ',
  'GE',
  'MD',
  'LT',
  'LV',
  'KG',
  'TJ',
  'AM',
  'TM',
  'EE',
};

AppLanguage defaultLanguageForLocale(String localeName) {
  final parts = localeName.replaceAll('-', '_').split('_');
  String? country;
  for (var i = 1; i < parts.length; i++) {
    final part = parts[i];
    if (part.length == 2 && RegExp(r'^[A-Za-z]{2}$').hasMatch(part)) {
      country = part.toUpperCase();
      break;
    }
  }
  if (country != null) {
    return _russianDefaultCountryCodes.contains(country)
        ? AppLanguage.ru
        : AppLanguage.en;
  }

  final language = parts.first.toLowerCase();
  return const {
        'ru',
        'uk',
        'be',
        'kk',
        'uz',
        'az',
        'ka',
        'ro',
        'ky',
        'tg',
        'hy',
        'tk',
      }.contains(language)
      ? AppLanguage.ru
      : AppLanguage.en;
}

class AppState extends ChangeNotifier {
  AppState() {
    _loadFuture = _load();
  }

  static const String _modeKey = 'tag_mode';
  static const String _qidiModelKey = 'qidi_model';
  static const String _osProfileKey = 'openspool_profile';
  static const String _osTierKey = 'openspool_tier';
  static const String _languageKey = 'app_language';
  static const String _homeTabKey = 'home_tab_v2';
  static const String _qidiMaterialKey = 'qidi_material_id';
  static const String _qidiColorKey = 'qidi_color_id';
  static const String _qidiManufacturerKey = 'qidi_manufacturer_id';

  QidiPrinterModel _qidiModel = QidiPrinterModel.plus4;
  TagMode _mode = TagMode.qidi;
  OpenSpoolProfile _openspoolProfile = OpenSpoolProfile.standard;
  OpenSpoolTier _openspoolTier = OpenSpoolTier.standard;
  AppLanguage _language = defaultLanguageForLocale(Platform.localeName);
  int _homeTab = 0;
  int? _qidiMaterialId;
  int _qidiColorId = 1;
  int _qidiManufacturerId = 1;
  Future<void>? _loadFuture;
  bool _loaded = false;

  Future<void> ensureLoaded() => _loadFuture ??= _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeName = prefs.getString(_modeKey);
      final modelName = prefs.getString(_qidiModelKey);
      final profileName = prefs.getString(_osProfileKey);
      final tierName = prefs.getString(_osTierKey);
      final languageName = prefs.getString(_languageKey);
      _homeTab = (prefs.getInt(_homeTabKey) ?? 0).clamp(0, 3);
      _qidiMaterialId = prefs.getInt(_qidiMaterialKey);
      _qidiColorId = prefs.getInt(_qidiColorKey) ?? 1;
      _qidiManufacturerId = prefs.getInt(_qidiManufacturerKey) ?? 1;

      if (modeName != null) {
        _mode =
            TagMode.values
                .where((value) => value.name == modeName)
                .firstOrNull ??
            _mode;
      }
      if (modelName != null) {
        _qidiModel =
            QidiPrinterModel.values
                .where((value) => value.name == modelName)
                .firstOrNull ??
            _qidiModel;
      }
      if (profileName != null) {
        _openspoolProfile =
            OpenSpoolProfile.values
                .where((value) => value.name == profileName)
                .firstOrNull ??
            _openspoolProfile;
      }
      if (tierName != null) {
        _openspoolTier =
            OpenSpoolTier.values
                .where((value) => value.name == tierName)
                .firstOrNull ??
            _openspoolTier;
      }
      if (languageName != null) {
        _language =
            AppLanguage.values
                .where((value) => value.name == languageName)
                .firstOrNull ??
            _language;
      }
      if (_openspoolProfile == OpenSpoolProfile.standard &&
          _openspoolTier == OpenSpoolTier.all) {
        _openspoolTier = OpenSpoolTier.standard;
      }
      if (_openspoolProfile == OpenSpoolProfile.u1 &&
          _openspoolTier == OpenSpoolTier.basic) {
        _openspoolTier = OpenSpoolTier.standard;
      }
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Could not load app settings: $e');
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    if (!_loaded) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, _mode.name);
      await prefs.setString(_qidiModelKey, _qidiModel.name);
      await prefs.setString(_osProfileKey, _openspoolProfile.name);
      await prefs.setString(_osTierKey, _openspoolTier.name);
      await prefs.setString(_languageKey, _language.name);
      await prefs.setInt(_homeTabKey, _homeTab);
      await prefs.setInt(_qidiColorKey, _qidiColorId);
      await prefs.setInt(_qidiManufacturerKey, _qidiManufacturerId);
      if (_qidiMaterialId == null) {
        await prefs.remove(_qidiMaterialKey);
      } else {
        await prefs.setInt(_qidiMaterialKey, _qidiMaterialId!);
      }
    } catch (e) {
      debugPrint('Could not save app settings: $e');
    }
  }

  QidiPrinterModel get qidiModel => _qidiModel;

  set qidiModel(QidiPrinterModel value) {
    if (_qidiModel == value) {
      return;
    }
    _qidiModel = value;
    unawaited(_persist());
    notifyListeners();
  }

  TagMode get mode => _mode;

  set mode(TagMode value) {
    if (_mode == value) {
      return;
    }
    _mode = value;
    unawaited(_persist());
    notifyListeners();
  }

  OpenSpoolProfile get openspoolProfile => _openspoolProfile;

  set openspoolProfile(OpenSpoolProfile value) {
    if (_openspoolProfile == value) {
      return;
    }
    _openspoolProfile = value;
    unawaited(_persist());
    notifyListeners();
  }

  OpenSpoolTier get openspoolTier => _openspoolTier;

  set openspoolTier(OpenSpoolTier value) {
    if (_openspoolTier == value) {
      return;
    }
    _openspoolTier = value;
    unawaited(_persist());
    notifyListeners();
  }

  AppLanguage get language => _language;

  set language(AppLanguage value) {
    if (_language == value) {
      return;
    }
    _language = value;
    unawaited(_persist());
    notifyListeners();
  }

  int get homeTab => _homeTab;

  set homeTab(int value) {
    final normalized = value.clamp(0, 3);
    if (_homeTab == normalized) {
      return;
    }
    _homeTab = normalized;
    unawaited(_persist());
    notifyListeners();
  }

  int? get qidiMaterialId => _qidiMaterialId;

  set qidiMaterialId(int? value) {
    if (_qidiMaterialId == value) {
      return;
    }
    _qidiMaterialId = value;
    unawaited(_persist());
    notifyListeners();
  }

  int get qidiColorId => _qidiColorId;

  set qidiColorId(int value) {
    if (_qidiColorId == value) {
      return;
    }
    _qidiColorId = value;
    unawaited(_persist());
    notifyListeners();
  }

  int get qidiManufacturerId => _qidiManufacturerId;

  set qidiManufacturerId(int value) {
    if (_qidiManufacturerId == value) {
      return;
    }
    _qidiManufacturerId = value;
    unawaited(_persist());
    notifyListeners();
  }
}
