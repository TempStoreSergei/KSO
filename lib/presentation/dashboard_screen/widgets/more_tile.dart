import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/presentation/helpers/adaptive_text.dart';
import 'package:motel/presentation/helpers/glassmorphic_container.dart';

class MoreTile extends StatelessWidget {
  final VoidCallback onTap;
  const MoreTile({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        // Добавляем точно такие же внутренние отступы для консистентности.
        padding: const EdgeInsets.all(14.0),
        child: Column(
          // Выравниваем весь контент по левому краю.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Иконка в левом верхнем углу.
            Icon(
              CupertinoIcons.ellipsis, // Иконка "больше"
              color: Colors.white,
              size: scaleText(context, 32), // Такой же размер, как у ServiceTile
            ),

            // 2. "Распорка", которая толкает текст вниз.
            const Spacer(),

            // 3. Текст в левом нижнем углу.
            Text(
              "Далее",
              // Используем абсолютно тот же стиль текста для идеального совпадения.
              style: TextStyle(
                color: Colors.white,
                fontSize: scaleText(context, 17),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}