// ============================================
// lib/presentation/widgets/numpad_keyboard.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NumpadKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;

  const NumpadKeyboard({super.key, required this.onKeyPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 12),
          _buildRow(['', '0', 'BACKSPACE']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String key) {
    if (key.isEmpty) {
      // Пустой виджет для выравнивания кнопки "0" по центру
      return const SizedBox(width: 72, height: 72);
    }

    // Радиус для круглых кнопок
    const double buttonRadius = 36.0;

    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: key == 'BACKSPACE'
            ? Colors.black.withOpacity(0.25)
            : Colors.white.withOpacity(0.25),
        shape: const CircleBorder(),
        child: InkWell(
          // === ИСПРАВЛЕНИЕ ===
          // У InkWell нет 'shape', используем borderRadius для ограничения области нажатия
          borderRadius: BorderRadius.circular(buttonRadius),
          highlightColor: Colors.white.withOpacity(0.2),
          splashColor: Colors.transparent,
          onTap: () => onKeyPressed(key),
          child: Center(
            child: key == 'BACKSPACE'
                ? const Icon(CupertinoIcons.delete_left_fill, color: Colors.white, size: 28)
                : Text(
              key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}