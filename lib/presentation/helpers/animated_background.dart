import 'dart:ui';
import 'package:flutter/material.dart';

/// Виджет, создающий светлый фон в стиле Apple HomeKit.
///
/// Характеризуется очень светлой, почти белой основой с едва
/// заметными, мягкими и пастельными источниками света, которые
/// добавляют глубину и цвет, не перегружая интерфейс.
class LightHomeKitBackground extends StatelessWidget {
  const LightHomeKitBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // 1. Базовый цвет. Вместо черного используем очень светлый серый,
      // стандартный для системных интерфейсов Apple (UIColor.systemGray6).
      color: const Color(0xffF2F2F7),
      child: Stack(
        children: [
          // 2. Источники света. Теперь они должны быть очень нежными
          // и пастельными, чтобы лишь слегка тонировать фон.

          // Легкий, холодный оттенок сверху
          _buildLightSource(
            alignment: const Alignment(-1.0, -1.0),
            color: Colors.cyan.shade100,
          ),

          // Легкий, теплый оттенок снизу
          _buildLightSource(
            alignment: const Alignment(1.0, 1.0),
            color: Colors.pink.shade100,
          ),

          // 3. Финальное размытие. Для светлой темы его можно сделать
          // еще сильнее, чтобы переходы были максимально незаметными.
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 150.0, sigmaY: 150.0),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  /// Вспомогательный виджет для одного источника света.
  Widget _buildLightSource({required Alignment alignment, required Color color}) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 500,
        height: 500,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              // Интенсивность свечения на светлом фоне должна быть ниже
              color.withOpacity(0.4),
              color.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}