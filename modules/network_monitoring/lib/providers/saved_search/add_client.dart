import 'package:crm/data/clients/client_saved_search.dart';
import 'package:network_monitoring/network_monitoring_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/lottie.dart';

final addClientToSavedSearch = Provider<AddSavedSearchToClientService>((ref) {
  return AddSavedSearchToClientService(ref);
});

class AddSavedSearchToClientService {
  final Ref ref;
  const AddSavedSearchToClientService(this.ref);

  Future<void> addClientToSavedSearch(int clientId, int savedSearchId) async {
    try {
      final response = await ApiServices.post(
        NetworkMonitoringUrls.clientSavedSearch('$clientId', '$savedSearchId'),
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        ref.invalidate(clientSavedSearchesProvider);
      } else {
        throw Exception('Failed to add client to saved search'.tr);
      }
    } catch (e) {
      debugPrint('Error adding client to saved search: $e');
      rethrow;
    }
  }
}

Future<void> addClientsToSavedSearch(
  BuildContext context,
  dynamic savedSearchId,
  WidgetRef ref,
) async {
  final theme = ref.watch(themeColorsProvider);

  final selectedClients = await showDialog<Set<int>>(
    context: context,
    builder: (dialogContext) {
      final screen = MediaQuery.of(dialogContext).size;
      final selected = <int>{};
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          final clientListAsyncValue = ref.watch(clientProvider);
          return AlertDialog(
            backgroundColor: theme.dashboardContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            title: Text(
              'add_clients_to_saved_searches'.tr,
              style: TextStyle(color: theme.textColor),
            ),
            content: SizedBox(
              width: screen.width * 0.5,
              height: screen.height * 0.5,
              child: clientListAsyncValue.when(
                data: (clients) {
                  if (clients.isEmpty) {
                    return Center(
                      child: Text(
                        'no_customers'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    );
                  }
                  return Scrollbar(
                    child: ListView.separated(
                      itemCount: clients.length,
                      separatorBuilder:
                          (_, __) => Divider(
                            height: 1,
                            color: theme.textColor.withOpacity(0.08),
                          ),
                      itemBuilder: (context, index) {
                        final client = clients[index];

                        final fullName = [
                          client.name,
                          if ((client.lastName ?? '').trim().isNotEmpty)
                            client.lastName!,
                        ].join(' ');

                        final isChecked = selected.contains(client.id);

                        return CheckboxListTile(
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: theme.themeColor,
                          checkColor: theme.dashboardContainer,
                          value: isChecked,
                          onChanged: (val) {
                            setStateDialog(() {
                              if (val == true) {
                                selected.add(client.id);
                              } else {
                                selected.remove(client.id);
                              }
                            });
                          },
                          title: Text(
                            fullName,
                            style: TextStyle(color: theme.textColor),
                          ),
                          subtitle:
                              (client.email != null &&
                                      client.email!.trim().isNotEmpty)
                                  ? Text(
                                    client.email!,
                                    style: TextStyle(
                                      color: theme.textColor.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  )
                                  : null,
                        );
                      },
                    ),
                  );
                },
                loading:
                    () => Center(
                      child: CircularProgressIndicator(color: theme.themeColor),
                    ),
                error:
                    (error, stack) => Center(
                      child: Text(
                        'failed_to_load_clients'.tr + error.toString(),
                        style: TextStyle(color: theme.textColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
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
                onPressed: () => Navigator.of(dialogContext).pop(selected),
                child: Text(
                  'Add'.tr,
                  style: TextStyle(color: theme.themeColorText),
                ),
              ),
            ],
          );
        },
      );
    },
  );

}

Future<void> addClientsToSavedSearchBottomSheet(
  BuildContext context,
  dynamic savedSearchId,
  WidgetRef ref,
) async {
  final theme = ref.watch(themeColorsProvider);

  final selectedClients = await showModalBottomSheet<Set<int>>(
  context: context,
  isScrollControlled: true,
  backgroundColor: theme.dashboardContainer,
  builder: (sheetContext) {
    final selected = <int>{};

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        final theme = ref.watch(themeColorsProvider);

        return Container(
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          child: StatefulBuilder(
            builder: (context, setStateSheet) {
              final clientListAsyncValue = ref.watch(clientProvider);

              return SafeArea(
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
                        'add_clients_to_saved_searches'.tr,
                        style: TextStyle(color: theme.textColor, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: clientListAsyncValue.when(
                          data: (clients) {
                            if (clients.isEmpty) {
                              return Center(
                                child: Text(
                                  'no_customers'.tr,
                                  style: TextStyle(color: theme.textColor),
                                ),
                              );
                            }

                            return Scrollbar(
                              child: ListView.separated(
                                controller: scrollController, 
                                itemCount: clients.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: theme.textColor.withOpacity(0.08),
                                ),
                                itemBuilder: (context, index) {
                                  final client = clients[index];

                                  final fullName = [
                                    client.name,
                                    if ((client.lastName ?? '').trim().isNotEmpty)
                                      client.lastName!,
                                  ].join(' ');

                                  final isChecked = selected.contains(client.id);

                                  return CheckboxListTile(
                                    dense: true,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    activeColor: theme.themeColor,
                                    checkColor: theme.dashboardContainer,
                                    value: isChecked,
                                    onChanged: (val) {
                                      setStateSheet(() {
                                        if (val == true) {
                                          selected.add(client.id);
                                        } else {
                                          selected.remove(client.id);
                                        }
                                      });
                                    },
                                    title: Text(
                                      fullName,
                                      style: TextStyle(color: theme.textColor),
                                    ),
                                    subtitle: (client.email != null &&
                                            client.email!.trim().isNotEmpty)
                                        ? Text(
                                            client.email!,
                                            style: TextStyle(
                                              color: theme.textColor.withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          )
                                        : null,
                                  );
                                },
                              ),
                            );
                          },
                          loading: () => Center(child: AppLottie.loading(size: 250)),
                          error: (error, stack) => Center(
                            child: Text(
                              'failed_to_load_clients'.tr + error.toString(),
                              style: TextStyle(color: theme.textColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ✅ Buttons are pinned (NOT scrollable)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
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
                            onPressed: () => Navigator.of(sheetContext).pop(selected),
                            child: Text(
                              'Add'.tr,
                              style: TextStyle(color: theme.themeColorText),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  },
);


  if (selectedClients != null && selectedClients.isNotEmpty) {
    for (final clientId in selectedClients) {
      await ref
          .read(addClientToSavedSearch)
          .addClientToSavedSearch(clientId, savedSearchId);
    }
    if (!context.mounted) return;
    context.showSnackBarLikeSection('clients_added_to_saved_search'.tr);
  }
}


extension ContextExtension on BuildContext {
  void showSnackBarLikeSection(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

