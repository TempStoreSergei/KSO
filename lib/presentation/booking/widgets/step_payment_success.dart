import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepPaymentSuccess extends StatefulWidget {
  final VoidCallback onComplete;

  const StepPaymentSuccess({
    super.key,
    required this.onComplete,
  });

  @override
  State<StepPaymentSuccess> createState() => _StepPaymentSuccessState();
}

class _StepPaymentSuccessState extends State<StepPaymentSuccess> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 10), () {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const StepContainer(
      icon: CupertinoIcons.check_mark_circled_solid,
      title: 'Оплата прошла успешно',
      subtitle: 'Сейчас вы будете перенаправлены',
      child: Center(
        child: CupertinoActivityIndicator(
          radius: 24,
        ),
      ),
    );
  }
}
