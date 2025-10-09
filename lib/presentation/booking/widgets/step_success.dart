// lib/presentation/booking/widgets/step_success.dart
import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepSuccess extends StatelessWidget {
  const StepSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      icon: CupertinoIcons.heart_fill,
      title: 'Спасибо за покупку!',
      subtitle: 'Вы успешно оплатили услугу! не забудьте взять чек и предъявит его админстратору',
      child: Container(), // На этом шаге нет дополнительного контента
    );
  }
}