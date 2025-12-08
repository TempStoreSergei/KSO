import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'keyboard_notifier.dart';

class CustomKeyboard extends StatefulWidget {
  final Function(String) onKeyPressed;
  final bool numpadOnly; // Флаг для отображения только цифровой клавиатуры

  const CustomKeyboard({
    super.key,
    required this.onKeyPressed,
    this.numpadOnly = false,
  });

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  bool _isRussian = true; // true = русский, false = английский
  bool _isNumberLayout = false; // true = цифровая раскладка

  @override
  Widget build(BuildContext context) {
    final List<List<String>> keys;

    if (widget.numpadOnly) {
      // Раскладка только для цифровой клавиатуры (numpad)
      keys = [
        ['1', '2', '3'],
        ['4', '5', '6'],
        ['7', '8', '9'],
        ['', '0', 'BACKSPACE'],
      ];
    } else if (_isNumberLayout) {
      // Цифровая раскладка
      keys = [
        ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
        ['-', '/', ':', ';', '(', ')', '₽', '&', '@', '"'],
        ['SHIFT', '.', ',', '?', '!', '\'', 'BACKSPACE'],
        ['ABC', 'SPACE'],
      ];
    } else {
      // Буквенные раскладки (без цифр)
      List<List<String>> russianKeys = [
        ['й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з', 'х', 'ъ'],
        ['ф', 'ы', 'в', 'а', 'п', 'р', 'о', 'л', 'д', 'ж', 'э'],
        ['SHIFT', 'я', 'ч', 'с', 'м', 'и', 'т', 'ь', 'б', 'ю', 'BACKSPACE'],
        ['123', 'SPACE', 'LANG'],
      ];
      List<List<String>> englishKeys = [
        ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
        ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
        ['SHIFT', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'BACKSPACE'],
        ['123', 'SPACE', 'LANG'],
      ];
      keys = _isRussian ? russianKeys : englishKeys;
    }

    return Consumer<KeyboardNotifier>(
      builder: (context, notifier, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Column(
                children: keys.asMap().entries.map((entry) {
                  List<String> row = entry.value;
                  bool isNumpadLayout = widget.numpadOnly;

                  return Padding(
                    padding: EdgeInsets.only(
                      left: !isNumpadLayout && !_isNumberLayout && (row.contains('ф') || row.contains('SHIFT') || row.contains('a')) ? 36.0 : 0.0,
                      bottom: 12.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: row.map((key) {
                        return _buildKey(context, key, notifier.isShiftEnabled, isNumpadLayout);
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKey(BuildContext context, String key, bool isShiftEnabled, bool isNumpad) {
    if (key == '') {
      return Container(width: 84, height: 60, margin: const EdgeInsets.all(6.0));
    }

    final bool isLetterKey = !isNumpad && !_isNumberLayout && key.length == 1 && !_isDigit(key);
    final bool isDigitKey = _isDigit(key);
    final bool isSpaceKey = key == 'SPACE';
    final bool isTabOrLangKey = key == 'LANG' || key == '123' || key == 'ABC';
    // final bool isSpecialFunctionKey = key == 'SHIFT' || key == 'BACKSPACE';

    final Color letterKeyColor = Colors.white.withValues(alpha: 0.35);
    final Color digitKeyColor = Colors.white.withValues(alpha: 0.25);
    final Color specialKeyColor = Colors.black.withValues(alpha: 0.25);

    Widget keyChild;
    switch (key) {
      case 'SHIFT':
        keyChild = Icon(CupertinoIcons.shift_fill, color: isShiftEnabled ? CupertinoColors.activeBlue : Colors.white, size: 28);
        break;
      case 'BACKSPACE':
        keyChild = const Icon(CupertinoIcons.delete_left_fill, color: Colors.white, size: 28);
        break;
      case 'SPACE':
        keyChild = const SizedBox();
        break;
      case '123':
        keyChild = const Text('123', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
        break;
      case 'ABC':
        keyChild = const Text('ABC', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
        break;
      case 'LANG':
        keyChild = Text(
          _isRussian ? 'EN' : 'RU',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        );
        break;
      default:
        final text = isShiftEnabled && isLetterKey ? key.toUpperCase() : key;
        keyChild = Text(text, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w400));
    }

    double keyWidth;
    if (isSpaceKey) {
      keyWidth = 250.0;
    } else if (isTabOrLangKey) {
      keyWidth = 84.0;
    } else if (isNumpad) {
      keyWidth = 84.0;
    } else {
      keyWidth = 60.0;
    }

    Color keyColor;
    if (isLetterKey) {
      keyColor = letterKeyColor;
    } else if (isDigitKey || _isNumberLayout || isSpaceKey) {
      keyColor = digitKeyColor;  // Пробел теперь использует цвет цифровой раскладки
    } else {
      keyColor = specialKeyColor;
    }

    return Container(
      width: keyWidth,
      height: 60.0,
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: keyColor,
        shape: (isLetterKey || (isDigitKey && !_isNumberLayout)) ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: (isLetterKey || (isDigitKey && !_isNumberLayout)) ? null : const BorderRadius.all(Radius.circular(50)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          highlightColor: Colors.white.withValues(alpha: 0.2),
          splashColor: Colors.transparent,
          borderRadius: BorderRadius.circular((isLetterKey || (isDigitKey && !_isNumberLayout)) ? 30 : 50),
          onTap: () {
            if (key == 'LANG') {
              setState(() {
                _isRussian = !_isRussian;
              });
            } else if (key == '123') {
              setState(() {
                _isNumberLayout = true;
              });
            } else if (key == 'ABC') {
              setState(() {
                _isNumberLayout = false;
              });
            } else {
              widget.onKeyPressed(key);
            }
          },
          child: Center(child: keyChild),
        ),
      ),
    );
  }

  bool _isDigit(String key) {
    return key.length == 1 && int.tryParse(key) != null;
  }
}