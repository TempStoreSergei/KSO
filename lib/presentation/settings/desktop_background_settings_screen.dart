import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/data/datasources/desktop_background_remote_data_source.dart';
import 'package:motel/data/repositories/desktop_background_repository_impl.dart';
import 'package:motel/domain/entities/desktop_background_entity.dart';
import 'package:motel/domain/repositories/desktop_background_repository.dart';

class DesktopBackgroundSettingsScreen extends StatefulWidget {
  const DesktopBackgroundSettingsScreen({super.key});

  @override
  State<DesktopBackgroundSettingsScreen> createState() => _DesktopBackgroundSettingsScreenState();
}

class _DesktopBackgroundSettingsScreenState extends State<DesktopBackgroundSettingsScreen> {
  final DesktopBackgroundRepository _repository = DesktopBackgroundRepositoryImpl(
    remoteDataSource: DesktopBackgroundRemoteDataSourceImpl(apiClient: ApiClient.instance),
  );

  DesktopBackgroundEntity? _background;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackground();
  }

  Future<void> _loadBackground() async {
    setState(() => _isLoading = true);
    final background = await _repository.getDesktopBackground();
    if (mounted) {
      setState(() {
        _background = background;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || !mounted) return;

    setState(() => _isLoading = true);
    await _repository.addDesktopBackground(pickedFile);
    await _loadBackground();
  }

  Future<void> _delete(String fileID) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Удалить фон?'),
        content: const Text('Это действие нельзя будет отменить.'),
        actions: [
          CupertinoDialogAction(child: const Text('Отмена'), onPressed: () => Navigator.of(ctx).pop(false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('Удалить'), onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    await _repository.deleteDesktopBackground(fileID);
    await _loadBackground();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Рабочий стол'),
            previousPageTitle: 'Настройки',
          ),
          SliverToBoxAdapter(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(heightFactor: 5, child: CupertinoActivityIndicator(radius: 15));
    }
    if (_background != null) {
      return _buildLoadedState(context, _background!);
    }
    return _buildNotSetState(context);
  }

  Widget _buildLoadedState(BuildContext context, DesktopBackgroundEntity background) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          // 1. Оборачиваем в Center, чтобы превью было по центру.
          child: Center(
            // 2. Ограничиваем максимальную ширину превью.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    background.fullUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CupertinoActivityIndicator()),
                    errorBuilder: (_, __, ___) => Container(color: CupertinoColors.systemGrey5, child: const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey, size: 50)),
                  ),
                ),
              ),
            ),
          ),
        ),
        CupertinoListSection.insetGrouped(
          children: [
            CupertinoListTile(
              title: const Text('Загрузить новый', style: TextStyle(color: CupertinoColors.activeBlue)),
              onTap: _pickAndUpload,
            ),
            CupertinoListTile(
              title: const Text('Удалить фон', style: TextStyle(color: CupertinoColors.systemRed)),
              onTap: () => _delete(background.fileID),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildNotSetState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            const Icon(CupertinoIcons.photo_on_rectangle, size: 60, color: CupertinoColors.systemGrey),
            const SizedBox(height: 16),
            const Text(
              'Фон рабочего стола не установлен',
              style: TextStyle(fontSize: 18, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 30),
            CupertinoButton.filled(
              onPressed: _pickAndUpload,
              child: const Text('Загрузить изображение'),
            ),
          ],
        ),
      ),
    );
  }
}