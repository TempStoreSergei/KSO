import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/services/metrics_service.dart';
import 'package:motel/domain/models/booking_models.dart';

import 'package:motel/presentation/booking/cubit/booking_cubit.dart';
import 'package:motel/presentation/booking/cubit/booking_state.dart';
import 'package:motel/presentation/booking/managers/inactivity_manager.dart';
import 'package:motel/presentation/booking/managers/keyboard_manager.dart';
import 'package:motel/presentation/booking/widgets/booking_sidebar.dart';
import 'package:motel/presentation/booking/widgets/step_building_selection.dart';
import 'package:motel/presentation/booking/widgets/step_category_selection.dart';
import 'package:motel/presentation/booking/widgets/step_confirmation.dart';
import 'package:motel/presentation/booking/widgets/step_guest_info.dart';
import 'package:motel/presentation/booking/widgets/step_item_selection.dart';
import 'package:motel/presentation/booking/widgets/step_payment.dart';
import 'package:motel/presentation/booking/widgets/step_payment_execution.dart';
import 'package:motel/presentation/booking/widgets/step_period.dart';
import 'package:motel/presentation/booking/widgets/step_room_selection.dart';
import 'package:motel/presentation/booking/widgets/step_room_type_selection.dart';
import 'package:motel/presentation/booking/widgets/step_success.dart';
import 'package:motel/presentation/booking/widgets/step_payment_error.dart';
import 'package:motel/core/services/websocket_service.dart';
import 'package:motel/presentation/guest_info/custom_keyboard.dart';
import 'package:motel/presentation/lock_screen/lock_screen.dart';
import 'package:provider/provider.dart';

import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/usecases/get_rooms.dart';

class RoomBookingScreen extends StatelessWidget {
  const RoomBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingCubit(GetRooms(ApiClient.instance), MetricsService()),
      child: const _RoomBookingView(),
    );
  }
}

class _RoomBookingView extends StatefulWidget {
  const _RoomBookingView();

  @override
  State<_RoomBookingView> createState() => _RoomBookingViewState();
}

class _RoomBookingViewState extends State<_RoomBookingView> {
  // Менеджеры
  late final KeyboardManager _keyboardManager;
  late final InactivityManager _inactivityManager;
  late final MetricsService _metricsService;
  late final WebSocketService _webSocketService;

  DateTime? _paymentDateTime;
  bool _isBedSelectionView = false; // Флаг для управления видимостью клавиатуры

  @override
  void initState() {
    super.initState();

    _keyboardManager = KeyboardManager();
    _metricsService = MetricsService();
    _webSocketService = WebSocketService();

    _inactivityManager = InactivityManager(
      onTimeout: () {
        if (mounted) {
          Timer? dialogTimer;
          showCupertinoDialog(
            context: context,
            builder: (ctx) {
              dialogTimer = Timer(const Duration(seconds: 60), () {
                if (mounted) {
                  Navigator.of(ctx).pop(); // Dismiss the dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    CupertinoPageRoute(builder: (context) => LockScreen()),
                    (route) => false,
                  );
                }
              });
              return CupertinoAlertDialog(
                title: const Text('Вы еще здесь?'),
                content: const Text('Если вы не ответите, сессия будет завершена.'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () {
                      dialogTimer?.cancel();
                      Navigator.of(ctx).pop();
                      _inactivityManager.reset(); // Reset the main inactivity timer
                    },
                    child: const Text('Да'),
                  ),
                ],
              );
            },
          ).then((_) {
            dialogTimer?.cancel(); // Ensure dialog timer is cancelled if dialog is dismissed by other means
          });
        }
      },
    );

    _keyboardManager.initializeGuestFocusListeners(setState);

    _inactivityManager.start();
    _metricsService.startPaymentScenario();
  }

  @override
  void dispose() {
    _keyboardManager.dispose();
    _inactivityManager.dispose();
    _webSocketService.disconnect();
    super.dispose();
  }

  void _onStepChanged(BookingStep newStep) {
    // Сбрасываем флаг при переходе на любой другой шаг
    if (newStep != BookingStep.roomSelection) {
      setState(() {
        _isBedSelectionView = false;
      });
    }

    if (newStep == BookingStep.guestInfo) {
      _keyboardManager.registerFields(
        controllers: [
          _keyboardManager.fullNameController,
          _keyboardManager.phoneNumberController,
        ],
        focusNodes: [
          _keyboardManager.fullNameFocusNode,
          _keyboardManager.phoneNumberFocusNode,
        ],
        phoneFieldIndex: 1,
      );
      _keyboardManager.focusFirstField();
    } else if (newStep == BookingStep.roomSelection) {
      _keyboardManager.registerFields(
        controllers: [
          _keyboardManager.roomSearchController,
        ],
        focusNodes: [
          _keyboardManager.roomSearchFocusNode,
        ],
        phoneFieldIndex: null,
      );
      _keyboardManager.roomSearchFocusNode.requestFocus();
    } else if (newStep == BookingStep.itemSelection) {
      _keyboardManager.registerFields(
        controllers: [
          _keyboardManager.itemSearchController,
        ],
        focusNodes: [
          _keyboardManager.itemSearchFocusNode,
        ],
        phoneFieldIndex: null,
      );
      _keyboardManager.itemSearchFocusNode.requestFocus();
    }
  }

  Future<void> _nextStep() async {
    final cubit = context.read<BookingCubit>();
    cubit.nextStep();
  }

  void _previousStep() {
    final cubit = context.read<BookingCubit>();
    cubit.previousStep();
  }

  void _onBookingSuccess() {
    _inactivityManager.start(); // Включаем обратно режим бездействия
    _paymentDateTime = DateTime.now();
    _metricsService.recordSuccessfulPayment();
    context.read<BookingCubit>().markBookingSuccessful();
  }

  void _onPaymentError() {
    _inactivityManager.start(); // Включаем обратно режим бездействия
    context.read<BookingCubit>().setPaymentError();
  }

  void _onBookingError(String message) {
    _showErrorDialog('Не удалось завершить бронирование.\n\n$message');
  }

  void _showHardwareErrorDialog(String message, Future<bool> Function() retryPrint) {
    final cubit = context.read<BookingCubit>();
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Ошибка оборудования'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                color: CupertinoColors.systemOrange, size: 48),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 8),
            const Text(
              'Платёж принят, но возникла проблема с оборудованием. Обратитесь к администратору.',
              style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await retryPrint();
              if (success) {
                if (mounted) cubit.markBookingSuccessful();
              } else {
                if (mounted) _showHardwareErrorDialog('Повторная печать не удалась.', retryPrint);
              }
            },
            child: const Text('Повторить печать'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              cubit.markBookingSuccessful();
            },
            child: const Text('Завершить без чека'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
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
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingCubit, BookingState>(
      listener: (context, state) {
        _onStepChanged(state.currentStep);
      },
      listenWhen: (previous, current) => previous.currentStepIndex != current.currentStepIndex,
      child: BlocBuilder<BookingCubit, BookingState>(
        builder: (context, state) {
          final currentStep = state.currentStep;
          final showBottomBar = currentStep != BookingStep.confirmation &&
              currentStep != BookingStep.paymentExecution &&
              currentStep != BookingStep.success &&
              currentStep != BookingStep.paymentError;

          final showSidebar = currentStep != BookingStep.paymentExecution &&
              currentStep != BookingStep.success &&
              currentStep != BookingStep.paymentError;

          final isRoomNumberSelection = currentStep == BookingStep.roomSelection && !_isBedSelectionView;
          final showKeyboard = currentStep == BookingStep.guestInfo ||
              isRoomNumberSelection ||
              currentStep == BookingStep.itemSelection;

          return ChangeNotifierProvider.value(
            value: _keyboardManager.keyboardNotifier,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _inactivityManager.reset,
              onPanDown: (_) => _inactivityManager.reset(),
              child: CupertinoPageScaffold(
                backgroundColor: const Color(0xFF000000),
                child: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 500),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 400),
                                      switchInCurve: Curves.easeInOut,
                                      switchOutCurve: Curves.easeInOut,
                                      transitionBuilder: (child, animation) {
                                        final offsetAnimation = Tween<Offset>(
                                          begin: const Offset(0.1, 0.0),
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        ));
                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _buildCurrentStepWidget(state),
                                    ),
                                    if (showBottomBar) ...[
                                      const SizedBox(height: 40),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                        child: _buildBottomButton(context),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (showSidebar) ...[
                                const SizedBox(width: 24),
                                _buildSidebar(state),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (showKeyboard)
                        Center(
                          child: SizedBox(
                            width: 1200,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
                                                                                            child: CustomKeyboard(
                                                                                              onKeyPressed: _keyboardManager.keyboardNotifier.onKeyPressed,
                                                                                              numpadOnly: currentStep == BookingStep.roomSelection ||
                                                                                                  (currentStep == BookingStep.guestInfo && _keyboardManager.focusedFieldIndex == 1),
                                                                                            ),                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSidebar(BookingState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (state.currentStepIndex > 0)
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _previousStep,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: CupertinoColors.activeBlue,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                CupertinoIcons.chevron_back,
                                size: 18,
                                color: CupertinoColors.activeBlue,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Назад',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.activeBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (state.currentStepIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: CupertinoColors.systemRed,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Отмена',
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.systemRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BookingSidebar(
                steps: state.steps,
                currentStepIndex: state.currentStepIndex,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepWidget(BookingState state) {
    final cubit = context.read<BookingCubit>();

    switch (state.currentStep) {
      case BookingStep.buildingSelection:
        return StepBuildingSelection(
          key: const ValueKey('building'),
          selectedBuilding: state.bookingData.selectedBuilding,
          onBuildingSelected: cubit.setBuilding,
        );
      case BookingStep.roomTypeSelection:
        return const StepRoomTypeSelection(
          key: ValueKey('room_type'),
        );
      case BookingStep.roomSelection:
        return StepRoomSelection(
          key: const ValueKey('room'),
          selectedBuilding: state.bookingData.selectedBuilding,
          searchController: _keyboardManager.roomSearchController,
          searchFocusNode: _keyboardManager.roomSearchFocusNode,
          onViewChange: (isBedView) {
            setState(() {
              _isBedSelectionView = isBedView;
            });
          },
        );
      case BookingStep.guestInfo:
        return StepGuestInfo(
          key: const ValueKey('guest'),
          onChanged: (first, last, middle, phone) => cubit.setGuestData(
            firstName: first,
            lastName: last,
            middleName: middle,
            phoneNumber: phone,
          ),
          fullNameController: _keyboardManager.fullNameController,
          phoneNumberController: _keyboardManager.phoneNumberController,
          fullNameFocusNode: _keyboardManager.fullNameFocusNode,
          phoneNumberFocusNode: _keyboardManager.phoneNumberFocusNode,
        );
      case BookingStep.categorySelection:
        return StepCategorySelection(
          key: const ValueKey('category'),
          selectedCategory: state.bookingData.selectedCategory,
          onCategorySelected: cubit.setCategory,
        );
      case BookingStep.period:
        return StepPeriod(
          key: const ValueKey('period'),
          checkIn: state.bookingData.checkInDate,
          checkOut: state.bookingData.checkOutDate,
          onDatesChanged: cubit.setDates,
        );
      case BookingStep.itemSelection:
        return StepItemSelection(
          key: const ValueKey('items'),
          category: state.bookingData.selectedCategory,
          selectedItems: state.bookingData.selectedItems,
          onItemsChanged: cubit.setSelectedItems,
          searchController: _keyboardManager.itemSearchController,
          searchFocusNode: _keyboardManager.itemSearchFocusNode,
        );
      case BookingStep.payment:
        return StepPayment(
          key: const ValueKey('payment'),
          selectedMethod: state.bookingData.paymentMethod,
          onMethodSelected: cubit.setPaymentMethod,
          totalPrice: state.bookingData.totalPrice,
        );
      case BookingStep.confirmation:
        return StepConfirmation(
          key: const ValueKey('confirm'),
          data: state.bookingData.data,
          onSuccess: () => cubit.nextStep(),
          onError: _onBookingError,
        );
      case BookingStep.paymentExecution:
        // Отключаем режим бездействия во время оплаты
        _inactivityManager.stop();
        return StepPaymentExecution(
          key: const ValueKey('payment_execution'),
          data: state.bookingData.data,
          paymentMethod: state.bookingData.paymentMethod ?? 'Наличные',
          totalPrice: state.bookingData.totalPrice,
          webSocketService: _webSocketService,
          onPaymentComplete: _onBookingSuccess,
          onPaymentError: _onPaymentError,
          onCancel: (state.bookingData.paymentMethod ?? 'Наличные') == 'Наличные'
              ? () {
                  _inactivityManager.start();
                  _webSocketService.disconnect();
                  final newIndex = state.steps.indexOf(BookingStep.payment);
                  while (cubit.state.currentStepIndex > newIndex) {
                    cubit.previousStep();
                  }
                }
              : null,
          onHardwareError: (message, retryPrint) {
            _inactivityManager.start();
            _webSocketService.disconnect();
            _showHardwareErrorDialog(message, retryPrint);
          },
          onPaymentTimeout: () {
            _inactivityManager.start();
            _webSocketService.disconnect();
            showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('Время истекло'),
                content: const Text('Время на оплату истекло. Попробуйте снова.'),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      final newIndex = state.steps.indexOf(BookingStep.payment);
                      while (cubit.state.currentStepIndex > newIndex) {
                        cubit.previousStep();
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        );
      case BookingStep.paymentError:
        return StepPaymentError(
          key: const ValueKey('payment_error'),
          onRetry: () {
            final newIndex = state.steps.indexOf(BookingStep.payment);
            while (cubit.state.currentStepIndex > newIndex) {
              cubit.previousStep();
            }
          },
        );
      case BookingStep.success:
        _webSocketService.disconnect();
        return StepSuccess(
          key: const ValueKey('success'),
          totalPrice: state.bookingData.totalPrice,
          paymentDateTime: _paymentDateTime ?? DateTime.now(),
        );
    }
  }

  Widget _buildBottomButton(BuildContext context) {
    final cubit = context.read<BookingCubit>();
    final canProceed = cubit.canProceed();

    return CupertinoButton(
      color: CupertinoColors.activeBlue,
      disabledColor: const Color(0xFF2C2C2E),
      onPressed: canProceed ? _nextStep : null,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: Text(
            'Продолжить',
            style: TextStyle(
              color: canProceed ? CupertinoColors.white : CupertinoColors.systemGrey,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
