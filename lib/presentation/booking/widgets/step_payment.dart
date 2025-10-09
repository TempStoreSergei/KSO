// ============================================
// lib/presentation/booking/widgets/step_payment.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepPayment extends StatelessWidget {
  final String? selectedMethod;
  final Function(String) onMethodSelected;
  final int totalPrice;

  const StepPayment({super.key, this.selectedMethod, required this.onMethodSelected, required this.totalPrice});

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      icon: CupertinoIcons.creditcard_fill,
      title: 'Способ оплаты',
      subtitle: 'Выберите удобный способ оплаты',
      // === ИЗМЕНЕНИЕ: Полностью переделан дочерний виджет в единый список ===
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // 1. Блок с итоговой стоимостью
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Итоговая стоимость',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$totalPrice ₽',
                    style: const TextStyle(
                      color: CupertinoColors.activeBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Разделитель
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
            ),

            // 3. Первый способ оплаты
            _buildMethodRow(
              title: 'Банковская карта',
              icon: CupertinoIcons.creditcard_fill,
              isSelected: selectedMethod == 'Банковская карта',
              onTap: () => onMethodSelected('Банковская карта'),
            ),

            // 4. Разделитель
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
            ),

            // 5. Второй способ оплаты
            _buildMethodRow(
              title: 'Оплата при заселении',
              icon: CupertinoIcons.money_dollar_circle_fill,
              isSelected: selectedMethod == 'Оплата при заселении',
              onTap: () => onMethodSelected('Оплата при заселении'),
            ),
          ],
        ),
      ),
    );
  }

  // Вспомогательный виджет для отрисовки одной строки выбора
  Widget _buildMethodRow({required String title, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, color: CupertinoColors.systemGrey, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: CupertinoColors.white, fontSize: 16),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 22,
              child: isSelected
                  ? const Icon(CupertinoIcons.checkmark_circle_fill, color: CupertinoColors.activeBlue, size: 22)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}