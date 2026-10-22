import 'package:flutter/material.dart';

import '../widgets/l_text.dart';

import 'package:provider/provider.dart';

import '../../data/snapmaker/snapmaker_models.dart';
import '../../data/snapmaker/snapmaker_settings.dart';
import '../../services/snapmaker_service.dart';

Future<void> showSnapmakerSendDialog(
  BuildContext context,
  SnapmakerTagPayload payload,
) async {
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => _SnapmakerSendDialog(payload: payload),
  );
  if (sent == true && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: LText('Данные отправлены в U1')));
  }
}

class _SnapmakerSendDialog extends StatefulWidget {
  const _SnapmakerSendDialog({required this.payload});

  final SnapmakerTagPayload payload;

  @override
  State<_SnapmakerSendDialog> createState() => _SnapmakerSendDialogState();
}

class _SnapmakerSendDialogState extends State<_SnapmakerSendDialog> {
  List<SnapmakerToolHead>? _heads;
  String? _error;
  int? _sending;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = context.read<SnapmakerSettingsStore>();
    try {
      await store.ensureLoaded();
      final service = SnapmakerService(host: store.host, port: store.port);
      final heads = await service.getToolHeads();
      if (mounted) {
        setState(() => _heads = heads);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const LText('Отправить на Snapmaker U1'),
      content: SizedBox(width: 420, child: _buildContent(context)),
      actions: [
        TextButton(
          onPressed: _sending == null
              ? () => Navigator.of(context).pop()
              : null,
          child: const LText('Закрыть'),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LText(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
          const LText('Проверьте host/port в Настройках.'),
        ],
      );
    }
    if (_heads == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _heads!
          .map(
            (head) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: LText('${head.index}')),
              title: LText(head.material.isEmpty ? 'Пусто' : head.material),
              subtitle: LText(
                [
                  if (head.subtype.isNotEmpty) head.subtype,
                  if (head.colorHex.isNotEmpty) head.colorHex,
                ].join(' · '),
              ),
              trailing: _sending == head.index
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _sending == null
                          ? () => _send(head.index)
                          : null,
                      child: const LText('Отправить'),
                    ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _send(int toolHead) async {
    final store = context.read<SnapmakerSettingsStore>();
    setState(() {
      _sending = toolHead;
      _error = null;
    });

    final service = SnapmakerService(host: store.host, port: store.port);
    try {
      final filamentDetected = await service.getFilamentDetected(toolHead);
      if (!mounted) {
        return;
      }
      if (filamentDetected) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: LText('ToolHead $toolHead занят'),
            content: const LText(
              'В ToolHead уже обнаружен филамент. Перезаписать данные?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const LText('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const LText('Перезаписать'),
              ),
            ],
          ),
        );
        if (confirmed != true) {
          if (mounted) {
            setState(() => _sending = null);
          }
          return;
        }
      }

      await service.sendTag(toolHead, widget.payload);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _sending = null;
        });
      }
    }
  }
}
