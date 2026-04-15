// ============================================
// lib/presentation/booking/managers/keyboard_manager.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/guest_info/keyboard_notifier.dart';

/// Менеджер для управления клавиатурой и полями ввода
class KeyboardManager {
  // Поля для данных гостя
  late final TextEditingController fullNameController;
  late final TextEditingController phoneNumberController;
  final FocusNode fullNameFocusNode = FocusNode();
  final FocusNode phoneNumberFocusNode = FocusNode();

  // Поля для поиска
  late final TextEditingController roomSearchController;
  late final TextEditingController itemSearchController;
  final FocusNode roomSearchFocusNode = FocusNode();
  final FocusNode itemSearchFocusNode = FocusNode();

  late final KeyboardNotifier keyboardNotifier;
  int focusedFieldIndex = 0;

  KeyboardManager() {
    fullNameController = TextEditingController();
    phoneNumberController = TextEditingController();
    roomSearchController = TextEditingController();
    itemSearchController = TextEditingController();
    keyboardNotifier = KeyboardNotifier();
  }

  /// Инициализация слушателей фокуса для полей гостя
  void initializeGuestFocusListeners(void Function(void Function()) setState) {
    fullNameFocusNode.addListener(() {
      if (fullNameFocusNode.hasFocus) {
        setState(() => focusedFieldIndex = 0);
        keyboardNotifier.setActiveField(0);
      }
    });

    phoneNumberFocusNode.addListener(() {
      if (phoneNumberFocusNode.hasFocus) {
        setState(() => focusedFieldIndex = 1);
        keyboardNotifier.setActiveField(1);
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
      if (fullNameFocusNode.canRequestFocus) {
        fullNameFocusNode.requestFocus();
      }
    });
  }

  /// Освобождение ресурсов
  void dispose() {
    fullNameController.dispose();
    phoneNumberController.dispose();
    roomSearchController.dispose();
    itemSearchController.dispose();

    fullNameFocusNode.dispose();
    phoneNumberFocusNode.dispose();
    roomSearchFocusNode.dispose();
    itemSearchFocusNode.dispose();
    
    keyboardNotifier.dispose();
  }

  /// Получение текущих значений полей
  Map<String, String> getValues() {
    return {
      'fullName': fullNameController.text,
      'phoneNumber': phoneNumberController.text,
    };
  }
}
