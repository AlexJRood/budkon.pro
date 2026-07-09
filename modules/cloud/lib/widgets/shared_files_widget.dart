import 'package:core/ui/device_type_util.dart';
import 'package:cloud/providers/shared_files_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class SharedFilesWidget extends ConsumerWidget {
  final bool isMobile;
  const SharedFilesWidget({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final sharedState = ref.watch(sharedFilesProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: isMobile ? TopAppBarSize.resolve(context) + 10 : 16,
        left: isMobile ? 10 : 18,
        right: isMobile ? 10 : 18,
        bottom: isMobile ? BottomBarSize.resolve(context) + 10 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_alt_outlined, color: theme.textColor, size: 35),
              const SizedBox(width: 8),
              Text(
                "Shared files".tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ref.read(sharedFilesProvider.notifier).refresh();
                },
                icon: Icon(Icons.refresh, color: theme.textColor),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (sharedState.isLoading)
             Center(child: AppLottie.loading()),

          if (!sharedState.isLoading && sharedState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                border: Border.all(color: theme.dashboardBoarder, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                sharedState.error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),

          if (!sharedState.isLoading &&
              sharedState.error == null &&
              sharedState.items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                border: Border.all(color: theme.dashboardBoarder, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppLottie.noResults(),
            ),

          if (!sharedState.isLoading && sharedState.items.isNotEmpty)
            Column(
              children:
                  sharedState.items.map((share) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.dashboardContainer,
                        border: Border.all(
                          color: theme.dashboardBoarder,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.insert_drive_file_outlined,
                            color: theme.textColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  share.file,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "${"Shared with".tr}: ${share.recipientLabel}",
                                  style: TextStyle(color: theme.textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${"Type".tr}: ${share.recipientType}",
                                  style: TextStyle(color: theme.textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${"Can edit".tr}: ${share.canEdit ? "Yes".tr : "No".tr}",
                                  style: TextStyle(color: theme.textColor),
                                ),
                                if (share.note != null &&
                                    share.note!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "${"Note".tr}: ${share.note}",
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                ],
                                if (share.expiresAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "${"Expires".tr}: ${share.expiresAt}",
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }
}
