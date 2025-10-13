import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/api/api_client.dart';
import 'cubit/bill_dispenser_cubit.dart';
import 'cubit/bill_dispenser_state.dart';
import 'models/test_status.dart';
import 'widgets/status_section.dart';
import 'widgets/count_settings_section.dart';
import 'widgets/level_settings_section.dart';
import 'widgets/test_section.dart';
import 'widgets/actions_section.dart';

class BillDispenserSettingsScreen extends StatelessWidget {
  const BillDispenserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BillDispenserCubit(ApiClient.instance)..loadStatus(),
      child: const _BillDispenserSettingsView(),
    );
  }
}

class _BillDispenserSettingsView extends StatelessWidget {
  const _BillDispenserSettingsView();

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

  void _showResetConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Инкассация'),
        content: const Text('Вы уверены, что хотите выполнить инкассацию и сбросить счетчик купюр в диспенсере?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Сбросить'),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<BillDispenserCubit>().resetCount();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BillDispenserCubit, BillDispenserState>(
      listener: (context, state) {
        if (state is BillDispenserError) {
          _showErrorDialog(context, state.message);
        } else if (state is BillDispenserSuccess) {
          _showSuccessDialog(context, state.message);
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        child: CustomScrollView(
          slivers: [
            const CupertinoSliverNavigationBar(
              largeTitle: Text('Диспенсер купюр'),
              previousPageTitle: 'Настройки',
            ),
            BlocBuilder<BillDispenserCubit, BillDispenserState>(
              builder: (context, state) {
                if (state is BillDispenserLoading || state is BillDispenserInitial) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CupertinoActivityIndicator(radius: 20),
                      ),
                    ),
                  );
                }

                if (state is BillDispenserLoaded || state is BillDispenserSuccess) {
                  final loadedState = state is BillDispenserLoaded
                      ? state
                      : (state as BillDispenserSuccess);

                  final status = loadedState is BillDispenserLoaded
                      ? loadedState.status
                      : (loadedState as BillDispenserSuccess).status;

                  final newUpperBoxCount = loadedState is BillDispenserLoaded
                      ? loadedState.newUpperBoxCount
                      : (loadedState as BillDispenserSuccess).newUpperBoxCount;

                  final newLowerBoxCount = loadedState is BillDispenserLoaded
                      ? loadedState.newLowerBoxCount
                      : (loadedState as BillDispenserSuccess).newLowerBoxCount;

                  final newUpperBoxValue = loadedState is BillDispenserLoaded
                      ? loadedState.newUpperBoxValue
                      : (loadedState as BillDispenserSuccess).newUpperBoxValue;

                  final newLowerBoxValue = loadedState is BillDispenserLoaded
                      ? loadedState.newLowerBoxValue
                      : (loadedState as BillDispenserSuccess).newLowerBoxValue;

                  final testStatus = loadedState is BillDispenserLoaded
                      ? loadedState.testStatus
                      : TestStatus.inactive;

                  return SliverMainAxisGroup(
                    slivers: [
                      // Текущее состояние
                      SliverToBoxAdapter(
                        child: StatusSection(status: status),
                      ),

                      // Настройка количества
                      SliverToBoxAdapter(
                        child: CountSettingsSection(
                          status: status,
                          newUpperBoxCount: newUpperBoxCount,
                          newLowerBoxCount: newLowerBoxCount,
                          onUpdateCount: () => context.read<BillDispenserCubit>().updateCount(),
                          onUpperCountChanged: (value) =>
                              context.read<BillDispenserCubit>().updateNewUpperBoxCount(value),
                          onLowerCountChanged: (value) =>
                              context.read<BillDispenserCubit>().updateNewLowerBoxCount(value),
                        ),
                      ),

                      // Настройка номиналов
                      SliverToBoxAdapter(
                        child: LevelSettingsSection(
                          newUpperBoxValue: newUpperBoxValue,
                          newLowerBoxValue: newLowerBoxValue,
                          onUpdateLevels: () => context.read<BillDispenserCubit>().updateLevels(),
                          onUpperValueChanged: (value) =>
                              context.read<BillDispenserCubit>().updateNewUpperBoxValue(value),
                          onLowerValueChanged: (value) =>
                              context.read<BillDispenserCubit>().updateNewLowerBoxValue(value),
                        ),
                      ),

                      // Тестирование
                      SliverToBoxAdapter(
                        child: TestSection(
                          status: status,
                          testStatus: testStatus,
                          onTestDispenser: () => context.read<BillDispenserCubit>().testDispenser(),
                        ),
                      ),

                      // Действия
                      SliverToBoxAdapter(
                        child: ActionsSection(
                          onResetCount: () => _showResetConfirmation(context),
                        ),
                      ),
                    ],
                  );
                }

                // Error state
                if (state is BillDispenserError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              size: 64,
                              color: CupertinoColors.systemRed,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            CupertinoButton.filled(
                              onPressed: () => context.read<BillDispenserCubit>().loadStatus(),
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }
}
