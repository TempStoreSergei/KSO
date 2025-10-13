import 'package:flutter/cupertino.dart';
import 'info_footer.dart';

class LevelSettingsSection extends StatelessWidget {
  final int newUpperBoxValue;
  final int newLowerBoxValue;
  final VoidCallback onUpdateLevels;
  final Function(int) onUpperValueChanged;
  final Function(int) onLowerValueChanged;

  const LevelSettingsSection({
    super.key,
    required this.newUpperBoxValue,
    required this.newLowerBoxValue,
    required this.onUpdateLevels,
    required this.onUpperValueChanged,
    required this.onLowerValueChanged,
  });

  void _showNominalPicker({
    required BuildContext context,
    required String title,
    required int currentValue,
    required Function(int) onValueChanged,
  }) {
    final values = [10, 50, 100, 200, 500, 1000, 2000, 5000];
    final initialIndex = values.contains(currentValue) ? values.indexOf(currentValue) : 0;

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
                  Text(
                    title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
                  onValueChanged(values[index]);
                },
                children: values.map((value) {
                  return Center(child: Text('$value руб.'));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('НАСТРОЙКА НОМИНАЛОВ'),
          children: [
            CupertinoListTile(
              title: const Text('Верхний бокс'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$newUpperBoxValue',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CupertinoListTileChevron(),
                ],
              ),
              onTap: () => _showNominalPicker(
                context: context,
                title: 'Номинал верхнего бокса',
                currentValue: newUpperBoxValue,
                onValueChanged: onUpperValueChanged,
              ),
            ),
            CupertinoListTile(
              title: const Text('Нижний бокс'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$newLowerBoxValue',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CupertinoListTileChevron(),
                ],
              ),
              onTap: () => _showNominalPicker(
                context: context,
                title: 'Номинал нижнего бокса',
                currentValue: newLowerBoxValue,
                onValueChanged: onLowerValueChanged,
              ),
            ),
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.pencil,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Обновить номиналы',
                style: TextStyle(
                  color: CupertinoColors.activeBlue,
                  fontSize: 17,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: onUpdateLevels,
            ),
          ],
        ),
        const InfoFooter(
          text: 'Установите номиналы купюр для каждого бокса диспенсера.',
          barColor: CupertinoColors.activeBlue,
        ),
      ],
    );
  }
}
