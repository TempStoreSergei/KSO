// ============================================
// lib/presentation/settings/screensaver/widgets/add_button_section.dart
// ============================================

import 'package:flutter/cupertino.dart';

/// Виджет секции кнопки добавления нового изображения
class AddButtonSection extends StatelessWidget {
  final VoidCallback onTap;
  final bool isBusy;

  const AddButtonSection({
    super.key,
    required this.onTap,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          children: [
            CupertinoListTile(
              title: const Text(
                'Добавить изображение',
                style: TextStyle(color: CupertinoColors.activeBlue),
              ),
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: isBusy ? null : onTap,
            ),
          ],
        ),
        _buildInfoFooter(
          context,
          'Добавьте изображения или видео для отображения в заставке.',
          CupertinoColors.activeBlue,
        ),
      ],
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
