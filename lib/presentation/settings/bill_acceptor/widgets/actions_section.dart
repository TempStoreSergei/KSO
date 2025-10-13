// ============================================
// lib/presentation/settings/bill_acceptor/widgets/actions_section.dart
// ============================================

import 'package:flutter/cupertino.dart';

/// Секция действий (инкассация)
class ActionsSection extends StatelessWidget {
  final VoidCallback onResetCount;

  const ActionsSection({
    super.key,
    required this.onResetCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('ДЕЙСТВИЯ'),
          children: [
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.money_dollar_circle,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Инкассация',
                style: TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 17,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: onResetCount,
            ),
          ],
        ),
        _buildInfoFooter(
          context,
          'Выполните инкассацию и сбросьте счетчик купюр после изъятия денег из купюроприемника.',
          CupertinoColors.systemRed,
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
}
