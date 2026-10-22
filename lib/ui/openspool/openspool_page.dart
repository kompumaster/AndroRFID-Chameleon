import 'dart:convert';

import 'package:flutter/material.dart';

import '../widgets/l_text.dart';

import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/ble/connection_service.dart';
import '../../data/openspool/openspool_data.dart';
import '../../data/records/record_repository.dart';
import '../../data/snapmaker/snapmaker_models.dart';
import '../../l10n/app_translations.dart';
import '../../services/openspool_tag_service.dart';
import '../snapmaker/snapmaker_send_dialog.dart';
import '../widgets/alpha_picker_dialog.dart';
import '../widgets/color_picker_dialog.dart';

class OpenSpoolPage extends StatefulWidget {
  const OpenSpoolPage({super.key});

  @override
  State<OpenSpoolPage> createState() => _OpenSpoolPageState();
}

class _OpenSpoolPageState extends State<OpenSpoolPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  late final TextEditingController _colorCtrl = TextEditingController(
    text: '#FFFFFF',
  );
  late final TextEditingController _minCtrl = TextEditingController(
    text: '190',
  );
  late final TextEditingController _maxCtrl = TextEditingController(
    text: '220',
  );
  late final TextEditingController _bedMinCtrl = TextEditingController(
    text: '50',
  );
  late final TextEditingController _bedMaxCtrl = TextEditingController(
    text: '60',
  );
  late final TextEditingController _alphaCtrl = TextEditingController(
    text: 'FF',
  );
  late final TextEditingController _weightCtrl = TextEditingController();
  late final TextEditingController _diameterCtrl = TextEditingController(
    text: '1.75',
  );
  late final TextEditingController _extraCtrl = TextEditingController();

  String _brand = 'Generic';
  String _material = 'PLA';
  String _subtype = '';
  OpenSpoolTagData? _readData;
  bool _busy = false;
  String? _readError;
  String? _writeError;

  @override
  void dispose() {
    _tabController.dispose();
    _colorCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _bedMinCtrl.dispose();
    _bedMaxCtrl.dispose();
    _alphaCtrl.dispose();
    _weightCtrl.dispose();
    _diameterCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.openspoolProfile;
    final tier = appState.openspoolTier;
    final language = appState.language;
    final connected = context.watch<ConnectionService>().isConnected;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
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
            controller: _tabController,
            children: [
              _buildReadTab(profile, connected, _readError),
              _buildWriteTab(profile, tier, connected, _writeError),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadTab(
    OpenSpoolProfile profile,
    bool connected,
    String? readError,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(
          title: profile == OpenSpoolProfile.u1
              ? 'Чтение Snapmaker U1'
              : 'Чтение OpenSpool',
          subtitle: 'NTAG215, CC E1 10 3E 00, MIME application/json.',
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
                'Приложите NTAG215 с OpenSpool-записью к Chameleon '
                'и нажмите «Прочитать метку».',
          ),
        ] else if (_readData != null)
          _ReadResultCard(
            data: _readData!,
            profile: profile,
            saving: _busy,
            onSave: () => _saveData(_readData!),
            onSend: () => _sendToU1(_readData!),
            showSend: profile == OpenSpoolProfile.u1,
          )
        else
          const _HintCard(
            text:
                'Приложите NTAG215 с OpenSpool-записью к Chameleon '
                'и нажмите «Прочитать метку».',
          ),
      ],
    );
  }

  Widget _buildWriteTab(
    OpenSpoolProfile profile,
    OpenSpoolTier tier,
    bool connected,
    String? writeError,
  ) {
    final isU1 = profile == OpenSpoolProfile.u1;
    final showExtended = isU1 && tier == OpenSpoolTier.all;
    final data = _buildData();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(
          title: profile == OpenSpoolProfile.u1
              ? 'Запись Snapmaker U1'
              : 'Запись OpenSpool',
          subtitle:
              'JSON/NDEF будет записан в пользовательские страницы NTAG215.',
        ),
        if (!connected) ...[
          const SizedBox(height: 12),
          const _HintCard(
            text:
                'Chameleon не подключён — чтение и запись метки недоступны. '
                'Сохранение и отправка на U1 работают.',
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<OpenSpoolTier>(
          key: ValueKey('os-tier-${profile.name}-${tier.name}'),
          initialValue: tier,
          decoration: const InputDecoration(
            label: LText('Версия данных'),
            border: OutlineInputBorder(),
          ),
          items:
              (isU1
                      ? const [OpenSpoolTier.standard, OpenSpoolTier.all]
                      : const [OpenSpoolTier.basic, OpenSpoolTier.standard])
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: LText(_tierLabel(value)),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) {
              context.read<AppState>().openspoolTier = value;
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('os-brand-$_brand'),
          initialValue: _brand,
          decoration: const InputDecoration(
            label: LText('Бренд'),
            border: OutlineInputBorder(),
          ),
          items: openSpoolManufacturers
              .map(
                (brand) => DropdownMenuItem(
                  value: brand.name,
                  child: LText(brand.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _brand = value);
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('os-material-$_material'),
          initialValue: _material,
          decoration: const InputDecoration(
            label: LText('Материал'),
            border: OutlineInputBorder(),
          ),
          items: openSpoolMaterials
              .map(
                (material) => DropdownMenuItem(
                  value: material.name,
                  child: LText(material.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _applyPreset(value);
            }
          },
        ),
        if (isU1) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('os-subtype-$_subtype'),
            initialValue: _subtype,
            decoration: const InputDecoration(
              label: LText('Подтип (subtype)'),
              border: OutlineInputBorder(),
            ),
            items:
                [
                      ...openSpoolDefaultSubtypes,
                      if (!openSpoolDefaultSubtypes.contains(_subtype))
                        _subtype,
                    ]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: LText(value.isEmpty ? 'Нет' : value),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _subtype = value);
              }
            },
          ),
        ],
        const SizedBox(height: 12),
        _ColorField(controller: _colorCtrl, onTap: _pickColor),
        if (tier != OpenSpoolTier.basic) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _minCtrl,
                  label: 'Сопло min, °C',
                  keyboardType: TextInputType.number,
                  onChanged: _rebuild,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  controller: _maxCtrl,
                  label: 'Сопло max, °C',
                  keyboardType: TextInputType.number,
                  onChanged: _rebuild,
                ),
              ),
            ],
          ),
        ],
        if (isU1) ...[
          const SizedBox(height: 12),
          _AlphaField(controller: _alphaCtrl, onTap: _pickAlpha),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _bedMinCtrl,
                  label: 'Стол min, °C',
                  keyboardType: TextInputType.number,
                  onChanged: _rebuild,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  controller: _bedMaxCtrl,
                  label: 'Стол max, °C',
                  keyboardType: TextInputType.number,
                  onChanged: _rebuild,
                ),
              ),
            ],
          ),
        ],
        if (showExtended) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _weightCtrl,
                  label: 'Вес, г',
                  keyboardType: TextInputType.number,
                  onChanged: _rebuild,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  controller: _diameterCtrl,
                  label: 'Диаметр, мм',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: _rebuild,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _extraCtrl,
            label: 'Доп. цвета через запятую',
            hint: '#FFFFFF, #000000',
            onChanged: _rebuild,
          ),
        ],
        const SizedBox(height: 16),
        _PreviewCard(data: data, profile: profile, tier: tier),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy || !connected
              ? null
              : () => _write(data, profile, tier),
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
        if (isU1) ...[
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _sendToU1(data),
            icon: const Icon(Icons.print_outlined),
            label: const LText('Отправить на U1'),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _saveData(data, profile, tier),
          icon: const Icon(Icons.save_outlined),
          label: const LText('Сохранить в данные'),
        ),
      ],
    );
  }

  void _rebuild(String _) => setState(() {});

  Future<void> _pickColor() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => ColorPickerDialog(selectedHex: _colorCtrl.text),
    );
    if (selected != null && mounted) {
      setState(() => _colorCtrl.text = selected);
    }
  }

  Future<void> _pickAlpha() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => AlphaPickerDialog(selectedAlpha: _alphaCtrl.text),
    );
    if (selected != null && mounted) {
      setState(() => _alphaCtrl.text = selected);
    }
  }

  void _applyPreset(String name) {
    final preset = openSpoolMaterialByName(name);
    if (preset == null) {
      return;
    }
    setState(() {
      _material = preset.name;
      _minCtrl.text = '${preset.nozzleMin}';
      _maxCtrl.text = '${preset.nozzleMax}';
      _bedMinCtrl.text = '${preset.bedMin}';
      _bedMaxCtrl.text = '${preset.bedMax}';
    });
  }

  OpenSpoolTagData _buildData() {
    return OpenSpoolTagData(
      brand: _brand,
      type: _material,
      subtype: _subtype.trim().isEmpty ? null : _subtype.trim(),
      colorHex: normalizeHexColor(_colorCtrl.text),
      alpha: _alphaCtrl.text,
      minTemp: _intOrNull(_minCtrl.text),
      maxTemp: _intOrNull(_maxCtrl.text),
      bedMinTemp: _intOrNull(_bedMinCtrl.text),
      bedMaxTemp: _intOrNull(_bedMaxCtrl.text),
      weight: _intOrNull(_weightCtrl.text),
      diameter: _doubleOrNull(_diameterCtrl.text),
      additionalColorHexes: _extraCtrl.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
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
      final data = await OpenSpoolTagService(communicator).read();
      if (!mounted) {
        return;
      }
      setState(() => _readData = data);
      _showMessage('OpenSpool-метка прочитана');
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

  Future<void> _write(
    OpenSpoolTagData data,
    OpenSpoolProfile profile,
    OpenSpoolTier tier,
  ) async {
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
      await OpenSpoolTagService(communicator)
          .write(data, profile: profile, tier: tier);
      if (!mounted) {
        return;
      }
      setState(() => _readData = data);
      _showMessage('OpenSpool-метка записана и проверена');
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

  Future<void> _sendToU1(OpenSpoolTagData data) async {
    await showSnapmakerSendDialog(
      context,
      SnapmakerTagPayload.fromOpenSpool(data),
    );
  }

  Future<void> _saveData(
    OpenSpoolTagData data, [
    OpenSpoolProfile? profile,
    OpenSpoolTier? tier,
  ]) async {
    final appState = context.read<AppState>();
    final repository = context.read<RecordRepository>();
    setState(() => _busy = true);

    try {
      final record = await repository.saveOpenSpool(
        data: data,
        profile: profile ?? appState.openspoolProfile,
        tier: tier ?? appState.openspoolTier,
      );
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

  String _tierLabel(OpenSpoolTier tier) {
    return switch (tier) {
      OpenSpoolTier.basic => 'Basic',
      OpenSpoolTier.standard => 'Standard',
      OpenSpoolTier.all => 'All (U1)',
    };
  }

  int? _intOrNull(String text) {
    final value = int.tryParse(text.trim());
    return value;
  }

  double? _doubleOrNull(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.'));
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

class _AlphaField extends StatelessWidget {
  const _AlphaField({required this.controller, required this.onTap});

  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        label: const LText('Alpha'),
        hintText: 'FF',
        border: const OutlineInputBorder(),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            widthFactor: 1,
            child: LText(controller.text.toUpperCase()),
          ),
        ),
      ),
    );
  }
}

class _ColorField extends StatelessWidget {
  const _ColorField({required this.controller, required this.onTap});

  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final raw = controller.text.replaceAll('#', '');
    final value = int.tryParse(raw, radix: 16);
    final color = value == null ? null : Color(0xFF000000 | value);

    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        label: const LText('Цвет (color_hex)'),
        hintText: '#RRGGBB',
        border: const OutlineInputBorder(),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color:
                  color ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        label: LText(label),
        hintText: hint == null
            ? null
            : AppTranslations.translate(
                context.watch<AppState>().language,
                hint!,
              ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.data,
    required this.profile,
    required this.tier,
  });

  final OpenSpoolTagData data;
  final OpenSpoolProfile profile;
  final OpenSpoolTier tier;

  @override
  Widget build(BuildContext context) {
    final json = const JsonEncoder.withIndent('  ')
        .convert(data.toJson(profile: profile, tier: tier));

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              'JSON для записи',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SelectableText(
              json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadResultCard extends StatelessWidget {
  const _ReadResultCard({
    required this.data,
    required this.profile,
    required this.saving,
    required this.onSave,
    required this.onSend,
    required this.showSend,
  });

  final OpenSpoolTagData data;
  final OpenSpoolProfile profile;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onSend;
  final bool showSend;

  @override
  Widget build(BuildContext context) {
    final json = const JsonEncoder.withIndent('  ')
        .convert(data.toJson(profile: profile, tier: OpenSpoolTier.all));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText('Прочитано', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _InfoRow(label: 'Бренд', value: data.brand ?? '—'),
            _InfoRow(label: 'Материал', value: data.type),
            _InfoRow(label: 'Подтип', value: data.subtype ?? '—'),
            _InfoRow(label: 'Цвет', value: data.colorHex),
            _InfoRow(
              label: 'Сопло',
              value: '${data.minTemp ?? '—'}–${data.maxTemp ?? '—'} °C',
            ),
            if (data.alpha != null)
              _InfoRow(label: 'Alpha', value: data.alpha!),
            if (data.weight != null)
              _InfoRow(label: 'Вес', value: '${data.weight} г'),
            if (data.diameter != null)
              _InfoRow(label: 'Диаметр', value: '${data.diameter} мм'),
            if (data.additionalColorHexes.isNotEmpty)
              _InfoRow(
                label: 'Доп. цвета',
                value: data.additionalColorHexes.join(', '),
              ),
            const Divider(height: 24),
            SelectableText(
              json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (showSend)
                  OutlinedButton.icon(
                    onPressed: saving ? null : onSend,
                    icon: const Icon(Icons.print_outlined),
                    label: const LText('Отправить на U1'),
                  ),
                FilledButton.tonalIcon(
                  onPressed: saving ? null : onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: const LText('Сохранить в данные'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: LText(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: LText(value)),
        ],
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
