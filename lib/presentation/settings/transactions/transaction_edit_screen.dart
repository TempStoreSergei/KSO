import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/entities/transaction.dart';
import 'package:motel/domain/usecases/update_transaction_usecase.dart';

class TransactionEditScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionEditScreen({super.key, required this.transaction});

  @override
  State<TransactionEditScreen> createState() => _TransactionEditScreenState();
}

class _TransactionEditScreenState extends State<TransactionEditScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _surnameController;
  late TextEditingController _roomNumberController;
  late TextEditingController _buildingController;
  late String _selectedRoomType;

  bool _isSaving = false;

  final Map<String, String> _roomTypeMap = {
    'fourBed': '4 места',
    'sixBed': '6 мест',
    'eightBed': '8 мест',
  };

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.transaction.guest.firstName);
    _lastNameController = TextEditingController(text: widget.transaction.guest.lastName);
    _surnameController = TextEditingController(text: widget.transaction.guest.surname);
    _roomNumberController = TextEditingController(text: widget.transaction.room.number);
    _buildingController = TextEditingController(text: widget.transaction.room.building.toString());
    _selectedRoomType = widget.transaction.room.type;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    _roomNumberController.dispose();
    _buildingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Редактирование'),
            previousPageTitle: 'Транзакция',
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const CupertinoActivityIndicator()
                  : const Text('Сохранить'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildGuestSection(),
                  const SizedBox(height: 16),
                  _buildRoomSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('ИНФОРМАЦИЯ О ГОСТЕ'),
      children: [
        CupertinoListTile(
          title: const Text('Фамилия'),
          additionalInfo: SizedBox(
            width: 200,
            child: CupertinoTextField(
              controller: _lastNameController,
              textAlign: TextAlign.end,
              placeholder: 'Фамилия',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Имя'),
          additionalInfo: SizedBox(
            width: 200,
            child: CupertinoTextField(
              controller: _firstNameController,
              textAlign: TextAlign.end,
              placeholder: 'Имя',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Отчество'),
          additionalInfo: SizedBox(
            width: 200,
            child: CupertinoTextField(
              controller: _surnameController,
              textAlign: TextAlign.end,
              placeholder: 'Отчество',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('ИНФОРМАЦИЯ О КОМНАТЕ'),
      children: [
        CupertinoListTile(
          title: const Text('Номер комнаты'),
          additionalInfo: SizedBox(
            width: 150,
            child: CupertinoTextField(
              controller: _roomNumberController,
              textAlign: TextAlign.end,
              placeholder: '000-0',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Тип'),
          additionalInfo: GestureDetector(
            onTap: _showRoomTypePicker,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _roomTypeMap[_selectedRoomType] ?? _selectedRoomType,
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.chevron_up_chevron_down,
                  size: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ],
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Корпус'),
          additionalInfo: SizedBox(
            width: 100,
            child: CupertinoTextField(
              controller: _buildingController,
              textAlign: TextAlign.end,
              placeholder: '1',
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  void _showRoomTypePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: const Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      child: const Text('Готово'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedRoomType = _roomTypeMap.keys.elementAt(index);
                    });
                  },
                  scrollController: FixedExtentScrollController(
                    initialItem: _roomTypeMap.keys.toList().indexOf(_selectedRoomType),
                  ),
                  children: _roomTypeMap.values
                      .map((value) => Center(child: Text(value)))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    // Валидация
    if (_firstNameController.text.trim().isEmpty) {
      _showError('Введите имя гостя');
      return;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showError('Введите фамилию гостя');
      return;
    }
    if (_roomNumberController.text.trim().isEmpty) {
      _showError('Введите номер комнаты');
      return;
    }

    final building = int.tryParse(_buildingController.text.trim());
    if (building == null) {
      _showError('Некорректный номер корпуса');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final useCase = UpdateTransactionUseCase(ApiClient.instance);
      await useCase.call(
        id: widget.transaction.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        surname: _surnameController.text.trim(),
        roomNumber: _roomNumberController.text.trim(),
        roomType: _selectedRoomType,
        building: building,
      );

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Успешно'),
            content: const Text('Изменения сохранены'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); // Возвращаемся к деталям транзакции
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Не удалось сохранить изменения: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
}