// ============================================
// lib/presentation/settings/services/service_edit_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/data/datasources/service_remote_data_source.dart';
import 'package:motel/data/repositories/service_repository_impl.dart';
import 'package:motel/domain/entities/service_entity.dart';
import 'package:motel/domain/repositories/service_repository.dart';

class ServiceEditScreen extends StatefulWidget {
  final ServiceEntity? service;
  const ServiceEditScreen({super.key, this.service});

  bool get isEditing => service != null;

  @override
  State<ServiceEditScreen> createState() => _ServiceEditScreenState();
}

class _ServiceEditScreenState extends State<ServiceEditScreen> {
  final ServiceRepository _repository = ServiceRepositoryImpl(
      remoteDataSource: ServiceRemoteDataSourceImpl(apiClient: ApiClient.instance));
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late int _tax;
  late bool _isCountable;
  late bool _isDuration;
  bool _isBusy = false;

  // Доступные варианты налога
  final List<int> _availableTaxes = [0, 5, 7, 10, 18, 20];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name);
    _priceController = TextEditingController(
      text: widget.service != null ? (widget.service!.price ~/ 100).toString() : ''
    );
    _tax = widget.service?.tax ?? 20;
    _isCountable = widget.service?.isCountable ?? false;
    _isDuration = widget.service?.isDuration ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _runBusy(Future<void> Function() operation) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await operation();
    } catch (e) {
      if (mounted) _showErrorDialog('Произошла ошибка: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    await _runBusy(() async {
      final name = _nameController.text;
      final priceInRubles = int.tryParse(_priceController.text);
      final price = priceInRubles != null ? priceInRubles * 100 : null;

      final bool success;
      if (widget.isEditing) {
        success = await _repository.updateService(
            serviceID: widget.service!.id.toString(),
            name: name,
            price: price,
            tax: _tax,
            isCountable: _isCountable,
            isDuration: _isDuration);
      } else {
        success = await _repository.createService(
            name: name,
            price: price,
            tax: _tax,
            isCountable: _isCountable,
            isDuration: _isDuration);
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          _showErrorDialog('Не удалось сохранить услугу.');
        }
      }
    });
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
              initialItem: _availableTaxes.indexOf(_tax),
            ),
            onSelectedItemChanged: (int selectedItem) {
              setState(() {
                _tax = _availableTaxes[selectedItem];
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

  Future<void> _onDelete() async {
    final confirmed = await _showConfirmationDialog(
        'Удалить услугу?', 'Это действие нельзя будет отменить.');
    if (confirmed != true) return;

    await _runBusy(() async {
      final success =
          await _repository.deleteService(serviceID: widget.service!.id.toString());
      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          _showErrorDialog('Не удалось удалить услугу.');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text(widget.isEditing ? 'Редактирование' : 'Новая услуга'),
                previousPageTitle: 'Услуги',
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isBusy ? null : _onSave,
                  child: const Text('Сохранить',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CupertinoFormSection.insetGrouped(
                        header: const Text('ИНФОРМАЦИЯ'),
                        children: [
                          CupertinoTextFormFieldRow(
                            controller: _nameController,
                            prefix: const Text('Название'),
                            placeholder: 'Например, Стирка',
                            validator: (value) => (value?.isEmpty ?? true)
                                ? 'Название не может быть пустым'
                                : null,
                          ),
                          CupertinoTextFormFieldRow(
                            controller: _priceController,
                            prefix: const Text('Цена (₽)'),
                            placeholder: 'Например, 500',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ],
                      ),
                      CupertinoFormSection.insetGrouped(
                        header: const Text('НАЛОГ'),
                        children: [
                          CupertinoListTile(
                            title: const Text('Ставка налога'),
                            trailing: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _showTaxPicker(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$_tax%',
                                    style: const TextStyle(color: CupertinoColors.activeBlue),
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
                        header: const Text('ПАРАМЕТРЫ'),
                        children: [
                          CupertinoListTile(
                            title: const Text('Можно задать количество'),
                            subtitle: const Text('Пользователь сможет выбрать количество единиц'),
                            trailing: CupertinoSwitch(
                              value: _isCountable,
                              onChanged: (value) => setState(() {
                                _isCountable = value;
                                if (value) _isDuration = false;
                              }),
                            ),
                          ),
                          CupertinoListTile(
                            title: const Text('Услуга на количество дней'),
                            subtitle: const Text('Пользователь сможет выбрать количество дней'),
                            trailing: CupertinoSwitch(
                              value: _isDuration,
                              onChanged: (value) => setState(() {
                                _isDuration = value;
                                if (value) _isCountable = false;
                              }),
                            ),
                          ),
                        ],
                      ),
                      if (widget.isEditing)
                        CupertinoListSection.insetGrouped(children: [
                          CupertinoListTile(
                            title: const Text('Удалить услугу',
                                style: TextStyle(color: CupertinoColors.systemRed)),
                            onTap: _isBusy ? null : _onDelete,
                          ),
                        ])
                    ],
                  ),
                ),
              )
            ],
          ),
          if (_isBusy)
            Container(
              color: CupertinoColors.black.withOpacity(0.4),
              child: const Center(child: CupertinoActivityIndicator(radius: 20)),
            ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(String title, String content) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
              child: const Text('Отмена'),
              onPressed: () => Navigator.of(ctx).pop(false)),
          CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Удалить'),
              onPressed: () => Navigator.of(ctx).pop(true)),
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
              child: const Text('OK'),
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop())
        ],
      ),
    );
  }
}
