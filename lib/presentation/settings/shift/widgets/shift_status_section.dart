import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:motel/presentation/settings/shift/models/shift_settings.dart';
import 'package:motel/presentation/settings/widgets/settings_info_footer.dart';

/// Секция отображения текущего состояния смены.
class ShiftStatusSection extends StatelessWidget {
  final ShiftSettings settings;

  const ShiftStatusSection({
    super.key,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final shiftData = settings.shiftData;
    final closeTime = settings.autoShiftsTimeToClose == null
        ? null
        : _nextTimeOccurrence(settings.autoShiftsTimeToClose!);
    final status = _ShiftStatusViewModel.fromSettings(settings);
    final timeRemaining = _timeRemaining(closeTime);

    return Column(
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('ТЕКУЩЕЕ СОСТОЯНИЕ'),
          children: [
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: status.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  status.icon,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: const Text('Статус смены'),
              trailing: Text(
                status.title,
                style: TextStyle(
                  color: status.color,
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
            if ((settings.shiftIsOpened || shiftData?.isExpired == true) &&
                shiftData != null) ...[
              if (timeRemaining != null)
                CupertinoListTile(
                  title: const Text('До закрытия'),
                  trailing: Text(
                    timeRemaining,
                    style: TextStyle(
                      color: _isCloseSoon(closeTime)
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemOrange,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
            if (settings.lastAutomationError != null)
              CupertinoListTile(
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.exclamationmark_circle_fill,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                ),
                title: const Text('Ошибка автоматики'),
                subtitle: Text(settings.lastAutomationError!),
                trailing: settings.lastAutomationAttemptAt == null
                    ? null
                    : Text(
                        DateFormat('HH:mm').format(
                          settings.lastAutomationAttemptAt!,
                        ),
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 15,
                        ),
                      ),
              ),
          ],
        ),
        SettingsInfoFooter(
          text: status.hint,
          barColor: status.color,
        ),
      ],
    );
  }

  DateTime _nextTimeOccurrence(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    var target = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }

    return target;
  }

  String? _timeRemaining(DateTime? closeTime) {
    if (!settings.shiftIsOpened || closeTime == null) return null;

    final remaining = closeTime.difference(DateTime.now());
    if (remaining.isNegative) return 'пора закрыть';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    if (hours == 0) return '$minutes мин';
    return '$hours ч $minutes мин';
  }

  bool _isCloseSoon(DateTime? closeTime) {
    if (closeTime == null) return false;
    return closeTime.difference(DateTime.now()).inMinutes < 30;
  }

}

class _ShiftStatusViewModel {
  final String title;
  final String hint;
  final IconData icon;
  final Color color;

  const _ShiftStatusViewModel({
    required this.title,
    required this.hint,
    required this.icon,
    required this.color,
  });

  factory _ShiftStatusViewModel.fromSettings(ShiftSettings settings) {
    final shiftData = settings.shiftData;

    if (shiftData?.isExpired == true) {
      return const _ShiftStatusViewModel(
        title: 'Истекла',
        hint:
            'Смена работает больше 24 часов. Закройте её вручную или дождитесь автозакрытия.',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        color: CupertinoColors.systemRed,
      );
    }

    if (shiftData?.isOpen == true || settings.shiftIsOpened) {
      return const _ShiftStatusViewModel(
        title: 'Открыта',
        hint: 'Продажи можно проводить. Закрытие зависит от настроек ниже.',
        icon: CupertinoIcons.checkmark_circle_fill,
        color: CupertinoColors.activeGreen,
      );
    }

    return const _ShiftStatusViewModel(
      title: 'Закрыта',
      hint: 'Продажи начнутся после ручного или автоматического открытия.',
      icon: CupertinoIcons.lock_fill,
      color: CupertinoColors.systemGrey,
    );
  }
}
