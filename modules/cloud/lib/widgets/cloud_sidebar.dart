import 'package:core/ui/device_type_util.dart';
import 'package:cloud/api/add_folder.dart';
import 'package:cloud/api/move.dart';
import 'package:cloud/components/docs_type.dart';
import 'package:cloud/components/folder_tree.dart';
import 'package:cloud/models/query_params.dart';
import 'package:cloud/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';

class CloudSidebar extends ConsumerWidget {
  final VoidCallback? onUpgrade;
  const CloudSidebar({super.key, this.onUpgrade});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    // Ultimate Explorer Provider!
    final cloudSidebarAsync = ref.watch(cloudSidebarProvider);

    return Padding(
      padding: EdgeInsets.only(top: 10, left: 10, right: 10),
      child: Column(
        children: [
          if (isMobile) SizedBox(height: TopAppBarSize.resolve(context) - 5),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                border: Border.all(color: theme.dashboardBoarder, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.only(
                top: 18,
                left: 10,
                right: 10,
                bottom: 10,
              ),
              child: cloudSidebarAsync.when(
                data:
                    (cloudSidebar) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Scrollowana sekcja (wszystko oprócz quota)
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.cloud,
                                      color: theme.textColor,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Cloud Storage".tr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: elevatedButtonStyleRounded10
                                        .copyWith(
                                          side: WidgetStateProperty.all(
                                            BorderSide(
                                              color: theme.textColor,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                    onPressed:
                                        () => showAddFolderDialog(context,theme),
                                    child: SizedBox(
                                      height: 40,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          AppIcons.add(color: theme.textColor),
                                          const SizedBox(width: 10),
                                          Text(
                                            "New folder".tr,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w300,
                                              color: theme.textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "Local documents".tr,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // FOLDERTREE – dane z explorer.subfolders
                                FolderTreeWidget(
                                  key: ValueKey(
                                    ref.watch(
                                      cloudSidebarRefreshTriggerProvider,
                                    ),
                                  ),
                                  folders: cloudSidebar.folders,
                                  parentId: null,
                                  onFileDropped: (file, folder) async {
                                    debugPrint(
                                      'CloudSidebar: onFileDropped ${file.name} -> ${folder.name}',
                                    );
                                    await moveFileToFolder(
                                      ref,
                                      file,
                                      folder,
                                    );
                                  },
                                  onFolderDropped: (
                                    movedFolder,
                                    targetFolder,
                                  ) async {
                                    debugPrint(
                                      'CloudSidebar: onFolderDropped ${movedFolder.name} -> ${targetFolder.name}',
                                    );
                                    await moveFolderToFolder(
                                      ref,
                                      movedFolder,
                                      targetFolder,
                                    );
                                  },
                                  onTap: (folder) {
                                    ref.read(cloudSidebarSelectedTabProvider.notifier).state = null;

                                    ref.read(cloudExplorerParamsProvider.notifier).state =
                                        ref.read(cloudExplorerParamsProvider).copyWith(
                                          parent: folder.id,
                                          isDeleted: false,
                                        );
                                  },
                                ),
                                Divider(height: 24, color: theme.textColor),
                                // Files by type
                                CloudFilesByTypeSection(),
                                Divider(height: 24, color: theme.textColor),
                                ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.delete_outline,
                                    color: theme.textColor,
                                  ),
                                  title: Text(
                                    "Trash".tr,
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                  onTap: () {
                                    ref.read(cloudSidebarSelectedTabProvider.notifier).state =
                                        CloudSidebarTab.trash;

                                    ref.read(cloudExplorerParamsProvider.notifier).state =
                                        FolderQueryParams(isDeleted: true);
                                  },
                                  contentPadding: const EdgeInsets.only(
                                    left: 0,
                                    right: 0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (isMobile) const SizedBox(height: 100),
                                CloudQuotaWidget(onUpgrade: onUpgrade),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),

                      ],
                    ),
                loading: () => Center(child: AppLottie.loading(size: 450)),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, color: Colors.redAccent, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          "${'Mistake:'.tr} $err",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: Text('Retry'.tr),
                          onPressed: () {
                            ref.invalidate(cloudSidebarProvider);
                            ref.invalidate(storageQuotaProvider);
                            ref.read(cloudSidebarRefreshTriggerProvider.notifier).state++;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: isMobile ? BottomBarSize.resolve(context) : 10),
        ],
      ),
    );
  }
}

class CloudQuotaWidget extends ConsumerWidget {
  final VoidCallback? onUpgrade;
  const CloudQuotaWidget({super.key, this.onUpgrade});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageQuotaAsync = ref.watch(storageQuotaProvider);
    final theme = ref.read(themeColorsProvider);

    return storageQuotaAsync.when(
      data: (quota) {
        final usedGB = quota.usedBytes / (1024 * 1024 * 1024);
        final totalGB = quota.quotaBytes / (1024 * 1024 * 1024);
        final leftGB = totalGB - usedGB;

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 180;

            return Container(
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                border: Border.all(color: theme.dashboardBoarder, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(isNarrow ? 10 : 14),
              margin: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud, size: isNarrow ? 14 : 17, color: theme.textColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Storage".tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: isNarrow ? 12 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    "${leftGB.toStringAsFixed(2)} ${'GB left from'.tr} ${totalGB.toStringAsFixed(0)} GB",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.textColor, fontSize: isNarrow ? 11 : 13),
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: (usedGB / totalGB).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade900,
                    color: Colors.blueAccent,
                    minHeight: 7,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: elevatedButtonStyleRounded10.copyWith(
                        backgroundColor: WidgetStateProperty.all(theme.themeColor),
                        minimumSize: WidgetStateProperty.all(Size.fromHeight(isNarrow ? 32 : 36)),
                        padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: isNarrow ? 4 : 8)),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                      onPressed: onUpgrade,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.upgrade,
                            size: isNarrow ? 14 : 18,
                            color: theme.themeTextColor,
                          ),
                          if (!isNarrow) const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "Upgrade to Pro".tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.themeTextColor,
                                fontSize: isNarrow ? 11 : 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: LinearProgressIndicator(
          minHeight: 7,
          color: Colors.blueAccent,
          backgroundColor: Colors.black12,
        ),
      ),
      error: (err, _) => const SizedBox(),
    );
  }
}
