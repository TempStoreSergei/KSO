import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class KeyboardNotifier extends ChangeNotifier {
  List<TextEditingController> _controllers = [];
  List<FocusNode> _focusNodes = [];
  int _activeIndex = 0;
  bool _isShiftEnabled = true;
  int? _phoneFieldIndex; // Индекс поля телефона

  final _phoneMask = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool get isShiftEnabled => _isShiftEnabled;
  TextEditingController? get activeController => _controllers.isNotEmpty ? _controllers[_activeIndex] : null;

  // Геттер для получения чистого номера телефона
  String get unmaskedPhone => _phoneMask.getUnmaskedText();

  bool isControllerActive(TextEditingController controller) {
    if (_controllers.isEmpty) return false;
    return _controllers[_activeIndex] == controller;
  }

  void registerFields({
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    int? phoneFieldIndex,
  }) {
    _controllers = controllers;
    _focusNodes = focusNodes;
    _phoneFieldIndex = phoneFieldIndex;
    if (_controllers.isNotEmpty && _focusNodes.isNotEmpty) {
      _activeIndex = 0;
      _focusNodes[_activeIndex].requestFocus();
    }
  }

  void setActiveControllerByIndex(int index) {
    if (index >= 0 && index < _controllers.length) {
      _activeIndex = index;
      _focusNodes[index].requestFocus();
      notifyListeners();
    }
  }

  // НОВЫЙ МЕТОД: устанавливает активное поле БЕЗ requestFocus (для синхронизации с UI)
  void setActiveField(int index) {
    if (index >= 0 && index < _controllers.length) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  void onKeyPressed(String key) {
    if (activeController == null) return;

    switch (key) {
      case 'BACKSPACE':
        _handleBackspace();
        break;
      case 'SHIFT':
        _toggleShift();
        break;
      case 'TAB':
        _handleTab();
        break;
      case 'SPACE':
        _insertText(' ');
        break;
      case 'LANG':
        debugPrint("Language key pressed");
        break;
      default:
        final textToInsert = _isShiftEnabled ? key.toUpperCase() : key.toLowerCase();
        _insertText(textToInsert);
        if (_isShiftEnabled) {
          _isShiftEnabled = false;
          notifyListeners();
        }
        break;
    }
  }

  void _toggleShift() {
    _isShiftEnabled = !_isShiftEnabled;
    notifyListeners();
  }

  void _handleTab() {
    final nextIndex = (_activeIndex + 1) % _controllers.length;
    setActiveControllerByIndex(nextIndex);
  }

  void _handleBackspace() {
    final controller = activeController!;

    // Если это поле телефона, используем маску
    if (_phoneFieldIndex != null && _activeIndex == _phoneFieldIndex) {
      final oldValue = controller.value;
      final selection = oldValue.selection;

      // Если курсор в начале, ничего не делаем
      if (selection.start == 0) return;

      // Удаляем один символ перед курсором
      final newText = oldValue.text.substring(0, selection.start - 1) +
                      oldValue.text.substring(selection.start);

      final newValue = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start - 1),
      );

      // Применяем маску
      final formatted = _phoneMask.formatEditUpdate(oldValue, newValue);
      controller.value = formatted;
      return;
    }

    // Для остальных полей - стандартная логика
    final text = controller.text;
    final selection = controller.selection;

    // Если есть выделенный текст, удаляем его
    if (selection.start != selection.end) {
      final newText = text.substring(0, selection.start) + text.substring(selection.end);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
      return;
    }

    // Если курсор в начале, ничего не делаем
    if (selection.start == 0) return;

    // Удаляем один символ перед курсором
    final newText = text.substring(0, selection.start - 1) + text.substring(selection.start);
    final newOffset = (selection.start - 1).clamp(0, newText.length);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  void _insertText(String text) {
    final controller = activeController!;

    // Если это поле телефона, используем маску
    if (_phoneFieldIndex != null && _activeIndex == _phoneFieldIndex) {
      final oldValue = controller.value;
      final selection = oldValue.selection;

      // Вставляем текст
      final newText = oldValue.text.replaceRange(
        selection.start,
        selection.end,
        text,
      );

      final newValue = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + text.length),
      );

      // Применяем маску
      final formatted = _phoneMask.formatEditUpdate(oldValue, newValue);
      controller.value = formatted;
      return;
    }

    // Для остальных полей - стандартная логика
    final selection = controller.selection;

    final newText = controller.text.replaceRange(
        selection.start,
        selection.end,
        text
    );

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (selection.start + text.length).clamp(0, newText.length),
      ),
    );
  }
}
