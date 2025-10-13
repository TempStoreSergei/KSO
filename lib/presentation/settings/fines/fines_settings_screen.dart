// ============================================
// lib/presentation/settings/fines/fines_settings_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/fine_models.dart';
import 'package:motel/domain/usecases/get_fines.dart';
import 'package:motel/domain/usecases/delete_fine.dart';
import 'package:motel/presentation/settings/fines/fine_edit_screen.dart';

class FinesSettingsScreen extends StatefulWidget {
  const FinesSettingsScreen({super.key});

  @override
  State<FinesSettingsScreen> createState() => _FinesSettingsScreenState();
}

class _FinesSettingsScreenState extends State<FinesSettingsScreen> {
  final _getFinesUseCase = GetFinesUseCase(ApiClient.instance);
  final _deleteFineUseCase = DeleteFineUseCase(ApiClient.instance);

  List<Fine>? _fines;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFines();
  }

  Future<void> _loadFines() async {
    setState(() => _isLoading = true);
    try {
      final fines = await _getFinesUseCase.execute();
      if (mounted) {
        setState(() {
          _fines = fines;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Ошибка загрузки штрафов: $e');
      }
    }
  }

  void _navigateAndReload(Widget screen) async {
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(builder: (_) => screen),
    );
    if (result == true) {
      _loadFines();
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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Штрафы'),
                previousPageTitle: 'Настройки',
              ),
              CupertinoSliverRefreshControl(onRefresh: _loadFines),

              _buildFinesList(),

              // Кнопка добавления штрафа
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  children: [
                    CupertinoListTile(
                      title: const Text(
                        'Добавить штраф',
                        style: TextStyle(color: CupertinoColors.activeBlue),
                      ),
                      leading: const Icon(
                        CupertinoIcons.add_circled_solid,
                        color: CupertinoColors.activeBlue,
                      ),
                      onTap: () => _navigateAndReload(const FineEditScreen()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading && _fines == null)
            const Center(child: CupertinoActivityIndicator(radius: 15)),
        ],
      ),
    );
  }

  Widget _buildFinesList() {
    if (_fines == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_fines!.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'Нажмите "Добавить штраф", чтобы\nсоздать первый штраф.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
        ),
      );
    }

    // Группируем штрафы по типу
    final violationFines = _fines!.where((f) => f.type == FineType.violationRules).toList();
    final damageFines = _fines!.where((f) => f.type == FineType.damageToProperty).toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        if (violationFines.isNotEmpty)
          CupertinoListSection.insetGrouped(
            header: const Text('НАРУШЕНИЕ ПРАВИЛ'),
            children: violationFines.map((fine) => _buildFineItem(fine)).toList(),
          ),
        if (damageFines.isNotEmpty)
          CupertinoListSection.insetGrouped(
            header: const Text('ПОРЧА ИМУЩЕСТВА'),
            children: damageFines.map((fine) => _buildFineItem(fine)).toList(),
          ),
      ]),
    );
  }

  Widget _buildFineItem(Fine fine) {
    return Dismissible(
      key: Key(fine.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showCupertinoDialog<bool>(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('Удалить штраф?'),
                content: Text('Вы уверены, что хотите удалить "${fine.name}"?'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('Отмена'),
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    child: const Text('Удалить'),
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) async {
        // Сначала удаляем из локального списка
        setState(() {
          _fines?.removeWhere((f) => f.id == fine.id);
        });

        // Затем отправляем запрос на сервер
        try {
          await _deleteFineUseCase.execute(fine.id);
        } catch (e) {
          // В случае ошибки показываем сообщение и перезагружаем список
          if (mounted) {
            _showError('Ошибка удаления штрафа: $e');
            _loadFines();
          }
        }
      },
      background: Container(
        color: CupertinoColors.systemRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          CupertinoIcons.delete,
          color: CupertinoColors.white,
          size: 24,
        ),
      ),
      child: CupertinoListTile(
        title: Text(fine.name),
        subtitle: Text(
          '${fine.price ~/ 100} ₽',
          style: const TextStyle(
            color: CupertinoColors.systemRed,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          CupertinoIcons.pencil,
          color: CupertinoColors.systemGrey,
          size: 20,
        ),
        onTap: () => _navigateAndReload(FineEditScreen(fine: fine)),
      ),
    );
  }
}
