import 'package:flutter/cupertino.dart';
import '../models/bill_dispenser_status.dart';
import 'info_footer.dart';

class CountSettingsSection extends StatelessWidget {
  final BillDispenserStatus status;
  final int newUpperBoxCount;
  final int newLowerBoxCount;
  final VoidCallback onUpdateCount;
  final Function(int) onUpperCountChanged;
  final Function(int) onLowerCountChanged;

  const CountSettingsSection({
    super.key,
    required this.status,
    required this.newUpperBoxCount,
    required this.newLowerBoxCount,
    required this.onUpdateCount,
    required this.onUpperCountChanged,
    required this.onLowerCountChanged,
  });

  void _showCountPicker({
    required BuildContext context,
    required String title,
    required int currentCount,
    required int newCount,
    required Function(int) onValueChanged,
  }) {
    final maxAdd = (1000 - currentCount).clamp(1, 1000);
    final addValues = List.generate(maxAdd, (index) => index + 1);

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
                    'Добавить купюр',
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
                  initialItem: 0,
                ),
                onSelectedItemChanged: (index) {
                  onValueChanged(currentCount + addValues[index]);
                },
                children: addValues.map((value) {
                  return Center(child: Text('+$value (итого: ${currentCount + value})'));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final hasChanges = newUpperBoxCount > status.upperBoxCount ||
        newLowerBoxCount > status.lowerBoxCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('ДОБАВЛЕНИЕ КУПЮР'),
          children: [
            CupertinoListTile(
              title: const Text('Верхний бокс'),
              subtitle: Text('Текущее: ${status.upperBoxCount} / 1000'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+${newUpperBoxCount - status.upperBoxCount}',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CupertinoListTileChevron(),
                ],
              ),
              onTap: () => _showCountPicker(
                context: context,
                title: 'Верхний бокс',
                currentCount: status.upperBoxCount,
                newCount: newUpperBoxCount,
                onValueChanged: onUpperCountChanged,
              ),
            ),
            CupertinoListTile(
              title: const Text('Нижний бокс'),
              subtitle: Text('Текущее: ${status.lowerBoxCount} / 1000'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+${newLowerBoxCount - status.lowerBoxCount}',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CupertinoListTileChevron(),
                ],
              ),
              onTap: () => _showCountPicker(
                context: context,
                title: 'Нижний бокс',
                currentCount: status.lowerBoxCount,
                newCount: newLowerBoxCount,
                onValueChanged: onLowerCountChanged,
              ),
            ),
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: hasChanges ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: Text(
                'Добавить купюры',
                style: TextStyle(
                  color: hasChanges ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                  fontSize: 17,
                ),
              ),
              trailing: hasChanges
                  ? const CupertinoListTileChevron()
                  : _buildStatusTag(
                'Нет изменений',
                CupertinoColors.systemGrey5,
                CupertinoColors.systemGrey,
              ),
              onTap: hasChanges ? onUpdateCount : null,
            ),
          ],
        ),
        const InfoFooter(
          text: 'Добавьте купюры в каждый бокс диспенсера. Максимальная вместимость: 1000 купюр.',
          barColor: CupertinoColors.activeBlue,
        ),
      ],
    );
  }
}
