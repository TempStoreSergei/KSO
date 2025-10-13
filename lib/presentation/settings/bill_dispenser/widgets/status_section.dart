import 'package:flutter/cupertino.dart';
import '../models/bill_dispenser_status.dart';

class StatusSection extends StatelessWidget {
  final BillDispenserStatus status;

  const StatusSection({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: const Text('ТЕКУЩЕЕ СОСТОЯНИЕ'),
      children: [
        CupertinoListTile(
          title: const Text('Верхний бокс'),
          subtitle: Text('Номинал: ${status.upperBoxValue ~/ 100} руб.'),
          trailing: Text(
            '${status.upperBoxCount} купюр',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Нижний бокс'),
          subtitle: Text('Номинал: ${status.lowerBoxValue ~/ 100} руб.'),
          trailing: Text(
            '${status.lowerBoxCount} купюр',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }
}
