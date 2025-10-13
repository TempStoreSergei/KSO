// ============================================
// lib/presentation/settings/screensaver/screensaver_settings_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motel/presentation/settings/screensaver/cubit/screensaver_cubit.dart';
import 'package:motel/presentation/settings/screensaver/cubit/screensaver_state.dart';
import 'package:motel/presentation/settings/screensaver/models/screensaver_models.dart';
import 'package:motel/presentation/settings/screensaver/widgets/add_button_section.dart';
import 'package:motel/presentation/settings/screensaver/widgets/images_section.dart';
import 'package:motel/presentation/settings/screensaver/widgets/time_picker_dialog.dart';

/// Экран настроек заставки с использованием BLoC-архитектуры
class ScreensaverSettingsScreen extends StatelessWidget {
  const ScreensaverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScreensaverCubit()..loadData(),
      child: const _ScreensaverSettingsView(),
    );
  }
}

class _ScreensaverSettingsView extends StatelessWidget {
  const _ScreensaverSettingsView();

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
          BlocConsumer<ScreensaverCubit, ScreensaverState>(
            listener: (context, state) {
              if (state is ScreensaverError) {
                _showErrorDialog(context, state.message);
              }
            },
            builder: (context, state) {
              if (state is ScreensaverLoading) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CupertinoActivityIndicator(radius: 20),
                    ),
                  ),
                );
              }

              if (state is ScreensaverLoaded) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    _MainSettingsSection(settings: state.settings),
                    ImagesSection(
                      files: state.files,
                      isEditing: state.isEditing,
                      onDelete: (fileId) => _handleDelete(context, fileId),
                      onShowTimePicker: (file) => _handleShowTimePicker(context, file),
                      onReorder: (oldIndex, newIndex) => _handleReorder(
                        context,
                        state.files,
                        oldIndex,
                        newIndex,
                      ),
                      onToggleEdit: () => context.read<ScreensaverCubit>().toggleEditMode(),
                      onSaveOrder: () => _handleSaveOrder(context, state.files),
                    ),
                    AddButtonSection(
                      onTap: () => _handleAddImage(context),
                      isBusy: false,
                    ),
                  ]),
                );
              }

              return const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Обработчик добавления нового изображения
  Future<void> _handleAddImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || !context.mounted) return;

    context.read<ScreensaverCubit>().addFile(pickedFile);
  }

  /// Обработчик удаления файла
  Future<void> _handleDelete(BuildContext context, int fileId) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Удалить файл?',
      'Это действие нельзя будет отменить.',
    );
    if (confirmed != true || !context.mounted) return;

    context.read<ScreensaverCubit>().deleteFile(fileId);
  }

  /// Обработчик отображения диалога выбора времени
  void _handleShowTimePicker(BuildContext context, ScreensaverFileModel file) {
    showTimePickerForFile(
      context,
      file,
      (timeShowImage) {
        context.read<ScreensaverCubit>().updateFileSettings(
              file,
              timeShowImage: timeShowImage,
            );
      },
    );
  }

  /// Обработчик переупорядочивания файлов
  void _handleReorder(
    BuildContext context,
    List<ScreensaverFileModel> files,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final newFiles = List<ScreensaverFileModel>.from(files);
    final item = newFiles.removeAt(oldIndex);
    newFiles.insert(newIndex, item);

    context.read<ScreensaverCubit>().updateFilesList(newFiles);
  }

  /// Обработчик сохранения порядка файлов
  void _handleSaveOrder(BuildContext context, List<ScreensaverFileModel> files) {
    context.read<ScreensaverCubit>().saveOrder(files);
  }

  /// Показывает диалог подтверждения
  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
  ) {
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

  /// Показывает диалог ошибки
  void _showErrorDialog(BuildContext context, String message) {
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
          ),
        ],
      ),
    );
  }
}

/// Секция основных настроек заставки
class _MainSettingsSection extends StatelessWidget {
  final ScreensaverSettingsModel settings;

  const _MainSettingsSection({required this.settings});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ScreensaverCubit>();

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
                  color: settings.isEnable
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  settings.isEnable
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.xmark_circle_fill,
                  size: 20,
                  color: CupertinoColors.white,
                ),
              ),
              trailing: CupertinoSwitch(
                value: settings.isEnable,
                onChanged: (val) => cubit.updateSettings(
                  settings.copyWith(isEnable: val),
                ),
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
                value: settings.soundIsEnable,
                onChanged: (val) => cubit.updateSettings(
                  settings.copyWith(soundIsEnable: val),
                ),
              ),
            ),
            CupertinoListTile(
              title: const Text('Время до активации'),
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
                    '${settings.idleTime} сек',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CupertinoListTileChevron(),
                ],
              ),
              onTap: () => showIdleTimePicker(
                context,
                settings,
                (idleTime) => cubit.updateSettings(
                  settings.copyWith(idleTime: idleTime),
                ),
              ),
            ),
          ],
        ),
        _buildInfoFooter(
          context,
          'Настройте параметры работы заставки: включение и время показа изображений.',
          CupertinoColors.systemGrey,
        ),
      ],
    );
  }

  /// Создает информационный футер с цветной полоской
  Widget _buildInfoFooter(BuildContext context, String text, Color barColor) {
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
}
