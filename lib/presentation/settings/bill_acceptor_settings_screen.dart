// lib/presentation/settings/bill_acceptor_settings_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

// Импорт API client и исключений
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/api/api_exceptions.dart';

// Модели данных для купюроприемника
class CassetteData {
  final String cassetteID;
  final int value;
  final bool cassetteIsSelected;

  CassetteData({
    required this.cassetteID,
    required this.value,
    required this.cassetteIsSelected,
  });

  factory CassetteData.fromJson(Map<String, dynamic> json) {
    return CassetteData(
      cassetteID: json['casseteID'] ?? '',
      value: json['value'] ?? 0,
      cassetteIsSelected: json['casseteIsSelected'] ?? false,
    );
  }
}

class BillAcceptorStatus {
  final int currentCount;
  final int maxCount;
  final double fillPercentage;

  BillAcceptorStatus({
    required this.currentCount,
    required this.maxCount,
    required this.fillPercentage,
  });

  factory BillAcceptorStatus.fromJson(Map<String, dynamic> json) {
    final billAcceptorData = json['billAcceptorData'] ?? {};
    final current = billAcceptorData['billCount'] ?? 0;
    final max = billAcceptorData['maxBillCount'] ?? 1;
    return BillAcceptorStatus(
      currentCount: current,
      maxCount: max,
      fillPercentage: max > 0 ? (current / max * 100) : 0,
    );
  }
}

// Use Cases для купюроприемника
class BillAcceptorUseCases {
  final ApiClient _apiClient;

  BillAcceptorUseCases(this._apiClient);

  Future<List<CassetteData>> getAllCassettes() async {
    final response = await _apiClient.get('/settings/get_all_cassetes_bill_acceptor');
    final List<dynamic> cassetesData = response['cassetesData'] ?? [];
    return cassetesData.map((json) => CassetteData.fromJson(json)).toList();
  }

  Future<void> selectCassette(String cassetteID) async {
    await _apiClient.put(
      '/settings/update_selected_cassete_bill_acceptor',
      body: {'casseteID': cassetteID},
    );
  }

  Future<void> updateMaxCount(int value) async {
    await _apiClient.put(
      '/settings/update_bill_acceptor_set_max_count',
      body: {'value': value},
    );
  }

  Future<BillAcceptorStatus> getStatus() async {
    final response = await _apiClient.get('/settings/get_bill_acceptor_status');
    return BillAcceptorStatus.fromJson(response);
  }

  Future<void> resetCount() async {
    await _apiClient.get('/settings/reset_bill_acceptor_count');
  }
}

/// Основной экран настроек купюроприемника
class BillAcceptorSettingsScreen extends StatelessWidget {
  const BillAcceptorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BillAcceptorUseCases useCases = BillAcceptorUseCases(ApiClient.instance);

    return Provider.value(
      value: useCases,
      child: const _BillAcceptorSettingsView(),
    );
  }
}

class _BillAcceptorSettingsView extends StatefulWidget {
  const _BillAcceptorSettingsView();

  @override
  State<_BillAcceptorSettingsView> createState() => _BillAcceptorSettingsViewState();
}

class _BillAcceptorSettingsViewState extends State<_BillAcceptorSettingsView> {
  List<CassetteData> _cassettes = [];
  BillAcceptorStatus? _status;
  bool _isLoading = false;
  int _customMaxCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final useCases = Provider.of<BillAcceptorUseCases>(context, listen: false);
      final cassettes = await useCases.getAllCassettes();
      final status = await useCases.getStatus();

      setState(() {
        _cassettes = cassettes;
        _status = status;
        _customMaxCount = status.maxCount;
      });
    } catch (e) {
      _showErrorDialog('Ошибка загрузки данных: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectCassette(String cassetteID) async {
    try {
      final useCases = Provider.of<BillAcceptorUseCases>(context, listen: false);

      // Сначала выбираем кассету
      await useCases.selectCassette(cassetteID);

      // Находим выбранную кассету и устанавливаем ее максимальный объем как пользовательский лимит
      final selectedCassette = _cassettes.firstWhere((c) => c.cassetteID == cassetteID);

      // Затем обновляем лимит на сервере
      await useCases.updateMaxCount(selectedCassette.value - 1);

      setState(() {
        _customMaxCount = selectedCassette.value;
      });

      await _loadData(); // Перезагружаем данные
      _showSuccessDialog('Кассета выбрана');
    } catch (e) {
      _showErrorDialog('Ошибка выбора кассеты: ${e.toString()}');
    }
  }

  Future<void> _updateMaxCount() async {
    // Проверяем лимиты выбранной кассеты
    final selectedCassette = _cassettes.firstWhere(
          (c) => c.cassetteIsSelected,
      orElse: () => CassetteData(cassetteID: '', value: 0, cassetteIsSelected: false),
    );

    if (_customMaxCount > selectedCassette.value) {
      _showErrorDialog('Значение не может превышать максимальную вместимость кассеты (${selectedCassette.value})');
      return;
    }

    if (_customMaxCount <= 0) {
      _showErrorDialog('Значение должно быть больше 0');
      return;
    }

    try {
      final useCases = Provider.of<BillAcceptorUseCases>(context, listen: false);
      await useCases.updateMaxCount(_customMaxCount);
      await _loadData(); // Перезагружаем данные
      _showSuccessDialog('Лимит обновлен');
    } catch (e) {
      _showErrorDialog('Ошибка обновления лимита: ${e.toString()}');
    }
  }

  Future<void> _resetCount() async {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Инкассация'),
        content: const Text('Вы уверены, что хотите произвести инкассацию? Счетчик будет сброшен в ноль.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Инкассировать'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final useCases = Provider.of<BillAcceptorUseCases>(context, listen: false);
                await useCases.resetCount();
                await _loadData();
                _showSuccessDialog('Инкассация выполнена');
              } catch (e) {
                _showErrorDialog('Ошибка инкассации: ${e.toString()}');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showMaxCountPicker() {
    final selectedCassette = _cassettes.firstWhere(
          (c) => c.cassetteIsSelected,
      orElse: () => CassetteData(cassetteID: '', value: 1000, cassetteIsSelected: false),
    );

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: const Border(
                  bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Отмена'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Лимит купюр',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    child: const Text('Готово'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateMaxCount();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: _customMaxCount - 1,
                ),
                onSelectedItemChanged: (index) {
                  setState(() => _customMaxCount = index + 1);
                },
                children: List.generate(selectedCassette.value, (index) {
                  return Center(child: Text('${index + 1}'));
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Простая полоса загрузки с данными
  Widget _buildStatusSection() {
    final fillPercentage = _status?.fillPercentage ?? 0;
    final currentCount = _status?.currentCount ?? 0;
    final maxCount = _status?.maxCount ?? 0;

    return CupertinoListSection.insetGrouped(
      header: const Text('ТЕКУЩЕЕ СОСТОЯНИЕ'),
      children: [
        CupertinoListTile(
          title: const Text('Заполнение'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                '$currentCount / $maxCount купюр',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(height: 8),
              // Полоса прогресса
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fillPercentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getFillColor(fillPercentage),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getFillColor(double percentage) {
    if (percentage < 50) return CupertinoColors.activeGreen;
    if (percentage < 80) return CupertinoColors.systemOrange;
    return CupertinoColors.systemRed;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCassette = _cassettes.firstWhere(
          (c) => c.cassetteIsSelected,
      orElse: () => CassetteData(cassetteID: '', value: 0, cassetteIsSelected: false),
    );

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Купюроприемник'),
            previousPageTitle: 'Настройки',
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CupertinoActivityIndicator(radius: 20),
                ),
              ),
            )
          else
            SliverMainAxisGroup(
              slivers: [
                // Статус заполнения
                SliverToBoxAdapter(
                  child: _buildStatusSection(),
                ),

                // Выбор кассеты
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('ВЫБОР КАССЕТЫ'),
                    footer: const Text('Выберите кассету с нужной вместимостью для использования.'),
                    children: _cassettes.map((cassette) {
                      return CupertinoListTile(
                        title: Text('Кассета ${cassette.value} купюр'),
                        trailing: cassette.cassetteIsSelected
                            ? const Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: CupertinoColors.activeBlue,
                        )
                            : const Icon(
                          CupertinoIcons.circle,
                          color: CupertinoColors.systemGrey,
                        ),
                        onTap: () => _selectCassette(cassette.cassetteID),
                      );
                    }).toList(),
                  ),
                ),

                // Настройки лимита
                if (selectedCassette.cassetteIsSelected)
                  SliverToBoxAdapter(
                    child: CupertinoListSection.insetGrouped(
                      header: const Text('НАСТРОЙКИ ЛИМИТА'),
                      footer: Text(
                        'Установите пользовательский лимит, не превышающий максимальную вместимость выбранной кассеты (${selectedCassette.value} купюр).',
                      ),
                      children: [
                        CupertinoListTile(
                          title: const Text('Пользовательский лимит'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_customMaxCount',
                                style: const TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const CupertinoListTileChevron(),
                            ],
                          ),
                          onTap: _showMaxCountPicker,
                        ),
                      ],
                    ),
                  ),

                // Действия
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('ДЕЙСТВИЯ'),
                    children: [
                      CupertinoListTile(
                        title: const Text(
                          'Инкассация',
                          style: TextStyle(color: CupertinoColors.systemRed),
                        ),
                        leading: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.money_dollar_circle,
                            color: CupertinoColors.white,
                            size: 20,
                          ),
                        ),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _resetCount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Успешно'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}