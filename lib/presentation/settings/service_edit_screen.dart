import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:motel/core/api/api_client.dart';
// --- ИСПРАВЛЕНИЕ ЗДЕСЬ: Добавлен недостающий импорт ---
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
  // Теперь эта строка корректна, так как класс ServiceRemoteDataSourceImpl импортирован
  final ServiceRepository _repository = ServiceRepositoryImpl(remoteDataSource: ServiceRemoteDataSourceImpl(apiClient: ApiClient.instance));
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late bool _isOneTime;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.serviceName);
    _priceController = TextEditingController(text: widget.service?.servicePrice?.toString() ?? '');
    _isOneTime = widget.service?.serviceOneTime ?? true;
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
      final price = int.tryParse(_priceController.text);

      final bool success;
      if(widget.isEditing) {
        success = await _repository.updateService(
            serviceID: widget.service!.serviceID,
            name: name,
            price: price,
            isOneTime: _isOneTime
        );
      } else {
        success = await _repository.createService(
            name: name,
            price: price,
            isOneTime: _isOneTime
        );
      }

      if(mounted) {
        if(success) {
          Navigator.of(context).pop(true);
        } else {
          _showErrorDialog('Не удалось сохранить услугу.');
        }
      }
    });
  }

  Future<void> _onDelete() async {
    final confirmed = await _showConfirmationDialog(
        'Удалить услугу?', 'Это действие нельзя будет отменить.'
    );
    if(confirmed != true) return;

    await _runBusy(() async {
      final success = await _repository.deleteService(serviceID: widget.service!.serviceID);
      if(mounted) {
        if(success) {
          // Выходим с результатом `true`, чтобы список обновился
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
                  child: const Text('Сохранить', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            validator: (value) => (value?.isEmpty ?? true) ? 'Название не может быть пустым' : null,
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
                        header: const Text('ПАРАМЕТРЫ'),
                        children: [
                          CupertinoListTile(
                            title: const Text('Разовая услуга'),
                            trailing: CupertinoSwitch(
                              value: _isOneTime,
                              onChanged: (value) => setState(() => _isOneTime = value),
                            ),
                          ),
                        ],
                      ),
                      if(widget.isEditing)
                        CupertinoListSection.insetGrouped(
                            children: [
                              CupertinoListTile(
                                title: const Text('Удалить услугу', style: TextStyle(color: CupertinoColors.systemRed)),
                                onTap: _isBusy ? null : _onDelete,
                              ),
                            ]
                        )
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
          CupertinoDialogAction(child: const Text('Отмена'), onPressed: () => Navigator.of(ctx).pop(false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('Удалить'), onPressed: () => Navigator.of(ctx).pop(true)),
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
        actions: [CupertinoDialogAction(child: const Text('OK'), isDefaultAction: true, onPressed: () => Navigator.of(ctx).pop())],
      ),
    );
  }
}