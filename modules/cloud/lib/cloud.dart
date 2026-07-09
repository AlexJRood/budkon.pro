import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:cloud/emma/anchors/anchors_cloud.dart';
import 'package:cloud/components/drag_n_drop.dart';
import 'package:cloud/components/folders_grid.dart';
import 'package:cloud/components/recent_docs.dart';
import 'package:cloud/components/secure_storage.dart';
import 'package:cloud/components/storage_quota.dart';
import 'package:cloud/explorer.dart';
import 'package:cloud/models/query_params.dart';
import 'package:cloud/providers/providers.dart';
import 'package:cloud/providers/refresh_provider.dart';
import 'package:cloud/widgets/cloud_sidebar.dart';
import 'package:cloud/providers/shared_explorer_provider.dart';
import 'package:cloud/widgets/flie_drop.dart';
import 'package:cloud/widgets/pinned_cloud_shortcuts.dart';
import 'package:cloud/widgets/recently_opened_cloud_section.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:cloud/widgets/shared_files_screen.dart';
import 'package:cloud/widgets/shared_files_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:payments/go_pro/go_pro_page.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:cloud/widgets/cloud_sidebar.dart';
import 'package:cloud/models/query_params.dart';
import 'package:get/get_utils/get_utils.dart';

import 'providers/shared_files_provider.dart';

final cloudSidebarVisibleProvider = StateProvider<bool>((ref) => true);

class CloudStoragePage extends ConsumerStatefulWidget {
  const CloudStoragePage({super.key});

  @override
  ConsumerState<CloudStoragePage> createState() => _CloudStoragePageState();
}

class _CloudStoragePageState extends ConsumerState<CloudStoragePage> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sharedExplorerProvider.notifier).preload(forceRefresh: true);
    });
  }
  /// Build the UploadExtra based on the currently opened folder.
  /// We map params.parent (whatever type) to UploadExtra.folderId (String?).
  UploadExtra? _currentUploadExtra(WidgetRef ref) {
    final params = ref.read(cloudExplorerParamsProvider);
    final folderIdStr = params.parent?.toString();
    return UploadExtra(folderId: folderIdStr);
  }

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;
    final nav = ref.read(navigationService);

    return EmmaUiAnchorTarget(
      anchorKey: CloudEmmaAnchors.pageRoot.anchorKey,

      spec: CloudEmmaAnchors.pageRoot,
      // @emma-backend: CloudEmmaAnchors.pageRoot,
      child: BarManager(
        showClientToggle: true,
        sideMenuKey: sideMenuKey,
        appModule: AppModule.agentCrm,
        layoutTypePc: LayoutTypePc.row,
      layoutTypeTablet: LayoutTypeTablet.row,
        verticalButtons: EmmaUiAnchorTarget(
          anchorKey: CloudEmmaAnchors.uploadButtonMobile.anchorKey,

          spec: CloudEmmaAnchors.uploadButtonMobile,
          // @emma-backend: CloudEmmaAnchors.uploadButtonMobile,
          child: FilePickerButton(
            color: theme.themeColorText,
            onFilesPicked: (files, [controller]) {
              if (!context.mounted) return;

              final container = ProviderScope.containerOf(context, listen: false);
              final extra = _currentUploadExtra(ref);

              for (final file in files) {
                ref
                    .read(uploadQueueProvider.notifier)
                    .addFile(file, extra: extra);
              }

              showFileUploadOverlay(context, ref);

              refreshSidebarOnUploadComplete(container);
            },
          ),
        ),
        verticalButtonsPc: EmmaUiAnchorTarget(
          anchorKey: CloudEmmaAnchors.uploadButtonDesktop.anchorKey,

          spec: CloudEmmaAnchors.uploadButtonDesktop,
          // @emma-backend: CloudEmmaAnchors.uploadButtonDesktop,
          child: FilePickerButton(
            color: theme.themeColorText,
            onFilesPicked: (files, [controller]) {
              if (!context.mounted) return;

              final container = ProviderScope.containerOf(context, listen: false);
              final extra = _currentUploadExtra(ref);

              for (final file in files) {
                ref
                    .read(uploadQueueProvider.notifier)
                    .addFile(file, extra: extra);
              }

              showFileUploadOverlay(context, ref);

              refreshSidebarOnUploadComplete(container);
            },
          ),
        ),
        childrenPc: [
          Expanded(
            flex: 3,
            child: EmmaUiAnchorTarget(
              anchorKey: CloudEmmaAnchors.sidebar.anchorKey,

              spec: CloudEmmaAnchors.sidebar,
              // @emma-backend: CloudEmmaAnchors.sidebar,
              child: CloudSidebar(
                onUpgrade: () {
                  nav.pushNamedScreen(Routes.goPro);
                },
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: MouseRegion(
              cursor: ref.watch(isDownloadingProvider)
                  ? SystemMouseCursors.progress
                  : SystemMouseCursors.click,
              child: const _CloudContentView(),
            ),
          ),
        ],
        childrenMobile: [
          const _CloudContentView(isMobile: true),
        ],
        childrenMobileSwipeLeft: [
          EmmaUiAnchorTarget(
            anchorKey: CloudEmmaAnchors.sidebar.anchorKey,

            spec: CloudEmmaAnchors.sidebar,
            // @emma-backend: CloudEmmaAnchors.sidebar,
            child: const CloudSidebar(),
          ),
        ],
      ),
    );
  }
}

class _CloudContentView extends ConsumerWidget {
  final bool isMobile;
  const _CloudContentView({super.key, this.isMobile = false});

  UploadExtra? _currentUploadExtra(WidgetRef ref) {
    final params = ref.read(cloudExplorerParamsProvider);
    return UploadExtra(folderId: params.parent?.toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final params = ref.watch(cloudExplorerParamsProvider);
    final selectedTab = ref.watch(cloudSidebarSelectedTabProvider);

    if (selectedTab == CloudSidebarTab.sharedFiles) {
      return SingleChildScrollView(
        padding: EdgeInsets.only(
          top: isMobile ? TopAppBarSize.resolve(context) + 10 : 16,
          left: isMobile ? 10 : 18,
          right: isMobile ? 10 : 18,
          bottom: isMobile ? BottomBarSize.resolve(context) + 10 : 24,
        ),
        child: SharedFilesScreen(isMobile: isMobile),
      );
    }
    // Explorer mode when any filter/folder is active
    final isExplorerMode =
        params.showAllFiles ||
        params.parent != null ||
        (params.fileType != null && params.fileType!.isNotEmpty) ||
        (params.isDeleted ?? false) ||
        (params.search != null && params.search!.isNotEmpty);

    final Widget body;

    if (isExplorerMode) {
      body = SingleChildScrollView(
        padding: EdgeInsets.only(
          top: isMobile ? TopAppBarSize.resolve(context) + 10 : 16,
          left: isMobile ? 10 : 18,
          right: isMobile ? 10 : 18,
          bottom: isMobile ? BottomBarSize.resolve(context) + 10 : 24,
        ),
        child: CloudExplorer(isMobile: isMobile),
      );
    } else {
      body = UniversalFileDropZone(
        extra: _currentUploadExtra(ref),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: isMobile ? TopAppBarSize.resolve(context) + 10 : 16,
            left: isMobile ? 10 : 18,
            right: isMobile ? 10 : 18,
            bottom: isMobile ? BottomBarSize.resolve(context) + 10 : 24,
          ),
          child: EmmaUiAnchorTarget(
            anchorKey: CloudEmmaAnchors.homeRoot.anchorKey,

            spec: CloudEmmaAnchors.homeRoot,
            // @emma-backend: CloudEmmaAnchors.homeRoot,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmmaUiAnchorTarget(
                  anchorKey: CloudEmmaAnchors.homeHeader.anchorKey,

                  spec: CloudEmmaAnchors.homeHeader,
                  // @emma-backend: CloudEmmaAnchors.homeHeader,
                  child: Row(
                    children: [
                      Icon(Icons.cloud, color: theme.textColor, size: isMobile ? 28 : 35),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Cloud Storage".tr,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobile ? 19 : 24,
                            fontWeight: FontWeight.w700,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                EmmaUiAnchorTarget(
                  anchorKey: CloudEmmaAnchors.storageQuota.anchorKey,

                  spec: CloudEmmaAnchors.storageQuota,
                  // @emma-backend: CloudEmmaAnchors.storageQuota,
                  child: const StorageQuotaWidgetConnected(),
                ),
                const SizedBox(height: 32),
                EmmaUiAnchorTarget(
                  anchorKey: CloudEmmaAnchors.foldersSection.anchorKey,

                  spec: CloudEmmaAnchors.foldersSection,
                  // @emma-backend: CloudEmmaAnchors.foldersSection,
                  child: const FoldersSection(),
                ),
                const SizedBox(height: 32),
                const SizedBox(height: 32),
                EmmaUiAnchorTarget(
                  anchorKey: 'cloud.home.pinned_shortcuts',
                  // @emma-backend: CloudEmmaAnchors.pinnedShortcutsSection,
                  child: PinnedCloudShortcutsSection(isMobile: isMobile),
                ),
                const SizedBox(height: 32),
                RecentlyOpenedCloudSection(isMobile: isMobile),
                const SizedBox(height: 32),
                EmmaUiAnchorTarget(
                  anchorKey: CloudEmmaAnchors.recentDocumentsSection.anchorKey,

                  spec: CloudEmmaAnchors.recentDocumentsSection,
                  // @emma-backend: CloudEmmaAnchors.recentDocumentsSection,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Recent documents".tr,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Documents recent added".tr,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textColor.withAlpha(178),
                        ),
                      ),
                      const SizedBox(height: 16),
                      EmmaUiAnchorTarget(
                        anchorKey:
                            CloudEmmaAnchors.recentDocumentsTable.anchorKey,
                        // @emma-backend: CloudEmmaAnchors.recentDocumentsTable,
                        child: RecentDocumentsTable(isMobile: isMobile),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: BottomBarSize.sizedBox40(context)),
              ],
            ),
          ),
        ),
      );
    }

    return EmmaUiAnchorTarget(
      anchorKey: CloudEmmaAnchors.contentView.anchorKey,

      spec: CloudEmmaAnchors.contentView,
      // @emma-backend: CloudEmmaAnchors.contentView,
      child: body,
    );
  }
}