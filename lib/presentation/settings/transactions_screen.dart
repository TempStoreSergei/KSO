// ============================================
// lib/presentation/settings/transactions_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/entities/transaction.dart';
import 'package:motel/domain/usecases/get_transactions.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _getTransactionsUseCase = GetTransactions(ApiClient.instance);

  List<Transaction>? _transactions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _getTransactionsUseCase.call();
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Ошибка загрузки транзакций: $e');
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru');

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Детали транзакции'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            _buildDetailRow('ID', transaction.id.toString()),
            const Divider(height: 16),
            _buildDetailRow('Гость', '${transaction.guest.lastName} ${transaction.guest.firstName} ${transaction.guest.surname}'),
            const Divider(height: 16),
            _buildDetailRow('Комната', transaction.room.name),
            const Divider(height: 16),
            _buildDetailRow('Заезд', dateFormat.format(transaction.checkIn)),
            _buildDetailRow('Выезд', dateFormat.format(transaction.checkOut)),
            const Divider(height: 16),
            _buildDetailRow('Оплата', transaction.paymentType),
            if (transaction.services.isNotEmpty) ...[
              const Divider(height: 16),
              const Text('Услуги:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...transaction.services.map((service) =>
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text('• ${service.name} - ${service.price} ₽'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Закрыть'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: CupertinoColors.systemGrey)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Транзакции'),
                previousPageTitle: 'Настройки',
              ),
              CupertinoSliverRefreshControl(onRefresh: _loadTransactions),

              _buildTransactionsList(),
            ],
          ),
          if (_isLoading && _transactions == null)
            const Center(child: CupertinoActivityIndicator(radius: 15)),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_transactions!.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'Нет транзакций',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
        ),
      );
    }

    // Сортируем транзакции по дате (новые сверху)
    final sortedTransactions = List<Transaction>.from(_transactions!);
    sortedTransactions.sort((a, b) => b.checkIn.compareTo(a.checkIn));

    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: const Text('ИСТОРИЯ ТРАНЗАКЦИЙ'),
        children: sortedTransactions.map((transaction) => _buildTransactionItem(transaction)).toList(),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final dateFormat = DateFormat('dd.MM.yyyy', 'ru');
    final totalPrice = transaction.services.fold<int>(
      0,
      (sum, service) => sum + service.price,
    );

    return CupertinoListTile(
      title: Text('${transaction.guest.lastName} ${transaction.guest.firstName}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Комната ${transaction.room.name} • ${dateFormat.format(transaction.checkIn)}',
            style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPaymentColor(transaction.paymentType).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.paymentType,
                  style: TextStyle(
                    color: _getPaymentColor(transaction.paymentType),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$totalPrice ₽',
                style: const TextStyle(
                  color: CupertinoColors.systemGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: const CupertinoListTileChevron(),
      onTap: () => _showTransactionDetails(transaction),
    );
  }

  Color _getPaymentColor(String paymentType) {
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
}
