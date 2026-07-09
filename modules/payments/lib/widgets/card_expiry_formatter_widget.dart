

import 'package:flutter/services.dart';

class CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^_0-9]'), '');
    if (digitsOnly.length > 4) {
      digitsOnly = digitsOnly.substring(0, 4);
    }
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2) formatted += '/';
      formatted += digitsOnly[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
