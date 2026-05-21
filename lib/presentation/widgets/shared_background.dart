import 'package:flutter/material.dart';
import 'package:motel/core/config/app_mode.dart';

const String _backgroundImagePath = 'assets/images/background.png';

class SharedBackground extends StatelessWidget {
  final Widget child;

  const SharedBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            key: const ValueKey('default_background'),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_backgroundImagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              gradient: AppMode.dentistrySelfService
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF002F35).withValues(alpha: 0.42),
                        Colors.black.withValues(alpha: 0.30),
                        const Color(0xFF00B3A4).withValues(alpha: 0.22),
                      ],
                    )
                  : null,
            ),
          ),
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}
