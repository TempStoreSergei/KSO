import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late TextEditingController _urlController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiClient.instance.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ApiClient.instance.setBaseUrl(_urlController.text);
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Успешно'),
            content: const Text('Адрес сервера обновлен. Рекомендуется перезапустить приложение.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Ошибка'),
            content: Text('Не удалось сохранить адрес: $e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetToDefault() {
    final defaultUrl = dotenv.env['BASE_URL'] ?? '';
    _urlController.text = defaultUrl;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Настройки сервера'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('АДРЕС СЕРВЕРА (BASE_URL)'),
              footer: const Text('Укажите полный адрес API, например: http://192.168.1.10:8005/api/v1'),
              children: [
                CupertinoListTile(
                  title: CupertinoTextField(
                    controller: _urlController,
                    placeholder: 'http://...',
                    decoration: null,
                    style: const TextStyle(color: CupertinoColors.white),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _resetToDefault,
                      child: const Text('Сбросить по умолчанию'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: CupertinoButton.filled(
                onPressed: _isLoading ? null : _saveUrl,
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
