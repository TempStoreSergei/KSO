import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/entities/transaction.dart';
import 'package:motel/domain/usecases/get_transactions.dart';
import 'package:motel/presentation/settings/transactions/transaction_detail_screen.dart';
import 'package:motel/presentation/settings/transactions/transactions_filters_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

enum PaymentFilter {
  all('Все'),
  cash('Наличные'),
  card('Карта'),
  sbp('СБП');

  final String label;
  const PaymentFilter(this.label);
}

enum Status1CFilter {
  all('Все'),
  notSent('Не отправлено'),
  sentSuccess('Отправлено'),
  sentError('Ошибка');

  final String label;
  const Status1CFilter(this.label);
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _getTransactionsUseCase = GetTransactions(ApiClient.instance);
  final _searchController = TextEditingController();

  List<Transaction>? _transactions;
  bool _isLoading = false;

  // Фильтры
  PaymentFilter _paymentFilter = PaymentFilter.all;
  Status1CFilter _status1CFilter = Status1CFilter.all;
  int? _selectedBuilding;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<Transaction> get _filteredTransactions {
    if (_transactions == null) return [];

    var filtered = _transactions!;

    // Поиск
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        final guestName = '${t.guest.lastName} ${t.guest.firstName}'.toLowerCase();
        final roomNumber = t.room.number.toLowerCase();
        final transactionId = t.id.toString();

        return guestName.contains(searchQuery) ||
            roomNumber.contains(searchQuery) ||
            transactionId.contains(searchQuery);
      }).toList();
    }

    // Фильтр по способу оплаты
    if (_paymentFilter != PaymentFilter.all) {
      filtered = filtered.where((t) {
        return t.paymentType.toLowerCase() == _paymentFilter.label.toLowerCase();
      }).toList();
    }

    // Фильтр по статусу 1С
    if (_status1CFilter != Status1CFilter.all) {
      filtered = filtered.where((t) {
        switch (_status1CFilter) {
          case Status1CFilter.notSent:
            return !t.sentTo1c;
          case Status1CFilter.sentSuccess:
            return t.sentTo1c && t.sentSuccessfully;
          case Status1CFilter.sentError:
            return t.sentTo1c && !t.sentSuccessfully;
          case Status1CFilter.all:
            return true;
        }
      }).toList();
    }

    // Фильтр по корпусу
    if (_selectedBuilding != null) {
      filtered = filtered.where((t) => t.room.building == _selectedBuilding).toList();
    }

    return filtered;
  }

  Set<int> get _availableBuildings {
    if (_transactions == null) return {};
    return _transactions!.map((t) => t.room.building).toSet();
  }

  bool get _hasActiveFilters {
    return _paymentFilter != PaymentFilter.all ||
        _status1CFilter != Status1CFilter.all ||
        _selectedBuilding != null ||
        _searchController.text.isNotEmpty;
  }

  void _resetFilters() {
    setState(() {
      _paymentFilter = PaymentFilter.all;
      _status1CFilter = Status1CFilter.all;
      _selectedBuilding = null;
      _searchController.clear();
    });
  }

  Future<void> _showFiltersScreen() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      CupertinoPageRoute(
        builder: (_) => TransactionsFiltersScreen(
          paymentFilter: _paymentFilter,
          status1CFilter: _status1CFilter,
          selectedBuilding: _selectedBuilding,
          availableBuildings: _availableBuildings.toList()..sort(),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _paymentFilter = result['payment'] as PaymentFilter;
        _status1CFilter = result['status'] as Status1CFilter;
        _selectedBuilding = result['building'] as int?;
      });
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

  Future<void> _exportTransactions() async {
    try {
      setState(() => _isLoading = true);

      // Получаем URL файла с сервера
      final fileUrl = await ApiClient.instance.exportTransactions();

      // Определяем имя файла из URL
      final fileName = fileUrl.split('/').last;

      // Показываем диалог выбора места сохранения
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить файл транзакций',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (savePath == null) {
        // Пользователь отменил сохранение
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Скачиваем файл
      final response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode == 200) {
        // Сохраняем файл
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          setState(() => _isLoading = false);
          _showSuccess('Файл успешно сохранен');
        }
      } else {
        throw Exception('Не удалось скачать файл: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Ошибка экспорта транзакций: $e');
      }
    }
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Успешно'),
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

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _filteredTransactions;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Транзакции'),
                previousPageTitle: 'Настройки',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showFiltersScreen,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              const Icon(CupertinoIcons.slider_horizontal_3),
                              if (_hasActiveFilters)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: CupertinoColors.systemRed,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          const Text('Фильтры'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isLoading ? null : _exportTransactions,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.arrow_down_doc),
                          const SizedBox(width: 4),
                          const Text('Экспорт'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSliverRefreshControl(onRefresh: _loadTransactions),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: 'Поиск по гостю, комнате или ID',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              if (_hasActiveFilters)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Найдено: ${filteredTransactions.length}',
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _resetFilters,
                          child: const Text(
                            'Сбросить фильтры',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              _buildTransactionsList(filteredTransactions),
            ],
          ),
          if (_isLoading && _transactions == null)
            const Center(child: CupertinoActivityIndicator(radius: 15)),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions) {
    if (_transactions == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (transactions.isEmpty) {
      return SliverToBoxAdapter(
        child: CupertinoListSection.insetGrouped(
          children: [
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  _hasActiveFilters ? 'Нет результатов' : 'Нет транзакций',
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: const Text('СПИСОК ТРАНЗАКЦИЙ'),
        children: transactions.map((transaction) => _buildTransactionItem(transaction)).toList(),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    // Считаем общую сумму
    final roomTotalPrice = transaction.room.totalPrice ?? 0;
    final servicesTotalPrice = transaction.services.fold<int>(0, (sum, service) => sum + service.totalPrice);
    final totalPrice = roomTotalPrice + servicesTotalPrice;

    // Формируем ФИО
    final guestName = '${transaction.guest.lastName} ${transaction.guest.firstName}';

    return CupertinoListTile(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  guestName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Номер и комната
                    Text(
                      '#${transaction.id} • ',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 13,
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.bed_double,
                      size: 11,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      transaction.room.number,
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Способ оплаты
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getPaymentColor(transaction.paymentType).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        transaction.paymentType,
                        style: TextStyle(
                          color: _getPaymentColor(transaction.paymentType),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Статус 1С
                    _build1CStatusBadge(transaction),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Сумма как тег
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.activeGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${totalPrice ~/ 100} ₽',
              style: const TextStyle(
                color: CupertinoColors.activeGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      trailing: const CupertinoListTileChevron(),
      onTap: () async {
        await Navigator.of(context).push(CupertinoPageRoute(
          builder: (_) => TransactionDetailScreen(transaction: transaction),
        ));
        _loadTransactions();
      },
    );
  }

  Widget _build1CStatusBadge(Transaction transaction) {
    if (!transaction.sentTo1c) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Не отправлено',
          style: TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (transaction.sentSuccessfully) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGreen.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '✓ Отправлено',
          style: TextStyle(
            color: CupertinoColors.systemGreen,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Отправлено, но с ошибкой
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '✗ Ошибка',
        style: TextStyle(
          color: CupertinoColors.systemRed,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
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
