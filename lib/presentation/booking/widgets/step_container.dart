// lib/presentation/booking/widgets/step_container.dart
import 'package:flutter/cupertino.dart';

class StepContainer extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const StepContainer({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 450), // Немного увеличим макс. ширину
      child: Column(
        children: [
          if (icon != null) ...[
            Container(
              // === ИЗМЕНЕНИЕ: Увеличен размер иконки и контейнера ===
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.activeBlue.withOpacity(0.15),
              ),
              child: Icon(icon, size: 60, color: CupertinoColors.activeBlue),
            ),
            const SizedBox(height: 28),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            // === ИЗМЕНЕНИЕ: Увеличен шрифт заголовка ===
            style: const TextStyle(color: CupertinoColors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              // === ИЗМЕНЕНИЕ: Увеличен шрифт подзаголовка ===
              style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 17),
            ),
          ],
          const SizedBox(height: 36),
          child,
        ],
      ),
    );
  }
}