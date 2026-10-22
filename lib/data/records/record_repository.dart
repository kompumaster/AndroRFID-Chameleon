import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../openspool/openspool_data.dart';
import '../qidi/qidi_data.dart';
import 'tag_record.dart';

class RecordRepository extends ChangeNotifier {
  final List<TagRecord> _records = [];
  Future<void>? _loadFuture;
  File? _file;
  bool _loaded = false;

  List<TagRecord> get records => List.unmodifiable(_records);
  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() {
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    final directory = await getApplicationDocumentsDirectory();
    _file = File('${directory.path}${Platform.pathSeparator}records.json');
    if (!await _file!.exists()) {
      _loaded = true;
      notifyListeners();
      return;
    }

    try {
      final content = await _file!.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! List) {
        return;
      }
      _records
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map(
                (item) => TagRecord.fromJson(Map<String, dynamic>.from(item)),
              )
              .whereType<TagRecord>(),
        );
      _records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      var migrated = false;
      for (var i = 0; i < _records.length; i++) {
        final record = _records[i];
        final data = record.openspoolData;
        if (record.type == TagRecordType.openspool &&
            record.openspoolProfile == OpenSpoolProfile.u1 &&
            data != null &&
            (data.id == null || data.id!.trim().isEmpty)) {
          _records[i] = record.copyWith(
            openspoolData: data.withId(newOpenSpoolTagId()),
            touch: false,
          );
          migrated = true;
        }
      }
      if (migrated) {
        await _persist();
      }
    } catch (e) {
      debugPrint('Could not load records: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<TagRecord> saveQidi({
    required QidiPrinterModel model,
    required QidiTagData data,
    String? name,
  }) async {
    await ensureLoaded();

    final generated = name?.trim().isNotEmpty == true
        ? name!.trim()
        : _qidiName(model, data);
    final uniqueName = _uniqueName(generated);

    final now = DateTime.now();
    final record = TagRecord(
      id: now.microsecondsSinceEpoch.toString(),
      name: uniqueName,
      type: TagRecordType.qidi,
      createdAt: now,
      updatedAt: now,
      qidiModel: model,
      qidiData: data,
    );

    _records.insert(0, record);
    await _persist();
    notifyListeners();
    return record;
  }

  Future<TagRecord> saveOpenSpool({
    required OpenSpoolTagData data,
    required OpenSpoolProfile profile,
    required OpenSpoolTier tier,
    String? name,
  }) async {
    await ensureLoaded();

    final normalizedData =
        profile == OpenSpoolProfile.u1 &&
            (data.id == null || data.id!.trim().isEmpty)
        ? data.withId(newOpenSpoolTagId())
        : data;
    final generated = name?.trim().isNotEmpty == true
        ? name!.trim()
        : _openSpoolName(normalizedData);
    final uniqueName = _uniqueName(generated);

    final now = DateTime.now();
    final record = TagRecord(
      id: now.microsecondsSinceEpoch.toString(),
      name: uniqueName,
      type: TagRecordType.openspool,
      createdAt: now,
      updatedAt: now,
      openspoolProfile: profile,
      openspoolTier: tier,
      openspoolData: normalizedData,
    );

    _records.insert(0, record);
    await _persist();
    notifyListeners();
    return record;
  }

  Future<void> updateOpenSpoolData(String id, OpenSpoolTagData data) async {
    await ensureLoaded();
    final index = _records.indexWhere((record) => record.id == id);
    if (index < 0) {
      return;
    }
    _records[index] = _records[index].copyWith(openspoolData: data);
    await _persist();
    notifyListeners();
  }

  Future<void> rename(String id, String name) async {
    await ensureLoaded();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Имя не может быть пустым');
    }

    final index = _records.indexWhere((record) => record.id == id);
    if (index < 0) {
      return;
    }
    _records[index] = _records[index].copyWith(
      name: _uniqueName(trimmed, excludeId: id),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await ensureLoaded();
    _records.removeWhere((record) => record.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final file = _file;
    if (file == null) {
      return;
    }
    await file.writeAsString(
      jsonEncode(_records.map((record) => record.toJson()).toList()),
      flush: true,
    );
  }

  String _qidiName(QidiPrinterModel model, QidiTagData data) {
    final material = qidiMaterialById(data.materialId, model);
    final color = qidiColorById(data.colorId);
    final printer = model == QidiPrinterModel.q2 ? 'Q2' : 'Plus 4';
    return 'QIDI $printer ${material?.name ?? 'Material ${data.materialId}'} '
        '${color?.name ?? 'Color ${data.colorId}'}';
  }

  String _openSpoolName(OpenSpoolTagData data) {
    final color = data.colorHex.replaceAll('#', '');
    return 'OpenSpool ${data.displayName} #$color';
  }

  String _uniqueName(String base, {String? excludeId}) {
    var candidate = base;
    var index = 2;
    while (_records.any(
      (record) => record.name == candidate && record.id != excludeId,
    )) {
      candidate = '$base $index';
      index++;
    }
    return candidate;
  }
}
