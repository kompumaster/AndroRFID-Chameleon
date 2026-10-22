import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'core/ble/connection_service.dart';
import 'data/qidi/qidi_lists_store.dart';
import 'data/records/record_repository.dart';
import 'data/snapmaker/snapmaker_settings.dart';
import 'ui/home/home_page.dart';

class RfidChameleonApp extends StatelessWidget {
  const RfidChameleonApp({super.key, this.autoStartConnections = true});

  final bool autoStartConnections;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionService()),
        ChangeNotifierProvider(create: (_) => AppState()..ensureLoaded()),
        ChangeNotifierProvider(create: (_) => QidiListsStore()..ensureLoaded()),
        ChangeNotifierProvider(
          create: (_) => RecordRepository()..ensureLoaded(),
        ),
        ChangeNotifierProvider(
          create: (_) => SnapmakerSettingsStore()..ensureLoaded(),
        ),
      ],
      child: MaterialApp(
        title: 'RFID Chameleon',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        home: HomePage(autoStartConnections: autoStartConnections),
      ),
    );
  }
}
