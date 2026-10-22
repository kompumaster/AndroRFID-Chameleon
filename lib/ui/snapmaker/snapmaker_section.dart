import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/snapmaker/snapmaker_models.dart';
import '../../data/snapmaker/snapmaker_settings.dart';
import '../../services/snapmaker_service.dart';
import '../widgets/l_text.dart';

class SnapmakerSection extends StatefulWidget {
  const SnapmakerSection({super.key});

  @override
  State<SnapmakerSection> createState() => _SnapmakerSectionState();
}

class _SnapmakerSectionState extends State<SnapmakerSection> {
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  bool _initialized = false;
  bool _busy = false;
  String? _error;
  String? _status;
  List<SnapmakerToolHead> _toolHeads = [];

  @override
  void initState() {
    super.initState();
    final store = context.read<SnapmakerSettingsStore>();
    _hostCtrl = TextEditingController(text: store.host);
    _portCtrl = TextEditingController(text: '${store.port}');
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final store = context.read<SnapmakerSettingsStore>();
    await store.ensureLoaded();
    if (!mounted) {
      return;
    }
    setState(() {
      _hostCtrl.text = store.host;
      _portCtrl.text = '${store.port}';
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LText('Snapmaker U1', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        LText(
          'Подключение по Wi-Fi без Chameleon. Телефон и принтер должны быть '
          'в одной сети. Используется HTTP.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _hostCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    label: LText('Host / IP'),
                    hintText: '192.168.1.10',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _portCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    label: LText('Порт'),
                    hintText: '7125',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy || !_initialized
                            ? null
                            : _saveAndRefresh,
                        icon: const Icon(Icons.save_outlined),
                        label: const LText('Сохранить'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const LText('Проверить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LText(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ],
        if (_status != null) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: LText(_status!),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_busy)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_toolHeads.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: LText(
                'Нажмите «Проверить», чтобы загрузить состояние ToolHead.',
              ),
            ),
          )
        else
          ..._toolHeads.map(_toolHeadCard),
      ],
    );
  }

  Widget _toolHeadCard(SnapmakerToolHead head) {
    final color = _parseColor(head.colorHex);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.print_outlined,
            color: color == null ? null : _contrastColor(color),
          ),
        ),
        title: LText('ToolHead ${head.index}'),
        subtitle: LText(
          head.empty
              ? 'Пусто'
              : '${head.material}'
                    '${head.subtype.isEmpty ? '' : ' · ${head.subtype}'}'
                    '${head.colorHex.isEmpty ? '' : ' · ${head.colorHex}'}',
        ),
        trailing: Chip(
          label: LText(head.empty ? 'Empty' : 'Loaded'),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Future<void> _saveAndRefresh() async {
    final port = int.tryParse(_portCtrl.text.trim());
    if (port == null) {
      setState(() => _error = 'Порт должен быть числом');
      return;
    }
    final store = context.read<SnapmakerSettingsStore>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await store.save(host: _hostCtrl.text, port: port);
      await _refreshInternal(store);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _refresh() async {
    final store = context.read<SnapmakerSettingsStore>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _refreshInternal(store);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _refreshInternal(SnapmakerSettingsStore store) async {
    final service = SnapmakerService(host: store.host, port: store.port);
    final heads = await service.getToolHeads();
    if (!mounted) {
      return;
    }
    setState(() {
      _toolHeads = heads;
      _status = 'Связь с U1 установлена';
      _error = null;
    });
  }

  Color? _parseColor(String hex) {
    if (hex.length != 7 || !hex.startsWith('#')) {
      return null;
    }
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }

  Color _contrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
