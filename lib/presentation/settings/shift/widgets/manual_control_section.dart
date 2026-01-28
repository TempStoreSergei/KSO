// lib/presentation/settings/shift/widgets/manual_control_section.dart

import 'package:flutter/cupertino.dart';

/// Секция ручного управления сменой
class ManualControlSection extends StatelessWidget {
  final bool isShiftOpen;
  final VoidCallback onOpenShift;
  final VoidCallback onCloseShift;

  const ManualControlSection({
    super.key,
    required this.isShiftOpen,
    required this.onOpenShift,
    required this.onCloseShift,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('УПРАВЛЕНИЕ'),
          children: [
            if (!isShiftOpen)
              CupertinoListTile(
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.play_circle_fill,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Открыть смену',
                  style: TextStyle(
                    color: CupertinoColors.activeGreen,
                    fontSize: 17,
                  ),
                ),
                trailing: const CupertinoListTileChevron(),
                onTap: onOpenShift,
              ),
            if (isShiftOpen)
              CupertinoListTile(
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.stop_circle_fill,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Закрыть смену',
                  style: TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 17,
                  ),
                ),
                trailing: const CupertinoListTileChevron(),
                onTap: () => _showCloseShiftConfirmation(context, onCloseShift),
              ),
          ],
        ),
        _buildInfoFooter(
          context,
          isShiftOpen
              ? 'Смена будет автоматически закрыта за 5 минут до конца рабочего дня.'
              : 'Смена откроется автоматически при печати первого чека.',
          isShiftOpen
              ? CupertinoColors.systemRed
              : CupertinoColors.activeGreen,
        ),
      ],
    );
  }

  Widget _buildInfoFooter(BuildContext context, String text, Color barColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            constraints: const BoxConstraints(minHeight: 24),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftConfirmation(BuildContext context, VoidCallback onConfirm) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Закрыть смену?'),
        content: const Text('Вы уверены, что хотите закрыть текущую смену?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Закрыть'),
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
          ),
        ],
      ),
    );
  }
}
