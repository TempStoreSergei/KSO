// ============================================
// lib/presentation/settings/screensaver/widgets/time_picker_dialog.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/settings/screensaver/models/screensaver_models.dart';

/// Показывает диалог выбора времени показа для конкретного файла
void showTimePickerForFile(
  BuildContext context,
  ScreensaverFileModel file,
  Function(int timeShowImage) onTimeSelected,
) {
  final times = [5, 10, 15, 20, 30, 60, 120, 180, 200];
  final initialIndex = times.contains(file.timeShowImage)
      ? times.indexOf(file.timeShowImage)
      : times.indexOf(200);

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
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
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
                  'Время показа',
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
                onTimeSelected(times[index]);
              },
              children: times.map((time) {
                return Center(child: Text('$time сек'));
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Показывает диалог выбора времени до активации заставки (idle time)
void showIdleTimePicker(
  BuildContext context,
  ScreensaverSettingsModel settings,
  Function(int idleTime) onIdleTimeSelected,
) {
  final times = [30, 60, 120, 180, 300, 600];
  final initialIndex = times.contains(settings.idleTime)
      ? times.indexOf(settings.idleTime)
      : 1;

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
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
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
                  'Время до активации',
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
                onIdleTimeSelected(times[index]);
              },
              children: times.map((time) {
                return Center(child: Text('$time сек'));
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );
}
