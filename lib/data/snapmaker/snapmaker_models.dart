import 'dart:typed_data';

import '../openspool/openspool_data.dart';
import '../qidi/qidi_data.dart';

class SnapmakerToolHead {
  const SnapmakerToolHead({
    required this.index,
    required this.material,
    required this.subtype,
    required this.colorHex,
    required this.empty,
  });

  final int index;
  final String material;
  final String subtype;
  final String colorHex;
  final bool empty;

  String get label {
    if (empty || material.trim().isEmpty) {
      return 'ToolHead $index · пусто';
    }
    final subtypeText = subtype.trim().isEmpty ? '' : ' ${subtype.trim()}';
    return 'ToolHead $index · $material$subtypeText';
  }
}

class SnapmakerTagPayload {
  const SnapmakerTagPayload({
    this.vendor,
    required this.mainType,
    this.subtype,
    this.colorHex,
    this.alpha,
    this.minTemp,
    this.maxTemp,
    this.bedTemp,
    this.uid,
  });

  final String? vendor;
  final String mainType;
  final String? subtype;
  final String? colorHex;
  final int? alpha;
  final int? minTemp;
  final int? maxTemp;
  final int? bedTemp;
  final Uint8List? uid;

  factory SnapmakerTagPayload.fromQidi(
    QidiTagData data,
    QidiPrinterModel model,
  ) {
    final material = qidiMaterialById(data.materialId, model);
    final color = qidiColorById(data.colorId);
    final manufacturer = qidiManufacturerById(data.manufacturerId);
    final preset = openSpoolMaterialByName(material?.name ?? '');
    return SnapmakerTagPayload(
      vendor: manufacturer?.name,
      mainType: material?.name ?? 'Material ${data.materialId}',
      colorHex: color?.hex,
      minTemp: material?.nozzleMin,
      maxTemp: material?.nozzleMax,
      bedTemp: preset?.bedMax,
      uid: data.uid,
    );
  }

  factory SnapmakerTagPayload.fromOpenSpool(OpenSpoolTagData data) {
    return SnapmakerTagPayload(
      vendor: data.brand,
      mainType: data.type,
      subtype: data.subtype,
      colorHex: data.colorHex,
      alpha: _alphaValue(data.alpha),
      minTemp: data.minTemp,
      maxTemp: data.maxTemp,
      bedTemp: data.bedMaxTemp ?? data.bedMinTemp,
      uid: data.uid,
    );
  }

  Map<String, dynamic> toJson(int toolHead) {
    final info = <String, dynamic>{
      if (vendor?.trim().isNotEmpty == true) 'VENDOR': vendor!.trim(),
      'MAIN_TYPE': mainType.trim(),
      if (subtype?.trim().isNotEmpty == true) 'SUB_TYPE': subtype!.trim(),
      if (colorHex != null && colorHex!.trim().isNotEmpty)
        'RGB_1': _rgbFromHex(colorHex!),
      if (alpha != null) 'ALPHA': alpha,
      if (minTemp != null) 'HOTEND_MIN_TEMP': minTemp,
      if (maxTemp != null) 'HOTEND_MAX_TEMP': maxTemp,
      if (bedTemp != null) 'BED_TEMP': bedTemp,
      'CARD_UID': uid?.toList() ?? <int>[],
    };

    return {
      'channel': toolHead - 1,
      'info': info,
    };
  }

  static int? _alphaValue(String? alpha) {
    if (alpha == null || alpha.trim().isEmpty) {
      return null;
    }
    return int.tryParse(
      alpha.trim().replaceAll('#', ''),
      radix: 16,
    );
  }

  static int _rgbFromHex(String hex) {
    final value = hex.trim().replaceAll('#', '');
    return int.tryParse(value, radix: 16) ?? 0xFFFFFF;
  }
}
