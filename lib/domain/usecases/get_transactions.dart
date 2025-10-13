// ============================================
// lib/domain/usecases/get_transactions.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/entities/transaction.dart';

class GetTransactions {
  final ApiClient _apiClient;

  GetTransactions(this._apiClient);

  Future<List<Transaction>> call() async {
    try {
      final response = await _apiClient.get('/guests/get_transactions');

      if (response['transactions'] != null) {
        final List<dynamic> transactionsJson = response['transactions'];
        return transactionsJson.map((json) => Transaction.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Не удалось загрузить транзакции: $e');
    }
  }
}
