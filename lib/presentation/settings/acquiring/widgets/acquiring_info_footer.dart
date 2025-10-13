// ============================================
// lib/presentation/settings/acquiring/widgets/acquiring_info_footer.dart
// ============================================

import 'package:flutter/cupertino.dart';

/// Виджет для отображения информационного футера с цветной полоской
class AcquiringInfoFooter extends StatelessWidget {
  final String text;
  final Color barColor;

  const AcquiringInfoFooter({
    super.key,
    required this.text,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: null,
            constraints: const BoxConstraints(minHeight: 28),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
