import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/entities/transaction.dart';
import 'package:motel/domain/usecases/send_transaction_to_1c_usecase.dart';
import 'package:motel/presentation/settings/transactions/transaction_edit_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isSending = false;
  final TextEditingController _clientIdController = TextEditingController();

  @override
  void dispose() {
    _clientIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Вычисляем общую сумму
    final roomTotalPrice = widget.transaction.room.totalPrice ?? 0;
    final servicesTotalPrice = widget.transaction.services.fold<int>(0, (sum, service) => sum + service.totalPrice);
    final totalPrice = roomTotalPrice + servicesTotalPrice;

    final roomTypeMap = {
      'fourBed': '4 места',
      'sixBed': '6 мест',
      'eightBed': '8 мест',
    };

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text('Транзакция #${widget.transaction.id}'),
            previousPageTitle: 'Транзакции',
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _navigateToEdit(),
              child: const Text('Изменить'),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Статус отправки в 1С
                CupertinoListSection.insetGrouped(
                  header: const Text('СТАТУС ОТПРАВКИ В 1С'),
                  children: [
                    CupertinoListTile(
                      title: const Text('Статус'),
                      additionalInfo: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(),
                            color: _getStatusColor(),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(),
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.transaction.errorMessage != null)
                      CupertinoListTile(
                        title: const Text('Ошибка'),
                        subtitle: Text(
                          widget.transaction.errorMessage!,
                          style: const TextStyle(color: CupertinoColors.systemRed),
                        ),
                      ),
                  ],
                ),

                // Информация о госте
                CupertinoListSection.insetGrouped(
                  header: const Text('ИНФОРМАЦИЯ О ГОСТЕ'),
                  children: [
                    _buildDetailRow('Фамилия', widget.transaction.guest.lastName),
                    _buildDetailRow('Имя', widget.transaction.guest.firstName),
                    if (widget.transaction.guest.surname.isNotEmpty)
                      _buildDetailRow('Отчество', widget.transaction.guest.surname),
                  ],
                ),

                // Информация о комнате
                CupertinoListSection.insetGrouped(
                  header: const Text('ИНФОРМАЦИЯ О КОМНАТЕ'),
                  children: [
                    _buildDetailRow('Номер комнаты', widget.transaction.room.number),
                    _buildDetailRow('Тип', roomTypeMap[widget.transaction.room.type] ?? widget.transaction.room.type),
                    _buildDetailRow('Корпус', widget.transaction.room.building.toString()),
                    if (widget.transaction.room.countDays != null && widget.transaction.room.countDays! > 0)
                      _buildDetailRow('Кол-во дней', widget.transaction.room.countDays.toString()),
                    if (widget.transaction.room.totalPrice != null)
                      _buildDetailRow('Стоимость проживания', '${widget.transaction.room.totalPrice! ~/ 100} ₽'),
                  ],
                ),

                // Услуги
                if (widget.transaction.services.isNotEmpty)
                  CupertinoListSection.insetGrouped(
                    header: const Text('УСЛУГИ'),
                    children: widget.transaction.services.map((service) {
                      return CupertinoListTile(
                        title: Text(service.name),
                        subtitle: Text('Код: ${service.serviceCode} | ${service.price ~/ 100} ₽ × ${service.count}'),
                        additionalInfo: Text(
                          '${service.totalPrice ~/ 100} ₽',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),

                // Штрафы
                if (widget.transaction.fines.isNotEmpty)
                  CupertinoListSection.insetGrouped(
                    header: const Text('ШТРАФЫ'),
                    children: widget.transaction.fines.map((fine) {
                      return CupertinoListTile(
                        title: Text('Штраф #${fine.id}'),
                        subtitle: Text('Кол-во: ${fine.count}'),
                      );
                    }).toList(),
                  ),

                // Итого
                CupertinoListSection.insetGrouped(
                  header: const Text('ОПЛАТА'),
                  children: [
                    CupertinoListTile(
                      title: const Text('Способ оплаты'),
                      additionalInfo: Text(
                        widget.transaction.paymentType,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    CupertinoListTile(
                      title: const Text(
                        'Итоговая сумма',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      additionalInfo: Text(
                        '${totalPrice ~/ 100} ₽',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.activeGreen,
                        ),
                      ),
                    ),
                  ],
                ),

                // Кнопка отправки в 1С
                if (!widget.transaction.sentSuccessfully)
                  CupertinoListSection.insetGrouped(
                    children: [
                      CupertinoListTile(
                        title: Text(
                          widget.transaction.sentTo1c ? 'Повторить отправку в 1С' : 'Отправить в 1С',
                          style: const TextStyle(
                            color: CupertinoColors.activeBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        leading: _isSending
                            ? const CupertinoActivityIndicator()
                            : const Icon(
                                CupertinoIcons.cloud_upload,
                                color: CupertinoColors.activeBlue,
                              ),
                        onTap: _isSending ? null : _sendTo1C,
                      ),
                    ],
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return CupertinoListTile(
      title: Text(label),
      additionalInfo: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getStatusColor() {
    if (!widget.transaction.sentTo1c) {
      return CupertinoColors.systemGrey;
    }
    if (widget.transaction.sentSuccessfully) {
      return CupertinoColors.systemGreen;
    }
    return CupertinoColors.systemRed;
  }

  IconData _getStatusIcon() {
    if (!widget.transaction.sentTo1c) {
      return CupertinoIcons.clock;
    }
    if (widget.transaction.sentSuccessfully) {
      return CupertinoIcons.checkmark_circle_fill;
    }
    return CupertinoIcons.xmark_circle_fill;
  }

  String _getStatusText() {
    if (!widget.transaction.sentTo1c) {
      return 'Не отправлено';
    }
    if (widget.transaction.sentSuccessfully) {
      return 'Отправлено';
    }
    return 'Ошибка';
  }

  Future<void> _sendTo1C() async {
    // Показываем диалог для ввода Client ID
    _clientIdController.text = widget.transaction.guest.id.toString();

    final result = await showCupertinoDialog<bool>(
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

    if (result != true) return;

    final clientId = _clientIdController.text.trim();
    // Проверяем, что строка состоит только из цифр
    if (clientId.isEmpty || !RegExp(r'^\d+$').hasMatch(clientId)) {
      _showError('Введите корректный Client ID (только цифры)');
      return;
    }

    setState(() => _isSending = true);
    try {
      final useCase = SendTransactionTo1CUseCase(ApiClient.instance);
      await useCase.call(widget.transaction, clientId);

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Успешно'),
            content: const Text('Транзакция отправлена в 1С'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); // Возвращаемся к списку транзакций
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Не удалось отправить транзакцию в 1С: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
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

  void _navigateToEdit() async {
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (_) => TransactionEditScreen(transaction: widget.transaction),
      ),
    );
    if (result == true && mounted) {
      // Обновляем экран после редактирования
      Navigator.of(context).pop();
    }
  }
}