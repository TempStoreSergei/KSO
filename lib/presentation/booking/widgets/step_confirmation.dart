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
    setState(() => _isLoading = true);
    try {
      final useCase = SaveTransactionUseCase(ApiClient.instance);
      await useCase.call(widget.data);
      widget.onSuccess();
    } catch (e) {
      widget.onError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      icon: CupertinoIcons.check_mark_circled_solid,
      title: 'Подтверждение',
      subtitle: 'Пожалуйста, проверьте все данные',
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
                _buildInfoRow('Комната:', widget.data.selectedRoom?.name ?? 'Не выбрана'),
                _buildInfoRow('Гость:', '${widget.data.lastName} ${widget.data.firstName}'),
                if (widget.data.bookingType == BookingType.accommodation) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Заезд:', DateFormat('dd.MM.yyyy', 'ru').format(widget.data.checkInDate)),
                  _buildInfoRow('Выезд:', DateFormat('dd.MM.yyyy', 'ru').format(widget.data.checkOutDate)),
                  _buildInfoRow('Ночей:', widget.data.totalNights.toString()),
                ],
                if (widget.data.bookingType == BookingType.serviceOnly) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Услуга:', widget.data.selectedService?.name ?? 'Не выбрана'),
                ],
                const SizedBox(height: 12),
                _buildInfoRow('Оплата:', widget.data.paymentMethod ?? 'Не выбран'),
                const SizedBox(height: 20),
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