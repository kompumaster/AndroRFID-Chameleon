import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:androrfid_chameleon/app.dart';

void main() {
  testWidgets('app starts on the connection tab', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'app_language': 'ru'});
    await tester.pumpWidget(
      const RfidChameleonApp(autoStartConnections: false),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('RFID Chameleon'), findsWidgets);
    expect(find.text('Подключение Chameleon'), findsOneWidget);
    expect(find.text('Подключение'), findsOneWidget);
    expect(find.text('Метка'), findsOneWidget);
    expect(find.text('Данные'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
  });

  testWidgets('non-BLE tabs are available without Chameleon', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_language': 'ru'});
    await tester.pumpWidget(
      const RfidChameleonApp(autoStartConnections: false),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Метка'));
    await tester.pump();

    expect(find.text('Чтение QIDI-метки'), findsOneWidget);
    expect(
      find.textContaining(
        'Chameleon не подключён — чтение и запись метки недоступны.',
      ),
      findsWidgets,
    );

    await tester.tap(find.text('Настройки'));
    await tester.pump();

    expect(find.text('Автоматическое сканирование'), findsOneWidget);
    expect(
      find.text('Автоматически подключаться к последнему'),
      findsOneWidget,
    );
  });
}
