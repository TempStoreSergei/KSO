import 'package:flutter/cupertino.dart';
import 'package:motel/core/services/tax_settings_service.dart';

class TaxSettingsScreen extends StatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  State<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends State<TaxSettingsScreen> {
  // Доступные варианты налога
  final List<int> _availableTaxes = [0, 5, 7, 10, 18, 20];
  int _defaultAccommodationTax = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final tax = await TaxSettingsService.getDefaultAccommodationTax();
      if (mounted) {
        setState(() {
          _defaultAccommodationTax = tax;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Ошибка загрузки настроек: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      await TaxSettingsService.setDefaultAccommodationTax(_defaultAccommodationTax);
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Ошибка сохранения настроек: $e');
      }
    }
  }

  void _showTaxPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32.0,
            scrollController: FixedExtentScrollController(
              initialItem: _availableTaxes.indexOf(_defaultAccommodationTax),
            ),
            onSelectedItemChanged: (int selectedItem) {
              setState(() {
                _defaultAccommodationTax = _availableTaxes[selectedItem];
              });
            },
            children: _availableTaxes.map((int tax) {
              return Center(
                child: Text(
                  '$tax%',
                  style: const TextStyle(fontSize: 22.0),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Успешно'),
        content: const Text('Настройки сохранены'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          )
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
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Налоговые настройки'),
            previousPageTitle: 'Настройки',
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _isLoading ? null : _saveSettings,
              child: const Text(
                'Сохранить',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CupertinoActivityIndicator(radius: 20),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Column(
                children: [
                  CupertinoFormSection.insetGrouped(
                    header: const Text('ПРОЖИВАНИЕ'),
                    footer: const Text(
                      'Налоговая ставка применяется к услуге "Предоставление койко-мест для временного размещения" когда дополнительные услуги не выбраны.',
                    ),
                    children: [
                      CupertinoListTile(
                        title: const Text('Ставка налога по умолчанию'),
                        subtitle: const Text('Для размещения без услуг'),
                        trailing: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _showTaxPicker,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_defaultAccommodationTax%',
                                style: const TextStyle(
                                  color: CupertinoColors.activeBlue,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                CupertinoIcons.chevron_down,
                                size: 16,
                                color: CupertinoColors.activeBlue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  CupertinoFormSection.insetGrouped(
                    header: const Text('ИНФОРМАЦИЯ'),
                    children: [
                      CupertinoListTile(
                        title: const Text('Доступные ставки налога'),
                        subtitle: Text(
                          _availableTaxes.map((t) => '$t%').join(', '),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
