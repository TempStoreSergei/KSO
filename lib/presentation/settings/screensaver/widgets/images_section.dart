// ============================================
// lib/presentation/settings/screensaver/widgets/images_section.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/presentation/settings/screensaver/models/screensaver_models.dart';

/// Виджет секции изображений с возможностью переупорядочивания
class ImagesSection extends StatelessWidget {
  final List<ScreensaverFileModel> files;
  final bool isEditing;
  final Function(int fileId) onDelete;
  final Function(ScreensaverFileModel file) onShowTimePicker;
  final Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onToggleEdit;
  final VoidCallback onSaveOrder;

  const ImagesSection({
    super.key,
    required this.files,
    required this.isEditing,
    required this.onDelete,
    required this.onShowTimePicker,
    required this.onReorder,
    required this.onToggleEdit,
    required this.onSaveOrder,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ИЗОБРАЖЕНИЯ'),
              if (files.isNotEmpty)
                GestureDetector(
                  onTap: isEditing ? onSaveOrder : onToggleEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isEditing ? CupertinoColors.systemGreen : CupertinoColors.activeBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isEditing ? 'Готово' : 'Изменить',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          children: [
            if (isEditing)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: files.length,
                onReorder: onReorder,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return _buildFileItem(
                    context,
                    file,
                    index,
                    key: ValueKey(file.id),
                  );
                },
              )
            else
              ...List.generate(files.length, (index) {
                final file = files[index];
                return _buildFileItem(context, file, index);
              }),
          ],
        ),
        _buildInfoFooter(
          context,
          isEditing
              ? 'Удерживайте и перетаскивайте для изменения порядка показа изображений.'
              : 'Настройте время показа для каждого изображения.',
          CupertinoColors.activeBlue,
        ),
      ],
    );
  }

  /// Создает элемент списка для отдельного файла
  Widget _buildFileItem(
    BuildContext context,
    ScreensaverFileModel file,
    int index, {
    Key? key,
  }) {
    return Container(
      key: key ?? ValueKey('file_${file.id}'),
      decoration: BoxDecoration(
        border: Border(
          bottom: index < files.length - 1
              ? const BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                )
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                file.fileUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: CupertinoColors.systemGrey5,
                  child: const Icon(CupertinoIcons.photo),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Изображение ${index + 1}',
                    style: const TextStyle(fontSize: 17),
                  ),
                  if (!isEditing) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => onShowTimePicker(file),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.timer,
                                  size: 14,
                                  color: CupertinoColors.systemGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${file.timeShowImage} сек',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isEditing)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    onPressed: () => onDelete(file.id),
                    child: const Icon(
                      CupertinoIcons.delete,
                      color: CupertinoColors.systemRed,
                      size: 22,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Создает информационный футер с цветной полоской
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
                  fontSize: 14,
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
