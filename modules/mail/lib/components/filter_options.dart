// mail_type_filter_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mail/utils/api_services.dart';
import 'package:mail/utils/mail_filters.dart';

typedef EmailButtonStyleBuilder = ButtonStyle Function(bool isSelected, Color bg);

/// -------------------------
/// PURE WIDGET (no Riverpod)
/// -------------------------
class MailFilterButton extends StatelessWidget {
  final String label;
  final String value;
  final String? selectedValue;
  final VoidCallback? onPressed;

  /// Visuals
  final EdgeInsetsGeometry padding;
  final double height;
  final double? width;
  final Color backgroundColor;
  final Color textColor;
  final EmailButtonStyleBuilder? styleBuilder;

  const MailFilterButton({
    super.key,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onPressed,
    this.padding = const EdgeInsets.all(5),
    this.height = 50,
    this.width,
    required this.backgroundColor,
    required this.textColor,
    this.styleBuilder,
  });

  ButtonStyle _defaultStyle(bool isSelected, Color bg) {
    // Prosty fallback, gdy nie podasz buildEmailButtonStyle
    return TextButton.styleFrom(
      backgroundColor: isSelected ? bg.withAlpha(230) : bg.withAlpha(102),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;
    final style = (styleBuilder ?? _defaultStyle).call(isSelected, backgroundColor);

    return Container(
      padding: padding,
      height: height,
      width: width ?? double.infinity,
      child: TextButton(
        style: style,
        onPressed: onPressed,
        child: Text(label, style: TextStyle(color: textColor)),
      ),
    );
  }
}

/// ---------------------------------------
/// RIVERPOD ADAPTER (uses given providers)
/// ---------------------------------------
/// Po kliknięciu:
/// - ustawia sort na value,
/// - resetuje stronę do 1,
/// - opcjonalnie odświeża filteredEmailsProvider (jeśli przekażesz).
class MailMailTypeFilterButtonRP extends ConsumerWidget {
  final String label;
  final String value;

  /// Visuals
  final EdgeInsetsGeometry padding;
  final double height;
  final double? width;
  final Color backgroundColor;
  final Color textColor;
  final EmailButtonStyleBuilder? styleBuilder;

  const MailMailTypeFilterButtonRP({
    super.key,
    required this.label,
    required this.value,
    this.padding = const EdgeInsets.all(5),
    this.height = 50,
    this.width,
    required this.backgroundColor,
    required this.textColor,
    this.styleBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(mailTypeProvider);

    return MailFilterButton(
      label: label,
      value: value,
      selectedValue: selectedType,
      backgroundColor: backgroundColor,
      textColor: textColor,
      padding: padding,
      height: height,
      width: width,
      styleBuilder: styleBuilder, // ← tu możesz podać buildEmailButtonStyle
      onPressed: () {
        ref.read(mailTypeProvider.notifier).state = value;
        ref.read(mailPageProvider.notifier).state = 1;
        ref.read(filteredEmailsProvider);
        Navigator.of(context).pop();
       
      },
    );
  }
}
