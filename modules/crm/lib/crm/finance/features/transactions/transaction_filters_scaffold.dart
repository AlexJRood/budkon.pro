import 'package:core/common/chrome/back_button.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'dart:ui' as ui;
import 'package:core/platform/navigation_service.dart';
import 'package:tms_app/todo/view/widgets/task_filters/pc_mobile_scaffold_widget.dart';

class MobileSheetScaffold extends StatelessWidget {
  final dynamic theme;
  final String title;
  final Widget body;
  final Widget actions;

  const MobileSheetScaffold({
    super.key,
    required this.theme,
    required this.title,
    required this.body,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            SheetHeader(theme: theme, title: title),
            const SizedBox(height: 8),
            Expanded(child: body),
            const SizedBox(height: 10),
            SafeArea(top: false, child: actions),
          ],
        ),
      ),
    );
  }
}

class PcDialogScaffold extends ConsumerWidget {
  final ThemeColors theme;
  final String title;
  final Widget body;
  final Widget actions;

  const PcDialogScaffold({
    super.key,
    required this.theme,
    required this.title,
    required this.body,
    required this.actions,
  });

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    return Stack(
      children: [
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: theme.adPopBackground.withAlpha((255 * 0.5).toInt()),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
          ),
        ),
        AlertDialog(
          backgroundColor: theme.adPopBackground.withAlpha(125),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(
            title,
            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
          ),
          content: body,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: actions,
            ),
          ],
        ),
        Positioned(
          top: DeviceTypeUtil.isCenterButtonIPhone(context) ? 20 : 40,
          left: 10,
          child: BackButtonHously(isNamedRoute: false),
        ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final ThemeColors theme;
  final String title;

  const _SheetHeader({required this.theme, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, color: theme.textColor),
        ),
      ],
    );
  }
}

class TransactionFilterActionsRow extends StatelessWidget {
  final ThemeColors theme;
  final VoidCallback onClear;
  final VoidCallback onApply;

  const TransactionFilterActionsRow({
    super.key,
    required this.theme,
    required this.onClear,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: theme.textColor,
            backgroundColor: theme.dashboardContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: onClear,
          child: const Text('Clear'),
        ),
        const SizedBox(width: 10),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: theme.themeTextColor,
            backgroundColor: theme.themeColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: onApply,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
