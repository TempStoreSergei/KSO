import 'package:flutter/cupertino.dart';

class TelegramInputModal extends StatelessWidget {
  final String title;
  final String placeholder;
  final TextEditingController controller;
  final VoidCallback onSave;

  const TelegramInputModal({
    super.key,
    required this.title,
    required this.placeholder,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    // Получаем цвет фона для корректного отображения
    final backgroundColor = CupertinoColors.systemBackground.resolveFrom(context);

    return Container(
      // Устанавливаем высоту, но лучше использовать FractionallySizedBox для модальных окон
      // или просто позволить содержимому определить высоту, если это не BottomSheet.
      // Для данного примера оставляем 300.
      height: 300,
      color: backgroundColor,
      child: Column(
        children: [
          // Навигационная панель (Заголовок, Отмена, Сохранить)
          Container(
            padding: const EdgeInsets.only(top: 10.0), // Отступ сверху для mimic-панели
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                CupertinoButton(
                  onPressed: onSave,
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ),
          // --- БЛОК ВВОДА В СТИЛЕ telegram_settings_screen ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                CupertinoListSection.insetGrouped(
                  backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
                  margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0),
                  children: [
                    CupertinoListTile(
                      title: Text(title),
                      additionalInfo: Expanded(
                        child: CupertinoTextField(
                          controller: controller,
                          textAlign: TextAlign.end,
                          style: const TextStyle(color: CupertinoColors.systemGrey),
                          decoration: null,
                          placeholder: placeholder,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}