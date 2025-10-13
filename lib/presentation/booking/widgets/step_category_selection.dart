// ============================================
// lib/presentation/booking/widgets/step_category_selection.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepCategorySelection extends StatelessWidget {
  final BookingCategory selectedCategory;
  final Function(BookingCategory) onCategorySelected;

  const StepCategorySelection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  String _getCategoryName(BookingCategory category) {
    switch (category) {
      case BookingCategory.accommodation:
        return 'Проживание';
      case BookingCategory.services:
        return 'Услуги';
      case BookingCategory.ruleViolationPenalty:
        return 'Штраф за нарушение правил';
      case BookingCategory.propertyDamagePenalty:
        return 'Штраф за порчу имущества';
      case BookingCategory.unknown:
        return '';
    }
  }

  IconData _getCategoryIcon(BookingCategory category) {
    switch (category) {
      case BookingCategory.accommodation:
        return CupertinoIcons.bed_double_fill;
      case BookingCategory.services:
        return CupertinoIcons.cube_box_fill;
      case BookingCategory.ruleViolationPenalty:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case BookingCategory.propertyDamagePenalty:
        return CupertinoIcons.hammer_fill;
      case BookingCategory.unknown:
        return CupertinoIcons.question;
    }
  }

  String _getCategoryDescription(BookingCategory category) {
    switch (category) {
      case BookingCategory.accommodation:
        return 'Бронирование комнаты с проживанием';
      case BookingCategory.services:
        return 'Дополнительные услуги отеля';
      case BookingCategory.ruleViolationPenalty:
        return 'Штрафы за несоблюдение правил отеля';
      case BookingCategory.propertyDamagePenalty:
        return 'Штрафы за повреждение имущества';
      case BookingCategory.unknown:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      title: 'Выберите категорию',
      subtitle: 'Выберите тип бронирования',
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Первая категория - Проживание
            _buildCategoryRow(
              category: BookingCategory.accommodation,
              isSelected: selectedCategory == BookingCategory.accommodation,
              onTap: () => onCategorySelected(BookingCategory.accommodation),
            ),

            // Разделитель
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Divider(height: 1, color: Color(0xFF2C2C2E)),
            ),

            // Вторая категория - Услуги
            _buildCategoryRow(
              category: BookingCategory.services,
              isSelected: selectedCategory == BookingCategory.services,
              onTap: () => onCategorySelected(BookingCategory.services),
            ),

            // Разделитель
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Divider(height: 1, color: Color(0xFF2C2C2E)),
            ),

            // Третья категория - Штраф за нарушение правил
            _buildCategoryRow(
              category: BookingCategory.ruleViolationPenalty,
              isSelected: selectedCategory == BookingCategory.ruleViolationPenalty,
              onTap: () => onCategorySelected(BookingCategory.ruleViolationPenalty),
            ),

            // Разделитель
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Divider(height: 1, color: Color(0xFF2C2C2E)),
            ),

            // Четвертая категория - Штраф за порчу имущества
            _buildCategoryRow(
              category: BookingCategory.propertyDamagePenalty,
              isSelected: selectedCategory == BookingCategory.propertyDamagePenalty,
              onTap: () => onCategorySelected(BookingCategory.propertyDamagePenalty),
            ),
          ],
        ),
      ),
    );
  }

  // Вспомогательный виджет для отрисовки одной строки категории
  Widget _buildCategoryRow({
    required BookingCategory category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? CupertinoColors.activeBlue.withValues(alpha: 0.2) : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCategoryName(category),
                    style: TextStyle(
                      color: isSelected ? CupertinoColors.white : CupertinoColors.systemGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getCategoryDescription(category),
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 24,
              child: isSelected
                  ? const Icon(CupertinoIcons.checkmark_circle_fill, color: CupertinoColors.activeBlue, size: 24)
                  : const Icon(CupertinoIcons.circle, color: CupertinoColors.systemGrey3, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
