import 'package:flutter/cupertino.dart';

/// Оверлей загрузки для блокировки UI во время выполнения операций.
/// Предотвращает повторные нажатия на кнопки во время выполнения запросов.
class AdminLoadingOverlay extends StatelessWidget {
  final bool isProcessing;
  final Widget child;

  const AdminLoadingOverlay({
    super.key,
    required this.isProcessing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isProcessing)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: CupertinoColors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CupertinoActivityIndicator(radius: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
