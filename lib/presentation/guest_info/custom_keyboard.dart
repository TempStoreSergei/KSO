import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'keyboard_notifier.dart';

class CustomKeyboard extends StatefulWidget {
  final Function(String) onKeyPressed;
  final bool showNumbers; // Флаг для отображения цифр

  const CustomKeyboard({
    super.key,
    required this.onKeyPressed,
    this.showNumbers = true, // По умолчанию показываем цифры
  });

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  bool _isRussian = true; // true = русский, false = английский

  @override
  Widget build(BuildContext context) {
    // Ряд с цифрами (если showNumbers = true)
    final List<String> numberRow = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];

    // Русская раскладка
    List<List<String>> russianKeys = [
      if (widget.showNumbers) numberRow,
      ['й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з', 'х', 'ъ'],
      ['ф', 'ы', 'в', 'а', 'п', 'р', 'о', 'л', 'д', 'ж', 'э'],
      ['SHIFT', 'я', 'ч', 'с', 'м', 'и', 'т', 'ь', 'б', 'ю', 'BACKSPACE'],
      ['TAB', 'SPACE', 'LANG'],
    ];

    // Английская раскладка
    List<List<String>> englishKeys = [
      if (widget.showNumbers) numberRow,
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
      ['SHIFT', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'BACKSPACE'],
      ['TAB', 'SPACE', 'LANG'],
    ];

    final keys = _isRussian ? russianKeys : englishKeys;

    return Consumer<KeyboardNotifier>(
      builder: (context, notifier, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Column(
                children: keys.asMap().entries.map((entry) {
                  int rowIndex = entry.key;
                  List<String> row = entry.value;

                  return Padding(
                    padding: EdgeInsets.only(
                      left: (row.contains('ф') || row.contains('SHIFT') || row.contains('a')) ? 36.0 : 0.0,
                      bottom: 12.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: row.map((key) {
                        return _buildKey(context, key, notifier.isShiftEnabled);
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

  Widget _buildKey(BuildContext context, String key, bool isShiftEnabled) {
    final bool isLetterKey = key.length == 1 && !_isDigit(key);
    final bool isDigitKey = _isDigit(key);
    final bool isSpaceKey = key == 'SPACE';
    final bool isTabOrLangKey = key == 'TAB' || key == 'LANG';

    final Color letterKeyColor = Colors.white.withOpacity(0.35);
    final Color digitKeyColor = Colors.white.withOpacity(0.25);
    final Color specialKeyColor = Colors.black.withOpacity(0.25);

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
      case 'TAB':
        keyChild = const Icon(CupertinoIcons.arrow_right_to_line, color: Colors.white, size: 28);
        break;
      case 'LANG':
        keyChild = Text(
          _isRussian ? 'EN' : 'RU',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        );
        break;
      default:
        // Применяем Shift для букв
        final text = isShiftEnabled && !isDigitKey ? key.toUpperCase() : key.toLowerCase();
        keyChild = Text(text, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w400));
    }

    double keyWidth;
    if (isSpaceKey) keyWidth = 250.0;
    else if (isTabOrLangKey) keyWidth = 84.0;
    else keyWidth = 60.0;

    Color keyColor;
    if (isLetterKey) keyColor = letterKeyColor;
    else if (isDigitKey) keyColor = digitKeyColor;
    else keyColor = specialKeyColor;

    return Container(
      width: keyWidth,
      height: 60.0,
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: keyColor,
        shape: (isLetterKey || isDigitKey) ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: (isLetterKey || isDigitKey) ? null : const BorderRadius.all(Radius.circular(50)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          highlightColor: Colors.white.withOpacity(0.2),
          splashColor: Colors.transparent,
          borderRadius: BorderRadius.circular((isLetterKey || isDigitKey) ? 30 : 50),
          onTap: () {
            if (key == 'LANG') {
              setState(() {
                _isRussian = !_isRussian;
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