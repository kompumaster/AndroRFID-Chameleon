import 'package:flutter/material.dart';

import 'l_text.dart';

class AlphaPickerDialog extends StatefulWidget {
  const AlphaPickerDialog({required this.selectedAlpha, super.key});

  final String selectedAlpha;

  @override
  State<AlphaPickerDialog> createState() => _AlphaPickerDialogState();
}

class _AlphaPickerDialogState extends State<AlphaPickerDialog> {
  late int _transparency = _transparencyFromAlpha(widget.selectedAlpha);

  @override
  Widget build(BuildContext context) {
    final alpha = _alphaFromTransparency(_transparency);
    final alphaHex = alpha.toRadixString(16).padLeft(2, '0').toUpperCase();

    return AlertDialog(
      title: const LText('Alpha / прозрачность'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Center(
                child: Text(
                  alphaHex,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.black.withValues(alpha: alpha / 255),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Slider(
              value: _transparency.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: '$_transparency%',
              onChanged: (value) {
                setState(() => _transparency = value.round());
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const LText('Прозрачность:'),
                LText('$_transparency%'),
              ],
            ),
            const SizedBox(height: 4),
            LText(
              '0% — непрозрачный, 100% — прозрачный',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const LText('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(alphaHex),
          child: const LText('Применить'),
        ),
      ],
    );
  }

  int _transparencyFromAlpha(String value) {
    final raw = value.trim().replaceAll('#', '');
    final alpha = int.tryParse(raw, radix: 16) ?? 0xFF;
    return (((255 - alpha.clamp(0, 255)) / 255) * 100).round();
  }

  int _alphaFromTransparency(int transparency) {
    return 255 - ((transparency.clamp(0, 100) * 255) / 100).round();
  }
}
