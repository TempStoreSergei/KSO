// ============================================
// lib/presentation/settings/screensaver/widgets/main_settings_section.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/settings/screensaver/models/screensaver_models.dart';

/// Виджет для отображения основных настроек заставки
class MainSettingsSection extends StatelessWidget {
  final ScreensaverSettingsModel settings;
  final Function(ScreensaverSettingsModel) onUpdateSettings;
  final VoidCallback onShowIdleTimePicker;

  const MainSettingsSection({
    super.key,
    required this.settings,
    required this.onUpdateSettings,
    required this.onShowIdleTimePicker,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              trailing: CupertinoSwitch(
                value: settings.isEnable,
                onChanged: (val) => onUpdateSettings(settings.copyWith(isEnable: val)),
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
                onChanged: (val) => onUpdateSettings(settings.copyWith(soundIsEnable: val)),
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
              onTap: onShowIdleTimePicker,
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
