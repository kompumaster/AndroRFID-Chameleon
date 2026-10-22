import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/snapmaker/snapmaker_models.dart';

class SnapmakerException implements Exception {
  SnapmakerException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    final details = body == null || body!.isEmpty ? '' : ': $body';
    return '$message$code$details';
  }
}

class SnapmakerService {
  SnapmakerService({
    required this.host,
    required this.port,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String host;
  final int port;
  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri(
      scheme: 'http',
      host: _normalizedHost,
      port: port,
      path: path,
      queryParameters: query,
    );
  }

  Uri _rawUri(String pathAndQuery) {
    return Uri.parse('http://$_normalizedHost:$port$pathAndQuery');
  }

  String get _normalizedHost {
    var normalized = host.trim();
    if (normalized.contains('://')) {
      normalized = Uri.parse(normalized).host;
    } else {
      normalized = normalized.split('/').first.split(':').first;
    }
    return normalized;
  }

  Future<List<SnapmakerToolHead>> getToolHeads() async {
    final response = await _client
        .get(_uri('/printer/objects/query', {'filament_detect': 'info'}))
        .timeout(const Duration(seconds: 6));
    final json = _decode(response, 'Не удалось получить статус U1');
    final status = json['result']?['status'];
    final info = status?['filament_detect']?['info'];
    if (info is! List) {
      throw SnapmakerException('В ответе U1 нет filament_detect.info');
    }

    final result = <SnapmakerToolHead>[];
    for (var i = 0; i < 4; i++) {
      Map? item;
      if (i < info.length && info[i] is Map) {
        item = info[i] as Map;
      }
      final material = _string(item?['MAIN_TYPE']);
      final subtype = _string(item?['SUB_TYPE']);
      final rgb = item?['RGB_1'];
      final colorHex = rgb is int
          ? '#${(rgb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}'
          : '';
      result.add(
        SnapmakerToolHead(
          index: i + 1,
          material: material,
          subtype: subtype,
          colorHex: colorHex,
          empty: material.isEmpty,
        ),
      );
    }
    return result;
  }

  Future<bool> getFilamentDetected(int toolHead) async {
    if (toolHead < 1 || toolHead > 4) {
      throw ArgumentError('ToolHead должен быть от 1 до 4');
    }
    final key = 'filament_motion_sensor e${toolHead - 1}_filament';
    final response = await _client
        .get(
          _rawUri(
            '/printer/objects/query?filament_motion_sensor%20e${toolHead - 1}'
            '_filament=filament_detected',
          ),
        )
        .timeout(const Duration(seconds: 6));
    final json = _decode(response, 'Не удалось проверить датчик филамента');
    final sensor = json['result']?['status']?[key];
    final detected = sensor?['filament_detected'];
    if (detected is! bool) {
      throw SnapmakerException(
        'U1 не вернул filament_detected для ToolHead $toolHead',
      );
    }
    return detected;
  }

  Future<void> sendTag(int toolHead, SnapmakerTagPayload payload) async {
    final body = jsonEncode(payload.toJson(toolHead));
    final response = await _client
        .post(
          _uri('/printer/filament_detect/set'),
          headers: const {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SnapmakerException(
        'U1 не принял данные',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response, String message) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SnapmakerException(
        message,
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // fall through
    }
    throw SnapmakerException('U1 вернул некорректный JSON');
  }

  String _string(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }
}
