import 'package:flutter/material.dart';

import '../widgets/l_text.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/ble/connection_service.dart';
import '../../core/chameleon/connector/serial_abstract.dart';
import '../../core/chameleon/helpers/utils.dart';

class ConnectPage extends StatelessWidget {
  const ConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionService>(
      builder: (context, service, _) {
        final connected = service.isConnected;
        final scanning = service.status == BleStatus.scanning;
        final connecting = service.status == BleStatus.connecting;
        final autoScan = service.autoScanActive;
        final canToggle = !connected && !connecting && !(scanning && !autoScan);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LText(
              'Подключение Chameleon',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            LText(
              service.autoScanSetting
                  ? 'Поиск запускается автоматически и повторяется, пока '
                        'Chameleon не будет найден.'
                  : 'Автоматическое сканирование выключено. '
                        'Нажмите «Начать поиск».',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            _StatusCard(service: service),
            if (!connected) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: canToggle
                    ? (autoScan ? service.stopAutoScan : service.startAutoScan)
                    : null,
                icon: scanning
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        autoScan
                            ? Icons.stop_circle_outlined
                            : Icons.bluetooth_searching,
                      ),
                label: LText(
                  autoScan
                      ? 'Остановить поиск'
                      : scanning
                      ? 'Поиск…'
                      : 'Начать поиск',
                ),
              ),
            ],
            if (service.error != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LText(
                        service.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      if (service.permissionDenied)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: openAppSettings,
                            icon: const Icon(Icons.settings),
                            label: const LText('Настройки приложения'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (service.isConnected)
              _ConnectedCard(service: service)
            else if (service.devices.isEmpty)
              const _HintCard()
            else ...[
              LText(
                'Найдено устройств: ${service.devices.length}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...service.devices.map(
                (device) => _DeviceTile(
                  device: device,
                  enabled: !scanning && !connecting,
                  onConnect: () => _connect(context, service, device),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _connect(
    BuildContext context,
    ConnectionService service,
    Chameleon device,
  ) async {
    final connected = await service.connect(device);
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: LText(
            connected
                ? 'Chameleon подключён'
                : service.error ?? 'Не удалось подключиться',
          ),
        ),
      );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.service});

  final ConnectionService service;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, title, subtitle, color) = switch (service.status) {
      BleStatus.connected => (
        Icons.bluetooth_connected,
        'Подключено',
        service.firmware ?? 'Chameleon',
        scheme.primary,
      ),
      BleStatus.scanning => (
        Icons.bluetooth_searching,
        'Поиск устройств',
        service.autoScanActive
            ? 'Поиск повторяется автоматически'
            : 'Держите Chameleon рядом с телефоном',
        scheme.primary,
      ),
      BleStatus.connecting => (
        Icons.bluetooth,
        'Подключение к Chameleon',
        'Ожидание ответа Chameleon',
        scheme.tertiary,
      ),
      BleStatus.error => (
        Icons.bluetooth_disabled,
        'Ошибка',
        'Проверьте Bluetooth и разрешения',
        scheme.error,
      ),
      BleStatus.idle =>
        service.autoScanActive
            ? (
                Icons.bluetooth_searching,
                'Ожидание поиска',
                'Следующий поиск начнётся автоматически',
                scheme.primary,
              )
            : (
                Icons.bluetooth_disabled,
                'Chameleon не подключён',
                'Нажмите «Начать поиск»',
                scheme.onSurfaceVariant,
              ),
    };

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: LText(title),
        subtitle: LText(subtitle),
      ),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({required this.service});

  final ConnectionService service;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: LText(service.firmware ?? 'Chameleon'),
        subtitle: LText(service.current?.port.toString() ?? ''),
        trailing: TextButton(
          onPressed: service.disconnect,
          child: const LText('Отключить'),
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.enabled,
    required this.onConnect,
  });

  final Chameleon device;
  final bool enabled;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final name = 'Chameleon ${chameleonDeviceName(device.device)}';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.bluetooth),
        title: LText(device.name?.isNotEmpty == true ? device.name! : name),
        subtitle: LText(device.port.toString()),
        trailing: FilledButton.tonal(
          onPressed: enabled ? onConnect : null,
          child: const LText('Подключить'),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(
              child: LText(
                'Если Chameleon не найден, проверьте Bluetooth и разрешения, '
                'затем нажмите «Начать поиск».',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
