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

  final buf = StringBuffer('+7');
  if (d.length <= 1) return buf.toString();

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
    final formatted = formatRuPhone(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
