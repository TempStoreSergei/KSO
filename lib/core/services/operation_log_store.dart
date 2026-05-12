import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OperationLogEntry {
  OperationLogEntry({
    required this.timestamp,
    required this.level,
    required this.area,
    required this.action,
    required this.data,
    this.id,
    this.flowId,
    this.transactionId,
  });

  final DateTime timestamp;
  final String level;
  final String area;
  final String? action;
  final String? id;
  final String? flowId;
  final String? transactionId;
  final Map<String, dynamic> data;

  factory OperationLogEntry.fromJson(Map<String, dynamic> json) {
    return OperationLogEntry(
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      level: json['level']?.toString() ?? 'INFO',
      area: json['area']?.toString() ?? 'unknown',
      action: json['action']?.toString(),
      id: json['id']?.toString(),
      flowId: json['flowId']?.toString(),
      transactionId: json['transactionId']?.toString(),
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level,
      'area': area,
      if (action != null) 'action': action,
      if (id != null) 'id': id,
      if (flowId != null) 'flowId': flowId,
      if (transactionId != null) 'transactionId': transactionId,
      'data': data,
    };
  }
}

class OperationLogStore {
  OperationLogStore._();

  static final OperationLogStore instance = OperationLogStore._();
  static const String _storageKey = 'operation_log_entries_v1';
  static const int _maxEntries = 800;
  Future<void> _writeQueue = Future.value();

  Future<void> append(Map<String, Object?> payload) async {
    _writeQueue = _writeQueue.catchError((_) {}).then((_) => _appendNow(payload));
    return _writeQueue;
  }

  Future<void> _appendNow(Map<String, Object?> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_storageKey) ?? <String>[];
    final normalizedPayload = _normalize(payload);
    entries.add(jsonEncode(normalizedPayload));

    if (entries.length > _maxEntries) {
      entries.removeRange(0, entries.length - _maxEntries);
    }

    await prefs.setStringList(_storageKey, entries);
  }

  Future<List<OperationLogEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getStringList(_storageKey) ?? <String>[];
    final entries = <OperationLogEntry>[];

    for (final rawEntry in rawEntries) {
      try {
        final decoded = jsonDecode(rawEntry) as Map<String, dynamic>;
        entries.add(OperationLogEntry.fromJson(decoded));
      } catch (_) {
        // Ignore malformed legacy entries.
      }
    }

    return entries.reversed.toList();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Map<String, dynamic> _normalize(Map<String, Object?> payload) {
    final data = Map<String, dynamic>.from(payload);
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'level': data.remove('level')?.toString() ?? 'INFO',
      'area': data.remove('area')?.toString() ?? 'unknown',
      if (data['action'] != null) 'action': data.remove('action')?.toString(),
      if (data['id'] != null) 'id': data.remove('id')?.toString(),
      if (data['flowId'] != null) 'flowId': data['flowId']?.toString(),
      if (data['transactionId'] != null) 'transactionId': data['transactionId']?.toString(),
      'data': data,
    };
  }
}
