// ============================================
// lib/presentation/booking/widgets/step_payment.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

            // Первый способ оплаты - СБП
            _buildMethodRow(
              title: 'СБП (Система быстрых платежей)',
              subtitle: 'Оплата по QR-коду через банковское приложение',
              icon: CupertinoIcons.qrcode,
              isSelected: selectedMethod == 'СБП',
              onTap: () => onMethodSelected('СБП'),
            ),

            // Разделитель
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Divider(height: 1, color: Color(0xFF2C2C2E)),
            ),

            // Второй способ оплаты - Карта
            _buildMethodRow(
              title: 'Банковская карта (Эквайринг)',
              subtitle: 'Оплата через терминал Visa, MasterCard, Мир',
              icon: CupertinoIcons.creditcard_fill,
              isSelected: selectedMethod == 'Карта',
              onTap: () => onMethodSelected('Карта'),
            ),

            // Разделитель
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Divider(height: 1, color: Color(0xFF2C2C2E)),
            ),

            // Третий способ оплаты - Наличные
            _buildMethodRow(
              title: 'Наличные',
              subtitle: 'Оплата наличными через купюроприемник',
              icon: CupertinoIcons.money_dollar_circle_fill,
              isSelected: selectedMethod == 'Наличные',
              onTap: () => onMethodSelected('Наличные'),
            ),
          ],
        ),
      ),
    );
  }

  // Вспомогательный виджет для отрисовки одной строки выбора
  Widget _buildMethodRow({
    required String title,
    required String subtitle,
    required IconData icon,
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
                icon,
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
                    title,
                    style: TextStyle(
                      color: isSelected ? CupertinoColors.white : CupertinoColors.systemGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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