// lib/presentation/settings/shift/widgets/shift_status_section.dart

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:motel/presentation/settings/shift/models/shift_settings.dart';

/// Секция отображения текущего состояния смены
class ShiftStatusSection extends StatelessWidget {
  final ShiftSettings settings;

  const ShiftStatusSection({
    super.key,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final shiftData = settings.shiftData;

    // Вычисляем время закрытия (date_time минус 5 минут)
    final closeTime = shiftData?.dateTime.subtract(const Duration(minutes: 5));

    // Вычисляем оставшееся время до закрытия
    String? timeRemaining;
    if (settings.shiftIsOpened && closeTime != null) {
      final now = DateTime.now();
      final remaining = closeTime.difference(now);

      if (remaining.isNegative) {
        timeRemaining = 'Смена должна быть закрыта';
      } else {
        final hours = remaining.inHours;
        final minutes = remaining.inMinutes % 60;
        timeRemaining = '$hoursч $minutesм';
      }
    }

    // Определяем статус смены и цвет
    String statusText;
    Color statusColor;

    if (shiftData != null) {
      if (shiftData.isExpired) {
        statusText = 'Истекла (>24ч)';
        statusColor = CupertinoColors.systemRed;
      } else if (shiftData.isOpen) {
        statusText = 'Открыта';
        statusColor = CupertinoColors.activeGreen;
      } else {
        statusText = 'Закрыта';
        statusColor = CupertinoColors.systemGrey;
      }
    } else {
      statusText = settings.shiftIsOpened ? 'Открыта' : 'Закрыта';
      statusColor = settings.shiftIsOpened
          ? CupertinoColors.activeGreen
          : CupertinoColors.systemGrey;
    }

    return CupertinoListSection.insetGrouped(
      header: const Text('ТЕКУЩЕЕ СОСТОЯНИЕ'),
      children: [
        CupertinoListTile(
          title: const Text('Статус смены'),
          trailing: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (shiftData != null)
          CupertinoListTile(
            title: const Text('Номер смены'),
            trailing: Text(
              '№${shiftData.shiftNumber}',
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 17,
              ),
            ),
          ),
        if ((settings.shiftIsOpened || shiftData?.isExpired == true) && shiftData != null) ...[
          CupertinoListTile(
            title: const Text('Время открытия'),
            trailing: Text(
              '${DateFormat('HH:mm').format(shiftData.dateTime)} '
                  '${_getDayLabel(shiftData.dateTime.subtract(const Duration(days: 1)))}',
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 17,
              ),
            ),
          ),
          if (closeTime != null)
            CupertinoListTile(
              title: const Text('Закрытие в'),
              trailing: Text(
                '${DateFormat('HH:mm').format(closeTime)} ${_getDayLabel(closeTime)}',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 17,
                ),
              ),
            ),
          if (timeRemaining != null)
            CupertinoListTile(
              title: const Text('До закрытия'),
              trailing: Text(
                timeRemaining,
                style: TextStyle(
                  color: closeTime != null && closeTime.difference(DateTime.now()).inMinutes < 30
                      ? CupertinoColors.systemRed
                      : CupertinoColors.systemOrange,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ],
    );
  }

  /// Возвращает подпись дня (сегодня/завтра)
  String _getDayLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (targetDate == today) {
      return '(сегодня)';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return '(завтра)';
    } else {
      // На всякий случай, если дата далеко
      return '(${DateFormat('dd.MM').format(dateTime)})';
    }
  }
}
