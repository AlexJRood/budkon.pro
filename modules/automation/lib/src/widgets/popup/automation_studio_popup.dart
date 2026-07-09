import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';

import '../../config/automation_studio_config.dart';
import '../../models/automation_context.dart';
import '../../screens/automation_builder_screen.dart';
import '../../screens/automation_form_builder_screen.dart';
import '../../screens/automation_workflow_list_screen.dart';

Future<T?> showAutomationStudioPopup<T>(
  ThemeColors theme,
  BuildContext context, {
  required AutomationContextData contextData,
  bool useFormBuilder = false,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Dialog(
        backgroundColor: theme.dashboardContainer,
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1600,
            maxHeight: 920,
          ),
          child: AutomationPresentationScope(
            presentation: AutomationShellPresentation.dialog,
            child: _AutomationPopupHome(
              contextData: contextData,
              useFormBuilder: useFormBuilder,
            ),
          ),
        ),
      );
    },
  );
}

class _AutomationPopupHome extends StatelessWidget {
  final AutomationContextData contextData;
  final bool useFormBuilder;
  final ScrollController? listScrollController;

  const _AutomationPopupHome({
    required this.contextData,
    required this.useFormBuilder,
    this.listScrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        if (settings.name == '/builder') {
          return MaterialPageRoute(
            builder: (_) => AutomationBuilderScreen(contextData: contextData),
          );
        }

        if (settings.name == '/form') {
          return MaterialPageRoute(
            builder: (_) => AutomationFormBuilderScreen(contextData: contextData),
          );
        }

        return MaterialPageRoute(
          builder: (innerContext) => Column(
            children: [
              _PopupHeader(contextData: contextData),
              Expanded(
                child: AutomationWorkflowListScreen(
                  contextData: contextData,
                  scopeType: contextData.defaultScopeType,
                  companyId: contextData.companyId,
                  ownerId: contextData.userId,
                  scrollController: listScrollController,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Close'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(innerContext).pushNamed('/form'),
                      icon: const Icon(Icons.view_list_rounded),
                      label: const Text('Form builder'),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(innerContext).pushNamed('/builder'),
                      icon: const Icon(Icons.account_tree_rounded),
                      label: const Text('Canvas builder'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Opens Automation Studio as a draggable, scrollable bottom sheet.
/// Intended for mobile layouts where a full [Dialog] doesn't fit well.
Future<T?> showAutomationStudioSheet<T>(
  ThemeColors theme,
  BuildContext context, {
  required AutomationContextData contextData,
  bool useFormBuilder = false,
  double initialChildSize = 0.75,
  double minChildSize = 0.4,
  double maxChildSize = 0.95,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (ctx, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: AutomationPresentationScope(
                    presentation: AutomationShellPresentation.dialog,
                    child: _AutomationPopupHome(
                      contextData: contextData,
                      useFormBuilder: useFormBuilder,
                      listScrollController: scrollController,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _PopupHeader extends StatelessWidget {
  final AutomationContextData contextData;

  const _PopupHeader({required this.contextData});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_motion_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              contextData.sourceLabel == null
                  ? 'Automation Studio'
                  : 'Automation Studio · ${contextData.sourceLabel}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).maybePop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
