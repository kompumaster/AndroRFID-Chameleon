import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../widgets/l_text.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../data/openspool/openspool_bin_codec.dart';
import '../../data/qidi/qidi_bin_codec.dart';
import '../../data/records/record_repository.dart';
import '../../data/records/tag_record.dart';
import '../../l10n/app_translations.dart';
import 'record_detail_page.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordRepository>(
      builder: (context, repository, _) {
        if (!repository.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: LText(
                      'Сохранённые метки',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        _importing ? null : () => _importBin(repository),
                    icon: _importing
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_open_outlined),
                    label: const LText('Импорт .bin'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: repository.records.isEmpty
                  ? const _EmptyRecords()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount: repository.records.length,
                      itemBuilder: (context, index) {
                        final record = repository.records[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              record.type == TagRecordType.qidi
                                  ? Icons.memory
                                  : Icons.nfc,
                            ),
                            title: LText(record.name),
                            subtitle: LText(record.summary),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    RecordDetailPage(record: record),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importBin(RecordRepository repository) async {
    final appState = context.read<AppState>();
    final model = appState.qidiModel;
    final profile = appState.openspoolProfile;
    final tier = appState.openspoolTier;
    final language = appState.language;
    setState(() => _importing = true);
    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: AppTranslations.translate(language, 'Импорт .bin'),
        type: FileType.custom,
        allowedExtensions: const ['bin'],
      );
      if (picked == null) {
        return;
      }

      final bytes = await picked.xFile.readAsBytes();
      final TagRecord record;
      if (bytes.length == QidiBinCodec.dumpSize) {
        final data = QidiBinCodec.decode(bytes);
        record = await repository.saveQidi(model: model, data: data);
      } else if (bytes.length == OpenSpoolBinCodec.dumpSize) {
        final data = OpenSpoolBinCodec.decode(bytes);
        record = await repository.saveOpenSpool(
          data: data,
          profile: profile,
          tier: tier,
        );
      } else {
        throw ArgumentError(
          'Неподдерживаемый размер .bin: ${bytes.length}. '
          'Ожидается 1024 (QIDI) или 540 (OpenSpool).',
        );
      }

      if (!mounted) {
        return;
      }
      _message('Импортировано: ${record.name}');
    } catch (e) {
      if (mounted) {
        _message('Не удалось импортировать .bin: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: LText(text)));
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 56),
            const SizedBox(height: 16),
            LText(
              'Пока нет сохранённых меток',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const LText(
              'Прочитайте метку или создайте новую на вкладке «Метка» '
              'и нажмите «Сохранить в данные». Также можно импортировать '
              'совместимый .bin.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
