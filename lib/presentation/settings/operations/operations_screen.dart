import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:motel/core/services/operation_log_store.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  List<OperationLogEntry> _entries = [];
  String _statusFilter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await OperationLogStore.instance.getEntries();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  Future<void> _clearEntries() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Очистить операции?'),
        content: const Text('Локальная история диагностики будет удалена с этого устройства.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await OperationLogStore.instance.clear();
    await _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final journeys = _filteredJourneys;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Операции'),
            previousPageTitle: 'Настройки',
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _entries.isEmpty ? null : _clearEntries,
              child: const Icon(CupertinoIcons.trash),
            ),
          ),
          CupertinoSliverRefreshControl(onRefresh: _loadEntries),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: CupertinoSlidingSegmentedControl<String>(
                groupValue: _statusFilter,
                children: const {
                  'all': Text('Все'),
                  'success': Text('Успешные'),
                  'problem': Text('Проблемы'),
                  'timeout': Text('Timeout'),
                },
                onValueChanged: (value) {
                  if (value == null) return;
                  setState(() => _statusFilter = value);
                },
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (journeys.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Путей оплаты пока нет',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: journeys.length,
              itemBuilder: (context, index) {
                final journey = journeys[index];
                return _JourneyTile(
                  journey: journey,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => _OperationJourneyDetailsScreen(journey: journey)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<_OperationJourney> get _filteredJourneys {
    final journeys = _buildJourneys(_entries);
    switch (_statusFilter) {
      case 'success':
        return journeys.where((journey) => journey.status == _JourneyStatus.success).toList();
      case 'problem':
        return journeys.where((journey) => journey.status == _JourneyStatus.failed || journey.hasFailure).toList();
      case 'timeout':
        return journeys.where((journey) => journey.status == _JourneyStatus.timeout).toList();
      default:
        return journeys;
    }
  }

  List<_OperationJourney> _buildJourneys(List<OperationLogEntry> entries) {
    final groups = <String, List<OperationLogEntry>>{};

    for (final entry in entries) {
      final key = entry.transactionId ?? entry.flowId;
      if (key == null || key.isEmpty) continue;
      groups.putIfAbsent(key, () => []).add(entry);
    }

    final journeys = groups.entries
        .map((entry) {
          final sortedEntries = [...entry.value]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return _OperationJourney(id: entry.key, entries: sortedEntries);
        })
        .where((journey) => journey.isUserPaymentJourney)
        .toList();

    journeys.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return journeys;
  }
}

enum _JourneyStatus {
  inProgress,
  success,
  failed,
  timeout,
  cancelled,
}

class _OperationJourney {
  _OperationJourney({
    required this.id,
    required this.entries,
  });

  final String id;
  final List<OperationLogEntry> entries;

  DateTime get startedAt => entries.first.timestamp;

  DateTime get finishedAt => entries.last.timestamp;

  Duration get duration => finishedAt.difference(startedAt);

  bool get isUserPaymentJourney {
    return entries.any((entry) => entry.area == 'payment_flow' && entry.action == 'flow_start');
  }

  bool get hasFailure => entries.any((entry) => entry.level == 'FAILURE');

  String get transactionId => entries.first.transactionId ?? id;

  String? get serverTransactionId => _firstValue('serverTransactionId');

  String? get paymentMethod => _firstValue('paymentMethod');

  int? get amount {
    final rawAmount = _firstValue('amount');
    if (rawAmount == null) return null;
    return int.tryParse(rawAmount);
  }

  int? get collectedAmount {
    final values = entries
        .map((entry) => entry.data['collectedAmount'])
        .where((value) => value != null)
        .map((value) => int.tryParse(value.toString()))
        .whereType<int>()
        .toList();
    if (values.isEmpty) return null;
    return values.last;
  }

  _JourneyStatus get status {
    final finishEntry = entries.lastWhere(
      (entry) => entry.area == 'payment_flow' && entry.action == 'flow_finish',
      orElse: () => entries.last,
    );
    final result = finishEntry.data['result']?.toString();

    if (result == 'completed') return _JourneyStatus.success;
    if (result == 'timeout') return _JourneyStatus.timeout;
    if (result == 'cancelled') return _JourneyStatus.cancelled;
    if (hasFailure || result == 'payment_error_event' || result == 'hardware_start_failed') {
      return _JourneyStatus.failed;
    }
    return _JourneyStatus.inProgress;
  }

  String get statusLabel {
    switch (status) {
      case _JourneyStatus.success:
        return 'Успешно';
      case _JourneyStatus.failed:
        return 'Ошибка';
      case _JourneyStatus.timeout:
        return 'Timeout';
      case _JourneyStatus.cancelled:
        return 'Отмена';
      case _JourneyStatus.inProgress:
        return 'Не завершено';
    }
  }

  Color get statusColor {
    switch (status) {
      case _JourneyStatus.success:
        return CupertinoColors.systemGreen;
      case _JourneyStatus.failed:
        return CupertinoColors.systemRed;
      case _JourneyStatus.timeout:
        return CupertinoColors.systemOrange;
      case _JourneyStatus.cancelled:
        return CupertinoColors.systemGrey;
      case _JourneyStatus.inProgress:
        return CupertinoColors.activeBlue;
    }
  }

  String? _firstValue(String key) {
    for (final entry in entries) {
      final value = entry.data[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return null;
  }
}

class _JourneyTile extends StatelessWidget {
  const _JourneyTile({
    required this.journey,
    required this.onTap,
  });

  final _OperationJourney journey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amount = journey.amount;
    final collected = journey.collectedAmount;
    final serverId = journey.serverTransactionId;

    return CupertinoListTile(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      title: Text(
        serverId == null ? journey.transactionId : 'Транзакция #$serverId',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            'Локальный путь: ${journey.transactionId}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 2),
          Text(
            'Старт: ${_formatDateTime(journey.startedAt)} • Длительность: ${_formatDuration(journey.duration)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey2),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (journey.paymentMethod != null) _pill(journey.paymentMethod!, CupertinoColors.systemGrey),
              if (amount != null) _pill('К оплате: ${amount ~/ 100} ₽', CupertinoColors.systemGrey),
              if (collected != null) _pill('Внесено: ${collected ~/ 100} ₽', CupertinoColors.systemGrey),
              _pill('${journey.entries.length} событий', CupertinoColors.systemGrey),
            ],
          ),
        ],
      ),
      additionalInfo: SizedBox(
        width: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusPill(journey.statusLabel, journey.statusColor),
            const SizedBox(height: 8),
            if (amount != null)
              Text(
                '${amount ~/ 100} ₽',
                style: const TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.activeBlue, fontSize: 16),
              ),
            const SizedBox(height: 8),
            const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey3, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _formatDateTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}м ${duration.inSeconds % 60}с';
    }
    return '${duration.inSeconds}с';
  }
}

class _OperationJourneyDetailsScreen extends StatelessWidget {
  const _OperationJourneyDetailsScreen({required this.journey});

  final _OperationJourney journey;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Путь оплаты'),
            previousPageTitle: 'Операции',
            trailing: _statusPill(journey.statusLabel, journey.statusColor),
          ),
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              header: const Text('СВОДКА'),
              children: [
                _summaryRow('Локальный ID', journey.transactionId),
                if (journey.serverTransactionId != null) _summaryRow('ID на сервере', journey.serverTransactionId!),
                if (journey.paymentMethod != null) _summaryRow('Оплата', journey.paymentMethod!),
                if (journey.amount != null) _summaryRow('К оплате', '${journey.amount! ~/ 100} ₽'),
                if (journey.collectedAmount != null) _summaryRow('Внесено', '${journey.collectedAmount! ~/ 100} ₽'),
                _summaryRow('Старт', _formatDateTime(journey.startedAt)),
                _summaryRow('Длительность', _formatDuration(journey.duration)),
                _summaryRow('Событий', journey.entries.length.toString()),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'ОТ НАЧАЛА ДО КОНЦА',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: journey.entries.length,
            itemBuilder: (context, index) {
              final entry = journey.entries[index];
              final previous = index == 0 ? null : journey.entries[index - 1];
              return _TimelineEventTile(
                entry: entry,
                delta: previous == null ? Duration.zero : entry.timestamp.difference(previous.timestamp),
                isFirst: index == 0,
                isLast: index == journey.entries.length - 1,
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return CupertinoListTile(
      title: Text(label),
      additionalInfo: Text(value, textAlign: TextAlign.right),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _formatDateTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}м ${duration.inSeconds % 60}с';
    }
    return '${duration.inSeconds}с';
  }
}

class _TimelineEventTile extends StatelessWidget {
  const _TimelineEventTile({
    required this.entry,
    required this.delta,
    required this.isFirst,
    required this.isLast,
  });

  final OperationLogEntry entry;
  final Duration delta;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(entry);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: isFirst ? 12 : 18,
                  color: isFirst ? CupertinoColors.transparent : CupertinoColors.systemGrey4,
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Container(
                  width: 2,
                  height: isLast ? 12 : 70,
                  color: isLast ? CupertinoColors.transparent : CupertinoColors.systemGrey4,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _eventTitle(entry),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(entry.timestamp),
                        style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.area} • ${entry.level}${delta == Duration.zero ? '' : ' • +${_formatDuration(delta)}'}',
                    style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    const JsonEncoder.withIndent('  ').convert(entry.toJson()),
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _eventColor(OperationLogEntry entry) {
    if (entry.level == 'FAILURE') return CupertinoColors.systemRed;
    if (entry.level == 'SUCCESS') return CupertinoColors.systemGreen;
    if (entry.area == 'payment_flow') return CupertinoColors.activeBlue;
    if (entry.area == 'api') return CupertinoColors.systemPurple;
    if (entry.area == 'websocket') return CupertinoColors.systemTeal;
    return CupertinoColors.systemGrey;
  }

  String _eventTitle(OperationLogEntry entry) {
    final event = entry.data['event']?.toString();
    if (event != null && event.isNotEmpty) return _humanize(event);
    return _humanize(entry.action ?? entry.level);
  }

  String _humanize(String value) {
    switch (value) {
      case 'flow_start':
        return 'Начало пути оплаты';
      case 'payment_start_requested':
        return 'Запрошен старт оплаты';
      case 'device_ready':
        return 'Оборудование готово';
      case 'cash_accepted':
        return 'Купюра принята';
      case 'success_payment_event':
        return 'Получено успешное событие оплаты';
      case 'print_check_started':
        return 'Печать чека начата';
      case 'print_check_succeeded':
        return 'Чек напечатан';
      case 'transaction_save_started':
        return 'Сохранение транзакции начато';
      case 'transaction_save_succeeded':
        return 'Транзакция сохранена';
      case 'timeout_started':
        return 'Истекло время оплаты';
      case 'partial_payment_prompt_shown':
        return 'Показано продление неполной оплаты';
      case 'partial_payment_extended':
        return 'Прием оплаты продлен';
      case 'cash_acceptance_stop_started':
        return 'Остановка приема наличных';
      case 'cash_return_started':
        return 'Выдача внесенной суммы';
      case 'cash_return_succeeded':
        return 'Внесенная сумма выдана';
      case 'flow_finish':
        return 'Путь оплаты завершен';
      default:
        return value.replaceAll('_', ' ');
    }
  }

  String _formatTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}м ${duration.inSeconds % 60}с';
    }
    return '${duration.inMilliseconds}мс';
  }
}
