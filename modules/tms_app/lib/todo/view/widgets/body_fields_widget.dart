import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

class BodyFields extends StatelessWidget {
  final Widget header;
  final Widget field;
  final VoidCallback? action;
  final IconData? headerIcon;
  final String? buttonLabel;
  final WidgetRef ref;

  const BodyFields({
    super.key,
    required this.ref,
    required this.header,
    required this.field,
    this.action,
    this.headerIcon,
    this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headerIcon != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Icon(
              headerIcon,
              color: theme.textColor.withAlpha((255 * 0.8).toInt()),
            ),
          )
        else
          const SizedBox(width: 40),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 10),
            field,
          ],
        ),
      ],
    );
  }
}
