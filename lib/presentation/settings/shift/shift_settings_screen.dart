// lib/presentation/settings/shift/shift_settings_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/presentation/settings/shift/cubit/shift_cubit.dart';
import 'package:motel/presentation/settings/shift/cubit/shift_state.dart';
import 'package:motel/presentation/settings/shift/models/shift_settings.dart';
import 'package:motel/presentation/settings/shift/widgets/auto_shifts_section.dart';
import 'package:motel/presentation/settings/shift/widgets/manual_control_section.dart';
import 'package:motel/presentation/settings/shift/widgets/shift_status_section.dart';
import 'package:motel/presentation/settings/shift/widgets/shift_time_picker.dart';
import 'package:motel/presentation/settings/shift/widgets/shift_times_section.dart';

class ShiftSettingsScreen extends StatelessWidget {
  const ShiftSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ShiftCubit(ApiClient.instance)..loadSettings(),
      child: const _ShiftSettingsView(),
    );
  }
}

class _ShiftSettingsView extends StatelessWidget {
  const _ShiftSettingsView();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: BlocConsumer<ShiftCubit, ShiftState>(
        listener: (context, state) {
          if (state is ShiftError) {
            _showErrorDialog(context, state.message);
          } else if (state is ShiftValidationError) {
            _showErrorDialog(context, state.message);
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Управление сменами'),
                previousPageTitle: 'Настройки',
              ),
              if (state is ShiftLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CupertinoActivityIndicator(radius: 20),
                    ),
                  ),
                )
              else if (state is ShiftLoaded || state is ShiftUpdating || state is ShiftValidationError)
                _buildContent(context, _getSettings(state))
              else if (state is ShiftError)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_circle,
                            size: 48,
                            color: CupertinoColors.systemRed,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CupertinoButton.filled(
                            child: const Text('Повторить'),
                            onPressed: () =>
                                context.read<ShiftCubit>().loadSettings(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  ShiftSettings _getSettings(ShiftState state) {
    if (state is ShiftLoaded) {
      return state.settings;
    } else if (state is ShiftUpdating) {
      return state.settings;
    } else if (state is ShiftValidationError) {
      return state.settings;
    }
    // Возвращаем значения по умолчанию (не должно произойти)
    return ShiftSettings(
      autoShiftsIsEnable: false,
      autoShiftsTimeToOpen: '08:00',
      autoShiftsTimeToClose: '20:00',
      shiftIsOpened: false,
    );
  }

  Widget _buildContent(BuildContext context, ShiftSettings settings) {
    return SliverMainAxisGroup(
      slivers: [
        // Статус текущей смены
        SliverToBoxAdapter(
          child: ShiftStatusSection(settings: settings),
        ),

        // Автоматические смены
        SliverToBoxAdapter(
          child: AutoShiftsSection(
            autoShiftsEnabled: settings.autoShiftsIsEnable,
            onToggle: (enabled) {
              context.read<ShiftCubit>().toggleAutoShifts(enabled, settings);
            },
          ),
        ),

        // Настройки времени
        if (settings.autoShiftsIsEnable)
          SliverToBoxAdapter(
            child: ShiftTimesSection(
              openTime: settings.autoShiftsTimeToOpen,
              closeTime: settings.autoShiftsTimeToClose,
              onOpenTimePressed: () => _showTimePicker(
                context: context,
                title: 'Время открытия',
                currentTime: settings.autoShiftsTimeToOpen,
                onTimeSelected: (time) {
                  context.read<ShiftCubit>().updateLocalTime(
                        time,
                        settings.autoShiftsTimeToClose,
                        settings,
                      );
                },
              ),
              onCloseTimePressed: () => _showTimePicker(
                context: context,
                title: 'Время закрытия',
                currentTime: settings.autoShiftsTimeToClose,
                onTimeSelected: (time) {
                  context.read<ShiftCubit>().updateLocalTime(
                        settings.autoShiftsTimeToOpen,
                        time,
                        settings,
                      );
                },
              ),
              onSavePressed: () {
                context.read<ShiftCubit>().updateShiftTimes(
                      settings.autoShiftsTimeToOpen,
                      settings.autoShiftsTimeToClose,
                      settings,
                    );
                _showSuccessDialog(context, 'Время смен обновлено');
              },
            ),
          ),

        // Ручное управление
        SliverToBoxAdapter(
          child: ManualControlSection(
            isShiftOpen: settings.shiftIsOpened,
            onOpenShift: () {
              context.read<ShiftCubit>().openShift();
              _showSuccessDialog(context, 'Смена открыта');
            },
            onCloseShift: () {
              context.read<ShiftCubit>().closeShift();
              _showSuccessDialog(context, 'Смена закрыта');
            },
          ),
        ),
      ],
    );
  }

  void _showTimePicker({
    required BuildContext context,
    required String title,
    required String currentTime,
    required Function(String) onTimeSelected,
  }) {
    ShiftTimePicker.show(
      context: context,
      title: title,
      currentTime: currentTime,
      onTimeSelected: onTimeSelected,
    );
  }

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
}
