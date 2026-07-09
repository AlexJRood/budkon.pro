import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:crm/data/clients/client_saved_search.dart';
import 'package:core/theme/apptheme.dart';

import 'api.dart';

/// Provider for EditSavedSearchService
final editSavedSearchProvider = Provider<EditSavedSearchService>((ref) {
  return EditSavedSearchService(ref);
});

class EditSavedSearchService {
  final Ref ref;

  const EditSavedSearchService(this.ref);

  /// Edit existing saved search
  Future<void> editClient(int savedSearchId, Map<String, dynamic> data) async {
    try {
      final response = await ApiServices.patch(
        URLs.editSavedSearch('$savedSearchId'),
        data: data,
        hasToken: true,
      );

      if (response == null) {
        throw Exception('no_response_from_server'.tr);
      }

      if (response.statusCode == 200) {
        // Refresh saved searches lists
        ref.invalidate(savedSearchesProvider);
        ref.invalidate(clientSavedSearchesProvider);
      } else {
        throw Exception('Failed to edit saved search'.tr);
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        debugPrint('Error editing saved search: $e');
      }
      rethrow;
    }
  }
}

/// Shows dialog for editing saved search (title, description + notification toggles)
Future<void> showEditSavedSearchDialog(
  BuildContext context,
  dynamic action,
  dynamic actionId,
  WidgetRef ref,
) async {
  final titleController =
      TextEditingController(text: (action?.title ?? '').toString());
  final descriptionController =
      TextEditingController(text: (action?.description ?? '').toString());

  final theme = ref.watch(themeColorsProvider);

  // Support both camelCase and snake_case
  bool enableNotifications =
      ((action?.enableNotifications ?? action?.enable_notifications ?? false) ==
          true);
  bool enableEmailNotification =
      ((action?.enableEmailNotification ??
              action?.enable_email_notification ??
              false) ==
          true);

  Map<String, dynamic>? editedSearch;

  try {
    editedSearch = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: theme.dashboardContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              title: Text(
                'edit_saved_search'.tr,
                style: TextStyle(color: theme.textColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      cursorColor: theme.textColor,
                      style: TextStyle(color: theme.textColor),
                      decoration: InputDecoration(
                        hintText: 'Title'.tr,
                        filled: true,
                        fillColor: theme.textFieldColor,
                        hintStyle: TextStyle(color: theme.textColor.withAlpha(160)),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      cursorColor: theme.textColor,
                      style: TextStyle(color: theme.textColor),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Description'.tr,
                        filled: true,
                        fillColor: theme.textFieldColor,
                        hintStyle: TextStyle(color: theme.textColor.withAlpha(160)),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'in_app_notifications'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                      subtitle: Text(
                        'send_notifications_about_new_ads'.tr,
                        style: TextStyle(color: theme.textColor.withAlpha(204)),
                      ),
                      value: enableNotifications,
                      onChanged: (value) =>
                          setState(() => enableNotifications = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Email notifications'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                      subtitle: Text(
                        'send_emails_when_new_matching_ads_appear'.tr,
                        style: TextStyle(color: theme.textColor.withAlpha(204)),
                      ),
                      value: enableEmailNotification,
                      onChanged: (value) =>
                          setState(() => enableEmailNotification = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child:
                      Text('Cancel'.tr, style: TextStyle(color: theme.textColor)),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: theme.themeColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext, <String, dynamic>{
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'enable_notifications': enableNotifications,
                      'enable_email_notification': enableEmailNotification,
                    });
                  },
                  child:
                      Text('Save'.tr, style: TextStyle(color: theme.textColor)),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    titleController.dispose();
    descriptionController.dispose();
  }

  if (editedSearch != null) {
    if (kDebugMode) {
      // ignore: avoid_print
      debugPrint("Edited search: $editedSearch");
    }
    await ref.read(editSavedSearchProvider).editClient(actionId as int, editedSearch);
  }
}

Future<void> showEditSavedSearchBottomSheet(
  BuildContext context,
  dynamic action,
  dynamic actionId,
  WidgetRef ref,
) async {
  final theme = ref.watch(themeColorsProvider);

  bool enableNotifications =
      ((action?.enableNotifications ?? action?.enable_notifications ?? false) ==
          true);
  bool enableEmailNotification =
      ((action?.enableEmailNotification ??
              action?.enable_email_notification ??
              false) ==
          true);

  Map<String, dynamic>? editedSearch;

  editedSearch = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final titleController = TextEditingController(text: (action?.title ?? '').toString());
      final descriptionController = TextEditingController(text: (action?.description ?? '').toString());
      
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'edit_saved_search'.tr,
                          style: TextStyle(color: theme.textColor),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: titleController,
                                  autofocus: true,
                                  cursorColor: theme.textColor,
                                  style: TextStyle(color: theme.textColor),
                                  decoration: InputDecoration(
                                    hintText: 'Title'.tr,
                                    filled: true,
                                    fillColor: theme.textFieldColor,
                                    hintStyle: TextStyle(
                                      color: theme.textColor.withAlpha(160),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: descriptionController,
                                  cursorColor: theme.textColor,
                                  style: TextStyle(color: theme.textColor),
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Description'.tr,
                                    filled: true,
                                    fillColor: theme.textFieldColor,
                                    hintStyle: TextStyle(
                                      color: theme.textColor.withAlpha(160),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                   'in_app_notifications'.tr,
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                  subtitle: Text(
                                    'send_notifications_about_new_ads'.tr,
                                    style: TextStyle(
                                      color: theme.textColor.withAlpha(204),
                                    ),
                                  ),
                                  value: enableNotifications,
                                  onChanged: (value) =>
                                      setState(() => enableNotifications = value),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Email notifications'.tr,
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                  subtitle: Text(
                                    'send_emails_when_new_matching_ads_appear'.tr,
                                    style: TextStyle(
                                      color: theme.textColor.withAlpha(204),
                                    ),
                                  ),
                                  value: enableEmailNotification,
                                  onChanged: (value) => setState(
                                    () => enableEmailNotification = value,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: Text(
                                'Cancel'.tr,
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: theme.themeColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(sheetContext, <String, dynamic>{
                                  'title': titleController.text.trim(),
                                  'description': descriptionController.text.trim(),
                                  'enable_notifications': enableNotifications,
                                  'enable_email_notification': enableEmailNotification,
                                });
                              },
                              child: Text(
                                'Save'.tr,
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );

  if (editedSearch != null && actionId != null) {
    if (kDebugMode) {
      debugPrint("Edited search: $editedSearch");
    }
    final int savedSearchId = actionId is int ? actionId : int.tryParse(actionId.toString()) ?? 0;
    if (savedSearchId != 0) {
      await ref.read(editSavedSearchProvider).editClient(savedSearchId, editedSearch);
    } else {
      if (kDebugMode) {
        debugPrint("Error: Invalid actionId: $actionId");
      }
    }
  }
}