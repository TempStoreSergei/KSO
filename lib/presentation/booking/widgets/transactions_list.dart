// ============================================
// lib/presentation/booking/widgets/transactions_panel.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/entities/transaction.dart';
import 'package:motel/domain/usecases/get_transactions.dart';

class TransactionsPanel extends StatefulWidget {
  final bool canLoad;

  const TransactionsPanel({super.key, required this.canLoad});

  @override
  State<TransactionsPanel> createState() => _TransactionsPanelState();
}

class _TransactionsPanelState extends State<TransactionsPanel> {
  List<Transaction>? _transactions;
  bool _isLoading = false;
  String? _errorMessage;

  void _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final getTransactionsUseCase = GetTransactions(ApiClient.instance);
      final transactions = await getTransactionsUseCase.call();
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'История транзакций',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (!widget.canLoad)
            const Text(
              'Введите данные гостя для загрузки истории транзакций',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 13,
              ),
            )
          else if (_transactions == null && !_isLoading)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _loadTransactions,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Загрузить транзакции',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CupertinoActivityIndicator(radius: 12),
                ),
              )
            else if (_errorMessage != null)
                Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 13),
                  ),
                )
              else if (_transactions!.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        'Транзакции отсутствуют',
                        style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: Column(
                        children: _transactions!.map((transaction) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#${transaction.id}',
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Комната ${transaction.room.number}',
                                      style: const TextStyle(
                                        color: CupertinoColors.activeBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${transaction.guest.lastName} ${transaction.guest.firstName}',
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 12,
                                  ),
                                ),
                                if (transaction.room.countDays != null && transaction.room.countDays! > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Дней: ${transaction.room.countDays}',
                                    style: const TextStyle(
                                      color: CupertinoColors.systemGrey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }
}