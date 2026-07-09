import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/providers/saved_search/api.dart';
import 'package:core/theme/apptheme.dart';
import '../providers/saved_search/add_client.dart';
import '../providers/saved_search/edit.dart';
import '../providers/saved_search/remove.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:flutter/foundation.dart';

List<PieAction> buildPieMenuActionsNMsavedSearch(
  WidgetRef ref,
  dynamic action,
  dynamic actionId,
  BuildContext context,
  ThemeColors theme,
) {
  return [
    PieAction(
      tooltip: Text(
        'remove_saved_search'.tr,
        style: TextStyle(color: ref.watch(themeColorsProvider).textColor),
      ),
      onSelect: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          useRootNavigator: true,
          builder:
              (dialogContext) => AlertDialog(
                backgroundColor: theme.dashboardContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                title: Text(
                  'Confirm'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
                content: Text(
                  'are_you_sure_remove_search'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(
                      'Cancel'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: theme.themeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(
                      'Remove'.tr,
                      style: TextStyle(color: theme.themeColorText),
                    ),
                  ),
                ],
              ),
        );

        if (confirmed == true) {
          final success = await ref
              .read(removeSavedSearchProvider)
              .removeSavedSearch(actionId);

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: success ? theme.themeColor : Colors.red,
              content: Text(
                success
                    ? 'saved_search_removed'.tr
                    : 'failed_to_remove_saved_search'.tr,
                style: TextStyle(
                  color: success ? theme.themeColorText : Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        }
      },
      child: const FaIcon(FontAwesomeIcons.trash),
    ),
    PieAction(
      tooltip: Text(
        'edit_search'.tr,
        style: TextStyle(color: ref.watch(themeColorsProvider).textColor),
      ),
      onSelect: () async {
        if (kDebugMode) print("Editing action with id: $actionId".tr);

        final isMobile = MediaQuery.of(context).size.width < 700;
        if (isMobile) {
          await showEditSavedSearchBottomSheet(context, action, actionId, ref);
        } else {
          await showEditSavedSearchDialog(context, action, actionId, ref);
        }
        if (context.mounted) {
          ref.invalidate(savedSearchesProvider); 
       }
      },
      child: const FaIcon(FontAwesomeIcons.penToSquare),
    ),
    PieAction(
      tooltip: Text(
        'add_clients'.tr,
        style: TextStyle(color: ref.watch(themeColorsProvider).textColor),
      ),
      onSelect: () async {
        final isMobile = MediaQuery.of(context).size.width < 700;
        isMobile
            ? await addClientsToSavedSearchBottomSheet(context, actionId, ref)
            : await addClientsToSavedSearch(context, actionId, ref);
      },
      child: const FaIcon(FontAwesomeIcons.userPlus),
    ),
  ];
}

extension ContextExtension on BuildContext {
  void showSnackBarLikeSection(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
