import 'package:flutter/cupertino.dart';
import '../models/bill_dispenser_status.dart';
import '../models/test_status.dart';
import 'info_footer.dart';

class TestSection extends StatelessWidget {
  final BillDispenserStatus status;
  final TestStatus testStatus;
  final VoidCallback onTestDispenser;

  const TestSection({
    super.key,
    required this.status,
    required this.testStatus,
    required this.onTestDispenser,
  });

  String _getTestStatusText() {
    switch (testStatus) {
      case TestStatus.inactive:
        final canTest = status.upperBoxCount >= 1 && status.lowerBoxCount >= 1;
        return canTest ? '' : 'Недостаточно купюр';
      case TestStatus.upperBox:
        return 'Верхний бокс';
      case TestStatus.lowerBox:
        return 'Нижний бокс';
      case TestStatus.complete:
        return 'Готово';
    }
  }

  Color _getTestStatusColor() {
    switch (testStatus) {
      case TestStatus.inactive:
        return CupertinoColors.systemGrey;
      case TestStatus.upperBox:
      case TestStatus.lowerBox:
        return CupertinoColors.systemOrange;
      case TestStatus.complete:
        return CupertinoColors.systemGreen;
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

  Widget? _getTestStatusWidget() {
    if (testStatus != TestStatus.inactive) {
      return _buildStatusTag(
        _getTestStatusText(),
        _getTestStatusColor().withValues(alpha: 0.15),
        _getTestStatusColor(),
      );
    }

    final canTest = status.upperBoxCount >= 1 && status.lowerBoxCount >= 1;
    if (!canTest) {
      return _buildStatusTag(
        'Недостаточно купюр',
        CupertinoColors.systemGrey5,
        CupertinoColors.systemGrey,
      );
    }

    return const CupertinoListTileChevron();
  }

  @override
  Widget build(BuildContext context) {
    final canTest = status.upperBoxCount >= 1 &&
        status.lowerBoxCount >= 1 &&
        testStatus == TestStatus.inactive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('ТЕСТИРОВАНИЕ'),
          children: [
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: canTest ? CupertinoColors.activeGreen : CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: testStatus != TestStatus.inactive
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white, radius: 10)
                    : const Icon(
                  CupertinoIcons.play_fill,
                  color: CupertinoColors.white,
                  size: 18,
                ),
              ),
              title: Text(
                'Тест выдачи',
                style: TextStyle(
                  color: canTest ? CupertinoColors.activeGreen : CupertinoColors.systemGrey,
                  fontSize: 17,
                ),
              ),
              trailing: _getTestStatusWidget(),
              onTap: canTest ? onTestDispenser : null,
            ),
          ],
        ),
        const InfoFooter(
          text: 'Запустите тест выдачи: будет выдана 1 купюра из верхнего бокса и 1 из нижнего.',
          barColor: CupertinoColors.activeGreen,
        ),
      ],
    );
  }
}
