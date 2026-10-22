import '../../app_state.dart';

class AppTranslations {
  static String translate(AppLanguage language, String source) {
    if (language == AppLanguage.ru) {
      return source;
    }
    final exact = _en[source];
    if (exact != null) {
      return exact;
    }

    for (final entry in _prefixes.entries) {
      if (source.startsWith(entry.key)) {
        return entry.value +
            translate(language, source.substring(entry.key.length));
      }
    }

    var result = source;
    final entries = _en.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in entries) {
      if (result.contains(entry.key)) {
        result = result.replaceAll(entry.key, entry.value);
      }
    }
    return result;
  }

  static const Map<String, String> _prefixes = {
    'Сохранено: ': 'Saved: ',
    'Импортировано: ': 'Imported: ',
    'CFG импортирован: ': 'CFG imported: ',
    'Создано: ': 'Created: ',
    'QIDI CFG: ': 'QIDI CFG: ',
    'Списки материалов заблокированы: ': 'Material lists locked: ',
    'Не удалось импортировать .bin: ': 'Could not import .bin: ',
    'Неподдерживаемый размер .bin: ': 'Unsupported .bin size: ',
    'Не удалось сохранить запись: ': 'Could not save record: ',
    'Не удалось экспортировать .bin: ': 'Could not export .bin: ',
    'Не удалось переименовать: ': 'Could not rename: ',
    'Не удалось импортировать CFG: ': 'Could not import CFG: ',
    'CFG: ': 'CFG: ',
    'Текущий адрес: ': 'Current address: ',
    'При первом запуске: СНГ → русский, остальные → английский.':
        'First launch: CIS → Russian, others → English.',
    'Редактирование списков вручную пока не реализовано. QIDI CFG импортируется выше.': 'Manual list editing is not implemented yet. QIDI CFG is imported above.',
    ' материалов · 24 цвета · 2 производителя.':
        ' materials · 24 colors · 2 manufacturers.',
    ' материалов · 22 производителя.': ' materials · 22 manufacturers.',
    'Ошибка поиска BLE: ': 'BLE scan error: ',
    'Найдено устройств: ': 'Devices found: ',
    'Последнее: ': 'Last: ',
    'Ошибка подключения: ': 'Connection error: ',
    'Метка вернула ': 'Tag returned ',
    'NTAG не вернул страницу ': 'NTAG did not return page ',
    'NTAG не подтвердил запись страницы ':
        'NTAG did not confirm write of page ',
    'Chameleon не подтвердил запись блока ':
        'Chameleon did not confirm write of block ',
    'Не удалось прочитать QIDI-метку. Проверьте, что это MIFARE Classic 1K и метка лежит на Chameleon. Ошибка: ': 'Could not read QIDI tag. Make sure it is MIFARE Classic 1K and on Chameleon. Error: ',
    'Не удалось записать QIDI-метку. Ошибка: ':
        'Could not write QIDI tag. Error: ',
    'Не удалось прочитать OpenSpool-метку. Проверьте, что это NTAG215. Ошибка: ':
        'Could not read OpenSpool tag. Make sure it is NTAG215. Error: ',
    'Не удалось записать OpenSpool-метку. Ошибка: ':
        'Could not write OpenSpool tag. Error: ',
    'U1 не вернул filament_detected для ToolHead ':
        'U1 did not return filament_detected for ToolHead ',
  };

  static const Map<String, String> _en = {
    'RFID Chameleon': 'RFID Chameleon',
    'RFID Chameleon · 1.0.0': 'RFID Chameleon · 1.0.0',
    'Подключение': 'Connection',
    'Подключение Chameleon': 'Chameleon connection',
    'Подключение к Chameleon': 'Connecting to Chameleon',
    'Поиск запускается автоматически и повторяется, пока Chameleon не будет найден.':
        'Search starts automatically and repeats until Chameleon is found.',
    'Автоматическое сканирование выключено. Нажмите «Начать поиск».':
        'Automatic scanning is off. Tap “Start search”.',
    'Остановить поиск': 'Stop search',
    'Начать поиск': 'Start search',
    'Нет Chameleon': 'No Chameleon',
    'Перейти к подключению': 'Go to connection',
    'Сначала подключите Chameleon': 'Connect Chameleon first',
    'Нажмите «Назад» ещё раз для выхода': 'Press Back again to exit',
    'Ожидание поиска': 'Waiting to search',
    'Следующий поиск начнётся автоматически':
        'Next search will start automatically',
    'Поиск повторяется автоматически': 'Search repeats automatically',
    'Нажмите «Начать поиск»': 'Tap “Start search”',
    'Автоматическое сканирование': 'Automatic scanning',
    'Запускать поиск Chameleon при старте приложения':
        'Start Chameleon search on app launch',
    'Автоматически подключаться к последнему':
        'Automatically connect to the last device',
    'Появится после первого подключения': 'Appears after the first connection',
    'Chameleon не подключён — чтение и запись метки недоступны.':
        'Chameleon is not connected — tag read and write are unavailable.',
    'Chameleon не подключён — чтение и запись метки недоступны. Сохранение и отправка на U1 работают.': 'Chameleon is not connected — tag read and write are unavailable. Saving and sending to U1 still work.',
    'Если Chameleon не найден, проверьте Bluetooth и разрешения, затем нажмите «Начать поиск».': 'If Chameleon is not found, check Bluetooth and permissions, then tap “Start search”.',
    'Ожидание ответа Chameleon': 'Waiting for Chameleon',
    'Поиск устройств': 'Scanning for devices',
    'Держите Chameleon рядом с телефоном': 'Keep Chameleon near your phone',
    'Найти Chameleon': 'Find Chameleon',
    'Поиск…': 'Scanning…',
    'Chameleon не подключён': 'Chameleon is not connected',
    'Включите Bluetooth и нажмите «Найти»': 'Turn on Bluetooth and tap “Find”',
    'Ошибка': 'Error',
    'Проверьте Bluetooth и разрешения': 'Check Bluetooth and permissions',
    'Подключено': 'Connected',
    'Отключить': 'Disconnect',
    'Подключить': 'Connect',
    'Нажмите «Найти Chameleon», чтобы найти устройство рядом.':
        'Tap “Find Chameleon” to find a nearby device.',
    'Chameleon подключён': 'Chameleon connected',
    'Не удалось подключиться': 'Could not connect',
    'Не удалось подключиться к Chameleon.': 'Could not connect to Chameleon.',
    'Соединение с Chameleon потеряно.': 'Connection to Chameleon lost.',
    'Порт должен быть числом': 'Port must be a number',
    'Нет разрешений Bluetooth. Разрешите «Устройства поблизости» в настройках приложения.': 'Bluetooth permission is missing. Allow “Nearby devices” in app settings.',
    'Настройки приложения': 'App settings',
    'Метка': 'Tag',
    'Данные': 'Data',
    'Настройки': 'Settings',
    'Отключить Chameleon': 'Disconnect Chameleon',
    'Читать': 'Read',
    'Записать': 'Write',
    'Чтение QIDI-метки': 'Read QIDI tag',
    'MIFARE Classic 1K, блок 4, ключ A FFFFFFFFFFFF.':
        'MIFARE Classic 1K, block 4, key A FFFFFFFFFFFF.',
    'Прочитать метку': 'Read tag',
    'Читаю…': 'Reading…',
    'Приложите QIDI-метку к Chameleon и нажмите «Прочитать метку».':
        'Place a QIDI tag on Chameleon and tap “Read tag”.',
    'Метка прочитана': 'Tag read',
    'Запись QIDI-метки': 'Write QIDI tag',
    'Будут записаны блок 4 и нули в байтах 3–15.':
        'Block 4 will be written; bytes 3–15 will be zeroed.',
    'Модель принтера': 'Printer model',
    'Материал': 'Material',
    'Цвет': 'Color',
    'Цвет (color_hex)': 'Color (color_hex)',
    'Выбор цвета': 'Select color',
    'Свой HEX': 'Custom HEX',
    'Применить': 'Apply',
    'Некорректный HEX': 'Invalid HEX',
    'Производитель': 'Manufacturer',
    'Предпросмотр блока 4': 'Block 4 preview',
    'Записать метку': 'Write tag',
    'Записываю…': 'Writing…',
    'Сохранить в данные': 'Save to data',
    'Прочитано': 'Read result',
    'Блок 4': 'Block 4',
    'Неизвестно': 'Unknown',
    'Чтение OpenSpool': 'Read OpenSpool',
    'Чтение Snapmaker U1': 'Read Snapmaker U1',
    'NTAG215, CC E1 10 3E 00, MIME application/json.':
        'NTAG215, CC E1 10 3E 00, MIME application/json.',
    'Приложите NTAG215 с OpenSpool-записью к Chameleon и нажмите «Прочитать метку».': 'Place an NTAG215 with an OpenSpool record on Chameleon and tap “Read tag”.',
    'OpenSpool-метка прочитана': 'OpenSpool tag read',
    'Запись OpenSpool': 'Write OpenSpool',
    'Запись Snapmaker U1': 'Write Snapmaker U1',
    'JSON/NDEF будет записан в пользовательские страницы NTAG215.':
        'JSON/NDEF will be written to the NTAG215 user pages.',
    'Версия данных': 'Data version',
    'Бренд': 'Brand',
    'Подтип (subtype)': 'Subtype',
    'Нет': 'None',
    'например, Matte': 'e.g. Matte',
    'Сопло min, °C': 'Nozzle min, °C',
    'Сопло max, °C': 'Nozzle max, °C',
    'Стол min, °C': 'Bed min, °C',
    'Стол max, °C': 'Bed max, °C',
    'Сопло': 'Nozzle',
    'Стол': 'Bed',
    'Вес': 'Weight',
    'Диаметр': 'Diameter',
    'Доп. цвета': 'Extra colors',
    'Alpha': 'Alpha',
    'Alpha / прозрачность': 'Alpha / transparency',
    'Прозрачность:': 'Transparency:',
    '0% — непрозрачный, 100% — прозрачный': '0% — opaque, 100% — transparent',
    'Вес, г': 'Weight, g',
    'Диаметр, мм': 'Diameter, mm',
    'Доп. цвета через запятую': 'Extra colors, comma separated',
    'JSON для записи': 'JSON to write',
    'OpenSpool-метка записана и проверена':
        'OpenSpool tag written and verified',
    'Отправить на U1': 'Send to U1',
    'Сохранённые метки': 'Saved tags',
    'Импорт .bin': 'Import .bin',
    'Импорт QIDI .bin': 'Import QIDI .bin',
    'Пока нет сохранённых меток': 'No saved tags yet',
    'Прочитайте метку или создайте новую на вкладке «Метка» и нажмите «Сохранить в данные». Также можно импортировать совместимый .bin.': 'Read or create a tag on the “Tag” tab and tap “Save to data”. You can also import a compatible .bin.',
    'Имя записи': 'Record name',
    'Отмена': 'Cancel',
    'Сохранить': 'Save',
    'Удалить запись?': 'Delete record?',
    'Удалить': 'Delete',
    'Переименовать': 'Rename',
    'Записать на метку': 'Write to tag',
    'Экспорт .bin': 'Export .bin',
    'Экспорт .bin (540)': 'Export .bin (540)',
    'Snapmaker U1': 'Snapmaker U1',
    'Телефон и принтер должны быть в одной Wi-Fi сети. Используется HTTP.':
        'Phone and printer must be on the same Wi-Fi network. HTTP is used.',
    'Подключение по Wi-Fi без Chameleon. Телефон и принтер должны быть в одной сети. Используется HTTP.': 'Wi-Fi connection without Chameleon. Phone and printer must be on the same network. HTTP is used.',
    'Host / IP': 'Host / IP',
    'Порт': 'Port',
    'Проверить': 'Check',
    'Нажмите «Проверить», чтобы загрузить состояние ToolHead.':
        'Tap “Check” to load ToolHead status.',
    'Связь с U1 установлена': 'U1 connection established',
    'Пусто': 'Empty',
    'Отправить': 'Send',
    'Закрыть': 'Close',
    'Отправить на Snapmaker U1': 'Send to Snapmaker U1',
    'В ToolHead уже обнаружен филамент. Перезаписать данные?':
        'Filament is already detected in this ToolHead. Overwrite the data?',
    'Перезаписать': 'Overwrite',
    'Данные отправлены в U1': 'Data sent to U1',
    'Проверьте host/port в разделе Snapmaker.':
        'Check host/port in the Snapmaker tab.',
    'Проверьте host/port в Настройках.': 'Check host/port in Settings.',
    'Язык / Language': 'Language',
    'Русский': 'Russian',
    'Модель QIDI': 'QIDI model',
    'Режим по умолчанию': 'Default mode',
    'OpenSpool профиль': 'OpenSpool profile',
    'OpenSpool версия данных': 'OpenSpool data version',
    'Host и порт задаются на вкладке «Snapmaker». Телефон и принтер должны быть в одной Wi-Fi сети.': 'Host and port are set in the “Snapmaker” tab. Phone and printer must be on the same Wi-Fi network.',
    'Списки': 'Lists',
    'Редактирование материалов и производителей — следующий шаг. QIDI .cfg импортируется выше и блокирует список.': 'Material and manufacturer editing is the next step. QIDI .cfg is imported above and locks the list.',
    'QIDI CFG не импортирован': 'QIDI CFG is not imported',
    'Можно импортировать officiall_filas_list.cfg с принтера.':
        'You can import officiall_filas_list.cfg from the printer.',
    'Импорт .cfg': 'Import .cfg',
    'Сбросить CFG': 'Reset CFG',
    'Сбросить': 'Reset',
    'Импорт QIDI .cfg': 'Import QIDI .cfg',
    'CFG сброшен, используются встроенные списки':
        'CFG reset; built-in lists are used',
    'Метка записана и проверена': 'Tag written and verified',
    'QIDI-метка записана и проверена': 'QIDI tag written and verified',
    'Файл сохранён': 'File saved',
    'импортированный список': 'imported list',
    'материалов': 'materials',
    'активных слотов': 'active slots',
    'занят': 'busy',
    'будет удалена.': 'will be deleted.',
    'Метка не найдена. Приложите QIDI-метку к Chameleon.':
        'Tag not found. Place a QIDI tag on Chameleon.',
    'Метка не найдена. Приложите NTAG215 к Chameleon.':
        'Tag not found. Place an NTAG215 on Chameleon.',
    'Проверка после записи OpenSpool не совпала.':
        'OpenSpool write verification failed.',
    'Chameleon не подтвердил запись блока 4.':
        'Chameleon did not confirm block 4 write.',
    'Проверка после записи не совпала.': 'Write verification failed.',
    'Не удалось получить статус U1': 'Could not get U1 status',
    'В ответе U1 нет filament_detect.info':
        'U1 response has no filament_detect.info',
    'ToolHead должен быть от 1 до 4': 'ToolHead must be from 1 to 4',
    'Не удалось проверить датчик филамента': 'Could not read filament sensor',
    'U1 не принял данные': 'U1 rejected the data',
    'U1 вернул некорректный JSON': 'U1 returned invalid JSON',
    'Не удалось установить NTAG215 CC E1 10 3E 00.':
        'Could not set NTAG215 CC E1 10 3E 00.',
    'NTAG вернул неполный заголовок.': 'NTAG returned an incomplete header.',
    'неизвестно': 'unknown',
    'импортирован': 'imported',
    'Сохранить QIDI .bin': 'Save QIDI .bin',
    'Сохранить OpenSpool .bin': 'Save OpenSpool .bin',
    'Неподдерживаемый размер .bin': 'Unsupported .bin size',
    'Ожидается 1024 (QIDI) или 540 (OpenSpool).':
        'Expected 1024 (QIDI) or 540 (OpenSpool).',
    'байт вместо': 'bytes instead of',
    'QIDI': 'QIDI',
    'OpenSpool': 'OpenSpool',
  };
}
