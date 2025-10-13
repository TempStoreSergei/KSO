// ============================================
// lib/presentation/settings/bill_acceptor/widgets/status_section.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/settings/bill_acceptor/models/bill_acceptor_models.dart';

/// Секция отображения текущего состояния купюроприемника
class StatusSection extends StatelessWidget {
  final CashSystemStatus status;

  const StatusSection({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final fillPercentage = status.fillPercentage;
    final currentCount = status.currentBillCount;
    final remainingSpace = status.remainingSpace;

    return CupertinoListSection.insetGrouped(
      header: const Text('ТЕКУЩЕЕ СОСТОЯНИЕ'),
      children: [
        CupertinoListTile(
          title: const Text('Заполнено'),
          trailing: Text(
            '$currentCount купюр',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Осталось места'),
          trailing: Text(
            '$remainingSpace купюр',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Процент заполнения'),
          trailing: Text(
            '${fillPercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: _getFillColor(fillPercentage),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Color _getFillColor(double percentage) {
    if (percentage < 50) return CupertinoColors.activeGreen;
    if (percentage < 80) return CupertinoColors.systemOrange;
    return CupertinoColors.systemRed;
  }
}
