// ============================================
// lib/presentation/booking/managers/keyboard_manager.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/guest_info/keyboard_notifier.dart';

/// Менеджер для управления клавиатурой и полями ввода гостевой информации
class KeyboardManager {
  late final TextEditingController lastNameController;
  late final TextEditingController firstNameController;
  late final TextEditingController middleNameController;

  final FocusNode lastNameFocusNode = FocusNode();
  final FocusNode firstNameFocusNode = FocusNode();
  final FocusNode middleNameFocusNode = FocusNode();

  late final KeyboardNotifier keyboardNotifier;
  int focusedFieldIndex = 0;

  KeyboardManager() {
    lastNameController = TextEditingController();
    firstNameController = TextEditingController();
    middleNameController = TextEditingController();
    keyboardNotifier = KeyboardNotifier();
  }

  /// Инициализация слушателей фокуса
  void initializeFocusListeners(void Function(void Function()) setState) {
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
  }

  /// Регистрация полей после построения виджета
  void registerFields() {
    keyboardNotifier.registerFields(
      controllers: [lastNameController, firstNameController, middleNameController],
      focusNodes: [lastNameFocusNode, firstNameFocusNode, middleNameFocusNode],
    );
  }

  /// Установка фокуса на первое поле
  void focusFirstField() {
    Future.delayed(const Duration(milliseconds: 100), () {
      lastNameFocusNode.requestFocus();
    });
  }

  /// Освобождение ресурсов
  void dispose() {
    lastNameController.dispose();
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameFocusNode.dispose();
    firstNameFocusNode.dispose();
    middleNameFocusNode.dispose();
    keyboardNotifier.dispose();
  }

  /// Получение текущих значений полей
  Map<String, String> getValues() {
    return {
      'lastName': lastNameController.text,
      'firstName': firstNameController.text,
      'middleName': middleNameController.text,
    };
  }
}
