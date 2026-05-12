import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:motel/core/services/operation_log_store.dart';

class DiagnosticLogger {
  DiagnosticLogger._();

  static int _sequence = 0;
  static final Map<String, DateTime> _startedAt = {};
  static final Map<String, Object?> _context = {};

  static String start(
    String area,
    String action, {
    Map<String, Object?> data = const {},
  }) {
    final id = '${area}_${++_sequence}';
    _startedAt[id] = DateTime.now();
    _write('START', id, area, action, data: data);
    return id;
  }

  static void success(
    String id, {
    Map<String, Object?> data = const {},
  }) {
    _write('SUCCESS', id, _areaFromId(id), null, data: data);
    _startedAt.remove(id);
  }

  static void failure(
    String id,
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> data = const {},
  }) {
    _write(
      'FAILURE',
      id,
      _areaFromId(id),
      null,
      data: {
        ...data,
        'errorType': error.runtimeType.toString(),
        'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      },
    );
    _startedAt.remove(id);
  }

  static void info(
    String area,
    String action, {
    Map<String, Object?> data = const {},
  }) {
    _write('INFO', null, area, action, data: data);
  }

  static bool isActive(String id) => _startedAt.containsKey(id);

  static void setContext(Map<String, Object?> context) {
    _context
      ..clear()
      ..addAll(_sanitizeMap(context));
  }

  static void updateContext(Map<String, Object?> context) {
    _context.addAll(_sanitizeMap(context));
  }

  static void clearContext() {
    _context.clear();
  }

  static void _write(
    String level,
    String? id,
    String area,
    String? action, {
    Map<String, Object?> data = const {},
  }) {
    final startedAt = id == null ? null : _startedAt[id];
    final elapsedMs = startedAt == null ? null : DateTime.now().difference(startedAt).inMilliseconds;
    final payload = <String, Object?>{
      'level': level,
      if (id != null) 'id': id,
      'area': area,
      if (action != null) 'action': action,
      if (elapsedMs != null) 'elapsedMs': elapsedMs,
      ..._context,
      ..._sanitizeMap(data),
    };

    debugPrint('[Diagnostics] ${jsonEncode(payload)}');
    unawaited(OperationLogStore.instance.append(payload));
  }

  static String _areaFromId(String id) {
    final separatorIndex = id.indexOf('_');
    return separatorIndex == -1 ? id : id.substring(0, separatorIndex);
  }

  static Map<String, Object?> _sanitizeMap(Map<String, Object?> data) {
    return data.map((key, value) => MapEntry(key, _sanitizeValue(key, value)));
  }

  static Object? _sanitizeValue(String key, Object? value) {
    final lowerKey = key.toLowerCase();
    if (_isSensitiveKey(lowerKey)) {
      return _mask(value);
    }

    if (value is Map) {
      return value.map((nestedKey, nestedValue) {
        final normalizedKey = nestedKey.toString();
        return MapEntry(normalizedKey, _sanitizeValue(normalizedKey, nestedValue));
      });
    }

    if (value is Iterable) {
      return value.map((item) => _sanitizeValue(key, item)).toList();
    }

    if (value == null || value is String || value is num || value is bool) {
      return value;
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    return value.toString();
  }

  static bool _isSensitiveKey(String key) {
    return key.contains('token') ||
        key.contains('authorization') ||
        key.contains('password') ||
        key.contains('phone') ||
        key.contains('fio') ||
        key.contains('chat');
  }

  static String _mask(Object? value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return '';
    if (text.length <= 4) return '***';
    return '${text.substring(0, 2)}***${text.substring(text.length - 2)}';
  }
}
