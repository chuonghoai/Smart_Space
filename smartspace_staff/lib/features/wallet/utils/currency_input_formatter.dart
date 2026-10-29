import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Keep only digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.tryParse(digitsOnly) ?? 0;
    final newFormatted = _formatter.format(number);

    return TextEditingValue(
      text: newFormatted,
      selection: TextSelection.collapsed(offset: newFormatted.length),
    );
  }

  static double parseAmount(String text) {
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(digits) ?? 0.0;
  }
}

