import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/ble/connection_service.dart';
import '../../l10n/app_translations.dart';
import '../connect/connect_page.dart';
import '../records/records_page.dart';
import '../settings/settings_page.dart';
import '../tag/tag_page.dart';
import '../widgets/l_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.autoStartConnections = true});

  final bool autoStartConnections;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? _lastBackAt;

  @override
  void initState() {
    super.initState();
    if (!widget.autoStartConnections) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_bootstrapConnection());
    });
  }

  Future<void> _bootstrapConnection() async {
    final connection = context.read<ConnectionService>();
    await connection.ensureLoaded();
    if (!mounted || connection.isConnected) {
      return;
    }
    if (connection.autoScanSetting) {
      connection.startAutoScan();
    }
  }

  void _onPopInvoked(bool didPop, Object? result) {
    if (didPop) {
      return;
    }
    final now = DateTime.now();
    final last = _lastBackAt;
    if (last == null || now.difference(last) > const Duration(seconds: 2)) {
      _lastBackAt = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: LText('Нажмите «Назад» ещё раз для выхода')),
        );
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionService>();
    final appState = context.watch<AppState>();
    final language = appState.language;
    final connected = connection.isConnected;
    final index = appState.homeTab;
    String t(String source) => AppTranslations.translate(language, source);

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: const LText('RFID Chameleon'),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  avatar: Icon(
                    connected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    size: 18,
                  ),
                  label: LText(
                    connected
                        ? (connection.firmware ?? 'Chameleon')
                        : 'Нет Chameleon',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (!context.mounted) {
                  return;
                }
                if (value == 'disconnect') {
                  await connection.disconnect();
                } else if (value == 'connect') {
                  context.read<AppState>().homeTab = 0;
                }
              },
              itemBuilder: (context) => [
                if (connected)
                  const PopupMenuItem(
                    value: 'disconnect',
                    child: LText('Отключить Chameleon'),
                  )
                else
                  const PopupMenuItem(
                    value: 'connect',
                    child: LText('Перейти к подключению'),
                  ),
              ],
            ),
          ],
        ),
        body: IndexedStack(
          index: index,
          children: const [
            ConnectPage(),
            TagPage(),
            RecordsPage(),
            SettingsPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) {
            context.read<AppState>().homeTab = value;
          },
          destinations: [
            NavigationDestination(
              icon: Icon(
                connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_searching,
              ),
              selectedIcon: Icon(
                connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_searching,
              ),
              label: t('Подключение'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.nfc_outlined),
              selectedIcon: const Icon(Icons.nfc),
              label: t('Метка'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2),
              label: t('Данные'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: t('Настройки'),
            ),
          ],
        ),
      ),
    );
  }
}
