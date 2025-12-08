import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motel/presentation/lock_screen/lock_screen.dart';

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

class _StepSuccessState extends State<StepSuccess> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoActivityIndicator(
            radius: 24,
          ),
          SizedBox(height: 32),
          Text(
            'Оплата прошла успешно',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Сейчас вы будете перенаправлены',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}