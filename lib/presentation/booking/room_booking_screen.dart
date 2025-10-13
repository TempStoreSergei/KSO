// ============================================
// lib/presentation/booking/room_booking_screen.dart
// ============================================

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:motel/core/services/metrics_service.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/domain/usecases/calculate_room_price.dart';
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
import 'package:motel/presentation/guest_info/keyboard_notifier.dart';
import 'package:motel/presentation/guest_info/numpad_keyboard.dart';
import 'package:provider/provider.dart';


class RoomBookingScreen extends StatefulWidget {
  const RoomBookingScreen({super.key});

  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  final BookingData _bookingData = BookingData();
  int _currentStepIndex = 0;
  bool _isBookingSuccessful = false;

  // Контроллеры и фокусы для полей гостя
  late final TextEditingController _lastNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _middleNameFocusNode = FocusNode();
  late KeyboardNotifier _keyboardNotifier;
  int _focusedFieldIndex = 0;

  // === НОВОЕ: Состояние для введенного номера комнаты ===
  String _roomNumberInput = '';
  RoomType? _selectedRoomType;

  // Глобальный таймер бездействия (60 секунд)
  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(seconds: 60);

  // Метрики и время платежа
  final _metricsService = MetricsService();
  DateTime? _paymentDateTime;

  // Use case для расчета цены
  final _calculateRoomPriceUseCase = CalculateRoomPriceUseCase();

  @override
  void initState() {
    super.initState();
    _lastNameController = TextEditingController();
    _firstNameController = TextEditingController();
    _middleNameController = TextEditingController();
    _keyboardNotifier = KeyboardNotifier();

    // Отслеживаем изменения фокуса
    _lastNameFocusNode.addListener(() {
      if (_lastNameFocusNode.hasFocus) {
        setState(() => _focusedFieldIndex = 0);
        _keyboardNotifier.setActiveField(0);
      }
    });
    _firstNameFocusNode.addListener(() {
      if (_firstNameFocusNode.hasFocus) {
        setState(() => _focusedFieldIndex = 1);
        _keyboardNotifier.setActiveField(1);
      }
    });
    _middleNameFocusNode.addListener(() {
      if (_middleNameFocusNode.hasFocus) {
        setState(() => _focusedFieldIndex = 2);
        _keyboardNotifier.setActiveField(2);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardNotifier.registerFields(
        controllers: [_lastNameController, _firstNameController, _middleNameController],
        focusNodes: [_lastNameFocusNode, _firstNameFocusNode, _middleNameFocusNode],
      );
      if (_currentStep == BookingStep.guestInfo) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _lastNameFocusNode.requestFocus();
        });
      }
    });

    _startInactivityTimer();
    _metricsService.startPaymentScenario();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameFocusNode.dispose();
    _firstNameFocusNode.dispose();
    _middleNameFocusNode.dispose();
    _keyboardNotifier.dispose();
    super.dispose();
  }

  // === НОВОЕ: Обработчик нажатий для цифровой клавиатуры ===
  void _onNumpadKeyPressed(String key) {
    setState(() {
      if (key == 'BACKSPACE') {
        if (_roomNumberInput.isNotEmpty) {
          _roomNumberInput = _roomNumberInput.substring(0, _roomNumberInput.length - 1);
        }
      } else if (_roomNumberInput.length < StepRoomSelection.maxRoomNumberLength) {
        _roomNumberInput += key;
      }

      // Обновляем данные бронирования
      if (_roomNumberInput.isNotEmpty) {
        // Создаем временный объект Room на основе введенного номера
        _bookingData.selectedRoom = Room(
          id: _roomNumberInput, // Используем номер как ID
          name: _roomNumberInput, // И как имя
          buildingId: _bookingData.selectedBuilding?.id ?? '',
          type: RoomType.all, // Тип неизвестен, т.к. вводится вручную
        );
      } else {
        _bookingData.selectedRoom = null;
      }
    });
  }


  List<BookingStep> get steps {
    final stepList = [
      BookingStep.buildingSelection,
      BookingStep.roomSelection,
      BookingStep.guestInfo,
      BookingStep.categorySelection,
    ];

    if (_bookingData.selectedCategory == BookingCategory.accommodation) {
      stepList.add(BookingStep.period);
    }
    else if (_bookingData.selectedCategory == BookingCategory.services ||
        _bookingData.selectedCategory == BookingCategory.ruleViolationPenalty ||
        _bookingData.selectedCategory == BookingCategory.propertyDamagePenalty) {
      stepList.add(BookingStep.itemSelection);
    }

    stepList.addAll([BookingStep.payment, BookingStep.confirmation, BookingStep.paymentExecution]);

    if (_isBookingSuccessful) {
      stepList.add(BookingStep.success);
    }
    return stepList;
  }

  BookingStep get _currentStep => steps[_currentStepIndex];

  bool _canProceed() {
    switch (_currentStep) {
      case BookingStep.buildingSelection:
        return _bookingData.selectedBuilding != null;
      case BookingStep.roomSelection:
        return _roomNumberInput.isNotEmpty &&
            _selectedRoomType != null &&
            _selectedRoomType != RoomType.all;
      case BookingStep.guestInfo:
        return (_bookingData.lastName?.isNotEmpty ?? false) &&
            (_bookingData.firstName?.isNotEmpty ?? false);
      case BookingStep.categorySelection:
        return _bookingData.selectedCategory != BookingCategory.unknown;
      case BookingStep.period:
        return true;
      case BookingStep.itemSelection:
        if (_bookingData.selectedCategory == BookingCategory.accommodation) {
          return true;
        }
        return _bookingData.selectedItems.isNotEmpty;
      case BookingStep.payment:
        return _bookingData.paymentMethod != null;
      case BookingStep.confirmation:
        return true;
      case BookingStep.paymentExecution:
        return false;
      case BookingStep.success:
        return false;
    }
  }

  Future<void> _nextStep() async {
    if (_currentStepIndex < steps.length - 1) {
      // Если переходим с шага выбора периода для проживания - рассчитываем цену
      if (_currentStep == BookingStep.period &&
          _bookingData.selectedCategory == BookingCategory.accommodation &&
          _bookingData.selectedRoom != null &&
          _bookingData.selectedBuilding != null) {

        try {
          // Показываем индикатор загрузки
          showCupertinoDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CupertinoActivityIndicator(radius: 20),
            ),
          );

          final roomType = _selectedRoomType?.toApiString() ?? 'all';
          final buildingId = int.tryParse(_bookingData.selectedBuilding!.id) ?? 0;
          final countDays = _bookingData.totalNights;

          final price = await _calculateRoomPriceUseCase(
            roomType: roomType,
            roomBuilding: buildingId,
            countDays: countDays,
          );

          // Сохраняем рассчитанную цену
          _bookingData.calculatedRoomPrice = price;

          // Закрываем индикатор загрузки
          if (mounted) Navigator.of(context).pop();

        } catch (e) {
          // Закрываем индикатор загрузки
          if (mounted) Navigator.of(context).pop();

          // Показываем ошибку
          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('Ошибка'),
                content: Text('Не удалось рассчитать цену проживания.\n\n$e'),
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
          return; // Не переходим дальше при ошибке
        }
      }

      setState(() => _currentStepIndex++);
      if (_currentStep == BookingStep.guestInfo) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _lastNameFocusNode.requestFocus();
        });
      }
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      if (_currentStep == BookingStep.itemSelection) {
        _bookingData.selectedItems.clear();
      } else if (_currentStep == BookingStep.categorySelection) {
        _bookingData.selectedCategory = BookingCategory.unknown;
        _bookingData.selectedItems.clear();
      }
      // === НОВОЕ: Сбрасываем комнату при возврате к ее выбору ===
      else if (_currentStep == BookingStep.guestInfo) {
        _bookingData.selectedRoom = null;
        _roomNumberInput = '';
        _selectedRoomType = null;
      }

      setState(() => _currentStepIndex--);

      if (_currentStep == BookingStep.guestInfo) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _lastNameFocusNode.requestFocus();
        });
      }
    }
  }

  void _onBookingSuccess() {
    _paymentDateTime = DateTime.now();
    _metricsService.recordSuccessfulPayment();
    setState(() {
      _isBookingSuccessful = true;
      _currentStepIndex++;
    });
  }

  void _onBookingError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text('Не удалось завершить бронирование.\n\n$message'),
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
    final bool showBottomBar = _currentStep != BookingStep.confirmation &&
        _currentStep != BookingStep.paymentExecution &&
        _currentStep != BookingStep.success;
    final bool showSidebar = _currentStep != BookingStep.paymentExecution &&
        _currentStep != BookingStep.success;

    // === ИЗМЕНЕНО: Логика отображения клавиатуры ===
    final bool showGuestKeyboard = _currentStep == BookingStep.guestInfo;
    final bool showNumpad = _currentStep == BookingStep.roomSelection;
    final bool showKeyboard = showGuestKeyboard || showNumpad;

    return ChangeNotifierProvider.value(
      value: _keyboardNotifier,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _resetInactivityTimer,
        onPanDown: (_) => _resetInactivityTimer(),
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
                                child: _buildCurrentStepWidget(),
                              ),
                              if (showBottomBar) ...[
                                const SizedBox(height: 40),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                  child: _buildBottomButton(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (showSidebar) ...[
                          const SizedBox(width: 24),
                          Column(
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
                                        if (_currentStepIndex > 0)
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
                                        if (_currentStepIndex > 0) const SizedBox(width: 12),
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
                                      steps: steps,
                                      currentStepIndex: _currentStepIndex,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // === ИЗМЕНЕНО: Блок отображения клавиатуры ===
                if (showKeyboard)
                  Center(
                    child: SizedBox(
                      // Numpad можно сделать уже
                      width: showNumpad ? 400 : 1200,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
                        // Выбираем какую клавиатуру показать
                        child: showNumpad
                            ? NumpadKeyboard(onKeyPressed: _onNumpadKeyPressed)
                            : CustomKeyboard(
                          onKeyPressed: _keyboardNotifier.onKeyPressed,
                          // Убираем цифры на экране ввода ФИО
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
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case BookingStep.buildingSelection:
        return StepBuildingSelection(
          key: const ValueKey('building'),
          selectedBuilding: _bookingData.selectedBuilding,
          onBuildingSelected: (building) => setState(() => _bookingData.selectedBuilding = building),
        );
      case BookingStep.roomSelection:
        return StepRoomSelection(
          key: const ValueKey('room'),
          roomNumber: _roomNumberInput,
          selectedBuilding: _bookingData.selectedBuilding,
          selectedRoomType: _selectedRoomType,
          onRoomTypeSelected: (type) {
            setState(() {
              _selectedRoomType = type;
              if (_bookingData.selectedRoom != null) {
                _bookingData.selectedRoom = Room(
                  id: _bookingData.selectedRoom!.id,
                  name: _bookingData.selectedRoom!.name,
                  buildingId: _bookingData.selectedRoom!.buildingId,
                  type: type,
                );
              }
            });
          },
        );
      case BookingStep.guestInfo:
        return StepGuestInfo(
          key: const ValueKey('guest'),
          onChanged: (first, last, middle) => setState(() {
            _bookingData.firstName = first;
            _bookingData.lastName = last;
            _bookingData.middleName = middle;
          }),
          lastNameController: _lastNameController,
          firstNameController: _firstNameController,
          middleNameController: _middleNameController,
          lastNameFocusNode: _lastNameFocusNode,
          firstNameFocusNode: _firstNameFocusNode,
          middleNameFocusNode: _middleNameFocusNode,
          focusedFieldIndex: _focusedFieldIndex,
        );
      case BookingStep.categorySelection:
        return StepCategorySelection(
          key: const ValueKey('category'),
          selectedCategory: _bookingData.selectedCategory,
          onCategorySelected: (category) => setState(() {
            _bookingData.selectedCategory = category;
            _bookingData.selectedItems.clear();
          }),
        );
      case BookingStep.period:
        return StepPeriod(
          key: const ValueKey('period'),
          checkIn: _bookingData.checkInDate,
          checkOut: _bookingData.checkOutDate,
          onDatesChanged: (checkIn, checkOut) => setState(() {
            _bookingData.checkInDate = checkIn;
            _bookingData.checkOutDate = checkOut;
          }),
        );
      case BookingStep.itemSelection:
        return StepItemSelection(
          key: const ValueKey('items'),
          category: _bookingData.selectedCategory,
          selectedItems: _bookingData.selectedItems,
          onItemsChanged: (items) => setState(() => _bookingData.selectedItems = items),
        );
      case BookingStep.payment:
        return StepPayment(
          key: const ValueKey('payment'),
          selectedMethod: _bookingData.paymentMethod,
          onMethodSelected: (method) => setState(() => _bookingData.paymentMethod = method),
          totalPrice: _bookingData.totalPrice,
        );
      case BookingStep.confirmation:
        return StepConfirmation(
          key: const ValueKey('confirm'),
          data: _bookingData,
          onSuccess: () {
            setState(() => _currentStepIndex++);
          },
          onError: _onBookingError,
        );
      case BookingStep.paymentExecution:
        return StepPaymentExecution(
          key: const ValueKey('payment_execution'),
          paymentMethod: _bookingData.paymentMethod ?? 'СБП',
          totalPrice: _bookingData.totalPrice,
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
                      setState(() {
                        _currentStepIndex = steps.indexOf(BookingStep.payment);
                      });
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
          totalPrice: _bookingData.totalPrice,
          paymentDateTime: _paymentDateTime ?? DateTime.now(),
        );
    }
  }

  Widget _buildBottomButton() {
    final canProceed = _canProceed();
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