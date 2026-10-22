import 'qidi_data.dart';

class QidiCfgSlot {
  const QidiCfgSlot({
    required this.slot,
    required this.filament,
    required this.type,
    this.minTemp,
    this.maxTemp,
    this.boxMinTemp,
    this.boxMaxTemp,
  });

  final int slot;
  final String filament;
  final String type;
  final int? minTemp;
  final int? maxTemp;
  final int? boxMinTemp;
  final int? boxMaxTemp;

  bool get isActive => filament.trim().isNotEmpty;
}

class QidiCfgParser {
  static List<QidiCfgSlot> parse(String text) {
    final sections = <int, Map<String, String>>{};
    int? currentSlot;
    Map<String, String>? current;

    for (final raw in text.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith(';') || line.startsWith('#')) {
        continue;
      }

      final section = RegExp(r'^\[fila(\d+)\]$', caseSensitive: false)
          .firstMatch(line);
      if (section != null) {
        currentSlot = int.parse(section.group(1)!);
        current = sections.putIfAbsent(currentSlot, () => {});
        continue;
      }

      if (current == null) {
        continue;
      }
      final equals = line.indexOf('=');
      if (equals <= 0) {
        continue;
      }
      final key = line.substring(0, equals).trim().toLowerCase();
      final value = line.substring(equals + 1).trim();
      current[key] = value;
    }

    if (sections.isEmpty) {
      throw const FormatException('В файле нет секций [filaN]');
    }

    final result = <QidiCfgSlot>[];
    final keys = sections.keys.toList()..sort();
    for (final slot in keys) {
      final values = sections[slot]!;
      result.add(
        QidiCfgSlot(
          slot: slot,
          filament: values['filament'] ?? '',
          type: values['type'] ?? '',
          minTemp: _int(values['min_temp']),
          maxTemp: _int(values['max_temp']),
          boxMinTemp: _int(values['box_min_temp']),
          boxMaxTemp: _int(values['box_max_temp']),
        ),
      );
    }
    return result;
  }

  static List<QidiMaterial> toMaterials(List<QidiCfgSlot> slots) {
    return slots
        .where((slot) => slot.isActive)
        .map(
          (slot) => QidiMaterial(
            slot.slot,
            slot.filament,
            slot.minTemp ?? 0,
            slot.maxTemp ?? 0,
          ),
        )
        .toList();
  }

  static int? _int(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return int.tryParse(value.trim());
  }
}
