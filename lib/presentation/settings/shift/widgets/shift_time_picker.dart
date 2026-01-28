// lib/presentation/settings/shift/widgets/shift_time_picker.dart

import 'package:flutter/cupertino.dart';

class ShiftTimePicker {
  static void show({
    required BuildContext context,
    required String title,
    required String currentTime,
    required Function(String) onTimeSelected,
  }) {
    final timeParts = currentTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    String tempTime = currentTime;

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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text('Готово'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onTimeSelected(tempTime);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(2024, 1, 1, hour, minute),
                use24hFormat: true,
                onDateTimeChanged: (DateTime dateTime) {
                  tempTime =
                      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
