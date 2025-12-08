import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/settings/transactions/transactions_screen.dart';

class TransactionsFiltersScreen extends StatefulWidget {
  final PaymentFilter paymentFilter;
  final Status1CFilter status1CFilter;
  final int? selectedBuilding;
  final List<int> availableBuildings;

  const TransactionsFiltersScreen({
    super.key,
    required this.paymentFilter,
    required this.status1CFilter,
    required this.selectedBuilding,
    required this.availableBuildings,
  });

  @override
  State<TransactionsFiltersScreen> createState() => _TransactionsFiltersScreenState();
}

class _TransactionsFiltersScreenState extends State<TransactionsFiltersScreen> {
  late PaymentFilter _paymentFilter;
  late Status1CFilter _status1CFilter;
  late int? _selectedBuilding;

  @override
  void initState() {
    super.initState();
    _paymentFilter = widget.paymentFilter;
    _status1CFilter = widget.status1CFilter;
    _selectedBuilding = widget.selectedBuilding;
  }

  void _resetFilters() {
    setState(() {
      _paymentFilter = PaymentFilter.all;
      _status1CFilter = Status1CFilter.all;
      _selectedBuilding = null;
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop({
      'payment': _paymentFilter,
      'status': _status1CFilter,
      'building': _selectedBuilding,
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Транзакции',
        middle: const Text('Фильтры'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _resetFilters,
          child: const Text(
            'Сбросить',
            style: TextStyle(fontSize: 17),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  CupertinoFormSection.insetGrouped(
                    header: const Text('СПОСОБ ОПЛАТЫ'),
                    children: PaymentFilter.values.map((filter) {
                      return CupertinoListTile(
                        title: Text(filter.label),
                        trailing: _paymentFilter == filter
                            ? const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: CupertinoColors.activeBlue,
                              )
                            : null,
                        onTap: () => setState(() => _paymentFilter = filter),
                      );
                    }).toList(),
                  ),
                  CupertinoFormSection.insetGrouped(
                    header: const Text('СТАТУС ОТПРАВКИ В 1С'),
                    children: Status1CFilter.values.map((filter) {
                      return CupertinoListTile(
                        title: Text(filter.label),
                        trailing: _status1CFilter == filter
                            ? const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: CupertinoColors.activeBlue,
                              )
                            : null,
                        onTap: () => setState(() => _status1CFilter = filter),
                      );
                    }).toList(),
                  ),
                  if (widget.availableBuildings.isNotEmpty)
                    CupertinoFormSection.insetGrouped(
                      header: const Text('КОРПУС'),
                      children: [
                        CupertinoListTile(
                          title: const Text('Все корпуса'),
                          trailing: _selectedBuilding == null
                              ? const Icon(
                                  CupertinoIcons.checkmark_alt,
                                  color: CupertinoColors.activeBlue,
                                )
                              : null,
                          onTap: () => setState(() => _selectedBuilding = null),
                        ),
                        ...widget.availableBuildings.map((building) {
                          return CupertinoListTile(
                            title: Text('Корпус $building'),
                            trailing: _selectedBuilding == building
                                ? const Icon(
                                    CupertinoIcons.checkmark_alt,
                                    color: CupertinoColors.activeBlue,
                                  )
                                : null,
                            onTap: () => setState(() => _selectedBuilding = building),
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
            // Кнопка применить внизу
            Padding(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _applyFilters,
                    child: const Text('Применить фильтры'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
