import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

TextStyle headerStyle(BuildContext context, WidgetRef ref) {
  final theme = ref.watch(themeColorsProvider);
  return TextStyle(
    color: theme.mobileTextcolor,
    fontWeight: FontWeight.bold,
  );
}

TextStyle customtextStyle(BuildContext context, WidgetRef ref) {
  final theme = ref.watch(themeColorsProvider);
  return TextStyle(color: theme.mobileTextcolor);
}

TextStyle textStylesubheading(BuildContext context, WidgetRef ref) {
  final theme = ref.watch(themeColorsProvider);
  return TextStyle(color: theme.mobileTextcolor.withAlpha((255 * 0.7).toInt()), fontSize: 12);
}
