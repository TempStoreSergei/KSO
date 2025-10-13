// lib/presentation/settings/shift/widgets/manual_control_section.dart

import 'package:flutter/cupertino.dart';

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
    return CupertinoListSection.insetGrouped(
      header: const Text('РУЧНОЕ УПРАВЛЕНИЕ'),
      footer: const Text(
        'Используйте эти опции для немедленного открытия или закрытия смены.',
      ),
      children: [
        CupertinoListTile(
          title: Text(
            isShiftOpen ? 'Закрыть смену' : 'Открыть смену',
            style: TextStyle(
              color: isShiftOpen
                  ? CupertinoColors.systemRed
                  : CupertinoColors.activeGreen,
            ),
          ),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isShiftOpen
                  ? CupertinoColors.systemRed
                  : CupertinoColors.activeGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isShiftOpen
                  ? CupertinoIcons.stop_fill
                  : CupertinoIcons.play_fill,
              color: CupertinoColors.white,
              size: 20,
            ),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: () {
            if (isShiftOpen) {
              _showCloseShiftConfirmation(context, onCloseShift);
            } else {
              onOpenShift();
            }
          },
        ),
      ],
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
