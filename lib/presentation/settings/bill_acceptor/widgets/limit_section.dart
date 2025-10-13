// ============================================
// lib/presentation/settings/bill_acceptor/widgets/limit_section.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/presentation/settings/bill_acceptor/cubit/bill_acceptor_cubit.dart';
import 'package:motel/presentation/settings/bill_acceptor/cubit/bill_acceptor_state.dart';

/// Секция настройки лимита купюр
class LimitSection extends StatelessWidget {
  final int customMaxCount;

  const LimitSection({
    super.key,
    required this.customMaxCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('НАСТРОЙКА ЛИМИТА'),
          children: [
            CupertinoListTile(
              title: const Text('Максимум купюр'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$customMaxCount',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CupertinoListTileChevron(),
                ],
              ),
              onTap: () => _showMaxCountPicker(context),
            ),
          ],
        ),
        _buildInfoFooter(
          context,
          'Установите максимальное количество купюр, которое может принять купюроприемник.',
          CupertinoColors.activeBlue,
        ),
      ],
    );
  }

  void _showMaxCountPicker(BuildContext context) {
    const maxLimit = 1500;
    final cubit = context.read<BillAcceptorCubit>();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: const Border(
                  bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Отмена'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Лимит купюр',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    child: const Text('Готово'),
                    onPressed: () {
                      final state = cubit.state;
                      if (state is BillAcceptorLoaded) {
                        cubit.updateMaxCount(state.customMaxCount);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: customMaxCount > 0 ? customMaxCount - 1 : 0,
                ),
                onSelectedItemChanged: (index) {
                  cubit.updateCustomMaxCount(index + 1);
                },
                children: List.generate(maxLimit, (index) {
                  return Center(child: Text('${index + 1}'));
                }),
              ),
            ),
          ],
        ),
      ),
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
