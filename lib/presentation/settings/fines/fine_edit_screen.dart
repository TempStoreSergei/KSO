// ============================================
// lib/presentation/settings/fines/fine_edit_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/fine_models.dart';
import 'package:motel/domain/usecases/add_fine.dart';
import 'package:motel/domain/usecases/update_fine.dart';

class FineEditScreen extends StatefulWidget {
  final Fine? fine;

  const FineEditScreen({super.key, this.fine});

  @override
  State<FineEditScreen> createState() => _FineEditScreenState();
}

class _FineEditScreenState extends State<FineEditScreen> {
  final _addFineUseCase = AddFineUseCase(ApiClient.instance);
  final _updateFineUseCase = UpdateFineUseCase(ApiClient.instance);

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _codeController;
  FineType _selectedType = FineType.violationRules;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fine?.name ?? '');
    _priceController = TextEditingController(
      text: widget.fine != null ? (widget.fine!.price ~/ 100).toString() : '',
    );
    _codeController = TextEditingController(text: widget.fine?.code ?? '');
    if (widget.fine != null) {
      _selectedType = widget.fine!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _priceController.text.trim().isNotEmpty &&
        int.tryParse(_priceController.text.trim()) != null &&
        _codeController.text.trim().isNotEmpty;
  }

  Future<void> _saveFine() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.fine != null;

      if (isEditing) {
        final request = UpdateFineRequest(
          id: widget.fine!.id,
          name: _nameController.text.trim(),
          price: int.parse(_priceController.text.trim()) * 100,
          type: _selectedType,
          code: _codeController.text.trim(),
        );
        await _updateFineUseCase.execute(request);
      } else {
        final request = CreateFineRequest(
          name: _nameController.text.trim(),
          price: int.parse(_priceController.text.trim()) * 100,
          type: _selectedType,
          code: _codeController.text.trim(),
        );
        await _addFineUseCase.execute(request);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Возвращаем true для обновления списка
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Ошибка сохранения штрафа: $e');
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

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.fine != null;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(isEditing ? 'Редактировать штраф' : 'Новый штраф'),
        previousPageTitle: 'Штрафы',
        trailing: _isLoading
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isFormValid ? _saveFine : null,
                child: Text(
                  'Сохранить',
                  style: TextStyle(
                    color: _isFormValid
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: CupertinoListSection.insetGrouped(
                header: const Text('ИНФОРМАЦИЯ'),
                children: [
                  // Название
                  CupertinoListTile(
                    title: const Text('Название'),
                    additionalInfo: SizedBox(
                      width: 200,
                      child: CupertinoTextField(
                        controller: _nameController,
                        placeholder: 'Введите название',
                        textAlign: TextAlign.end,
                        decoration: null,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),

                  // Цена
                  CupertinoListTile(
                    title: const Text('Сумма штрафа'),
                    additionalInfo: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 100,
                          child: CupertinoTextField(
                            controller: _priceController,
                            placeholder: '0',
                            textAlign: TextAlign.end,
                            decoration: null,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('₽', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),

                  // Код
                  CupertinoListTile(
                    title: const Text('Код'),
                    additionalInfo: SizedBox(
                      width: 200,
                      child: CupertinoTextField(
                        controller: _codeController,
                        placeholder: 'FINE_001',
                        textAlign: TextAlign.end,
                        decoration: null,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Тип штрафа
            SliverToBoxAdapter(
              child: CupertinoListSection.insetGrouped(
                header: const Text('ТИП ШТРАФА'),
                children: [
                  CupertinoListTile(
                    title: const Text('Нарушение правил'),
                    trailing: _selectedType == FineType.violationRules
                        ? const Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: CupertinoColors.activeBlue,
                          )
                        : const Icon(
                            CupertinoIcons.circle,
                            color: CupertinoColors.systemGrey3,
                          ),
                    onTap: () {
                      setState(() {
                        _selectedType = FineType.violationRules;
                      });
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Порча имущества'),
                    trailing: _selectedType == FineType.damageToProperty
                        ? const Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: CupertinoColors.activeBlue,
                          )
                        : const Icon(
                            CupertinoIcons.circle,
                            color: CupertinoColors.systemGrey3,
                          ),
                    onTap: () {
                      setState(() {
                        _selectedType = FineType.damageToProperty;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
