// ============================================
// lib/presentation/settings/bill_acceptor/widgets/test_section.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/presentation/settings/bill_acceptor/cubit/bill_acceptor_cubit.dart';
import 'package:motel/presentation/settings/bill_acceptor/models/bill_acceptor_models.dart';
import 'package:motel/presentation/settings/bill_acceptor/widgets/test_events_screen.dart';

/// Секция тестирования купюроприемника
class TestSection extends StatelessWidget {
  final int testAmount;
  final TestingStatus testingStatus;
  final int collectedAmount;
  final List<TestEvent> events;
  final VoidCallback onStartTest;
  final VoidCallback onStopTest;

  const TestSection({
    super.key,
    required this.testAmount,
    required this.testingStatus,
    required this.collectedAmount,
    required this.events,
    required this.onStartTest,
    required this.onStopTest,
  });

  @override
  Widget build(BuildContext context) {
    final canTest = testingStatus == TestingStatus.inactive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('ТЕСТИРОВАНИЕ'),
          children: [
            if (canTest) ...[
              CupertinoListTile(
                title: const Text('Сумма для теста'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$testAmount руб.',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const CupertinoListTileChevron(),
                  ],
                ),
                onTap: () => _showTestAmountPicker(context),
              ),
            ] else ...[
              CupertinoListTile(
                title: const Text('Собрано'),
                trailing: Text(
                  '$collectedAmount руб.',
                  style: const TextStyle(
                    color: CupertinoColors.activeGreen,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: canTest
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: testingStatus == TestingStatus.active
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                        radius: 10,
                      )
                    : Icon(
                        canTest ? CupertinoIcons.play_fill : CupertinoIcons.stop_fill,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
              ),
              title: Text(
                canTest ? 'Запустить тест' : 'Остановить тест',
                style: TextStyle(
                  color: canTest
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.systemRed,
                  fontSize: 17,
                ),
              ),
              trailing: _getTestStatusWidget(),
              onTap: canTest ? onStartTest : onStopTest,
            ),
            if (testingStatus != TestingStatus.inactive && events.isNotEmpty)
              CupertinoListTile(
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.list_bullet,
                    color: CupertinoColors.systemGrey,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Журнал операций',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 17,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusTag(
                      '${events.length}',
                      CupertinoColors.systemGrey5,
                      CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 8),
                    const CupertinoListTileChevron(),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => TestEventsScreen(events: events),
                    ),
                  );
                },
              ),
          ],
        ),
        _buildInfoFooter(
          context,
          'Запустите тест приема купюр: вносите наличные до достижения заданной суммы.',
          CupertinoColors.activeGreen,
        ),
      ],
    );
  }

  void _showTestAmountPicker(BuildContext context) {
    final amounts = [10, 50, 100, 150, 200, 500, 1000];
    final initialIndex = amounts.contains(testAmount) ? amounts.indexOf(testAmount) : 2;
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
                    'Сумма для теста',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    child: const Text('Готово'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: initialIndex,
                ),
                onSelectedItemChanged: (index) {
                  cubit.updateTestAmount(amounts[index]);
                },
                children: amounts.map((amount) {
                  return Center(child: Text('$amount руб.'));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _getTestStatusWidget() {
    switch (testingStatus) {
      case TestingStatus.inactive:
        return const CupertinoListTileChevron();
      case TestingStatus.active:
        return _buildStatusTag(
          'Активен',
          CupertinoColors.systemOrange.withValues(alpha: 0.15),
          CupertinoColors.systemOrange,
        );
      case TestingStatus.completed:
        return _buildStatusTag(
          'Завершен',
          CupertinoColors.systemGreen.withValues(alpha: 0.15),
          CupertinoColors.systemGreen,
        );
    }
  }

  Widget _buildStatusTag(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
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
