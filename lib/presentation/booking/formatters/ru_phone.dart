import 'package:flutter/services.dart';

String? normalizeRuPhoneDigits(String input) {
  final digits = input.replaceAll(RegExp(r'\D+'), '');
  if (digits.isEmpty) return null;

  var normalized = digits;
  if (normalized.startsWith('8') && normalized.length >= 11) {
    normalized = '7${normalized.substring(1)}';
  }
  if (normalized.startsWith('7') && normalized.length >= 11) {
    normalized = normalized.substring(0, 11);
  } else if (normalized.length >= 10) {
    normalized = '7${normalized.substring(normalized.length - 10)}';
  } else {
    return null;
  }

  if (normalized.length != 11) return null;
  if (!normalized.startsWith('7')) return null;
  return normalized;
}

String formatRuPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D+'), '');
  if (digits.isEmpty) return '';

  var d = digits;
  if (d.startsWith('8')) {
    d = '7${d.substring(1)}';
  } else if (!d.startsWith('7')) {
    d = '7$d';
  }
  if (d.length > 11) d = d.substring(0, 11);

  // Если только "7" или меньше - возвращаем пустую строку (разрешаем полное удаление)
  if (d.length <= 1) return '';

  final buf = StringBuffer('+7');

  final aEnd = d.length.clamp(1, 4);
  final a = d.substring(1, aEnd);
  if (a.isNotEmpty) {
    buf.write(' ($a');
    if (a.length == 3) buf.write(')');
  }
  if (d.length <= 4) return buf.toString();

  final bEnd = d.length.clamp(4, 7);
  final b = d.substring(4, bEnd);
  if (b.isNotEmpty) buf.write(' $b');
  if (d.length <= 7) return buf.toString();

  final cEnd = d.length.clamp(7, 9);
  final c = d.substring(7, cEnd);
  if (c.isNotEmpty) buf.write('-$c');
  if (d.length <= 9) return buf.toString();

  final eEnd = d.length.clamp(9, 11);
  final e = d.substring(9, eEnd);
  if (e.isNotEmpty) buf.write('-$e');
  return buf.toString();
}

class RuPhoneTextInputFormatter extends TextInputFormatter {
  const RuPhoneTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Извлекаем только цифры
    final digits = newValue.text.replaceAll(RegExp(r'\D+'), '');

    // Если пусто, возвращаем пустое значение
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Форматируем
    final formatted = formatRuPhone(newValue.text);

    // Подсчитываем количество цифр до позиции курсора в старом значении
    final oldDigitsBeforeCursor = oldValue.text
        .substring(0, oldValue.selection.start)
        .replaceAll(RegExp(r'\D+'), '')
        .length;

    // Находим позицию курсора в новом отформатированном тексте
    int newCursorPos = 0;
    int digitCount = 0;

    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        digitCount++;
        if (digitCount > oldDigitsBeforeCursor) {
          newCursorPos = i;
          break;
        }
      }
    }

    // Если цифры закончились, курсор в конец
    if (digitCount <= oldDigitsBeforeCursor) {
      newCursorPos = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
}
