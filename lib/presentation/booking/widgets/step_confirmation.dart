// ============================================
// lib/presentation/booking/widgets/step_confirmation.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/domain/usecases/save_transaction_usecase.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';
import 'package:intl/intl.dart';

class StepConfirmation extends StatefulWidget {
  final BookingData data;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const StepConfirmation({
    super.key,
    required this.data,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<StepConfirmation> createState() => _StepConfirmationState();
}

class _StepConfirmationState extends State<StepConfirmation> {
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final useCase = SaveTransactionUseCase(ApiClient.instance);
      await useCase.call(widget.data);
      widget.onSuccess();
    } catch (e) {
      widget.onError('Ошибка при отправке данных: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      icon: CupertinoIcons.check_mark_circled_solid,
      title: 'Подтверждение',
      subtitle: 'Пожалуйста, проверьте все данные. Если Вы видите ошибку, нажмите кнопку «Назад»',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoRow('Корпус:', widget.data.selectedBuilding?.name ?? 'Не выбран'),
                _buildInfoRow('Комната:', widget.data.selectedRoom?.name ?? 'Не выбрана'),
                _buildInfoRow('Гость:', '${widget.data.lastName} ${widget.data.firstName}'),
                const SizedBox(height: 12),
                _buildInfoRow('Категория:', _getCategoryName(widget.data.selectedCategory)),
                if (widget.data.selectedCategory == BookingCategory.accommodation) ...[
                  _buildInfoRow('Заезд:', DateFormat('dd.MM.yyyy', 'ru').format(widget.data.checkInDate)),
                  _buildInfoRow('Выезд:', DateFormat('dd.MM.yyyy', 'ru').format(widget.data.checkOutDate)),
                  _buildInfoRow('Ночей:', widget.data.totalNights.toString()),
                ],
                if (widget.data.selectedItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Выбранные услуги:',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.data.selectedItems.map((item) {
                    String itemText = '  ${item.name}';
                    String priceText;

                    if (item.isCountable) {
                      itemText += ' (×${item.quantity})';
                      priceText = '${item.price} × ${item.quantity} = ${item.totalPrice} ₽';
                    } else if (item.isDuration) {
                      itemText += ' (${item.quantity} ${_getDaysText(item.quantity)})';
                      priceText = '${item.price} × ${item.quantity} = ${item.totalPrice} ₽';
                    } else {
                      priceText = '${item.totalPrice} ₽';
                    }

                    return _buildInfoRow(itemText, priceText);
                  }),
                ],
                const SizedBox(height: 12),
                _buildInfoRow('Оплата:', widget.data.paymentMethod ?? 'Не выбран'),
                const SizedBox(height: 20),
                _buildInfoRow('ИТОГО:', '${widget.data.totalPrice} ₽', isTotal: true),
              ],
            ),
          ),

          const SizedBox(height: 40),

          CupertinoButton(
            color: CupertinoColors.activeBlue,
            onPressed: _isLoading ? null : _submit,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text(
                        'Подтвердить и оплатить',
                        style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold, fontSize: 17),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        return 'Не выбрано';
    }
  }

  String _getDaysText(int days) {
    if (days % 10 == 1 && days % 100 != 11) {
      return 'день';
    } else if ([2, 3, 4].contains(days % 10) && ![12, 13, 14].contains(days % 100)) {
      return 'дня';
    } else {
      return 'дней';
    }
  }

  Widget _buildInfoRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: CupertinoColors.white,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 26 : 16,
            ),
          ),
        ],
      ),
    );
  }
}