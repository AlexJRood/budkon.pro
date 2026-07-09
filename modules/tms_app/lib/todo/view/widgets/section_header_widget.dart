import 'package:flutter/material.dart';
import 'package:core/theme/design.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    this.subTitle,
    super.key,
    required this.theme,
  });
  final String title;
  final String? subTitle;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        if (subTitle != null) ...[
          const SizedBox(width: 10),
          Text(
            subTitle!,
            style: AppTextStyles.interLight.copyWith(
              color: theme.textColor.withAlpha((255 * 0.8).toInt()),
            ),
          ),
        ],
      ],
    );
  }
}
