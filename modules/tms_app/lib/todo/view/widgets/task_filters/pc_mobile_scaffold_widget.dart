import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
    );
  }
}

class PcDialogScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: AlertDialog(
        backgroundColor: theme.popupcontainercolor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(
          title,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: body,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: actions,
          ),
        ],
      ),
    );
  }
}

class SheetHeader extends StatelessWidget {
  final dynamic theme;
  final String title;

  const SheetHeader({super.key, required this.theme, required this.title});

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
