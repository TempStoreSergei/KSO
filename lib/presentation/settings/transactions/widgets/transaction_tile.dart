import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:motel/domain/entities/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onSend,
    required this.onInfo,
    required this.onSelect,
    this.onSelectBlocked,
    this.onDelete,
    required this.selectionMode,
    required this.isSelected,
    required this.isValidated,
    required this.validationError,
    required this.isProcessing,
    required this.accentColor,
  });

  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onSend;
  final VoidCallback onInfo;
  final VoidCallback onSelect;
  final VoidCallback? onSelectBlocked;
  final VoidCallback? onDelete;
  final bool selectionMode;
  final bool isSelected;
  final bool isValidated;
  final String? validationError;
  final bool isProcessing;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final displayPrice = _calculateDisplayPrice(transaction);
    final guestName = transaction.guest.fullName;
    final paymentColor = _paymentColor(transaction.paymentType);
    final phone = transaction.guest.phoneNumber?.trim();
    final paymentDateTime = _formatPaymentDateTime(transaction.paymentDateTime);
    final servicesSum = transaction.services.fold<int>(0, (sum, s) => sum + s.totalPrice);
    final finesSum = transaction.fines.fold<int>(0, (sum, f) => sum + f.totalPrice);
    final hasServices = transaction.services.isNotEmpty;
    final hasFines = transaction.fines.isNotEmpty;
    final hasRoomCharge = (!hasServices && !hasFines) || ((transaction.room.totalPrice ?? 0) > 0);
    final roomSum = hasRoomCharge ? (transaction.room.totalPrice ?? transaction.room.price) : 0;
    final itemsPreview = _itemsPreview(transaction);
    final status = _statusInfo(transaction);
    final canSelect = isValidated && !transaction.sentSuccessfully;
    final canSend = !transaction.sentSuccessfully && !isProcessing;

    return CupertinoListTile(
      onTap: selectionMode
          ? () {
              if (!canSelect) {
                onSelectBlocked?.call();
                return;
              }
              onSelect();
            }
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: selectionMode
          ? Icon(
              isSelected ? CupertinoIcons.checkmark_square_fill : CupertinoIcons.square,
              color: isSelected
                  ? accentColor
                  : (canSelect ? accentColor : CupertinoColors.systemGrey3),
            )
          : null,
      title: Text(
        guestName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            '#${transaction.id} • Корп. ${transaction.room.building} • Комн. ${transaction.room.number} • ${transaction.room.type}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 2),
          Text(
            'Гость #${transaction.guest.id} • Тел: ${phone == null || phone.isEmpty ? '—' : phone}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey2),
          ),
          if (paymentDateTime != null) ...[
            const SizedBox(height: 2),
            Text(
              'Оплата: $paymentDateTime',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey2),
            ),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if ((transaction.room.countDays ?? 0) > 0)
                _pill(
                  'Суток: ${transaction.room.countDays}',
                  CupertinoColors.systemGrey,
                ),
              if (hasRoomCharge) _pill('Проживание: ${roomSum ~/ 100} ₽', CupertinoColors.systemGrey),
              if (transaction.services.isNotEmpty) _pill('Услуги: ${transaction.services.length} (${servicesSum ~/ 100} ₽)', CupertinoColors.systemGrey),
              if (transaction.fines.isNotEmpty) _pill('Штрафы: ${transaction.fines.length} (${finesSum ~/ 100} ₽)', CupertinoColors.systemGrey),
            ],
          ),
          if (itemsPreview.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              itemsPreview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey2),
            ),
          ],
          if (transaction.sentSuccessfully) ...[
            const SizedBox(height: 6),
            const Text(
              'Уже отправлено в 1С',
              style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
            ),
          ] else if (validationError != null) ...[
            const SizedBox(height: 6),
            Text(
              validationError!,
              style: const TextStyle(fontSize: 12, color: CupertinoColors.systemRed),
            ),
          ] else if (isValidated) ...[
            const SizedBox(height: 6),
            Text(
              'Телефон подтвержден, клиент найден',
              style: TextStyle(fontSize: 12, color: accentColor),
            ),
          ] else if (selectionMode) ...[
            const SizedBox(height: 6),
            const Text(
              'Требуется проверка номера перед выбором',
              style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
            ),
          ],
          if (transaction.sentTo1c && !transaction.sentSuccessfully && (transaction.errorMessage ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Ошибка 1С: ${(transaction.errorMessage ?? '').trim()}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: CupertinoColors.systemRed),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _iconAction(
                icon: CupertinoIcons.pencil,
                color: CupertinoColors.activeBlue,
                onPressed: isProcessing ? null : onEdit,
              ),
              const SizedBox(width: 12),
              _iconAction(
                icon: transaction.sentSuccessfully ? CupertinoIcons.checkmark_alt : CupertinoIcons.cloud_upload,
                color: transaction.sentSuccessfully ? CupertinoColors.systemGreen : CupertinoColors.activeBlue,
                onPressed: canSend ? onSend : null,
                trailing: isProcessing ? const CupertinoActivityIndicator(radius: 8) : null,
              ),
              const SizedBox(width: 12),
              _iconAction(
                icon: CupertinoIcons.info,
                color: CupertinoColors.systemGrey,
                onPressed: isProcessing ? null : onInfo,
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 12),
                _iconAction(
                  icon: CupertinoIcons.trash,
                  color: CupertinoColors.systemRed,
                  onPressed: isProcessing ? null : onDelete,
                ),
              ],
            ],
          ),
        ],
      ),
      additionalInfo: SizedBox(
        width: 144,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _paymentPill(transaction.paymentType, paymentColor),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${displayPrice ~/ 100} ₽',
                style: TextStyle(fontWeight: FontWeight.bold, color: accentColor, fontSize: 16),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: _statusPill(status.label, status.color),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateDisplayPrice(Transaction transaction) {
    if (transaction.services.isNotEmpty) {
      return transaction.services.fold<int>(0, (sum, service) => sum + service.totalPrice);
    }
    if (transaction.fines.isNotEmpty) {
      return transaction.fines.fold<int>(0, (sum, fine) => sum + fine.totalPrice);
    }
    return transaction.room.totalPrice ?? transaction.room.price;
  }

  String? _formatPaymentDateTime(DateTime? value) {
    if (value == null) return null;
    return DateFormat('dd.MM.yyyy HH:mm', 'ru').format(value.toLocal());
  }

  Color _paymentColor(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'наличные':
        return CupertinoColors.systemGreen;
      case 'карта':
        return CupertinoColors.systemBlue;
      case 'сбп':
        return CupertinoColors.systemPurple;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  _StatusInfo _statusInfo(Transaction transaction) {
    if (!transaction.sentTo1c) {
      return const _StatusInfo('Не отправлено', CupertinoColors.systemGrey);
    }
    if (transaction.sentSuccessfully) {
      return const _StatusInfo('Отправлено', CupertinoColors.systemGreen);
    }
    return const _StatusInfo('Ошибка', CupertinoColors.systemRed);
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _paymentPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    Widget? trailing,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[
            trailing,
            const SizedBox(width: 8),
          ],
          Icon(icon, size: 18, color: onPressed == null ? CupertinoColors.systemGrey4 : color),
        ],
      ),
    );
  }

  String _itemsPreview(Transaction transaction) {
    final parts = <String>[];
    if (transaction.services.isNotEmpty) {
      final items = transaction.services.take(2).map((s) => '${s.name}×${s.count}').toList();
      final suffix = transaction.services.length > 2 ? '…' : '';
      parts.add('Услуги: ${items.join(', ')}$suffix');
    }
    if (transaction.fines.isNotEmpty) {
      final items = transaction.fines.take(2).map((f) => '${f.name}×${f.count}').toList();
      final suffix = transaction.fines.length > 2 ? '…' : '';
      parts.add('Штрафы: ${items.join(', ')}$suffix');
    }
    return parts.join(' • ');
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}
