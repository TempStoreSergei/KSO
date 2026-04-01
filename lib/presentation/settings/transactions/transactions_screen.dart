import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/entities/transaction.dart';
import 'package:motel/domain/usecases/get_client_by_number.dart';
import 'package:motel/domain/usecases/get_transactions.dart';
import 'package:motel/domain/usecases/send_transaction_to_1c_usecase.dart';
import 'package:motel/presentation/settings/transactions/transaction_detail_screen.dart';
import 'package:motel/presentation/settings/transactions/transaction_edit_screen.dart';
import 'package:motel/presentation/settings/transactions/transactions_filters_screen.dart';
import 'package:motel/presentation/settings/transactions/models/send_mode.dart';
import 'package:motel/presentation/settings/transactions/widgets/transaction_tile.dart';
import 'package:motel/presentation/settings/transactions/widgets/transactions_header_panel.dart';
import 'package:motel/presentation/settings/transactions/widgets/transactions_selection_panel.dart';
import 'package:file_picker/file_picker.dart';

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
  final _getClientByNumberUseCase = GetClientByNumberUseCase(
      ApiClient.instance);
  final _searchController = TextEditingController();
  final TextEditingController _clientIdController = TextEditingController();

  final Color _accentColor = CupertinoColors.activeBlue;

  List<Transaction>? _transactions;
  bool _isLoading = false;

  // Набор ID транзакций, которые сейчас обрабатываются (отправляются в 1С)
  final Set<int> _processingIds = {};

  // Множественный выбор
  bool _selectionMode = false;
  final Set<int> _selectedTransactionIds = {};
  final Map<int, String> _validatedClientIds = {};
  final Map<int, String> _validationErrors = {};
  bool _isValidatingPhones = false;
  bool _isBulkSending = false;
  SendMode _sendMode = SendMode.single;

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
    _clientIdController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _getTransactionsUseCase.call();
      if (mounted) {
        // Сортируем по ID (последние сверху)
        transactions.sort((a, b) => b.id.compareTo(a.id));
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

  Future<void> _sendTo1C(Transaction transaction) async {
    await _sendTo1CInternal(transaction);
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Удалить транзакцию?'),
        content: Text(
          'Транзакция #${transaction.id} будет удалена безвозвратно.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.instance.delete('/transactions/delete_transaction/${transaction.id}');
      if (mounted) {
        _showSuccess('Транзакция #${transaction.id} удалена');
        _loadTransactions();
      }
    } catch (e) {
      if (mounted) {
        _showError('Ошибка удаления: $e');
      }
    }
  }

  Future<String?> _resolveClientIdForTransaction(
    Transaction transaction, {
    String? presetClientId,
  }) async {
    final preset = presetClientId?.trim();
    if (preset != null && preset.isNotEmpty) return preset;

    final phoneNumber = transaction.guest.phoneNumber;
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      final foundClientId = await _getClientByNumberUseCase.call(phoneNumber.trim());
      if (foundClientId != null && foundClientId.isNotEmpty) {
        return foundClientId;
      }
    }

    if (!mounted) return null;

    _clientIdController.text = transaction.guest.id.toString();
    final manualInput = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Отправка в 1С'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Введите Client ID для отправки в систему 1С:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _clientIdController,
              placeholder: 'Client ID',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Отправить'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (manualInput != true) return null;
    final entered = _clientIdController.text.trim();
    return entered.isEmpty ? null : entered;
  }

  Future<void> _sendTo1CInternal(Transaction transaction, {
    String? presetClientId,
    bool showSuccess = true,
    bool reloadOnSuccess = true,
  }) async {
    if (transaction.sentSuccessfully) {
      if (mounted) {
        _showError('Транзакция уже отправлена в 1С');
      }
      return;
    }
    if (_processingIds.contains(transaction.id)) return;

    setState(() {
      _processingIds.add(transaction.id);
    });

    try {
      final clientId = await _resolveClientIdForTransaction(
        transaction,
        presetClientId: presetClientId,
      );
      if (clientId == null || clientId.isEmpty) return;

      // 3. Отправляем в 1С
      final useCase = SendTransactionTo1CUseCase(ApiClient.instance);
      await useCase.call(transaction, clientId);
      if (mounted) {
        if (showSuccess) {
          _showSuccess('Транзакция отправлена в 1С');
        }
        if (reloadOnSuccess) {
          _loadTransactions(); // Обновить список
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Ошибка при отправке: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(transaction.id);
        });
      }
    }
  }

  Future<void> _validatePhones({Set<int>? targetIds}) async {
    if (_transactions == null) {
      _showError('Дождитесь загрузки транзакций');
      return;
    }
    final allIds = targetIds ?? _filteredTransactions.map((t) => t.id).toSet();
    final ids = allIds.where((id) => _getTransactionById(id)?.sentSuccessfully != true).toSet();
    if (ids.isEmpty) {
      _showError('Нет транзакций для проверки');
      return;
    }

    setState(() {
      _isValidatingPhones = true;
      _validationErrors.removeWhere((key, value) => ids.contains(key));
      _validatedClientIds.removeWhere((key, value) => ids.contains(key));
    });

    final successes = <int, String>{};
    final failures = <int, String>{};

    for (final id in ids) {
      final transaction = _getTransactionById(id);
      if (transaction == null) {
        failures[id] = 'Транзакция не найдена';
        continue;
      }

      final phone = transaction.guest.phoneNumber?.trim() ?? '';
      if (phone.isEmpty) {
        failures[id] = 'Нет номера телефона';
        continue;
      }

      final clientId = await _getClientByNumberUseCase.call(phone);
      if (clientId == null || clientId.isEmpty) {
        failures[id] = 'Клиент не найден в 1С';
        continue;
      }

      successes[id] = clientId;
    }

    if (mounted) {
      setState(() {
        _validatedClientIds.addAll(successes);
        _validationErrors.addAll(failures);
        _isValidatingPhones = false;
        _selectedTransactionIds
          ..removeWhere((id) => !successes.containsKey(id))
          ..addAll(successes.keys);
      });
    }

    if (successes.isNotEmpty) {
      _showSuccess('Номеров проверено: ${successes.length}');
    }
    if (failures.isNotEmpty) {
      final failedList = failures.entries
          .map((e) => '#${e.key}: ${e.value}')
          .join('\n');
      _showError('Не удалось подтвердить: \n$failedList');
    }
  }

  Future<void> _sendSelectedTo1C() async {
    if (_transactions == null) {
      _showError('Дождитесь загрузки транзакций');
      return;
    }
    if (_selectedTransactionIds.isEmpty) {
      _showError('Выберите транзакции для отправки');
      return;
    }
    final alreadySent = _selectedTransactionIds.where((id) {
      final transaction = _getTransactionById(id);
      return transaction?.sentSuccessfully == true;
    }).toList();
    if (alreadySent.isNotEmpty) {
      _showError('В выборе есть уже отправленные транзакции: ${alreadySent.join(', ')}');
      return;
    }
    final notValidated = _selectedTransactionIds.where((
        id) => !_validatedClientIds.containsKey(id)).toList();
    if (notValidated.isNotEmpty) {
      _showError(
          'Проверьте номера перед отправкой. Не подтверждены: ${notValidated
              .join(', ')}');
      return;
    }

    setState(() => _isBulkSending = true);
    final idsToSend = _selectedTransactionIds.toList();
    final totalToSend = idsToSend.length;
    for (final id in idsToSend) {
      final transaction = _getTransactionById(id);
      if (transaction == null) continue;
      final clientId = _validatedClientIds[id];
      if (clientId == null) continue;
      await _sendTo1CInternal(
        transaction,
        presetClientId: clientId,
        showSuccess: false,
        reloadOnSuccess: false,
      );
    }
    if (mounted) {
      setState(() {
        _selectedTransactionIds.clear();
        _isBulkSending = false;
      });
      await _loadTransactions();
      _showSuccess('Отправлено: $totalToSend');
    }
  }

  Future<void> _sendAllValidated() async {
    if (_transactions == null) {
      _showError('Дождитесь загрузки транзакций');
      return;
    }
    final filtered = _filteredTransactions;
    final candidates = filtered.where((t) => !t.sentSuccessfully).toList();
    final skippedAlreadySent = filtered.length - candidates.length;

    await _validatePhones(targetIds: candidates.map((t) => t.id).toSet());
    final idsToSend = candidates.map((t) => t.id).where(_isValidated).toList();
    if (idsToSend.isEmpty) {
      _showError(skippedAlreadySent > 0
          ? 'Нет транзакций для отправки (уже отправлено: $skippedAlreadySent)'
          : 'Нет подтвержденных номеров для отправки');
      return;
    }

    setState(() => _isBulkSending = true);
    for (final id in idsToSend) {
      final transaction = _getTransactionById(id);
      if (transaction == null) continue;
      final clientId = _validatedClientIds[id];
      if (clientId == null) continue;
      await _sendTo1CInternal(
        transaction,
        presetClientId: clientId,
        showSuccess: false,
        reloadOnSuccess: false,
      );
    }

    if (mounted) {
      setState(() {
        _isBulkSending = false;
        _selectedTransactionIds.clear();
      });
      await _loadTransactions();
      _showSuccess(skippedAlreadySent > 0
          ? 'Отправлено: ${idsToSend.length}, пропущено (уже отправлено): $skippedAlreadySent'
          : 'Отправлено: ${idsToSend.length}');
    }
  }

  List<Transaction> get _filteredTransactions {
    if (_transactions == null) return [];

    var filtered = _transactions!;

    // Поиск
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        final guestName = '${t.guest.lastName} ${t.guest.firstName}'
            .toLowerCase();
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
        return t.paymentType.toLowerCase() ==
            _paymentFilter.label.toLowerCase();
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
      filtered =
          filtered.where((t) => t.room.building == _selectedBuilding).toList();
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

  bool _isValidated(int transactionId) =>
      _validatedClientIds.containsKey(transactionId);

  Transaction? _getTransactionById(int id) {
    try {
      return _transactions?.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _showFiltersScreen() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      CupertinoPageRoute(
        builder: (_) =>
            TransactionsFiltersScreen(
              paymentFilter: _paymentFilter,
              status1CFilter: _status1CFilter,
              selectedBuilding: _selectedBuilding,
              availableBuildings: _availableBuildings.toList()
                ..sort(),
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
      builder: (ctx) =>
          CupertinoAlertDialog(
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
      final fileName = fileUrl
          .split('/')
          .last;

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
      final response = await ApiClient.instance.getRawUrl(fileUrl);

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
      builder: (ctx) =>
          CupertinoAlertDialog(
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
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TransactionsHeaderPanel(
                      sendMode: _sendMode,
                      accentColor: _accentColor,
                      isValidating: _isValidatingPhones,
                      isSending: _isBulkSending,
                      onValidateAll: () => _validatePhones(),
                      onSendAll: _sendAllValidated,
                      onModeChanged: (mode) {
                        setState(() {
                          _sendMode = mode;
                          _selectionMode = mode == SendMode.multi;
                          _selectedTransactionIds.clear();
                          _validatedClientIds.clear();
                          _validationErrors.clear();
                        });
                      },
                    ),
                    if (_selectionMode)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Text(
                          'Для множественной отправки выбирайте только записи с подтвержденным номером.',
                          style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                        ),
                      ),
                  ],
                ),
              ),
              if (_selectionMode)
                SliverToBoxAdapter(
                  child: TransactionsSelectionPanel(
                      selectedCount: _selectedTransactionIds.length,
                      isValidating: _isValidatingPhones,
                      isSending: _isBulkSending,
                      accentColor: _accentColor,
                      onSendSelected: _sendSelectedTo1C,
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
              if (_transactions != null && filteredTransactions.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Text(
                        _hasActiveFilters
                            ? 'Нет результатов'
                            : 'Нет транзакций',
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),

              if (_transactions != null && filteredTransactions.isNotEmpty)
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('СПИСОК ТРАНЗАКЦИЙ'),
                    children: filteredTransactions
                        .map(
                          (t) =>
                          TransactionTile(
                            transaction: t,
                            selectionMode: _selectionMode,
                            isSelected: _selectedTransactionIds.contains(t.id),
                            isValidated: _isValidated(t.id),
                            validationError: _validationErrors[t.id],
                            isProcessing: _processingIds.contains(t.id),
                            accentColor: _accentColor,
                            onSelect: () {
                              setState(() {
                                if (_selectedTransactionIds.contains(t.id)) {
                                  _selectedTransactionIds.remove(t.id);
                                } else {
                                  _selectedTransactionIds.add(t.id);
                                }
                              });
                            },
                            onSelectBlocked: () => _showError(t.sentSuccessfully
                                ? 'Транзакция уже отправлена в 1С'
                                : 'Сначала подтвердите номер телефона для этой транзакции'),
                            onDelete: () => _deleteTransaction(t),
                            onEdit: () async {
                              if (_processingIds.contains(t.id)) return;
                              final result = await Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (_) =>
                                      TransactionEditScreen(transaction: t),
                                ),
                              );
                              if (result == true) _loadTransactions();
                            },
                            onSend: () => _sendTo1C(t),
                            onInfo: () async {
                              if (_processingIds.contains(t.id)) return;
                              await Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (_) =>
                                      TransactionDetailScreen(transaction: t),
                                ),
                              );
                              _loadTransactions();
                            },
                          ),
                    )
                        .toList(),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
          if (_isLoading && _transactions == null)
            const Center(child: CupertinoActivityIndicator(radius: 15)),
        ],
      ),
    );
  }
}
