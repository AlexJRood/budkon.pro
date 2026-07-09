import 'package:cloud/models/query_params.dart';
import 'package:cloud/providers/shared_explorer_provider.dart';
import 'package:cloud/providers/shared_files_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:cloud/providers/providers.dart';

class CloudFilesByTypeSection extends ConsumerWidget {
  const CloudFilesByTypeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final selectedTab = ref.watch(cloudSidebarSelectedTabProvider);
    final sharedExplorerState = ref.watch(sharedExplorerProvider);
    final sharedFilesCount =
        sharedExplorerState.sharedToMe.totalCount +
            sharedExplorerState.iShared.totalCount;

    final fileTypeCounts =
        ref.watch(cloudSidebarProvider).value?.fileTypeCounts ?? {};

    Widget tile({
      required String title,
      required CloudSidebarTab tab,
      required IconData icon,
      required int count,
      required Color color,
      required VoidCallback onTap,
    }) {
      final isSelected = selectedTab == tab;

      return ListTile(
        dense: true,
        leading: Icon(icon, color: isSelected ? Colors.blueAccent : color),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blueAccent : theme.textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Text(
          "$count",
          style: TextStyle(
            color: isSelected ? Colors.blueAccent : theme.textColor,
            fontSize: 12,
          ),
        ),
        contentPadding: const EdgeInsets.only(left: 0, right: 0),
        onTap: onTap,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2, top: 16),
          child: Text(
            "Cloud documents".tr,
            style: TextStyle(color: theme.textColor, fontSize: 13),
          ),
        ),

        tile(
          title: "Images".tr,
          tab: CloudSidebarTab.images,
          icon: Icons.image,
          count: fileTypeCounts['image'] ?? 0,
          color: Colors.amber,
          onTap: () {
            ref.read(cloudSidebarSelectedTabProvider.notifier).state =
                CloudSidebarTab.images;
            ref.read(cloudExplorerParamsProvider.notifier).state =
                ref.read(cloudExplorerParamsProvider).copyWith(
                  parent: null,
                  search: null,
                  fileType: 'image',
                  isDeleted: false,
                  showAllFiles: true,
                );
          },
        ),

        tile(
          title: "Videos".tr,
          tab: CloudSidebarTab.videos,
          icon: Icons.videocam,
          count: fileTypeCounts['video'] ?? 0,
          color: Colors.lightBlueAccent,
          onTap: () {
            ref.read(cloudSidebarSelectedTabProvider.notifier).state =
                CloudSidebarTab.videos;
            ref.read(cloudExplorerParamsProvider.notifier).state =
                ref.read(cloudExplorerParamsProvider).copyWith(
                  parent: null,
                  search: null,
                  fileType: 'video',
                  isDeleted: false,
                  showAllFiles: true,
                );
          },
        ),

        tile(
          title: "Documents".tr,
          tab: CloudSidebarTab.documents,
          icon: Icons.folder,
          count: fileTypeCounts['document'] ?? 0,
          color: Colors.black54,
          onTap: () {
            ref.read(cloudSidebarSelectedTabProvider.notifier).state =
                CloudSidebarTab.documents;
            ref.read(cloudExplorerParamsProvider.notifier).state =
                ref.read(cloudExplorerParamsProvider).copyWith(
                  parent: null,
                  search: null,
                  fileType: 'document',
                  isDeleted: false,
                  showAllFiles: true,
                );
          },
        ),

        tile(
          title: "Others".tr,
          tab: CloudSidebarTab.others,
          icon: Icons.folder_open,
          count: fileTypeCounts['other'] ?? 0,
          color: theme.textColor,
          onTap: () {
            ref.read(cloudSidebarSelectedTabProvider.notifier).state =
                CloudSidebarTab.others;
            ref.read(cloudExplorerParamsProvider.notifier).state =
                ref.read(cloudExplorerParamsProvider).copyWith(
                  parent: null,
                  search: null,
                  fileType: 'other',
                  isDeleted: false,
                  showAllFiles: true,
                );
          },
        ),

        tile(
          title: "Emma".tr,
          tab: CloudSidebarTab.emma,
          icon: Icons.auto_awesome,
          count: fileTypeCounts['emma'] ?? 0,
          color: const Color(0xFF9B6BFF),
          onTap: () {
            ref.read(cloudSidebarSelectedTabProvider.notifier).state =
                CloudSidebarTab.emma;
            ref.read(cloudExplorerParamsProvider.notifier).state =
                ref.read(cloudExplorerParamsProvider).copyWith(
                  parent: null,
                  search: null,
                  fileType: 'emma',
                  isDeleted: false,
                  showAllFiles: true,
                );
          },
        ),

        tile(
          title: "Shares".tr,
          tab: CloudSidebarTab.sharedFiles,
          icon: Icons.people_alt_outlined,
          count: sharedFilesCount,
          color: theme.textColor,
          onTap: () {
            ref.read(cloudSidebarSelectedTabProvider.notifier).state =
                CloudSidebarTab.sharedFiles;

            ref.read(sharedExplorerProvider.notifier).selectTab(
              SharedExplorerTab.sharedToMe,
            );
          },
        ),

        tile(
          title: "All files".tr,
          tab: CloudSidebarTab.allFiles,
          icon: Icons.all_inbox,
          count: (fileTypeCounts['image'] ?? 0) +
              (fileTypeCounts['video'] ?? 0) +
              (fileTypeCounts['document'] ?? 0) +
              (fileTypeCounts['other'] ?? 0),
          color: theme.textColor,
          onTap: () {
            ref.read(cloudSidebarSelectedTabProvider.notifier).state =
                CloudSidebarTab.allFiles;
            ref.read(cloudExplorerParamsProvider.notifier).state =
                ref.read(cloudExplorerParamsProvider).copyWith(
                  parent: null,
                  search: null,
                  fileType: null,
                  isDeleted: false,
                  showAllFiles: true,
                );
          },
        ),
      ],
    );
  }
}