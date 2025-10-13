// ============================================
// lib/presentation/booking/room_booking_screen_refactored.dart
// ============================================

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/services/metrics_service.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/domain/usecases/calculate_room_price.dart';
import 'package:motel/presentation/booking/cubit/booking_cubit.dart';
import 'package:motel/presentation/booking/cubit/booking_state.dart';
import 'package:motel/presentation/booking/managers/inactivity_manager.dart';
import 'package:motel/presentation/booking/managers/keyboard_manager.dart';
import 'package:motel/presentation/booking/managers/room_input_manager.dart';
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
import 'package:motel/presentation/booking/widgets/step_success.dart';
import 'package:motel/presentation/guest_info/custom_keyboard.dart';
import 'package:motel/presentation/guest_info/numpad_keyboard.dart';
import 'package:provider/provider.dart';

class RoomBookingScreen extends StatelessWidget {
  const RoomBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingCubit(),
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
  late final RoomInputManager _roomInputManager;
  late final InactivityManager _inactivityManager;
  late final MetricsService _metricsService;
  late final CalculateRoomPriceUseCase _calculateRoomPriceUseCase;

  DateTime? _paymentDateTime;

  @override
  void initState() {
    super.initState();

    // Инициализация менеджеров
    _keyboardManager = KeyboardManager();
    _roomInputManager = RoomInputManager();
    _metricsService = MetricsService();
    _calculateRoomPriceUseCase = CalculateRoomPriceUseCase();

    _inactivityManager = InactivityManager(
      onTimeout: () {
        if (mounted) Navigator.of(context).pop();
      },
    );

    // Настройка клавиатуры
    _keyboardManager.initializeFocusListeners(setState);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardManager.registerFields();
      final cubit = context.read<BookingCubit>();
      if (cubit.state.currentStep == BookingStep.guestInfo) {
        _keyboardManager.focusFirstField();
      }
    });

    _inactivityManager.start();
    _metricsService.startPaymentScenario();
  }

  @override
  void dispose() {
    _keyboardManager.dispose();
    _inactivityManager.dispose();
    super.dispose();
  }

  void _onNumpadKeyPressed(String key) {
    final cubit = context.read<BookingCubit>();
    setState(() {
      _roomInputManager.handleKeyPress(key);
      final room = _roomInputManager.createRoom(cubit.state.bookingData.selectedBuilding);
      cubit.setRoom(room);
    });
  }

  Future<void> _nextStep() async {
    final cubit = context.read<BookingCubit>();
    final state = cubit.state;

    // Расчет цены проживания при переходе с шага периода
    if (state.currentStep == BookingStep.period &&
        state.bookingData.selectedCategory == BookingCategory.accommodation &&
        state.bookingData.selectedRoom != null &&
        state.bookingData.selectedBuilding != null) {
      await _calculateRoomPrice(cubit);
    }

    cubit.nextStep();

    if (cubit.state.currentStep == BookingStep.guestInfo) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _keyboardManager.focusFirstField();
      });
    }
  }

  Future<void> _calculateRoomPrice(BookingCubit cubit) async {
    try {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CupertinoActivityIndicator(radius: 20),
        ),
      );

      final roomType = _roomInputManager.selectedRoomType?.toApiString() ?? 'all';
      final buildingId = int.tryParse(cubit.state.bookingData.selectedBuilding!.id) ?? 0;
      final countDays = cubit.state.bookingData.totalNights;

      final price = await _calculateRoomPriceUseCase(
        roomType: roomType,
        roomBuilding: buildingId,
        countDays: countDays,
      );

      cubit.setCalculatedRoomPrice(price);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('Не удалось рассчитать цену проживания.\n\n$e');
      }
    }
  }

  void _previousStep() {
    final cubit = context.read<BookingCubit>();

    if (cubit.state.currentStep == BookingStep.guestInfo) {
      _roomInputManager.reset();
    }

    cubit.previousStep();

    if (cubit.state.currentStep == BookingStep.guestInfo) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _keyboardManager.focusFirstField();
      });
    }
  }

  void _onBookingSuccess() {
    _paymentDateTime = DateTime.now();
    _metricsService.recordSuccessfulPayment();
    context.read<BookingCubit>().markBookingSuccessful();
  }

  void _onBookingError(String message) {
    _showErrorDialog('Не удалось завершить бронирование.\n\n$message');
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
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        final showBottomBar = state.currentStep != BookingStep.confirmation &&
            state.currentStep != BookingStep.paymentExecution &&
            state.currentStep != BookingStep.success;

        final showSidebar = state.currentStep != BookingStep.paymentExecution &&
            state.currentStep != BookingStep.success;

        final showGuestKeyboard = state.currentStep == BookingStep.guestInfo;
        final showNumpad = state.currentStep == BookingStep.roomSelection;
        final showKeyboard = showGuestKeyboard || showNumpad;

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
                          width: showNumpad ? 400 : 1200,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
                            child: showNumpad
                                ? NumpadKeyboard(onKeyPressed: _onNumpadKeyPressed)
                                : CustomKeyboard(
                              onKeyPressed: _keyboardManager.keyboardNotifier.onKeyPressed,
                              showNumbers: !showGuestKeyboard,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
      case BookingStep.roomSelection:
        return StepRoomSelection(
          key: const ValueKey('room'),
          roomNumber: _roomInputManager.roomNumberInput,
          selectedBuilding: state.bookingData.selectedBuilding,
          selectedRoomType: _roomInputManager.selectedRoomType,
          onRoomTypeSelected: (type) {
            setState(() {
              _roomInputManager.setRoomType(type);
              cubit.setRoomType(type);
            });
          },
        );
      case BookingStep.guestInfo:
        return StepGuestInfo(
          key: const ValueKey('guest'),
          onChanged: (first, last, middle) => cubit.setGuestData(
            firstName: first,
            lastName: last,
            middleName: middle,
          ),
          lastNameController: _keyboardManager.lastNameController,
          firstNameController: _keyboardManager.firstNameController,
          middleNameController: _keyboardManager.middleNameController,
          lastNameFocusNode: _keyboardManager.lastNameFocusNode,
          firstNameFocusNode: _keyboardManager.firstNameFocusNode,
          middleNameFocusNode: _keyboardManager.middleNameFocusNode,
          focusedFieldIndex: _keyboardManager.focusedFieldIndex,
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
        return StepPaymentExecution(
          key: const ValueKey('payment_execution'),
          paymentMethod: state.bookingData.paymentMethod ?? 'СБП',
          totalPrice: state.bookingData.totalPrice,
          onPaymentComplete: _onBookingSuccess,
          onPaymentTimeout: () {
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
                      // Возвращаемся к шагу оплаты
                      final newIndex = state.steps.indexOf(BookingStep.payment);
                      // Нужно вручную установить индекс
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
      case BookingStep.success:
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
