// lib/presentation/settings/shift/widgets/shift_times_section.dart

import 'package:flutter/cupertino.dart';

class ShiftTimesSection extends StatelessWidget {
  final String openTime;
  final String closeTime;
  final VoidCallback onOpenTimePressed;
  final VoidCallback onCloseTimePressed;
  final VoidCallback onSavePressed;

  const ShiftTimesSection({
    super.key,
    required this.openTime,
    required this.closeTime,
    required this.onOpenTimePressed,
    required this.onCloseTimePressed,
    required this.onSavePressed,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: const Text('ВРЕМЯ СМЕН'),
      footer: const Text(
        'Время закрытия должно быть позже времени открытия. Минимальная продолжительность смены — 1 час.',
      ),
      children: [
        _buildTimeSettingTile(
          label: 'Время открытия',
          time: openTime,
          onTap: onOpenTimePressed,
        ),
        _buildTimeSettingTile(
          label: 'Время закрытия',
          time: closeTime,
          onTap: onCloseTimePressed,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(12),
              onPressed: onSavePressed,
              child: const Text(
                'Сохранить время',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSettingTile({
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return CupertinoListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
          const SizedBox(width: 8),
          const CupertinoListTileChevron(),
        ],
      ),
      onTap: onTap,
    );
  }
}
