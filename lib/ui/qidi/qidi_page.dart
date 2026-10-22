import 'package:flutter/material.dart';

import '../widgets/l_text.dart';

import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/ble/connection_service.dart';
import '../../core/chameleon/helpers/utils.dart';
import '../../data/qidi/qidi_data.dart';
import '../../data/qidi/qidi_lists_store.dart';
import '../../data/records/record_repository.dart';
import '../../l10n/app_translations.dart';
import '../../services/qidi_tag_service.dart';

class QidiPage extends StatefulWidget {
  const QidiPage({super.key});

  @override
  State<QidiPage> createState() => _QidiPageState();
}

class _QidiPageState extends State<QidiPage> {
  QidiTagData? _readData;
  bool _busy = false;
  String? _readError;
  String? _writeError;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final model = appState.qidiModel;
    final language = appState.language;
    final lists = context.watch<QidiListsStore>();
    final connected = context.watch<ConnectionService>().isConnected;
    final materials = lists.materialsFor(model);
    final selectedMaterial =
        lists.materialById(
          appState.qidiMaterialId ?? materials.first.id,
          model,
        ) ??
        materials.first;
    final selectedColor =
        qidiColorById(appState.qidiColorId) ?? qidiColors.first;
    final selectedManufacturer =
        qidiManufacturerById(appState.qidiManufacturerId) ??
        qidiManufacturers.first;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.download),
                text: AppTranslations.translate(language, 'Читать'),
              ),
              Tab(
                icon: const Icon(Icons.upload),
                text: AppTranslations.translate(language, 'Записать'),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildReadTab(model, lists, connected, _readError),
                _buildWriteTab(
                  model: model,
                  lists: lists,
                  materials: materials,
                  selectedMaterial: selectedMaterial,
                  selectedColor: selectedColor,
                  selectedManufacturer: selectedManufacturer,
                  connected: connected,
                  writeError: _writeError,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadTab(
    QidiPrinterModel model,
    QidiListsStore lists,
    bool connected,
    String? readError,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(
          title: 'Чтение QIDI-метки',
          subtitle: 'MIFARE Classic 1K, блок 4, ключ A FFFFFFFFFFFF.',
        ),
        if (!connected) ...[
          const SizedBox(height: 12),
          const _HintCard(
            text: 'Chameleon не подключён — чтение и запись метки недоступны.',
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy || !connected ? null : _read,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.nfc),
          label: LText(_busy ? 'Читаю…' : 'Прочитать метку'),
        ),
        const SizedBox(height: 16),
        if (readError != null) ...[
          _ErrorCard(message: readError),
          const SizedBox(height: 12),
          const _HintCard(
            text:
                'Приложите QIDI-метку к Chameleon и нажмите «Прочитать метку».',
          ),
        ] else if (_readData != null)
          _ReadResultCard(
            data: _readData!,
            model: model,
            lists: lists,
            saving: _busy,
            onSave: () => _saveData(_readData!),
          )
        else
          const _HintCard(
            text:
                'Приложите QIDI-метку к Chameleon и нажмите «Прочитать метку».',
          ),
      ],
    );
  }

  Widget _buildWriteTab({
    required QidiPrinterModel model,
    required QidiListsStore lists,
    required List<QidiMaterial> materials,
    required QidiMaterial selectedMaterial,
    required QidiColor selectedColor,
    required QidiManufacturer selectedManufacturer,
    required bool connected,
    required String? writeError,
  }) {
    final preview = QidiTagData(
      materialId: selectedMaterial.id,
      colorId: selectedColor.id,
      manufacturerId: selectedManufacturer.id,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(
          title: 'Запись QIDI-метки',
          subtitle: 'Будут записаны блок 4 и нули в байтах 3–15.',
        ),
        if (!connected) ...[
          const SizedBox(height: 12),
          const _HintCard(
            text: 'Chameleon не подключён — чтение и запись метки недоступны.',
          ),
        ],
        if (lists.hasCfg) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: const Icon(Icons.lock_outline, size: 18),
              label: LText(
                'CFG: ${lists.cfgName ?? 'импортированный список'} · '
                '${materials.length} материалов',
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<QidiPrinterModel>(
          key: ValueKey('model-${model.name}'),
          initialValue: model,
          decoration: const InputDecoration(
            label: LText('Модель принтера'),
            border: OutlineInputBorder(),
          ),
          items: QidiPrinterModel.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: LText(value.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            context.read<AppState>().qidiModel = value;
            final first = lists.materialsFor(value).first;
            context.read<AppState>().qidiMaterialId = first.id;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey('material-${model.name}-${selectedMaterial.id}'),
          initialValue: selectedMaterial.id,
          decoration: const InputDecoration(
            label: LText('Материал'),
            border: OutlineInputBorder(),
          ),
          items: materials
              .map(
                (material) => DropdownMenuItem(
                  value: material.id,
                  child: LText(
                    '${material.name}  ·  ${material.nozzleMin}–${material.nozzleMax} °C',
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              context.read<AppState>().qidiMaterialId = value;
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey('color-${selectedColor.id}'),
          initialValue: selectedColor.id,
          decoration: const InputDecoration(
            label: LText('Цвет'),
            border: OutlineInputBorder(),
          ),
          items: qidiColors
              .map(
                (color) => DropdownMenuItem(
                  value: color.id,
                  child: Row(
                    children: [
                      _ColorDot(color: color),
                      const SizedBox(width: 10),
                      LText('${color.name}  ·  ${color.id}'),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              context.read<AppState>().qidiColorId = value;
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey('manufacturer-${selectedManufacturer.id}'),
          initialValue: selectedManufacturer.id,
          decoration: const InputDecoration(
            label: LText('Производитель'),
            border: OutlineInputBorder(),
          ),
          items: qidiManufacturers
              .map(
                (manufacturer) => DropdownMenuItem(
                  value: manufacturer.id,
                  child: LText('${manufacturer.name}  ·  ${manufacturer.id}'),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              context.read<AppState>().qidiManufacturerId = value;
            }
          },
        ),
        const SizedBox(height: 16),
        _PreviewCard(data: preview),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy || !connected ? null : () => _write(preview),
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.nfc),
          label: LText(_busy ? 'Записываю…' : 'Записать метку'),
        ),
        if (writeError != null) ...[
          const SizedBox(height: 12),
          _ErrorCard(message: writeError),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _saveData(preview),
          icon: const Icon(Icons.save_outlined),
          label: const LText('Сохранить в данные'),
        ),
      ],
    );
  }

  Future<void> _read() async {
    final communicator = context.read<ConnectionService>().communicator;
    if (communicator == null) {
      setState(() => _readError = 'Chameleon не подключён.');
      return;
    }

    setState(() {
      _busy = true;
      _readError = null;
    });

    try {
      final data = await QidiTagService(communicator).read();
      if (!mounted) {
        return;
      }
      setState(() => _readData = data);
      _showMessage('Метка прочитана');
    } catch (e) {
      if (mounted) {
        setState(() => _readError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _write(QidiTagData data) async {
    final communicator = context.read<ConnectionService>().communicator;
    if (communicator == null) {
      setState(() => _writeError = 'Chameleon не подключён.');
      return;
    }

    setState(() {
      _busy = true;
      _writeError = null;
    });

    try {
      await QidiTagService(communicator).write(data);
      if (!mounted) {
        return;
      }
      setState(() => _readData = data);
      _showMessage('QIDI-метка записана и проверена');
    } catch (e) {
      if (mounted) {
        setState(() => _writeError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveData(QidiTagData data) async {
    final repository = context.read<RecordRepository>();
    final model = context.read<AppState>().qidiModel;
    setState(() => _busy = true);

    try {
      final record = await repository.saveQidi(model: model, data: data);
      if (!mounted) {
        return;
      }
      _showMessage('Сохранено: ${record.name}');
    } catch (e) {
      if (mounted) {
        _showMessage('Не удалось сохранить запись: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: LText(text)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LText(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        LText(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ReadResultCard extends StatelessWidget {
  const _ReadResultCard({
    required this.data,
    required this.model,
    required this.lists,
    required this.saving,
    required this.onSave,
  });

  final QidiTagData data;
  final QidiPrinterModel model;
  final QidiListsStore lists;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final material = lists.materialById(data.materialId, model);
    final color = qidiColorById(data.colorId);
    final manufacturer = qidiManufacturerById(data.manufacturerId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText('Прочитано', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Материал',
              value: material?.name ?? 'ID ${data.materialId} (неизвестно)',
            ),
            _InfoRow(
              label: 'Цвет',
              value: color == null
                  ? 'ID ${data.colorId} (неизвестно)'
                  : '${color.name} (ID ${color.id})',
              leading: color == null ? null : _ColorDot(color: color),
            ),
            _InfoRow(
              label: 'Производитель',
              value:
                  manufacturer?.name ??
                  'ID ${data.manufacturerId} (неизвестно)',
            ),
            const Divider(height: 24),
            LText('Блок 4', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SelectableText(
              bytesToHexSpace(data.rawBlock ?? data.toBlock()),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: saving ? null : onSave,
                icon: const Icon(Icons.save_outlined),
                label: const LText('Сохранить в данные'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.leading});

  final String label;
  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          SizedBox(
            width: 120,
            child: LText(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: LText(value)),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.data});

  final QidiTagData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              'Предпросмотр блока 4',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SelectableText(
              bytesToHexSpace(data.toBlock()),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final QidiColor color;

  @override
  Widget build(BuildContext context) {
    final value = int.parse(color.hex.substring(1), radix: 16) | 0xFF000000;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Color(value),
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(child: LText(text)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LText(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
