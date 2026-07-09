import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:get/get_utils/get_utils.dart';
class CustomPopupMenuButton extends ConsumerWidget {
  final bool showEdit;
  final bool showDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final double horizontalPadding;
  final double iconSize;
  final Widget Function(double width, double height, Color color)
  appIconBuilder;
  final Color Function(BuildContext context) iconColorBuilder;

  const CustomPopupMenuButton({
    super.key,
    required this.showEdit,
    required this.showDelete,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
    required this.horizontalPadding,
    required this.iconSize,
    required this.appIconBuilder,
    required this.iconColorBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_MenuOption>(
      color: CustomColors.secondaryWidgetColor(
        context,
        ref,
      ), // background color of popup
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // smoother curvature
      ),
      offset: const Offset(0, 35), // positions the popup a bit lower
      shadowColor: Colors.black.withAlpha(51),
      onSelected: (value) {
        switch (value) {
          case _MenuOption.edit:
            onEdit();
            break;
          case _MenuOption.delete:
            onDelete();
            break;
          case _MenuOption.report:
            onReport();
            break;
        }
      },
      itemBuilder: (context) {
        final List<PopupMenuEntry<_MenuOption>> items = [];

        if (showEdit) {
          items.add(
            PopupMenuItem(
              value: _MenuOption.edit,
              child: _buildMenuRow(HugeIcons.strokeRoundedEdit01, 'Edit'.tr,CustomColors.secondaryWidgetTextColor(context, ref)),
            ),
          );
        }

        if (showDelete) {
          items.add(
            PopupMenuItem(
              value: _MenuOption.delete,
              child: _buildMenuRow(HugeIcons.strokeRoundedDelete01, 'Delete'.tr,CustomColors.secondaryWidgetTextColor(context, ref)),
            ),
          );
        }

        // Always show Report
        items.add(
          PopupMenuItem(
            value: _MenuOption.report,
            child: _buildMenuRow(HugeIcons.strokeRoundedFlag01, 'Report'.tr,CustomColors.secondaryWidgetTextColor(context, ref)),
          ),
        );

        return items;
      },
      // Custom trigger button design
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: null, // handled by PopupMenuButton internally
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding * 0.3),
          child: appIconBuilder(iconSize, iconSize, iconColorBuilder(context)),
        ),
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label, style:  TextStyle(fontSize: 14, color:color)),
      ],
    );
  }
}

enum _MenuOption { edit, delete, report }
