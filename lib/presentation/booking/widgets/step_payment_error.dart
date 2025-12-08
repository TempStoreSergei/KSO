import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepPaymentError extends StatelessWidget {
  final VoidCallback onRetry;

  const StepPaymentError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      icon: CupertinoIcons.xmark_seal_fill,
      title: 'Ошибка оплаты',
      subtitle: 'Не удалось обработать платеж. Пожалуйста, попробуйте еще раз.',
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(
            CupertinoIcons.xmark_circle_fill,
            color: CupertinoColors.systemRed,
            size: 80,
          ),
          const SizedBox(height: 20),
          const Text(
            'Платеж не прошел',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Попробуйте другой способ оплаты или обратитесь к администратору.',
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          CupertinoButton(
            color: CupertinoColors.activeBlue,
            onPressed: onRetry,
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }
}
