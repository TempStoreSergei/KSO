import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class RoomPricesSettingsScreen extends StatefulWidget {
  const RoomPricesSettingsScreen({super.key});

  @override
  State<RoomPricesSettingsScreen> createState() =>
      _RoomPricesSettingsScreenState();
}

class _RoomPricesSettingsScreenState extends State<RoomPricesSettingsScreen> {
  bool _isLoading = false;
  bool _isPreviewing = false;
  List<List<dynamic>>? _csvData;

  Future<void> _previewRoomPrices() async {
    setState(() {
      _isPreviewing = true;
      _csvData = null;
    });
    try {
      final url = await ApiClient.instance.exportRoomPrices();
      final response = await ApiClient.instance.getRawUrl(url);

      if (response.statusCode == 200) {
        final csvDataString = response.body;
        final csvTable = const CsvToListConverter().convert(csvDataString);
        setState(() {
          _csvData = csvTable;
        });
      } else {
        throw Exception('Не удалось загрузить данные: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Ошибка предпросмотра: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPreviewing = false;
        });
      }
    }
  }

  Future<void> _exportRoomPrices() async {
    setState(() => _isLoading = true);
    try {
      final url = await ApiClient.instance.exportRoomPrices();
      final fileName = url.split('/').last;

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить файл с ценами',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (savePath == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await ApiClient.instance.getRawUrl(url);

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        final csvDataString = response.body;
        final csvTable = const CsvToListConverter().convert(csvDataString);

        if (mounted) {
          setState(() {
            _isLoading = false;
            _csvData = csvTable;
          });
          _showSuccess('Файл успешно сохранен');
        }
      } else {
        throw Exception('Не удалось скачать файл: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Ошибка экспорта цен: $e');
      }
    }
  }

  Future<void> _importRoomPrices() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);

        final file = XFile(result.files.single.path!);

        await ApiClient.instance.loadRoomPrices(file);

        if (mounted) {
          setState(() => _isLoading = false);
          _showSuccess('Цены успешно загружены');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Ошибка загрузки цен: $e');
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

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Успешно'),
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
                largeTitle: Text('Цены на жилье'),
                previousPageTitle: 'Настройки',
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    CupertinoListSection.insetGrouped(
                      header: const Text('ИНФОРМАЦИЯ'),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Управление ценами на проживание. '
                            'Вы можете выгрузить текущие цены в CSV файл '
                            'или загрузить обновленные цены из файла.',
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isPreviewing)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CupertinoActivityIndicator(),
                      ),
                    if (_csvData != null) _buildPreviewTable(),
                    CupertinoListSection.insetGrouped(
                      header: const Text('ДЕЙСТВИЯ'),
                      children: [
                        if (_csvData == null)
                          CupertinoListTile(
                            title: const Text('Просмотр цен'),
                            subtitle: const Text(
                              'Показать таблицу с ценами',
                              style:
                                  TextStyle(color: CupertinoColors.systemGrey),
                            ),
                            leading: const Icon(
                              CupertinoIcons.eye,
                              color: CupertinoColors.activeBlue,
                            ),
                            trailing: const CupertinoListTileChevron(),
                            onTap: _isPreviewing ? null : _previewRoomPrices,
                          ),
                        CupertinoListTile(
                          title: const Text('Выгрузить цены'),
                          subtitle: const Text(
                            'Скачать CSV файл с текущими ценами',
                            style:
                                TextStyle(color: CupertinoColors.systemGrey),
                          ),
                          leading: const Icon(
                            CupertinoIcons.arrow_down_doc,
                            color: CupertinoColors.activeBlue,
                          ),
                          trailing: const CupertinoListTileChevron(),
                          onTap: _isLoading ? null : _exportRoomPrices,
                        ),
                        CupertinoListTile(
                          title: const Text('Загрузить цены'),
                          subtitle: const Text(
                            'Загрузить CSV файл с обновленными ценами',
                            style:
                                TextStyle(color: CupertinoColors.systemGrey),
                          ),
                          leading: const Icon(
                            CupertinoIcons.arrow_up_doc,
                            color: CupertinoColors.activeGreen,
                          ),
                          trailing: const CupertinoListTileChevron(),
                          onTap: _isLoading ? null : _importRoomPrices,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: CupertinoColors.black.withOpacity(0.3),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 15),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewTable() {
    if (_csvData == null) {
      return const SizedBox.shrink();
    }

    return CupertinoListSection.insetGrouped(
      header: const Text('ПРЕДПРОСМОТР ЦЕН'),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _csvData!.asMap().entries.map((entry) {
              final rowIndex = entry.key;
              final row = entry.value;
              final isHeader = rowIndex == 0;

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: row.map<Widget>((cell) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      width: 150, // Adjust width as needed
                      child: Text(
                        cell.toString(),
                        style: TextStyle(
                          fontWeight:
                              isHeader ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
