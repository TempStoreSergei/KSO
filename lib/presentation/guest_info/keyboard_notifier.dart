import 'package:flutter/material.dart';

class KeyboardNotifier extends ChangeNotifier {
  List<TextEditingController> _controllers = [];
  List<FocusNode> _focusNodes = [];
  int _activeIndex = 0;
  bool _isShiftEnabled = true;

  bool get isShiftEnabled => _isShiftEnabled;
  TextEditingController? get activeController => _controllers.isNotEmpty ? _controllers[_activeIndex] : null;

  bool isControllerActive(TextEditingController controller) {
    if (_controllers.isEmpty) return false;
    return _controllers[_activeIndex] == controller;
  }

  void registerFields({
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
  }) {
    _controllers = controllers;
    _focusNodes = focusNodes;
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
    final text = controller.text;
    final selection = controller.selection;
    if (selection.baseOffset == 0) return;
    final newText = text.substring(0, selection.baseOffset - 1) + text.substring(selection.baseOffset);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: (selection.baseOffset - 1).clamp(0, newText.length)),
    );
  }

  void _insertText(String text) {
    final controller = activeController!;
    final selection = controller.selection;

    // Используем встроенный механизм
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
