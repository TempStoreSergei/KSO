import 'package:flutter/cupertino.dart';
import 'package:motel/domain/models/shift_automation_settings.dart';
import 'package:motel/presentation/settings/widgets/settings_info_footer.dart';

class AutoShiftsSection extends StatelessWidget {
  final ShiftOpenMode openMode;
  final String? openTime;
  final String? closeTime;
  final bool acquiringReceiptReportOnClose;
  final ValueChanged<ShiftOpenMode> onOpenModeChanged;
  final VoidCallback onOpenTimePressed;
  final VoidCallback onCloseTimePressed;
  final VoidCallback onDisableAutoClose;
  final ValueChanged<bool> onAcquiringReceiptReportChanged;

  const AutoShiftsSection({
    super.key,
    required this.openMode,
    required this.openTime,
    required this.closeTime,
    required this.acquiringReceiptReportOnClose,
    required this.onOpenModeChanged,
    required this.onOpenTimePressed,
    required this.onCloseTimePressed,
    required this.onDisableAutoClose,
    required this.onAcquiringReceiptReportChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('ОТКРЫТИЕ СМЕНЫ'),
          children: [
            CupertinoListTile(
              leading: const _IconBox(
                icon: CupertinoIcons.doc_text_fill,
                color: CupertinoColors.activeGreen,
              ),
              title: const Text('Стандартно'),
              subtitle: const Text(
                'Если смена закрыта, она откроется перед печатью чека.',
              ),
              trailing: _SelectionTrailing(
                selected: openMode == ShiftOpenMode.firstReceipt,
              ),
              onTap: () => onOpenModeChanged(ShiftOpenMode.firstReceipt),
            ),
            CupertinoListTile(
              leading: const _IconBox(
                icon: CupertinoIcons.clock_fill,
                color: CupertinoColors.activeBlue,
              ),
              title: const Text('По времени'),
              subtitle: Text(
                openTime == null
                    ? 'Открывать каждый день в выбранное время.'
                    : 'Открывать каждый день в $openTime.',
              ),
              additionalInfo: Text(
                openTime ?? 'Выбрать',
                style: TextStyle(
                  color: openMode == ShiftOpenMode.byTime
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey,
                  fontSize: 16,
                  fontWeight: openMode == ShiftOpenMode.byTime
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: onOpenTimePressed,
            ),
          ],
        ),
        const SettingsInfoFooter(
          text:
              'Открытие по времени и открытие по первому чеку взаимоисключающие. Расписание хранится и выполняется на сервере.',
          barColor: CupertinoColors.activeBlue,
        ),
        CupertinoListSection.insetGrouped(
          header: const Text('ЗАКРЫТИЕ СМЕНЫ'),
          children: [
            CupertinoListTile(
              leading: const _IconBox(
                icon: CupertinoIcons.hand_raised_fill,
                color: CupertinoColors.systemGrey,
              ),
              title: const Text('Вручную'),
              subtitle: const Text('Сотрудник нажимает кнопку закрытия.'),
              trailing: _SelectionTrailing(selected: closeTime == null),
              onTap: onDisableAutoClose,
            ),
            CupertinoListTile(
              leading: const _IconBox(
                icon: CupertinoIcons.moon_zzz_fill,
                color: CupertinoColors.systemOrange,
              ),
              title: const Text('По времени'),
              subtitle: Text(
                closeTime == null
                    ? 'Закрывать каждый день в выбранное время.'
                    : 'Закрывать каждый день в $closeTime.',
              ),
              additionalInfo: Text(
                closeTime ?? 'Выбрать',
                style: TextStyle(
                  color: closeTime != null
                      ? CupertinoColors.systemOrange
                      : CupertinoColors.systemGrey,
                  fontSize: 16,
                  fontWeight:
                      closeTime != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: onCloseTimePressed,
            ),
          ],
        ),
        const SettingsInfoFooter(
          text:
              'Если время закрытия не задано, смена закрывается только вручную. При ошибке устройства автоматическое действие будет повторено позже.',
          barColor: CupertinoColors.systemOrange,
        ),
        CupertinoListSection.insetGrouped(
          header: const Text('ДОПОЛНИТЕЛЬНО'),
          children: [
            CupertinoListTile(
              leading: const _IconBox(
                icon: CupertinoIcons.creditcard_fill,
                color: CupertinoColors.systemIndigo,
              ),
              title: const Text('Итог по чекам в эквайринге'),
              subtitle: const Text('Формировать итог перед закрытием смены.'),
              trailing: CupertinoSwitch(
                value: acquiringReceiptReportOnClose,
                onChanged: onAcquiringReceiptReportChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = CupertinoDynamicColor.resolve(color, context);

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: CupertinoColors.white,
        size: 20,
      ),
    );
  }
}

class _SelectionTrailing extends StatelessWidget {
  final bool selected;

  const _SelectionTrailing({
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    if (!selected) return const SizedBox.shrink();

    return const Icon(
      CupertinoIcons.checkmark_circle_fill,
      color: CupertinoColors.activeBlue,
      size: 22,
    );
  }
}
