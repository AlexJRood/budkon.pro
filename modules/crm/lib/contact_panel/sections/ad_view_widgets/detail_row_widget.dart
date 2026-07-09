import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.theme,
    required this.editingChild,
    required this.viewText,
    required this.isEditing,
  }) : _composite = false,
       editingBuilder = null;

  const DetailRow.composite({
    super.key,
    required this.label,
    required this.theme,
    required this.isEditing,
    required this.editingBuilder,
    required this.viewText,
  }) : editingChild = null,
       _composite = true;

  final String label;
  final ThemeColors theme;
  final bool isEditing;
  final Widget? editingChild;
  final String viewText;
  final bool _composite;
  final Widget Function()? editingBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.interRegular14.copyWith(
                color: theme.textColor,
              ),
            ),
            const Spacer(),
            if (isEditing)
              (_composite ? editingBuilder!.call() : editingChild!)
            else
              Text(
                viewText,
                style: AppTextStyles.interRegular.copyWith(
                  fontSize: 14,
                  color: theme.textColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        const Divider(color: AppColors.dark, thickness: 1),
        const SizedBox(height: 5),
      ],
    );
  }
}
