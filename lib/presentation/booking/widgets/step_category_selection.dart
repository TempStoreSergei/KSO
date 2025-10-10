// ============================================
// lib/presentation/booking/widgets/step_category_selection.dart
// ============================================

import 'package:flutter/cupertino.dart';
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
    final categories = [
      BookingCategory.accommodation,
      BookingCategory.services,
      BookingCategory.ruleViolationPenalty,
      BookingCategory.propertyDamagePenalty,
    ];

    return StepContainer(
      title: 'Выберите категорию',
      child: SizedBox(
        height: 360,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedCategory == category;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => onCategorySelected(category),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CupertinoColors.white.withOpacity(0.2)
                              : const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          size: 24,
                          color: isSelected
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
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
                                color: isSelected
                                    ? CupertinoColors.white
                                    : CupertinoColors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getCategoryDescription(category),
                              style: TextStyle(
                                color: isSelected
                                    ? CupertinoColors.white.withOpacity(0.8)
                                    : CupertinoColors.systemGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: CupertinoColors.white,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
