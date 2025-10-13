// lib/presentation/settings/shift/widgets/auto_shifts_section.dart

import 'package:flutter/cupertino.dart';

class AutoShiftsSection extends StatelessWidget {
  final bool autoShiftsEnabled;
  final ValueChanged<bool> onToggle;

  const AutoShiftsSection({
    super.key,
    required this.autoShiftsEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: const Text('АВТОМАТИЧЕСКОЕ УПРАВЛЕНИЕ'),
      footer: const Text(
        'При включении автоматического управления смены будут открываться и закрываться в указанное время.',
      ),
      children: [
        CupertinoListTile(
          title: const Text('Автоматические смены'),
          trailing: CupertinoSwitch(
            value: autoShiftsEnabled,
            onChanged: onToggle,
          ),
        ),
      ],
    );
  }
}
