import 'package:flutter/material.dart';

import '../../models/automation_context.dart';
import 'automation_studio_popup.dart';
import 'package:core/theme/apptheme.dart';

class AutomationContextLauncherButton extends StatelessWidget {
  final AutomationContextData contextData;
  final String? label;
  final IconData icon;
  final bool compact;
  final ButtonStyle? style;
  final ThemeColors theme;

  const AutomationContextLauncherButton({
    super.key,
    required this.contextData,
    this.label,
    this.icon = Icons.account_tree_rounded,
    this.compact = false,
    this.style,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: label ?? 'Automation Studio',
        icon: Icon(icon),
        onPressed: () => showAutomationStudioPopup(
          theme,
          context,
          contextData: contextData,
        ),
      );
    }

    return OutlinedButton.icon(
      style: style,
      icon: Icon(icon),
      label: Text(label ?? 'Automation'),
      onPressed: () => showAutomationStudioPopup(
        theme,
        context,
        contextData: contextData,
      ),
    );
  }
}

Future<void> openTmsBoardAutomationStudio(
  ThemeColors theme,
  BuildContext context, {
  required String boardId,
  required String boardName,
  int? companyId,
  int? userId,
}) async {
  await showAutomationStudioPopup<void>(
    theme,
    context,
    contextData: AutomationContextData.tmsBoard(
      boardId: boardId,
      boardName: boardName,
      companyId: companyId,
      userId: userId,
    ),
  );
}

/// Opens Automation Studio for one TMS board as a draggable bottom sheet.
/// Use this on mobile layouts instead of [openTmsBoardAutomationStudio].
Future<void> openTmsBoardAutomationStudioSheet(
  ThemeColors theme,
  BuildContext context, {
  required String boardId,
  required String boardName,
  int? companyId,
  int? userId,
}) async {
  await showAutomationStudioSheet<void>(
    theme,
    context,
    contextData: AutomationContextData.tmsBoard(
      boardId: boardId,
      boardName: boardName,
      companyId: companyId,
      userId: userId,
    ),
  );
}

/// Opens Automation Studio for one TMS column.
/// Use this from the column menu or column settings button.
Future<void> openTmsColumnAutomationStudio(
  ThemeColors theme,
  BuildContext context, {
  required String columnId,
  required String columnKey,
  required String columnName,
  required String boardId,
  int? companyId,
  int? userId,
}) async {
  await showAutomationStudioPopup<void>(
    theme,
    context,
    contextData: AutomationContextData.tmsColumn(
      columnId: columnId,
      columnKey: columnKey,
      columnName: columnName,
      boardId: boardId,
      companyId: companyId,
      userId: userId,
    ),
  );
}
