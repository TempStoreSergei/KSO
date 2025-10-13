// lib/presentation/settings/shift/widgets/shift_status_section.dart

import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/settings/shift/models/shift_settings.dart';

class ShiftStatusSection extends StatelessWidget {
  final ShiftSettings settings;

  const ShiftStatusSection({
    super.key,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: const Text('ТЕКУЩЕЕ СОСТОЯНИЕ'),
      children: [
        CupertinoListTile(
          title: const Text('Статус смены'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: settings.shiftIsOpened
                  ? CupertinoColors.activeGreen
                  : CupertinoColors.systemGrey4,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              settings.shiftIsOpened ? 'Открыта' : 'Закрыта',
              style: TextStyle(
                color: settings.shiftIsOpened
                    ? CupertinoColors.white
                    : CupertinoColors.systemGrey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (settings.shiftIsOpened && settings.shiftOpenedAt != null)
          CupertinoListTile(
            title: const Text('Время открытия'),
            trailing: Text(
              settings.shiftOpenedAt!,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 17,
              ),
            ),
          ),
        if (settings.shiftIsOpened && settings.shiftDuration != null)
          CupertinoListTile(
            title: const Text('Продолжительность'),
            trailing: Text(
              settings.shiftDuration!,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 17,
              ),
            ),
          ),
      ],
    );
  }
}
