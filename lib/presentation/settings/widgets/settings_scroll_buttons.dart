import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// Кнопки прокрутки вверх/вниз для экранов настроек (только нативные платформы).
class SettingsScrollButtons extends StatelessWidget {
  final ScrollController controller;

  const SettingsScrollButtons({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScrollButton(
          icon: CupertinoIcons.chevron_up,
          label: 'Вверх',
          onTap: () => controller.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          ),
        ),
        const SizedBox(width: 4),
        _ScrollButton(
          icon: CupertinoIcons.chevron_down,
          label: 'Вниз',
          onTap: () {
            if (controller.hasClients) {
              controller.animateTo(
                controller.position.maxScrollExtent,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              );
            }
          },
        ),
      ],
    );
  }
}

class _ScrollButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ScrollButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
