import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motel/core/api/api_client.dart';

// Модели данных
class ScreensaverFile {
  final int id;
  final int order;
  final String fileUrl;
  final bool soundIsEnable;
  final int timeShowImage;
  final String fileType;

  ScreensaverFile({
    required this.id,
    required this.order,
    required this.fileUrl,
    required this.soundIsEnable,
    required this.timeShowImage,
    required this.fileType,
  });

  factory ScreensaverFile.fromJson(Map<String, dynamic> json) {
    return ScreensaverFile(
      id: json['id'] ?? 0,
      order: json['order'] ?? 0,
      fileUrl: json['fileUrl'] ?? '',
      soundIsEnable: json['soundIsEnable'] ?? false,
      timeShowImage: json['timeShowImage'] ?? 200,
      fileType: json['fileType'] ?? '',
    );
  }
}

class ScreensaverSettings {
  final bool isEnable;
  final bool soundIsEnable;
  final int timeShowImage;
  final int idleTime;
  final bool showClock;

  ScreensaverSettings({
    required this.isEnable,
    required this.soundIsEnable,
    required this.timeShowImage,
    required this.idleTime,
    required this.showClock,
  });

  factory ScreensaverSettings.fromJson(Map<String, dynamic> json) {
    return ScreensaverSettings(
      isEnable: json['isEnable'] ?? false,
      soundIsEnable: json['soundIsEnable'] ?? false,
      timeShowImage: json['timeShowImage'] ?? 200,
      idleTime: json['idleTime'] ?? 100,
      showClock: json['showClock'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnable': isEnable,
      'soundIsEnable': soundIsEnable,
      'timeShowImage': timeShowImage,
      'idleTime': idleTime,
      'showClock': showClock,
    };
  }
}

class ScreensaverSettingsScreen extends StatefulWidget {
  const ScreensaverSettingsScreen({super.key});

  @override
  State<ScreensaverSettingsScreen> createState() => _ScreensaverSettingsViewState();
}

class _ScreensaverSettingsViewState extends State<ScreensaverSettingsScreen> {
  final ApiClient _apiClient = ApiClient.instance;

  List<ScreensaverFile>? _files;
  ScreensaverSettings? _settings;
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
    try {
      final filesResponse = await _apiClient.get('/screensaver/get_files');
      final filesList = (filesResponse['files'] as List)
          .map((json) => ScreensaverFile.fromJson(json))
          .toList();

      // Сортируем по order
      filesList.sort((a, b) => a.order.compareTo(b.order));

      final settingsResponse = await _apiClient.get('/screensaver/get_settings');
      final settings = ScreensaverSettings.fromJson(settingsResponse);

      if (mounted) {
        setState(() {
          _files = filesList;
          _settings = settings;
        });
      }
    } catch (e) {
      if (mounted) _showErrorDialog('Ошибка загрузки данных: $e');
    }
  }

  Future<void> _pickAndUpload() async {
    await _runBusy(() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null || !mounted) return;

      final bytes = await pickedFile.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final newOrder = (_files?.length ?? 0) + 1;

      await _apiClient.post('/screensaver/add_file', body: {
        'order': newOrder,
        'fileBase64': base64String,
        'soundIsEnable': _settings?.soundIsEnable ?? false,
        'timeShowImage': _settings?.timeShowImage ?? 200,
      });

      await _loadData();
    });
  }

  Future<void> _deleteFile(int fileId) async {
    final confirmed = await _showConfirmationDialog(
      'Удалить файл?',
      'Это действие нельзя будет отменить.',
    );
    if (confirmed != true) return;

    await _runBusy(() async {
      await _apiClient.delete('/screensaver/delete_file?file_id=$fileId');
      await _loadData();
      if (_files?.isEmpty == true && mounted) {
        setState(() => _isEditing = false);
      }
    });
  }

  Future<void> _saveOrder() async {
    await _runBusy(() async {
      setState(() => _isEditing = false);

      for (int i = 0; i < _files!.length; i++) {
        final file = _files![i];
        await _apiClient.put('/screensaver/update_file', body: {
          'id': file.id,
          'order': i + 1,
          'soundIsEnable': file.soundIsEnable,
          'timeShowImage': file.timeShowImage,
        });
      }

      await _loadData();
    });
  }

  Future<void> _updateSettings(ScreensaverSettings newSettings) async {
    await _runBusy(() async {
      await _apiClient.put('/screensaver/update_settings', body: newSettings.toJson());
      await _loadData();
    });
  }

  Future<void> _updateFileSettings(ScreensaverFile file, {bool? soundIsEnable, int? timeShowImage}) async {
    await _runBusy(() async {
      await _apiClient.put('/screensaver/update_file', body: {
        'id': file.id,
        'order': file.order,
        'fileBase64': '',
        'soundIsEnable': soundIsEnable ?? file.soundIsEnable,
        'timeShowImage': timeShowImage ?? file.timeShowImage,
      });
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

  void _showTimePickerForFile(ScreensaverFile file) {
    final times = [5, 10, 15, 20, 30, 60, 120, 180, 200];
    final initialIndex = times.indexOf(file.timeShowImage) != -1
        ? times.indexOf(file.timeShowImage)
        : times.indexOf(200);

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
                    'Время показа',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    child: const Text('Готово'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: initialIndex,
                ),
                onSelectedItemChanged: (index) {
                  _updateFileSettings(file, timeShowImage: times[index]);
                },
                children: times.map((time) {
                  return Center(child: Text('$time сек'));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIdleTimePicker() {
    if (_settings == null) return;
    final times = [30, 60, 120, 180, 300, 600];
    final initialIndex = times.indexOf(_settings!.idleTime) != -1
        ? times.indexOf(_settings!.idleTime)
        : 1;

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
                    'Время до активации',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    child: const Text('Готово'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: initialIndex,
                ),
                onSelectedItemChanged: (index) {
                  _updateSettings(ScreensaverSettings(
                    isEnable: _settings!.isEnable,
                    soundIsEnable: _settings!.soundIsEnable,
                    timeShowImage: _settings!.timeShowImage,
                    idleTime: times[index],
                    showClock: _settings!.showClock,
                  ));
                },
                children: times.map((time) {
                  return Center(child: Text('$time сек'));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoFooter(String text, Color barColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            constraints: const BoxConstraints(minHeight: 24),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ),
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
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Заставка'),
            previousPageTitle: 'Настройки',
          ),
          if (_isBusy)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CupertinoActivityIndicator(radius: 20),
                ),
              ),
            )
          else if (_files == null || _settings == null)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                _buildMainSettingsSection(),
                if (_files!.isNotEmpty) _buildImagesSection(),
                _buildAddButton(),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildMainSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('ОСНОВНЫЕ НАСТРОЙКИ'),
          children: [
            CupertinoListTile(
              title: const Text('Заставка'),
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _settings!.isEnable
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _settings!.isEnable
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.xmark_circle_fill,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              trailing: CupertinoSwitch(
                value: _settings!.isEnable,
                onChanged: (val) => _updateSettings(ScreensaverSettings(
                  isEnable: val,
                  soundIsEnable: _settings!.soundIsEnable,
                  timeShowImage: _settings!.timeShowImage,
                  idleTime: _settings!.idleTime,
                  showClock: _settings!.showClock,
                )),
              ),
            ),
            CupertinoListTile(
              title: const Text('Звук по умолчанию'),
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.speaker_2_fill,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              trailing: CupertinoSwitch(
                value: _settings!.soundIsEnable,
                onChanged: (val) => _updateSettings(ScreensaverSettings(
                  isEnable: _settings!.isEnable,
                  soundIsEnable: val,
                  timeShowImage: _settings!.timeShowImage,
                  idleTime: _settings!.idleTime,
                  showClock: _settings!.showClock,
                )),
              ),
            ),
            CupertinoListTile(
              title: const Text('Время показа (базовое)'),
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.timer,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_settings!.idleTime} сек',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CupertinoListTileChevron(),
                ],
              ),
              onTap: _showIdleTimePicker,
            ),
          ],
        ),
        _buildInfoFooter(
          'Настройте параметры работы заставки: включени и время показа изображений.',
          CupertinoColors.systemGrey,
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ИЗОБРАЖЕНИЯ'),
              if (_files!.isNotEmpty)
                GestureDetector(
                  onTap: _isEditing ? _saveOrder : () => setState(() => _isEditing = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isEditing ? CupertinoColors.systemGreen : CupertinoColors.activeBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _isEditing ? 'Готово' : 'Изменить',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          children: [
            if (_isEditing)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _files!.length,
                onReorder: _onReorder,
                itemBuilder: (context, index) {
                  final file = _files![index];
                  return _buildFileItem(file, index, key: ValueKey(file.id));
                },
              )
            else
              ...List.generate(_files!.length, (index) {
                final file = _files![index];
                return _buildFileItem(file, index);
              }),
          ],
        ),
        _buildInfoFooter(
          _isEditing
              ? 'Удерживайте и перетаскивайте для изменения порядка показа изображений.'
              : 'Настройте время показа для каждого изображения.',
          CupertinoColors.activeBlue,
        ),
      ],
    );
  }

  Widget _buildFileItem(ScreensaverFile file, int index, {Key? key}) {
    return Container(
      key: key ?? ValueKey('file_${file.id}'),
      decoration: BoxDecoration(
        border: Border(
          bottom: index < _files!.length - 1
              ? const BorderSide(
            color: CupertinoColors.separator,
            width: 0.5,
          )
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                file.fileUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: CupertinoColors.systemGrey5,
                  child: const Icon(CupertinoIcons.photo),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Изображение ${index + 1}',
                    style: const TextStyle(fontSize: 17),
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showTimePickerForFile(file),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.timer,
                                  size: 14,
                                  color: CupertinoColors.systemGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${file.timeShowImage} сек',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_isEditing)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    onPressed: () => _deleteFile(file.id),
                    child: const Icon(
                      CupertinoIcons.delete,
                      color: CupertinoColors.systemRed,
                      size: 22,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          children: [
            CupertinoListTile(
              title: const Text(
                'Добавить изображение',
                style: TextStyle(color: CupertinoColors.activeBlue),
              ),
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: _isBusy ? null : _pickAndUpload,
            ),
          ],
        ),
        _buildInfoFooter(
          'Добавьте изображения или видео для отображения в заставке.',
          CupertinoColors.activeBlue,
        ),
      ],
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
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Удалить'),
            onPressed: () => Navigator.of(ctx).pop(true),
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
            child: const Text('OK'),
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}