import 'package:flutter/cupertino.dart';
import '../models/send_mode.dart';

class TransactionsHeaderPanel extends StatelessWidget {
  const TransactionsHeaderPanel({
    super.key,
    required this.sendMode,
    required this.onModeChanged,
    required this.onValidateAll,
    required this.onSendAll,
    required this.accentColor,
    required this.isValidating,
    required this.isSending,
  });

  final SendMode sendMode;
  final ValueChanged<SendMode> onModeChanged;
  final VoidCallback onValidateAll;
  final VoidCallback onSendAll;
  final Color accentColor;
  final bool isValidating;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      children: [
        CupertinoListTile(
          leading: const Icon(CupertinoIcons.slider_horizontal_3),
          title: const Text('Отправка в 1С'),
          subtitle: const Text('Режим отправки'),
          additionalInfo: SizedBox(
            width: 180,
            child: CupertinoSlidingSegmentedControl<SendMode>(
              groupValue: sendMode,
              thumbColor: accentColor,
              children: const {
                SendMode.single: Text('Один'),
                SendMode.multi: Text('Несколько'),
              },
              onValueChanged: (mode) {
                if (mode != null) onModeChanged(mode);
              },
            ),
          ),
        ),
        CupertinoListTile(
          leading: Icon(CupertinoIcons.phone, color: accentColor),
          title: const Text('Проверить телефоны'),
          subtitle: const Text('Ищет клиента в 1С по номеру'),
          trailing: isValidating
              ? const CupertinoActivityIndicator(radius: 8)
              : const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey3, size: 18),
          onTap: isValidating ? null : onValidateAll,
        ),
        CupertinoListTile(
          leading: Icon(CupertinoIcons.cloud_upload, color: accentColor),
          title: Text(
            'Отправить все',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Отправляет только подтвержденные'),
          trailing: isSending
              ? const CupertinoActivityIndicator(radius: 8)
              : const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey3, size: 18),
          onTap: (isSending || isValidating) ? null : onSendAll,
        ),
      ],
    );
  }
}
