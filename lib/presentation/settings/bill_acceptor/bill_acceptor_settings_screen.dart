// ============================================
// lib/presentation/settings/bill_acceptor/bill_acceptor_settings_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/presentation/settings/bill_acceptor/cubit/bill_acceptor_cubit.dart';
import 'package:motel/presentation/settings/bill_acceptor/cubit/bill_acceptor_state.dart';
import 'package:motel/presentation/settings/bill_acceptor/widgets/actions_section.dart';
import 'package:motel/presentation/settings/bill_acceptor/widgets/limit_section.dart';
import 'package:motel/presentation/settings/bill_acceptor/widgets/status_section.dart';
import 'package:motel/presentation/settings/bill_acceptor/widgets/test_section.dart';

/// Экран настроек купюроприемника
class BillAcceptorSettingsScreen extends StatelessWidget {
  const BillAcceptorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BillAcceptorCubit()..loadData(),
      child: const _BillAcceptorSettingsView(),
    );
  }
}

class _BillAcceptorSettingsView extends StatelessWidget {
  const _BillAcceptorSettingsView();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: BlocConsumer<BillAcceptorCubit, BillAcceptorState>(
        listener: (context, state) {
          if (state is BillAcceptorError) {
            _handleError(context, state);
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Купюроприемник'),
                previousPageTitle: 'Настройки',
              ),
              if (state is BillAcceptorLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CupertinoActivityIndicator(radius: 20),
                    ),
                  ),
                )
              else if (state is BillAcceptorLoaded)
                SliverMainAxisGroup(
                  slivers: [
                    // Текущее состояние
                    SliverToBoxAdapter(
                      child: StatusSection(status: state.status),
                    ),

                    // Настройки лимита
                    SliverToBoxAdapter(
                      child: LimitSection(
                        customMaxCount: state.customMaxCount,
                      ),
                    ),

                    // Тестирование
                    SliverToBoxAdapter(
                      child: TestSection(
                        testAmount: state.testAmount,
                        testingStatus: state.testingStatus,
                        collectedAmount: state.collectedAmount,
                        events: state.events,
                        onStartTest: () {
                          context.read<BillAcceptorCubit>().startTest(
                                state.testAmount,
                              );
                        },
                        onStopTest: () {
                          context.read<BillAcceptorCubit>().stopTest();
                        },
                      ),
                    ),

                    // Действия
                    SliverToBoxAdapter(
                      child: ActionsSection(
                        onResetCount: () => _showResetConfirmation(context),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleError(BuildContext context, BillAcceptorError state) {
    // Если это ошибка требующая инкассации
    if (state.message == 'INKASSATION_REQUIRED') {
      _showInkassationDialog(context);
      return;
    }

    // Обычная ошибка
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(state.message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Инкассация'),
        content: const Text(
          'Вы уверены, что хотите произвести инкассацию? Счетчик будет сброшен в ноль.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Инкассировать'),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<BillAcceptorCubit>().resetCount();
              _showSuccessDialog(context, 'Инкассация выполнена');
            },
          ),
        ],
      ),
    );
  }

  void _showInkassationDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Требуется инкассация'),
        content: const Text(
          'Для запуска теста необходимо провести инкассацию купюроприемника.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Инкассировать'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showResetConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Успешно'),
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
