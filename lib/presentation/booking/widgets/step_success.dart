// lib/presentation/booking/widgets/step_success.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StepSuccess extends StatelessWidget {
  final int totalPrice;
  final DateTime paymentDateTime;

  const StepSuccess({
    super.key,
    required this.totalPrice,
    required this.paymentDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru_RU');
    final formattedDate = dateFormat.format(paymentDateTime);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Большая иконка галочки
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                size: 100,
                color: CupertinoColors.systemGreen,
              ),
            ),

            const SizedBox(height: 32),

            // Заголовок
            const Text(
              'Оплата успешна',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 32),

            // Информация о платеже
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Сумма',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$totalPrice ₽',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFF2C2C2E)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Дата и время',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Кнопка возврата на главный экран
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(vertical: 18),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'На главный экран',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}