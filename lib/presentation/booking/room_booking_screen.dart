// ============================================
// lib/presentation/booking/room_booking_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/presentation/booking/widgets/booking_sidebar.dart';
import 'package:motel/presentation/booking/widgets/step_building_selection.dart';
import 'package:motel/presentation/booking/widgets/step_category_selection.dart';
import 'package:motel/presentation/booking/widgets/step_confirmation.dart';
import 'package:motel/presentation/booking/widgets/step_guest_info.dart';
import 'package:motel/presentation/booking/widgets/step_item_selection.dart';
import 'package:motel/presentation/booking/widgets/step_payment.dart';
import 'package:motel/presentation/booking/widgets/step_period.dart';
import 'package:motel/presentation/booking/widgets/step_room_selection.dart';
import 'package:motel/presentation/booking/widgets/step_success.dart';
import 'package:motel/presentation/guest_info/custom_keyboard.dart';
import 'package:motel/presentation/guest_info/keyboard_notifier.dart';
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
        // ВАЖНО: синхронизируем клавиатуру с новым активным полем
        _keyboardNotifier.setActiveField(0);
      }
    });
    _firstNameFocusNode.addListener(() {
      if (_firstNameFocusNode.hasFocus) {
        setState(() => _focusedFieldIndex = 1);
        // ВАЖНО: синхронизируем клавиатуру с новым активным полем
        _keyboardNotifier.setActiveField(1);
      }
    });
    _middleNameFocusNode.addListener(() {
      if (_middleNameFocusNode.hasFocus) {
        setState(() => _focusedFieldIndex = 2);
        // ВАЖНО: синхронизируем клавиатуру с новым активным полем
        _keyboardNotifier.setActiveField(2);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardNotifier.registerFields(
        controllers: [_lastNameController, _firstNameController, _middleNameController],
        focusNodes: [_lastNameFocusNode, _firstNameFocusNode, _middleNameFocusNode],
      );
      // Устанавливаем фокус на первое поле когда открывается экран гостя
      if (_currentStep == BookingStep.guestInfo) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _lastNameFocusNode.requestFocus();
        });
      }
    });
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameFocusNode.dispose();
    _firstNameFocusNode.dispose();
    _middleNameFocusNode.dispose();
    _keyboardNotifier.dispose();
    super.dispose();
  }

  List<BookingStep> get steps {
    final stepList = [
      BookingStep.buildingSelection,
      BookingStep.roomSelection,
      BookingStep.guestInfo,
      BookingStep.categorySelection,
    ];

    // Для проживания добавляем только выбор периода (БЕЗ выбора услуг)
    if (_bookingData.selectedCategory == BookingCategory.accommodation) {
      stepList.add(BookingStep.period);
    }
    // Для услуг и штрафов добавляем выбор элементов
    else if (_bookingData.selectedCategory == BookingCategory.services ||
        _bookingData.selectedCategory == BookingCategory.ruleViolationPenalty ||
        _bookingData.selectedCategory == BookingCategory.propertyDamagePenalty) {
      stepList.add(BookingStep.itemSelection);
    }

    stepList.addAll([BookingStep.payment, BookingStep.confirmation]);

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
        return _bookingData.selectedRoom != null;
      case BookingStep.guestInfo:
        return (_bookingData.lastName?.isNotEmpty ?? false) &&
            (_bookingData.firstName?.isNotEmpty ?? false);
      case BookingStep.categorySelection:
        return _bookingData.selectedCategory != BookingCategory.unknown;
      case BookingStep.period:
        return true; // Даты всегда установлены по умолчанию
      case BookingStep.itemSelection:
        // Для услуг и штрафов хотя бы один элемент обязателен
        return _bookingData.selectedItems.isNotEmpty;
      case BookingStep.payment:
        return _bookingData.paymentMethod != null;
      case BookingStep.confirmation:
        return true;
      case BookingStep.success:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStepIndex < steps.length - 1) {
      setState(() => _currentStepIndex++);

      // Устанавливаем фокус когда переходим на экран гостя
      if (_currentStep == BookingStep.guestInfo) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _lastNameFocusNode.requestFocus();
        });
      }
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      // Очищаем данные при возврате на предыдущие шаги
      if (_currentStep == BookingStep.itemSelection) {
        _bookingData.selectedItems.clear();
      } else if (_currentStep == BookingStep.categorySelection) {
        _bookingData.selectedCategory = BookingCategory.unknown;
        _bookingData.selectedItems.clear();
      }

      setState(() => _currentStepIndex--);

      // Устанавливаем фокус когда возвращаемся на экран гостя
      if (_currentStep == BookingStep.guestInfo) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _lastNameFocusNode.requestFocus();
        });
      }
    }
  }

  void _onBookingSuccess() {
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
        _currentStep != BookingStep.success;
    final bool showSidebar = _currentStep != BookingStep.success;
    final bool showKeyboard = _currentStep == BookingStep.guestInfo ||
        (_currentStep == BookingStep.itemSelection &&
         (_bookingData.selectedCategory == BookingCategory.services ||
          _bookingData.selectedCategory == BookingCategory.ruleViolationPenalty ||
          _bookingData.selectedCategory == BookingCategory.propertyDamagePenalty));

    return ChangeNotifierProvider.value(
      value: _keyboardNotifier,
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
                      // Центральная колонка с контентом
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(opacity: animation, child: child);
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

                      // Правая колонка с кнопками и этапами
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
                                  // Кнопки управления
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
                                  // Панель этапов
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
              // Клавиатура внизу
              if (showKeyboard)
                Center(
                  child: SizedBox(
                    width: 1200,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
                      child: CustomKeyboard(onKeyPressed: _keyboardNotifier.onKeyPressed),
                    ),
                  ),
                ),
            ],
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
          onRoomSelected: (room) => setState(() => _bookingData.selectedRoom = room),
          selectedRoom: _bookingData.selectedRoom,
          selectedBuilding: _bookingData.selectedBuilding,
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
            _bookingData.selectedItems.clear(); // Очищаем выбранные элементы при смене категории
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
          onSuccess: _onBookingSuccess,
          onError: _onBookingError,
        );
      case BookingStep.success:
        return const StepSuccess(key: ValueKey('success'));
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