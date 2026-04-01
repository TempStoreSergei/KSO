import 'dart:async';
import 'package:flutter/cupertino.dart';

class StepSuccess extends StatefulWidget {
  final int totalPrice;
  final DateTime paymentDateTime;

  const StepSuccess({
    super.key,
    required this.totalPrice,
    required this.paymentDateTime,
  });

  @override
  State<StepSuccess> createState() => _StepSuccessState();
}

class _StepSuccessState extends State<StepSuccess> with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _countdown = 10;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _animController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                color: Color(0xFF34C759),
                size: 80,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Спасибо за покупку!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Оплата ${widget.totalPrice ~/ 100} ₽ прошла успешно',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Возврат на главный экран через $_countdown сек.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CupertinoColors.systemGrey2,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}