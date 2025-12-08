// ============================================
// lib/presentation/booking/widgets/booking_sidebar.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/domain/models/booking_models.dart';

class BookingSidebar extends StatelessWidget {
  final List<BookingStep> steps;
  final int currentStepIndex;

  const BookingSidebar({
    super.key,
    required this.steps,
    required this.currentStepIndex,
  });

  String _getStepTitle(BookingStep step) {
    switch (step) {
      case BookingStep.buildingSelection:
        return 'Выбор корпуса';
      case BookingStep.roomTypeSelection:
        return 'Тип комнаты';
      case BookingStep.roomSelection:
        return 'Выбор комнаты';
      case BookingStep.guestInfo:
        return 'Данные гостя';
      case BookingStep.categorySelection:
        return 'Категория';
      case BookingStep.period:
        return 'Период проживания';
      case BookingStep.itemSelection:
        return 'Выбор услуг';
      case BookingStep.payment:
        return 'Способ оплаты';
      case BookingStep.confirmation:
        return 'Подтверждение';
      case BookingStep.paymentExecution:
        return 'Оплата';
      case BookingStep.paymentError:
        return 'Ошибка оплаты';
      case BookingStep.success:
        return 'Завершено';
    }
  }

  IconData _getStepIcon(BookingStep step) {
    switch (step) {
      case BookingStep.buildingSelection:
        return CupertinoIcons.building_2_fill;
      case BookingStep.roomTypeSelection:
        return CupertinoIcons.tag_fill;
      case BookingStep.roomSelection:
        return CupertinoIcons.bed_double_fill;
      case BookingStep.guestInfo:
        return CupertinoIcons.person_fill;
      case BookingStep.categorySelection:
        return CupertinoIcons.square_grid_2x2_fill;
      case BookingStep.period:
        return CupertinoIcons.calendar;
      case BookingStep.itemSelection:
        return CupertinoIcons.checkmark_square_fill;
      case BookingStep.payment:
        return CupertinoIcons.creditcard_fill;
      case BookingStep.confirmation:
        return CupertinoIcons.checkmark_circle_fill;
      case BookingStep.paymentExecution:
        return CupertinoIcons.money_dollar_circle_fill;
      case BookingStep.paymentError:
        return CupertinoIcons.exclamationmark_circle_fill;
      case BookingStep.success:
        return CupertinoIcons.checkmark_seal_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displaySteps = steps.where((s) => s != BookingStep.success && s != BookingStep.paymentExecution && s != BookingStep.paymentError).toList();

    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Этапы бронирования',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(displaySteps.length, (index) {
            final step = displaySteps[index];
            final isActive = index == currentStepIndex;
            final isCompleted = index < currentStepIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive
                          ? CupertinoColors.activeOrange
                          : isCompleted
                          ? CupertinoColors.activeGreen
                          : const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCompleted ? CupertinoIcons.checkmark : _getStepIcon(step),
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getStepTitle(step),
                      style: TextStyle(
                        color: isActive
                            ? CupertinoColors.white
                            : CupertinoColors.systemGrey,
                        fontSize: 15,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
