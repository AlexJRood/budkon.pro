import 'package:flutter/material.dart';

class ColorPickerResult {
  final Color? color;
  final bool isClear;
  const ColorPickerResult._(this.color, this.isClear);

  const ColorPickerResult.clear() : this._(null, true);

  factory ColorPickerResult.pick(Color color) =>
      ColorPickerResult._(color, false);
}
