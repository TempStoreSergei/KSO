// ============================================
// lib/presentation/settings/acquiring/acquiring_settings_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/presentation/settings/acquiring/acquiring_cubit.dart';
import 'package:motel/presentation/settings/acquiring/acquiring_models.dart';
import 'package:motel/presentation/settings/acquiring/acquiring_use_cases.dart';
import 'package:motel/presentation/settings/acquiring/widgets/acquiring_info_footer.dart';
import 'package:motel/presentation/settings/acquiring/widgets/acquiring_status_section.dart';

/// Основной экран настроек эквайринга
class AcquiringSettingsScreen extends StatelessWidget {
  const AcquiringSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final useCases = AcquiringUseCases(ApiClient.instance);
        final cubit = AcquiringCubit(useCases);
        cubit.checkConnection();
        return cubit;
      },
      child: const _AcquiringSettingsView(),
    );
  }
}

class _AcquiringSettingsView extends StatelessWidget {
  const _AcquiringSettingsView();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Эквайринг'),
            previousPageTitle: 'Настройки',
          ),
          SliverMainAxisGroup(
            slivers: [
              // Статус подключения
              const SliverToBoxAdapter(
                child: AcquiringStatusSection(),
              ),

              // Операции с платежами
              SliverToBoxAdapter(
                child: _buildPaymentActionsSection(context),
              ),

              // Отчеты
              SliverToBoxAdapter(
                child: _buildReportsSection(context),
              ),

              // Настройки
              SliverToBoxAdapter(
                child: _buildSettingsSection(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentActionsSection(BuildContext context) {
    return BlocBuilder<AcquiringCubit, AcquiringConnectionState>(
      builder: (context, state) {
        final cubit = context.read<AcquiringCubit>();
        final isConnected = state.isConnected;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('ОПЕРАЦИИ С ПЛАТЕЖАМИ'),
              children: [
                CupertinoListTile(
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.money_dollar_circle,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Запустить платеж',
                    style: TextStyle(
                      color: CupertinoColors.activeGreen,
                      fontSize: 17,
                    ),
                  ),
                  trailing: const CupertinoListTileChevron(),
                  onTap: isConnected ? () => _startPayment(context, cubit) : null,
                ),
                CupertinoListTile(
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_counterclockwise,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Возврат платежа',
                    style: TextStyle(
                      color: CupertinoColors.systemOrange,
                      fontSize: 17,
                    ),
                  ),
                  trailing: const CupertinoListTileChevron(),
                  onTap: isConnected ? () => _refundPayment(context, cubit) : null,
                ),
                CupertinoListTile(
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark_circle,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Отменить платеж',
                    style: TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 17,
                    ),
                  ),
                  trailing: const CupertinoListTileChevron(),
                  onTap: isConnected ? () => _cancelPayment(context, cubit) : null,
                ),
              ],
            ),
            const AcquiringInfoFooter(
              text: 'Управление платежными операциями через терминал эквайринга.',
              barColor: CupertinoColors.activeBlue,
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportsSection(BuildContext context) {
    return BlocBuilder<AcquiringCubit, AcquiringConnectionState>(
      builder: (context, state) {
        final cubit = context.read<AcquiringCubit>();
        final isConnected = state.isConnected;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('ОТЧЕТЫ'),
              children: [
                CupertinoListTile(
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.doc_text,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Отчет о чеках',
                    style: TextStyle(
                      color: CupertinoColors.activeBlue,
                      fontSize: 17,
                    ),
                  ),
                  trailing: const CupertinoListTileChevron(),
                  onTap: isConnected ? () => _receiptReport(context, cubit) : null,
                ),
              ],
            ),
            const AcquiringInfoFooter(
              text: 'Получение отчетов о проведенных операциях.',
              barColor: CupertinoColors.activeBlue,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return BlocBuilder<AcquiringCubit, AcquiringConnectionState>(
      builder: (context, state) {
        final cubit = context.read<AcquiringCubit>();
        final isConnected = state.isConnected;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('НАСТРОЙКИ'),
              children: [
                CupertinoListTile(
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.settings,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Открыть меню терминала',
                    style: TextStyle(
                      fontSize: 17,
                    ),
                  ),
                  trailing: const CupertinoListTileChevron(),
                  onTap: isConnected ? () => _openMenu(context, cubit) : null,
                ),
              ],
            ),
            const AcquiringInfoFooter(
              text: 'Открыть меню настроек на терминале эквайринга.',
              barColor: CupertinoColors.systemGrey,
            ),
          ],
        );
      },
    );
  }

  // Action handlers
  Future<void> _startPayment(BuildContext context, AcquiringCubit cubit) async {
    await _executeAction(
      context,
      cubit,
      'Запуск платежа',
      () async {
        final useCases = AcquiringUseCases(ApiClient.instance);
        return await useCases.startPayment();
      },
    );
  }

  Future<void> _refundPayment(BuildContext context, AcquiringCubit cubit) async {
    await _executeAction(
      context,
      cubit,
      'Возврат платежа',
      () async {
        final useCases = AcquiringUseCases(ApiClient.instance);
        return await useCases.refundPayment();
      },
    );
  }

  Future<void> _receiptReport(BuildContext context, AcquiringCubit cubit) async {
    await _executeAction(
      context,
      cubit,
      'Отчет о чеках',
      () async {
        final useCases = AcquiringUseCases(ApiClient.instance);
        return await useCases.receiptReport();
      },
    );
  }

  Future<void> _cancelPayment(BuildContext context, AcquiringCubit cubit) async {
    await _executeAction(
      context,
      cubit,
      'Отмена платежа',
      () async {
        final useCases = AcquiringUseCases(ApiClient.instance);
        return await useCases.cancelPayment();
      },
    );
  }

  Future<void> _openMenu(BuildContext context, AcquiringCubit cubit) async {
    await _executeAction(
      context,
      cubit,
      'Открыть меню',
      () async {
        final useCases = AcquiringUseCases(ApiClient.instance);
        return await useCases.openMenu();
      },
    );
  }

  Future<void> _executeAction(
    BuildContext context,
    AcquiringCubit cubit,
    String actionName,
    Future<AcquiringResponse> Function() action,
  ) async {
    try {
      final response = await cubit.executeAction(action);

      if (context.mounted) {
        if (response.status) {
          _showSuccessDialog(context, '$actionName выполнен успешно', response.detail);
        } else {
          _showErrorDialog(context, '$actionName не выполнен', response.detail);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Ошибка выполнения', e.toString());
      }
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
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

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
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
