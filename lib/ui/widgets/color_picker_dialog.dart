import 'package:flutter/material.dart';

import '../../data/openspool/openspool_data.dart';
import 'l_text.dart';

class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({required this.selectedHex, super.key});

  final String selectedHex;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late final TextEditingController _customCtrl =
      TextEditingController(text: widget.selectedHex.toUpperCase());
  String? _error;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedHex.toUpperCase();
    return AlertDialog(
      title: const LText('Выбор цвета'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: openSpoolDefaultColors.length,
              itemBuilder: (context, index) {
                final hex = openSpoolDefaultColors[index].toUpperCase();
                final color = _parseColor(hex);
                final isSelected = hex == selected;
                return Tooltip(
                  message: hex,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.of(context).pop(hex),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                label: LText('Свой HEX'),
                hintText: '#RRGGBB',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() => _error = null);
                }
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              LText(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const LText('Отмена'),
        ),
        FilledButton(
          onPressed: _applyCustom,
          child: const LText('Применить'),
        ),
      ],
    );
  }

  void _applyCustom() {
    final raw = _customCtrl.text.trim().replaceAll('#', '');
    if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(raw)) {
      setState(() => _error = 'Некорректный HEX');
      return;
    }
    Navigator.of(context).pop('#${raw.toUpperCase()}');
  }

  Color _parseColor(String hex) {
    final value = int.tryParse(hex.replaceAll('#', ''), radix: 16) ?? 0xFFFFFF;
    return Color(0xFF000000 | value);
  }
}
