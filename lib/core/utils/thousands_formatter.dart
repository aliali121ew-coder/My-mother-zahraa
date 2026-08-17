import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsFormatter extends TextInputFormatter {
  static const _separator = ',';

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Convert Arabic-Indic numerals to Latin digits and strip formatting
    String cleanText = newValue.text
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll('٬', '')
        .replaceAll(_separator, '')
        .replaceAll(' ', '');

    // Handle invalid input
    final number = int.tryParse(cleanText);
    if (number == null) {
      return oldValue;
    }

    // Format with commas
    final formatter = NumberFormat('#,###', 'en');
    String formatted = formatter.format(number);

    // Calculate selection index offset
    int selectionIndex = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
