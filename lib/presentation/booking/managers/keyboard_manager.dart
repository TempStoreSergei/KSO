// ============================================
// lib/presentation/booking/managers/keyboard_manager.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/guest_info/keyboard_notifier.dart';

/// Менеджер для управления клавиатурой и полями ввода
class KeyboardManager {
  // Поля для данных гостя
  late final TextEditingController lastNameController;
  late final TextEditingController firstNameController;
  late final TextEditingController middleNameController;
  late final TextEditingController phoneNumberController;
  final FocusNode lastNameFocusNode = FocusNode();
  final FocusNode firstNameFocusNode = FocusNode();
  final FocusNode middleNameFocusNode = FocusNode();
  final FocusNode phoneNumberFocusNode = FocusNode();

  // Поля для поиска
  late final TextEditingController roomSearchController;
  late final TextEditingController itemSearchController;
  final FocusNode roomSearchFocusNode = FocusNode();
  final FocusNode itemSearchFocusNode = FocusNode();

  late final KeyboardNotifier keyboardNotifier;
  int focusedFieldIndex = 0;

  KeyboardManager() {
    lastNameController = TextEditingController();
    firstNameController = TextEditingController();
    middleNameController = TextEditingController();
    phoneNumberController = TextEditingController();
    roomSearchController = TextEditingController();
    itemSearchController = TextEditingController();
    keyboardNotifier = KeyboardNotifier();
  }

  /// Инициализация слушателей фокуса для полей гостя
  void initializeGuestFocusListeners(void Function(void Function()) setState) {
    lastNameFocusNode.addListener(() {
      if (lastNameFocusNode.hasFocus) {
        setState(() => focusedFieldIndex = 0);
        keyboardNotifier.setActiveField(0);
      }
    });

    firstNameFocusNode.addListener(() {
      if (firstNameFocusNode.hasFocus) {
        setState(() => focusedFieldIndex = 1);
        keyboardNotifier.setActiveField(1);
      }
    });

    middleNameFocusNode.addListener(() {
      if (middleNameFocusNode.hasFocus) {
        setState(() => focusedFieldIndex = 2);
        keyboardNotifier.setActiveField(2);
      }
    });

    phoneNumberFocusNode.addListener(() {
      if (phoneNumberFocusNode.hasFocus) {
        setState(() => focusedFieldIndex = 3);
        keyboardNotifier.setActiveField(3);
      }
    });
  }

  /// Регистрация полей для клавиатуры
  void registerFields({
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    int? phoneFieldIndex,
  }) {
    keyboardNotifier.registerFields(
      controllers: controllers,
      focusNodes: focusNodes,
      phoneFieldIndex: phoneFieldIndex,
    );
  }

  /// Установка фокуса на первое поле
  void focusFirstField() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (lastNameFocusNode.canRequestFocus) {
        lastNameFocusNode.requestFocus();
      }
    });
  }

  /// Освобождение ресурсов
  void dispose() {
    lastNameController.dispose();
    firstNameController.dispose();
    middleNameController.dispose();
    phoneNumberController.dispose();
    roomSearchController.dispose();
    itemSearchController.dispose();

    lastNameFocusNode.dispose();
    firstNameFocusNode.dispose();
    middleNameFocusNode.dispose();
    phoneNumberFocusNode.dispose();
    roomSearchFocusNode.dispose();
    itemSearchFocusNode.dispose();
    
    keyboardNotifier.dispose();
  }

  /// Получение текущих значений полей
  Map<String, String> getValues() {
    return {
      'lastName': lastNameController.text,
      'firstName': firstNameController.text,
      'middleName': middleNameController.text,
      'phoneNumber': phoneNumberController.text,
    };
  }
}
