import 'dart:typed_data';

enum QidiPrinterModel {
  plus4('QIDI Plus 4 / Max 4'),
  q2('QIDI Q2');

  const QidiPrinterModel(this.label);

  final String label;
}

class QidiMaterial {
  const QidiMaterial(this.id, this.name, this.nozzleMin, this.nozzleMax);

  final int id;
  final String name;
  final int nozzleMin;
  final int nozzleMax;
}

class QidiColor {
  const QidiColor(this.id, this.name, this.rgb565);

  final int id;
  final String name;
  final int rgb565;

  String get hex {
    final r = ((rgb565 >> 11) & 0x1F) * 255 ~/ 31;
    final g = ((rgb565 >> 5) & 0x3F) * 255 ~/ 63;
    final b = (rgb565 & 0x1F) * 255 ~/ 31;
    final value = '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
    return '#${value.toUpperCase()}';
  }
}

class QidiManufacturer {
  const QidiManufacturer(this.id, this.name);

  final int id;
  final String name;
}

/// Materials known by the QIDI Plus 4 / Max 4 firmware.
const List<QidiMaterial> qidiPlus4Materials = [
  QidiMaterial(1, 'PLA', 190, 240),
  QidiMaterial(41, 'PETG', 220, 270),
  QidiMaterial(11, 'ABS', 240, 280),
  QidiMaterial(18, 'ASA', 240, 280),
  QidiMaterial(12, 'ABS-GF', 240, 280),
  QidiMaterial(13, 'ABS-Metal', 240, 280),
  QidiMaterial(14, 'ABS-Odorless', 240, 280),
  QidiMaterial(19, 'ASA-AERO', 240, 280),
  QidiMaterial(25, 'PA12-CF', 260, 300),
  QidiMaterial(30, 'PAHT-CF', 300, 320),
  QidiMaterial(31, 'PAHT-GF', 300, 320),
  QidiMaterial(34, 'PC/ABS-FR', 260, 280),
  QidiMaterial(37, 'PET-CF', 280, 320),
  QidiMaterial(38, 'PET-GF', 280, 320),
  QidiMaterial(39, 'PETG Basic', 240, 280),
  QidiMaterial(45, 'PETG Translucent', 240, 280),
  QidiMaterial(40, 'PETG-Though', 240, 275),
  QidiMaterial(7, 'PLA Basic', 190, 240),
  QidiMaterial(2, 'PLA Matte', 190, 240),
  QidiMaterial(8, 'PLA Matte Basic', 190, 230),
  QidiMaterial(3, 'PLA Metal', 190, 240),
  QidiMaterial(4, 'PLA Silk', 190, 240),
  QidiMaterial(5, 'PLA-CF', 210, 250),
  QidiMaterial(6, 'PLA-Wood', 190, 240),
  QidiMaterial(44, 'PPS-CF', 300, 350),
  QidiMaterial(47, 'PVA', 210, 250),
  QidiMaterial(32, 'Support For PAHT', 260, 280),
  QidiMaterial(33, 'Support For PET/PA', 260, 280),
  QidiMaterial(50, 'TPU', 200, 250),
  QidiMaterial(49, 'TPU-AERO', 200, 250),
  QidiMaterial(24, 'UltraPA', 260, 300),
  QidiMaterial(26, 'UltraPA-CF25', 300, 320),
];

/// Materials used by QIDI Q2. IDs overlap with Plus 4 but mean other materials.
const List<QidiMaterial> qidiQ2Materials = [
  QidiMaterial(1, 'PLA Rapido', 190, 240),
  QidiMaterial(2, 'PLA Matte', 190, 240),
  QidiMaterial(3, 'PLA Metal', 190, 240),
  QidiMaterial(4, 'PLA Silk', 190, 240),
  QidiMaterial(5, 'PLA-CF', 210, 250),
  QidiMaterial(6, 'PLA-Wood', 190, 240),
  QidiMaterial(7, 'PLA Basic', 190, 240),
  QidiMaterial(8, 'PLA Matte Basic', 190, 230),
  QidiMaterial(10, 'Support For PLA', 210, 240),
  QidiMaterial(11, 'ABS Rapido', 240, 280),
  QidiMaterial(12, 'ABS-GF', 240, 280),
  QidiMaterial(13, 'ABS-Metal', 240, 280),
  QidiMaterial(14, 'ABS-Odorless', 240, 280),
  QidiMaterial(18, 'ASA', 240, 280),
  QidiMaterial(19, 'ASA-Aero', 240, 280),
  QidiMaterial(20, 'ASA-CF', 240, 280),
  QidiMaterial(23, 'PC', 240, 280),
  QidiMaterial(24, 'UltraPA', 260, 300),
  QidiMaterial(25, 'PA-CF', 260, 300),
  QidiMaterial(26, 'UltraPA-CF25', 300, 320),
  QidiMaterial(27, 'PA12-CF', 260, 300),
  QidiMaterial(30, 'PAHT-CF', 300, 320),
  QidiMaterial(31, 'PAHT-GF', 300, 320),
  QidiMaterial(32, 'Support For PAHT', 260, 280),
  QidiMaterial(33, 'Support For PET/PA', 260, 280),
  QidiMaterial(34, 'PC/ABS-FR', 260, 280),
  QidiMaterial(35, 'TPEE', 230, 260),
  QidiMaterial(36, 'PEBA', 230, 260),
  QidiMaterial(37, 'PET-CF', 280, 320),
  QidiMaterial(38, 'PET-GF', 280, 320),
  QidiMaterial(39, 'PETG Basic', 240, 280),
  QidiMaterial(40, 'PETG-Tough', 240, 275),
  QidiMaterial(41, 'PETG Rapido', 220, 270),
  QidiMaterial(42, 'PETG-CF', 240, 270),
  QidiMaterial(43, 'PETG-GF', 240, 270),
  QidiMaterial(44, 'PPS-CF', 300, 350),
  QidiMaterial(45, 'PETG Translucent', 240, 280),
  QidiMaterial(46, 'PPS-GF', 300, 350),
  QidiMaterial(47, 'PVA', 210, 250),
  QidiMaterial(48, 'TPU-AERO 64D', 200, 250),
  QidiMaterial(49, 'TPU-Aero', 200, 250),
  QidiMaterial(50, 'TPU 95A-HF', 200, 250),
];

const List<QidiColor> qidiColors = [
  QidiColor(1, 'White', 0xFFFF),
  QidiColor(2, 'Black', 0x0000),
  QidiColor(3, 'Gray', 0xC638),
  QidiColor(4, 'Light Green', 0xA7EA),
  QidiColor(5, 'Mint', 0x96F2),
  QidiColor(6, 'Blue', 0x2B9F),
  QidiColor(7, 'Pink', 0xF3F2),
  QidiColor(8, 'Yellow', 0xFEA0),
  QidiColor(9, 'Green', 0x4DE9),
  QidiColor(10, 'Light Blue', 0x7DDF),
  QidiColor(11, 'Dark Blue', 0x10B3),
  QidiColor(12, 'Lavender', 0xC51F),
  QidiColor(13, 'Lime', 0xB7E0),
  QidiColor(14, 'Royal Blue', 0x43DC),
  QidiColor(15, 'Sky Blue', 0x867F),
  QidiColor(16, 'Violet', 0xA2DF),
  QidiColor(17, 'Rose', 0xFBB6),
  QidiColor(18, 'Red', 0xE1A6),
  QidiColor(19, 'Beige', 0xF7BB),
  QidiColor(20, 'Silver', 0xC618),
  QidiColor(21, 'Brown', 0x79E0),
  QidiColor(22, 'Khaki', 0xB5A0),
  QidiColor(23, 'Orange', 0xFBE0),
  QidiColor(24, 'Bronze', 0xA145),
];

const List<QidiManufacturer> qidiManufacturers = [
  QidiManufacturer(0, 'Generic'),
  QidiManufacturer(1, 'QIDI'),
];

const int qidiDataBlock = 4;
const int qidiBlockSize = 16;
const List<int> qidiDefaultKeyA = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF];

List<QidiMaterial> qidiMaterialsFor(QidiPrinterModel model) {
  return model == QidiPrinterModel.q2 ? qidiQ2Materials : qidiPlus4Materials;
}

QidiMaterial? qidiMaterialById(int id, QidiPrinterModel model) {
  for (final material in qidiMaterialsFor(model)) {
    if (material.id == id) {
      return material;
    }
  }
  return null;
}

QidiColor? qidiColorById(int id) {
  for (final color in qidiColors) {
    if (color.id == id) {
      return color;
    }
  }
  return null;
}

QidiManufacturer? qidiManufacturerById(int id) {
  for (final manufacturer in qidiManufacturers) {
    if (manufacturer.id == id) {
      return manufacturer;
    }
  }
  return null;
}

class QidiTagData {
  const QidiTagData({
    required this.materialId,
    required this.colorId,
    required this.manufacturerId,
    this.rawBlock,
    this.uid,
  });

  final int materialId;
  final int colorId;
  final int manufacturerId;
  final Uint8List? rawBlock;
  final Uint8List? uid;

  factory QidiTagData.fromBlock(Uint8List block, {Uint8List? uid}) {
    if (block.length < 3) {
      throw ArgumentError.value(block.length, 'block', 'QIDI block is too short');
    }
    return QidiTagData(
      materialId: block[0],
      colorId: block[1],
      manufacturerId: block[2],
      rawBlock: Uint8List.fromList(block),
      uid: uid == null ? null : Uint8List.fromList(uid),
    );
  }

  Uint8List toBlock() {
    final block = Uint8List(qidiBlockSize);
    block[0] = materialId & 0xFF;
    block[1] = colorId & 0xFF;
    block[2] = manufacturerId & 0xFF;
    return block;
  }

  String describe(QidiPrinterModel model) {
    final material = qidiMaterialById(materialId, model);
    final color = qidiColorById(colorId);
    final manufacturer = qidiManufacturerById(manufacturerId);
    return '${material?.name ?? 'Material $materialId'} / '
        '${color?.name ?? 'Color $colorId'} / '
        '${manufacturer?.name ?? 'Manufacturer $manufacturerId'}';
  }
}
