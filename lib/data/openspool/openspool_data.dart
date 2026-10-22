import 'dart:convert';
import 'dart:typed_data';

import 'openspool_ntag.dart';

enum OpenSpoolProfile { standard, u1 }

enum OpenSpoolTier { basic, standard, all }

class OpenSpoolMaterialPreset {
  const OpenSpoolMaterialPreset(
    this.name,
    this.nozzleMin,
    this.nozzleMax,
    this.bedMin,
    this.bedMax,
  );

  final String name;
  final int nozzleMin;
  final int nozzleMax;
  final int bedMin;
  final int bedMax;
}

class OpenSpoolManufacturer {
  const OpenSpoolManufacturer(this.id, this.name);

  final int id;
  final String name;
}

const List<OpenSpoolMaterialPreset> openSpoolMaterials = [
  OpenSpoolMaterialPreset('PLA', 190, 220, 50, 60),
  OpenSpoolMaterialPreset('PETG', 220, 250, 70, 80),
  OpenSpoolMaterialPreset('ABS', 230, 260, 90, 110),
  OpenSpoolMaterialPreset('ASA', 240, 270, 90, 110),
  OpenSpoolMaterialPreset('TPU', 210, 230, 30, 60),
  OpenSpoolMaterialPreset('PA', 240, 270, 70, 90),
  OpenSpoolMaterialPreset('PA12', 240, 270, 70, 90),
  OpenSpoolMaterialPreset('PC', 270, 310, 100, 120),
  OpenSpoolMaterialPreset('PEEK', 360, 400, 120, 150),
  OpenSpoolMaterialPreset('PVA', 190, 220, 50, 60),
  OpenSpoolMaterialPreset('HIPS', 230, 250, 90, 110),
  OpenSpoolMaterialPreset('PCTG', 220, 250, 70, 80),
  OpenSpoolMaterialPreset('PLA-CF', 190, 220, 50, 60),
  OpenSpoolMaterialPreset('PETG-CF', 230, 260, 70, 80),
  OpenSpoolMaterialPreset('PA-CF', 250, 280, 70, 90),
];

const List<OpenSpoolManufacturer> openSpoolManufacturers = [
  OpenSpoolManufacturer(0, 'Generic'),
  OpenSpoolManufacturer(1, 'Snapmaker'),
  OpenSpoolManufacturer(2, 'SUNLU'),
  OpenSpoolManufacturer(3, 'eSUN'),
  OpenSpoolManufacturer(4, 'Jayo'),
  OpenSpoolManufacturer(5, 'QIDI'),
  OpenSpoolManufacturer(6, 'Bambu Lab'),
  OpenSpoolManufacturer(7, 'Polymaker'),
  OpenSpoolManufacturer(8, 'TECBEARS'),
  OpenSpoolManufacturer(9, 'Giantarm'),
  OpenSpoolManufacturer(10, 'HATCHBOX'),
  OpenSpoolManufacturer(11, 'OVERTURE'),
  OpenSpoolManufacturer(12, 'Prusament'),
  OpenSpoolManufacturer(13, 'TINMORRY'),
  OpenSpoolManufacturer(14, 'Kingroon'),
  OpenSpoolManufacturer(15, 'ELEGOO'),
  OpenSpoolManufacturer(16, 'Creality'),
  OpenSpoolManufacturer(17, 'Deeplee'),
  OpenSpoolManufacturer(18, 'Anycubic'),
  OpenSpoolManufacturer(19, 'FLASHFORGE'),
  OpenSpoolManufacturer(20, 'CC3D'),
  OpenSpoolManufacturer(21, 'Ziro'),
  OpenSpoolManufacturer(22, '3Dgenius'),
  OpenSpoolManufacturer(23, '3DJake'),
  OpenSpoolManufacturer(24, '3DXTECH'),
  OpenSpoolManufacturer(25, '3D BEST-Q'),
  OpenSpoolManufacturer(26, '3D Hero'),
  OpenSpoolManufacturer(27, '3D-Fuel'),
  OpenSpoolManufacturer(28, 'Aceaddity'),
  OpenSpoolManufacturer(29, 'AddNorth'),
  OpenSpoolManufacturer(30, 'Amazon Basics'),
  OpenSpoolManufacturer(31, 'AMOLEN'),
  OpenSpoolManufacturer(32, 'Ankermake'),
  OpenSpoolManufacturer(33, 'Atomic'),
  OpenSpoolManufacturer(34, 'AzureFilm'),
  OpenSpoolManufacturer(35, 'BASF'),
  OpenSpoolManufacturer(36, 'Bblife'),
  OpenSpoolManufacturer(37, 'BCN3D'),
  OpenSpoolManufacturer(38, 'Beyond Plastic'),
  OpenSpoolManufacturer(39, 'California Filament'),
  OpenSpoolManufacturer(40, 'Capricorn'),
  OpenSpoolManufacturer(41, 'colorFabb'),
  OpenSpoolManufacturer(42, 'Comgrow'),
  OpenSpoolManufacturer(43, 'Cookiecad'),
  OpenSpoolManufacturer(44, 'CERPRiSE'),
  OpenSpoolManufacturer(45, 'Das Filament'),
  OpenSpoolManufacturer(46, 'DO3D'),
  OpenSpoolManufacturer(47, 'DOW'),
  OpenSpoolManufacturer(48, 'DSM'),
  OpenSpoolManufacturer(49, 'Duramic'),
  OpenSpoolManufacturer(50, 'Eryone'),
  OpenSpoolManufacturer(51, 'Essentium'),
  OpenSpoolManufacturer(52, 'Extrudr'),
  OpenSpoolManufacturer(53, 'Fiberforce'),
  OpenSpoolManufacturer(54, 'Fiberlogy'),
  OpenSpoolManufacturer(55, 'FilaCube'),
  OpenSpoolManufacturer(56, 'Filamentive'),
  OpenSpoolManufacturer(57, 'Fillamentum'),
  OpenSpoolManufacturer(58, 'Formfutura'),
  OpenSpoolManufacturer(59, 'Francofil'),
  OpenSpoolManufacturer(60, 'FilamentOne'),
  OpenSpoolManufacturer(61, 'Fil X'),
  OpenSpoolManufacturer(62, 'GEEETECH'),
  OpenSpoolManufacturer(63, 'Gizmo Dorks'),
  OpenSpoolManufacturer(64, 'GreenGate3D'),
  OpenSpoolManufacturer(65, 'Hello3D'),
  OpenSpoolManufacturer(66, 'IC3D'),
  OpenSpoolManufacturer(67, 'IEMAI'),
  OpenSpoolManufacturer(68, 'IIID Max'),
  OpenSpoolManufacturer(69, 'INLAND'),
  OpenSpoolManufacturer(70, 'iProspect'),
  OpenSpoolManufacturer(71, 'iSANMATE'),
  OpenSpoolManufacturer(72, 'Justmaker'),
  OpenSpoolManufacturer(73, 'Keene Village Plastics'),
  OpenSpoolManufacturer(74, 'Kexcelled'),
  OpenSpoolManufacturer(75, 'LDO'),
  OpenSpoolManufacturer(76, 'MakerBot'),
  OpenSpoolManufacturer(77, 'MatterHackers'),
  OpenSpoolManufacturer(78, 'MIKA3D'),
  OpenSpoolManufacturer(79, 'NinjaTek'),
  OpenSpoolManufacturer(80, 'Nobufil'),
  OpenSpoolManufacturer(81, 'Novamaker'),
  OpenSpoolManufacturer(82, 'OVVNYXE'),
  OpenSpoolManufacturer(83, 'Priline'),
  OpenSpoolManufacturer(84, 'Printed Solid'),
  OpenSpoolManufacturer(85, 'Protopasta'),
  OpenSpoolManufacturer(86, 'Push Plastic'),
  OpenSpoolManufacturer(87, 'R3D'),
  OpenSpoolManufacturer(88, 'Re-pet3D'),
  OpenSpoolManufacturer(89, 'Recreus'),
  OpenSpoolManufacturer(90, 'Regen'),
  OpenSpoolManufacturer(91, 'Sain SMART'),
  OpenSpoolManufacturer(92, 'SliceWorx'),
  OpenSpoolManufacturer(93, 'SnoLabs'),
  OpenSpoolManufacturer(94, 'Spectrum'),
  OpenSpoolManufacturer(95, 'TTYT3D'),
  OpenSpoolManufacturer(96, 'Tianse'),
  OpenSpoolManufacturer(97, 'UltiMaker'),
  OpenSpoolManufacturer(98, 'Valment'),
  OpenSpoolManufacturer(99, 'Verbatim'),
  OpenSpoolManufacturer(100, 'VO3D'),
  OpenSpoolManufacturer(101, 'Voxelab'),
  OpenSpoolManufacturer(102, 'VOXELPLA'),
  OpenSpoolManufacturer(103, 'YOOPAI'),
  OpenSpoolManufacturer(104, 'Yousu'),
  OpenSpoolManufacturer(105, 'Zyltech'),
];

const List<String> openSpoolDefaultSubtypes = [
  '',
  'Basic',
  'Matte',
  'SnapSpeed',
  'Silk',
  'Support',
  'HF',
  '95A',
  '95A HF',
];

const List<String> openSpoolDefaultColors = [
  '#FFFFFF',
  '#000000',
  '#C5C6C5',
  '#A4FF52',
  '#94DE94',
  '#2971FF',
  '#F67D94',
  '#FFD600',
  '#4ABE4A',
  '#7BBAFF',
  '#10149C',
  '#C5A1FF',
  '#B4FF00',
  '#4179E6',
  '#83CEFF',
  '#A459FF',
  '#FF75B4',
  '#E63431',
  '#F6F6DE',
  '#C5C2C5',
  '#7B3C00',
  '#B4B600',
  '#FF7D00',
  '#A42829',
];

OpenSpoolMaterialPreset? openSpoolMaterialByName(String name) {
  final normalized = name.trim().toLowerCase();
  for (final preset in openSpoolMaterials) {
    if (preset.name.toLowerCase() == normalized) {
      return preset;
    }
  }
  return null;
}

String normalizeHexColor(String value, {bool withHash = true}) {
  var hex = value.trim().replaceAll('#', '').replaceAll(' ', '').toUpperCase();
  if (hex.length == 3) {
    hex = hex.split('').map((char) => '$char$char').join();
  }
  if (hex.isEmpty) {
    hex = 'FFFFFF';
  }
  if (hex.length > 6) {
    hex = hex.substring(0, 6);
  }
  if (hex.length < 6) {
    hex = hex.padLeft(6, '0');
  }
  return withHash ? '#$hex' : hex;
}

String normalizeAlphaHex(String? value) {
  var alpha = (value ?? '').trim().replaceAll('#', '').toUpperCase();
  alpha = alpha.replaceAll(RegExp(r'[^0-9A-F]'), '');
  if (alpha.isEmpty) {
    return 'FF';
  }
  if (alpha.length == 1) {
    alpha = '0$alpha';
  }
  return alpha.substring(0, 2);
}

String newOpenSpoolTagId() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

class OpenSpoolTagData {
  const OpenSpoolTagData({
    required this.type,
    required this.colorHex,
    this.brand,
    this.subtype,
    this.alpha,
    this.id,
    this.minTemp,
    this.maxTemp,
    this.bedMinTemp,
    this.bedMaxTemp,
    this.weight,
    this.diameter,
    this.additionalColorHexes = const [],
    this.rawJson,
    this.uid,
    this.ntagType = OpenSpoolNtagType.ntag215,
  });

  final String type;
  final String colorHex;
  final String? brand;
  final String? subtype;
  final String? alpha;
  final String? id;
  final int? minTemp;
  final int? maxTemp;
  final int? bedMinTemp;
  final int? bedMaxTemp;
  final int? weight;
  final double? diameter;
  final List<String> additionalColorHexes;
  final String? rawJson;
  final Uint8List? uid;
  final OpenSpoolNtagType ntagType;

  Map<String, dynamic> toJson({
    OpenSpoolProfile profile = OpenSpoolProfile.standard,
    OpenSpoolTier tier = OpenSpoolTier.standard,
  }) {
    final json = <String, dynamic>{
      'protocol': 'openspool',
      'version': '1.0',
      'type': type.trim(),
      'color_hex': normalizeHexColor(colorHex, withHash: false),
    };

    final trimmedBrand = brand?.trim() ?? '';
    if (trimmedBrand.isNotEmpty) {
      json['brand'] = trimmedBrand;
    }

    if (minTemp != null) {
      json['min_temp'] = minTemp;
    }
    if (maxTemp != null) {
      json['max_temp'] = maxTemp;
    }

    final isU1 = profile == OpenSpoolProfile.u1;
    if (isU1) {
      final trimmedId = id?.trim() ?? '';
      if (trimmedId.isNotEmpty) {
        json['id'] = trimmedId;
      }
      final trimmedSubtype = subtype?.trim() ?? '';
      json['subtype'] = trimmedSubtype.isEmpty ? 'Basic' : trimmedSubtype;
      json['alpha'] = normalizeAlphaHex(alpha);
      if (bedMinTemp != null) {
        json['bed_min_temp'] = bedMinTemp;
      }
      if (bedMaxTemp != null) {
        json['bed_max_temp'] = bedMaxTemp;
      }
      json['weight'] = weight ?? 1000;
      json['diameter'] = ((diameter ?? 1.75) * 100).round();

      if (tier == OpenSpoolTier.all) {
        final nonEmpty = additionalColorHexes
            .where((value) => value.trim().isNotEmpty)
            .map((value) => normalizeHexColor(value, withHash: false))
            .toList();
        if (nonEmpty.isNotEmpty) {
          json['additional_color_hexes'] = nonEmpty;
        }
      }
    }

    return json;
  }

  String toJsonString({
    OpenSpoolProfile profile = OpenSpoolProfile.standard,
    OpenSpoolTier tier = OpenSpoolTier.standard,
  }) {
    return jsonEncode(toJson(profile: profile, tier: tier));
  }

  factory OpenSpoolTagData.fromJson(Map<String, dynamic> json) {
    if (json['protocol'] != 'openspool') {
      throw const OpenSpoolFormatException('В JSON нет protocol=openspool');
    }
    final type = json['type'];
    if (type is! String || type.trim().isEmpty) {
      throw const OpenSpoolFormatException('В JSON нет поля type');
    }
    final color = json['color_hex'];
    final colorHex = color is String && color.trim().isNotEmpty
        ? normalizeHexColor(color)
        : '#FFFFFF';

    final addColors = <String>[];
    final rawColors = json['additional_color_hexes'];
    if (rawColors is List) {
      for (final value in rawColors) {
        if (value is String && value.trim().isNotEmpty) {
          addColors.add(normalizeHexColor(value));
        }
      }
    }

    return OpenSpoolTagData(
      type: type.trim(),
      colorHex: colorHex,
      brand: _stringValue(json['brand']),
      subtype: _stringValue(json['subtype']),
      alpha: _stringValue(json['alpha']),
      id: _stringValue(json['id']),
      minTemp: _intValue(json['min_temp']),
      maxTemp: _intValue(json['max_temp']),
      bedMinTemp: _intValue(json['bed_min_temp']),
      bedMaxTemp: _intValue(json['bed_max_temp']),
      weight: _intValue(json['weight']),
      diameter: _diameterValue(json['diameter']),
      additionalColorHexes: addColors,
      rawJson: jsonEncode(json),
    );
  }

  String get displayName {
    final parts = <String>[
      if (brand?.trim().isNotEmpty == true) brand!.trim(),
      type.trim(),
      if (subtype?.trim().isNotEmpty == true) subtype!.trim(),
    ];
    return parts.join(' ');
  }

  OpenSpoolTagData withUid(Uint8List? value) {
    return OpenSpoolTagData(
      type: type,
      colorHex: colorHex,
      brand: brand,
      subtype: subtype,
      alpha: alpha,
      id: id,
      minTemp: minTemp,
      maxTemp: maxTemp,
      bedMinTemp: bedMinTemp,
      bedMaxTemp: bedMaxTemp,
      weight: weight,
      diameter: diameter,
      additionalColorHexes: additionalColorHexes,
      rawJson: rawJson,
      uid: value,
      ntagType: ntagType,
    );
  }

  OpenSpoolTagData withNtagType(OpenSpoolNtagType value) {
    return OpenSpoolTagData(
      type: type,
      colorHex: colorHex,
      brand: brand,
      subtype: subtype,
      alpha: alpha,
      id: id,
      minTemp: minTemp,
      maxTemp: maxTemp,
      bedMinTemp: bedMinTemp,
      bedMaxTemp: bedMaxTemp,
      weight: weight,
      diameter: diameter,
      additionalColorHexes: additionalColorHexes,
      rawJson: rawJson,
      uid: uid,
      ntagType: value,
    );
  }

  OpenSpoolTagData withId(String? value) {
    return OpenSpoolTagData(
      type: type,
      colorHex: colorHex,
      brand: brand,
      subtype: subtype,
      alpha: alpha,
      id: value,
      minTemp: minTemp,
      maxTemp: maxTemp,
      bedMinTemp: bedMinTemp,
      bedMaxTemp: bedMaxTemp,
      weight: weight,
      diameter: diameter,
      additionalColorHexes: additionalColorHexes,
      rawJson: rawJson,
      uid: uid,
      ntagType: ntagType,
    );
  }

  static String? _stringValue(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _intValue(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static double? _doubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim().replaceAll(',', '.'));
    }
    return null;
  }

  static double? _diameterValue(dynamic value) {
    final diameter = _doubleValue(value);
    if (diameter == null) {
      return null;
    }
    return diameter >= 10 ? diameter / 100 : diameter;
  }
}

class OpenSpoolFormatException implements Exception {
  const OpenSpoolFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}
