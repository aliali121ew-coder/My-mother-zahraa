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
    
    // Remove all commas
    String newText = newValue.text.replaceAll(_separator, '');
    
    // Handle invalid input
    if (int.tryParse(newText) == null) {
      return oldValue;
    }

    // Format with commas
    final formatter = NumberFormat('#,###', 'en');
    String formatted = formatter.format(int.parse(newText));

    // Calculate selection index offset
    int selectionIndex = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
