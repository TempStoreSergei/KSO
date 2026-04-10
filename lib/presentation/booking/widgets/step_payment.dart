// ============================================
// lib/presentation/booking/widgets/step_payment.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/system_settings.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

const String _cardPaymentMethod = 'Карта';
const String _sbpPaymentMethod = 'СБП';
const String _cashPaymentMethod = 'Наличные';

class StepPayment extends StatefulWidget {
  final String? selectedMethod;
  final ValueChanged<String?> onMethodSelected;
  final int totalPrice;

  const StepPayment({super.key, this.selectedMethod, required this.onMethodSelected, required this.totalPrice});

  @override
  State<StepPayment> createState() => _StepPaymentState();
}

class _StepPaymentState extends State<StepPayment> {
  bool _isLoadingMethods = true;
  bool _isAcquiringEnabled = true;
  bool _isSbpEnabled = false;
  bool _isCashSystemEnabled = true;
  bool _canGiveChange = true;
  String? _changeErrorMessage;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void didUpdateWidget(covariant StepPayment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalPrice != widget.totalPrice) {
      _loadPaymentMethods();
    }
  }

  Future<void> _loadPaymentMethods() async {
    final requestVersion = ++_requestVersion;

    if (widget.selectedMethod != null) {
      widget.onMethodSelected(null);
    }

    if (mounted) {
      setState(() {
        _isLoadingMethods = true;
      });
    }

    try {
      final response = await ApiClient.instance.get('/system/get_system_settings');
      final settings = SystemSettings.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      final cashAvailability = settings.devices.cashSystem
          ? await _fetchCashAvailability()
          : const _CashAvailabilityResult(
              canGiveChange: false,
              errorMessage: null,
            );

      if (!_isCurrentRequest(requestVersion)) {
        return;
      }

      setState(() {
        _isLoadingMethods = false;
        _isAcquiringEnabled = settings.devices.acquiring;
        _isSbpEnabled = settings.sbpPayment.isEnable;
        _isCashSystemEnabled = settings.devices.cashSystem;
        _canGiveChange = settings.devices.cashSystem ? cashAvailability.canGiveChange : false;
        _changeErrorMessage = cashAvailability.errorMessage;
      });

      _clearInvalidSelection();
    } catch (e) {
      final cashAvailability = await _fetchCashAvailability();

      if (!_isCurrentRequest(requestVersion)) {
        return;
      }

      setState(() {
        _isLoadingMethods = false;
        _isAcquiringEnabled = true;
        _isSbpEnabled = false;
        _isCashSystemEnabled = true;
        _canGiveChange = cashAvailability.canGiveChange;
        _changeErrorMessage = cashAvailability.errorMessage;
      });

      _clearInvalidSelection();
    }
  }

  bool _isCurrentRequest(int requestVersion) => mounted && requestVersion == _requestVersion;

  void _clearInvalidSelection() {
    final selectedMethod = widget.selectedMethod;
    if (selectedMethod == null) {
      return;
    }
    if (!_isMethodSelectable(selectedMethod)) {
      widget.onMethodSelected(null);
    }
  }

  Future<_CashAvailabilityResult> _fetchCashAvailability() async {
    try {
      final response = await ApiClient.instance.get('/cash_system/bill_dispenser/status');
      final upperBoxValue = response['upperBoxValue'] as int; // в копейках
      final upperBoxCount = response['upperBoxCount'] as int;
      final lowerBoxValue = response['lowerBoxValue'] as int; // в копейках
      final lowerBoxCount = response['lowerBoxCount'] as int;

      // Проверяем можем ли выдать сдачу для любой возможной суммы оплаты
      final canGive = _canMakeChange(
        widget.totalPrice,
        upperBoxValue,
        upperBoxCount,
        lowerBoxValue,
        lowerBoxCount,
      );

      return _CashAvailabilityResult(
        canGiveChange: canGive,
        errorMessage: canGive
            ? null
            : 'Оплата наличными недоступна — невозможно выдать сдачу. Используйте безналичную оплату или обратитесь к администратору',
      );
    } catch (e) {
      // Если не удалось проверить, разрешаем оплату наличными
      return const _CashAvailabilityResult(
        canGiveChange: true,
        errorMessage: null,
      );
    }
  }

  List<Widget> _buildPaymentMethodRows() {
    final rows = <Widget>[];

    void addRow(Widget row) {
      if (rows.isNotEmpty) {
        rows.add(
          const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Divider(height: 1, color: Color(0xFF2C2C2E)),
          ),
        );
      }
      rows.add(row);
    }

    if (_isAcquiringEnabled) {
      addRow(
        _buildMethodRow(
          title: 'Банковская карта (Эквайринг)',
          subtitle: 'Оплата через терминал Visa, MasterCard, Мир',
          icon: CupertinoIcons.creditcard_fill,
          isSelected: widget.selectedMethod == _cardPaymentMethod,
          onTap: () => widget.onMethodSelected(_cardPaymentMethod),
        ),
      );
    }

    if (_isSbpEnabled) {
      addRow(
        _buildMethodRow(
          title: 'СБП',
          subtitle: 'Оплата по QR-коду через систему быстрых платежей',
          icon: CupertinoIcons.qrcode,
          isSelected: widget.selectedMethod == _sbpPaymentMethod,
          onTap: () => widget.onMethodSelected(_sbpPaymentMethod),
        ),
      );
    }

    if (_isCashSystemEnabled) {
      addRow(
        _buildMethodRow(
          title: 'Наличные',
          subtitle: _canGiveChange
              ? 'Оплата наличными через купюроприемник'
              : _changeErrorMessage ?? 'Недоступно',
          icon: CupertinoIcons.money_dollar_circle_fill,
          isSelected: widget.selectedMethod == _cashPaymentMethod,
          onTap: () => widget.onMethodSelected(_cashPaymentMethod),
          isDisabled: !_canGiveChange,
        ),
      );
    }

    return rows;
  }

  bool _isMethodSelectable(String method) {
    switch (method) {
      case _cardPaymentMethod:
        return _isAcquiringEnabled;
      case _sbpPaymentMethod:
        return _isSbpEnabled;
      case _cashPaymentMethod:
        return _isCashSystemEnabled && _canGiveChange;
      default:
        return false;
    }
  }

  bool _canMakeChange(int totalPrice, int upperValue, int upperCount, int lowerValue, int lowerCount) {
    // Если нет купюр в диспенсере, не можем дать сдачу
    if (upperCount == 0 && lowerCount == 0) {
      return false;
    }

    // Номиналы в рублях
    final upperRub = upperValue ~/ 100;
    final lowerRub = lowerValue ~/ 100;
    final totalRub = totalPrice ~/ 100;

    // НОД номиналов определяет минимальную единицу, которую можно собрать
    final gcdValue = _gcd(upperRub, lowerRub);

    // КЛЮЧЕВАЯ ПРОВЕРКА: если сумма к оплате не делится на НОД номиналов,
    // то для ЛЮБОЙ суммы оплаты (которая будет кратна НОД) сдача не будет кратна НОД,
    // а значит её невозможно выдать имеющимися купюрами!
    if (totalRub % gcdValue != 0) {
      return false;
    }

    // Если сумма кратна НОД, проверяем можем ли мы физически собрать сдачу
    // для разумных сумм оплаты (до 2x от суммы)
    final maxPayment = totalRub * 2;

    for (int payment = totalRub + gcdValue; payment <= maxPayment; payment += gcdValue) {
      final change = payment - totalRub;

      // Пробуем собрать эту сдачу имеющимися купюрами
      if (_canMakeExactChange(change, upperRub, upperCount, lowerRub, lowerCount)) {
        return true;
      }
    }
    return false;
  }

  // Вычисление НОД (наибольший общий делитель)
  int _gcd(int a, int b) {
    if (a == 0) return b;
    if (b == 0) return a;
    while (b != 0) {
      int temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }

  bool _canMakeExactChange(int amount, int upperValue, int upperCount, int lowerValue, int lowerCount) {
    // Перебираем все возможные комбинации купюр
    // Для каждого количества крупных купюр проверяем можно ли остаток выдать мелкими
    for (int upper = 0; upper <= upperCount; upper++) {
      int remaining = amount - (upper * upperValue);

      // Если перебор, прекращаем
      if (remaining < 0) break;

      // Если точно выдали крупными
      if (remaining == 0) return true;

      // Проверяем можно ли остаток выдать мелкими купюрами
      if (lowerValue > 0 && remaining % lowerValue == 0) {
        int lower = remaining ~/ lowerValue;
        if (lower <= lowerCount) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodRows = _buildPaymentMethodRows();

    return StepContainer(
      icon: CupertinoIcons.creditcard_fill,
      title: 'Способ оплаты',
      subtitle: 'Выберите удобный способ оплаты',
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // 1. Блок с итоговой стоимостью
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Итоговая стоимость',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${widget.totalPrice ~/ 100} ₽',
                    style: const TextStyle(
                      color: CupertinoColors.activeBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Разделитель
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
            ),

            if (_isLoadingMethods)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CupertinoActivityIndicator(radius: 16),
              )
            else if (paymentMethodRows.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Text(
                  'Нет доступных способов оплаты. Проверьте системные настройки.',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...paymentMethodRows,
          ],
        ),
      ),
    );
  }

  // Вспомогательный виджет для отрисовки одной строки выбора
  Widget _buildMethodRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? CupertinoColors.activeBlue.withValues(alpha: 0.2)
                      : const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDisabled
                      ? CupertinoColors.systemGrey3
                      : (isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDisabled
                            ? CupertinoColors.systemGrey3
                            : (isSelected ? CupertinoColors.white : CupertinoColors.systemGrey),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDisabled ? CupertinoColors.systemGrey3 : CupertinoColors.systemGrey2,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 24,
                child: isSelected
                    ? const Icon(CupertinoIcons.checkmark_circle_fill,
                        color: CupertinoColors.activeBlue, size: 24)
                    : Icon(
                        CupertinoIcons.circle,
                        color: isDisabled ? CupertinoColors.systemGrey4 : CupertinoColors.systemGrey3,
                        size: 24,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashAvailabilityResult {
  final bool canGiveChange;
  final String? errorMessage;

  const _CashAvailabilityResult({
    required this.canGiveChange,
    required this.errorMessage,
  });
}
