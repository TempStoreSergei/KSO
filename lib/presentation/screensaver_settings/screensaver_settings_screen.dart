import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/data/repositories/screensaver_repository_impl.dart';
import 'package:motel/domain/entities/screensaver_file.dart';

class ScreensaverSettingsScreen extends StatefulWidget {
  const ScreensaverSettingsScreen({super.key});

  @override
  State<ScreensaverSettingsScreen> createState() => _ScreensaverSettingsViewState();
}

class _ScreensaverSettingsViewState extends State<ScreensaverSettingsScreen> {
  final ScreensaverRepositoryImpl _repository = ScreensaverRepositoryImpl(ApiClient.instance);

  List<ScreensaverFile>? _files;
  bool _isEditing = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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

  Future<void> _loadData() async {
    final loadedFiles = await _repository.getScreensaverFiles();
    if (mounted) {
      setState(() {
        _files = loadedFiles;
      });
    }
  }

  Future<void> _pickAndUpload() async {
    await _runBusy(() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null || !mounted) return;

      final success = await _repository.addScreensaverFile(pickedFile);
      if (success) {
        await _loadData();
      } else {
        _showErrorDialog('Не удалось загрузить файл.');
      }
    });
  }

  Future<void> _deleteFile(String fileID) async {
    final confirmed = await _showConfirmationDialog('Удалить файл?', 'Это действие нельзя будет отменить.');
    if (confirmed != true) return;

    await _runBusy(() async {
      final success = await _repository.deleteScreensaverFile(fileID);
      if (success) {
        await _loadData();
        if (_files?.isEmpty == true && mounted) {
          setState(() => _isEditing = false);
        }
      } else {
        _showErrorDialog('Не удалось удалить файл.');
      }
    });
  }

  Future<void> _saveOrder() async {
    await _runBusy(() async {
      setState(() => _isEditing = false);
      final futures = <Future<bool>>[];
      for (int i = 0; i < _files!.length; i++) {
        futures.add(_repository.updateFileOrder(_files![i].fileID, i + 1));
      }
      await Future.wait(futures);
      await _loadData();
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _files!.removeAt(oldIndex);
      _files!.insert(newIndex, item);
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
                largeTitle: const Text('Настройка заставки'),
                leading: CupertinoNavigationBarBackButton(
                  previousPageTitle: 'Настройки',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                trailing: _buildTrailingButton(),
              ),
              CupertinoSliverRefreshControl(onRefresh: _loadData),
              _buildBody(),
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

  Widget? _buildTrailingButton() {
    if (_files == null || _files!.isEmpty) return null;

    if (_isEditing) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _isBusy ? null : _saveOrder,
        child: const Text('Готово', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _isBusy ? null : () => setState(() => _isEditing = true),
        child: const Text('Изменить'),
      );
    }
  }

  Widget _buildBody() {
    if (_files == null) {
      return const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator()));
    }

    return SliverMainAxisGroup(
      slivers: [
        // Header
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 8, top: 20),
            child: Text('ИЗОБРАЖЕНИЯ', style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13)),
          ),
        ),

        // Используем SliverReorderableList с вашим кастомным виджетом
        if (_files!.isNotEmpty)
          SliverReorderableList(
            itemBuilder: (context, index) => _buildListItem(_files![index], index),
            itemCount: _files!.length,
            onReorder: _onReorder,
          ),

        // Кнопка "Добавить" в отдельной секции для чистоты кода
        SliverToBoxAdapter(
          child: CupertinoListSection.insetGrouped(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              CupertinoListTile(
                title: const Text('Добавить изображение', style: TextStyle(color: CupertinoColors.activeBlue)),
                leading: const Icon(CupertinoIcons.add_circled_solid, color: CupertinoColors.activeBlue),
                onTap: _isBusy ? null : _pickAndUpload,
              ),
            ],
          ),
        ),

        // Footer
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              _files!.isEmpty
                  ? 'Добавьте изображения для заставки.'
                  : (_isEditing
                  ? 'Удерживайте и перетаскивайте элементы для сортировки.'
                  : 'Нажмите "Изменить" для управления списком.'),
              style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  /// Ваш кастомный виджет для элемента списка, который вы предоставили.
  /// Он идеально подходит для использования с SliverReorderableList.
  Widget _buildListItem(ScreensaverFile file, int index) {
    const radius = Radius.circular(10.0);
    // Получаем правильный цвет фона для текущей темы
    final backgroundColor = CupertinoColors.secondarySystemFill;

    return Container(
      key: ValueKey(file.fileID), // Ключ обязателен для сортировки
      margin: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        // Добавляем отступ снизу для всех, кроме последнего элемента, чтобы имитировать разделитель
        bottom: index == _files!.length - 1 ? 0 : 0.5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        // Скругление углов только у первого и последнего элемента
        borderRadius: BorderRadius.vertical(
          top: index == 0 ? radius : Radius.zero,
          bottom: index == _files!.length - 1 ? radius : Radius.zero,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              file.fullUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: CupertinoColors.systemGrey5, child: const Icon(CupertinoIcons.photo)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text('Изображение ${index + 1}', style: const TextStyle(fontSize: 17))),
          if (_isEditing)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () => _deleteFile(file.fileID),
                  child: const Icon(CupertinoIcons.minus_circle_fill, color: CupertinoColors.systemRed),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(CupertinoIcons.bars, color: CupertinoColors.systemGrey2),
                  ),
                ),
              ],
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