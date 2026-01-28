import 'package:flutter/cupertino.dart';

class TransactionsSelectionPanel extends StatelessWidget {
  const TransactionsSelectionPanel({
    super.key,
    required this.selectedCount,
    required this.onSendSelected,
    required this.isValidating,
    required this.isSending,
    required this.accentColor,
  });

  final int selectedCount;
  final VoidCallback onSendSelected;
  final bool isValidating;
  final bool isSending;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final canSend = selectedCount > 0 && !isSending && !isValidating;

    return CupertinoListSection.insetGrouped(
      children: [
        CupertinoListTile(
          leading: const Icon(CupertinoIcons.check_mark_circled),
          title: const Text('Выбрано'),
          additionalInfo: Text(
            selectedCount.toString(),
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
        ),
        CupertinoListTile(
          leading: Icon(CupertinoIcons.cloud_upload, color: canSend ? accentColor : CupertinoColors.systemGrey3),
          title: Text(
            'Отправить выбранные',
            style: TextStyle(
              color: canSend ? accentColor : CupertinoColors.systemGrey,
              fontWeight: canSend ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: isSending
              ? const CupertinoActivityIndicator(radius: 8)
              : const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey3, size: 18),
          onTap: canSend ? onSendSelected : null,
        ),
      ],
    );
  }
}
