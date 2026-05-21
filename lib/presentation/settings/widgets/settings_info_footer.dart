import 'package:flutter/cupertino.dart';

class SettingsInfoFooter extends StatelessWidget {
  const SettingsInfoFooter({
    required this.text,
    required this.barColor,
    super.key,
  });

  final String text;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            constraints: const BoxConstraints(minHeight: 24),
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
                  fontSize: 15,
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
