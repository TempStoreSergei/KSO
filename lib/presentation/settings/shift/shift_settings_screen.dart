// lib/presentation/settings/shift/shift_settings_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/di/service_locator.dart';
import 'package:motel/presentation/helpers/permission_protected_screen.dart';
import 'package:motel/presentation/settings/shift/cubit/shift_cubit.dart';
import 'package:motel/presentation/settings/shift/cubit/shift_state.dart';
import 'package:motel/presentation/settings/shift/models/shift_settings.dart';
import 'package:motel/presentation/settings/shift/widgets/auto_shifts_section.dart';
import 'package:motel/presentation/settings/shift/widgets/manual_control_section.dart';
import 'package:motel/presentation/settings/shift/widgets/shift_status_section.dart';
import 'package:motel/presentation/settings/shift/widgets/shift_time_picker.dart';
import 'package:motel/presentation/settings/widgets/admin_loading_overlay.dart';
import 'package:motel/presentation/settings/widgets/settings_scroll_buttons.dart';

class ShiftSettingsScreen extends StatelessWidget {
  const ShiftSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionProtectedScreen(
      requiredPermissions: [
        'open_shift',
        'close_shift',
        'print_x_report',
        'get_shift_status'
      ],
      title: 'Управление сменами',
      child: BlocProvider(
        create: (context) => ShiftCubit(sl.manageShiftUseCase)..loadSettings(),
        child: const _ShiftSettingsView(),
      ),
    );
  }
}

class _ShiftSettingsView extends StatefulWidget {
  const _ShiftSettingsView();

  @override
  State<_ShiftSettingsView> createState() => _ShiftSettingsViewState();
}

class _ShiftSettingsViewState extends State<_ShiftSettingsView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
          return AdminLoadingOverlay(
            isProcessing: state is ShiftUpdating,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: const Text('Управление сменами'),
                  previousPageTitle: 'Настройки',
                  trailing:
                      SettingsScrollButtons(controller: _scrollController),
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
                else if (state is ShiftLoaded ||
                    state is ShiftUpdating ||
                    state is ShiftValidationError)
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
            ),
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
    return ShiftSettings(shiftIsOpened: false);
  }

  Widget _buildContent(BuildContext context, ShiftSettings settings) {
    return SliverMainAxisGroup(
      slivers: [
        // Статус текущей смены
        SliverToBoxAdapter(
          child: ShiftStatusSection(settings: settings),
        ),

        // Автоматическое управление
        SliverToBoxAdapter(
          child: AutoShiftsSection(
            openMode: settings.openMode,
            openTime: settings.autoShiftsTimeToOpen,
            closeTime: settings.autoShiftsTimeToClose,
            acquiringReceiptReportOnClose:
                settings.acquiringReceiptReportOnClose,
            onOpenModeChanged: (mode) {
              context.read<ShiftCubit>().updateOpenMode(mode);
            },
            onOpenTimePressed: () => _showTimePicker(
              context: context,
              title: 'Открытие смены',
              currentTime: settings.autoShiftsTimeToOpen ?? '08:00',
              onTimeSelected: (time) {
                context.read<ShiftCubit>().updateOpenTime(time);
              },
            ),
            onCloseTimePressed: () => _showTimePicker(
              context: context,
              title: 'Закрытие смены',
              currentTime: settings.autoShiftsTimeToClose ?? '23:55',
              onTimeSelected: (time) {
                context.read<ShiftCubit>().updateCloseTime(time);
              },
            ),
            onDisableAutoClose: () {
              context.read<ShiftCubit>().disableAutoClose();
            },
            onAcquiringReceiptReportChanged: (value) {
              context
                  .read<ShiftCubit>()
                  .toggleAcquiringReceiptReportOnClose(value);
            },
          ),
        ),

        // Ручное управление
        SliverToBoxAdapter(
          child: ManualControlSection(
            isShiftOpen: settings.shiftData?.isOpen == true ||
                settings.shiftData?.isExpired == true,
            onOpenShift: () {
              context.read<ShiftCubit>().openShift();
            },
            onCloseShift: () {
              context.read<ShiftCubit>().closeShift();
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
    required ValueChanged<String> onTimeSelected,
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
}
