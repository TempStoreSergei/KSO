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
                  child: const Text('Отмена'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                CupertinoButton(
                  child: const Text('Сохранить'),
                  onPressed: onSave,
                ),
              ],
            ),
          ),
          // --- ИСПРАВЛЕННЫЙ БЛОК ВВОДА В СТИЛЕ LIST SECTION ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                CupertinoListSection.insetGrouped(
                  // Убираем фоновый цвет секции, чтобы просвечивал фон модального окна
                  backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
                  // Добавим отступ сверху для визуального отделения от навигационной панели
                  margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0),
                  children: [
                    CupertinoTextField(
                      controller: controller,
                      placeholder: placeholder,
                      // !!! Главное изменение: убираем стандартное оформление TextField,
                      // чтобы он выглядел как элемент списка.
                      decoration: null,
                      // Используем prefix для метки (аналог title в list tile)
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 0.0),
                        child: Text(
                          title,
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontSize: 17.0,
                          ),
                        ),
                      ),
                      // Выравнивание текста ввода по правому краю — нативный паттерн iOS
                      textAlign: TextAlign.right,
                      // Добавляем padding для текста ввода внутри ячейки списка
                      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 0.0),
                      // Опционально: кнопка очистки при редактировании
                      clearButtonMode: OverlayVisibilityMode.editing,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // -----------------------------------------------------------------
        ],
      ),
    );
  }
}