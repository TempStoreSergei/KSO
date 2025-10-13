import 'package:flutter/cupertino.dart';
import 'info_footer.dart';

class ActionsSection extends StatelessWidget {
  final VoidCallback onResetCount;

  const ActionsSection({
    super.key,
    required this.onResetCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('ДЕЙСТВИЯ'),
          children: [
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.money_dollar_circle,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Инкассация',
                style: TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 17,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: onResetCount,
            ),
          ],
        ),
        const InfoFooter(
          text: 'Выполните инкассацию и сбросьте счетчик купюр после изъятия денег из диспенсера.',
          barColor: CupertinoColors.systemRed,
        ),
      ],
    );
  }
}
