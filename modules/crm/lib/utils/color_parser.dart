import 'package:flutter/material.dart';


extension HexColorParsing on String? {
  Color toColor({required Color fallback}) {
    final input = this;
    if (input == null) return fallback;

    var s = input.trim();
    if (s.isEmpty) return fallback;

    final colorWrap = RegExp(r'Color\((0x[a-fA-F0-9]{8})\)');
    final m = colorWrap.firstMatch(s);
    if (m != null) s = m.group(1)!;

    if (s.startsWith('0x')) {
      final v = int.tryParse(s.substring(2), radix: 16);
      return v == null ? fallback : Color(v);
    }

    s = s.replaceAll('#', '');

    if (s.length == 3) {
      s = '${s[0]}${s[0]}${s[1]}${s[1]}${s[2]}${s[2]}';
    }
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return fallback;

    final v = int.tryParse(s, radix: 16);
    return v == null ? fallback : Color(v);
  }
}
