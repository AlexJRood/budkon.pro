import 'dart:ui';
import 'package:cloud/models/shared_folder_fetch_model.dart';
import 'package:cloud/widgets/share_file_dialog.dart';
import 'package:cloud/models/shared_file_fetch_model.dart';
import 'package:cloud/providers/shared_explorer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import 'package:cloud/models/file.dart';
import 'package:cloud/widgets/file_viewer.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/design.dart';

class SharedFilesScreen extends ConsumerStatefulWidget {
  final bool isMobile;

  const SharedFilesScreen({
    super.key,
    this.isMobile = false,
  });

  @override
  ConsumerState<SharedFilesScreen> createState() => _SharedFilesScreenState();
}

class _SharedFilesScreenState extends ConsumerState<SharedFilesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(sharedExplorerProvider.notifier).preload(forceRefresh: true);
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      final selectedTab = _tabController.index == 0
          ? SharedExplorerTab.sharedToMe
          : SharedExplorerTab.iShared;

      ref.read(sharedExplorerProvider.notifier).selectTab(selectedTab);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(sharedExplorerProvider);

    final currentBucket = state.bucketFor(state.selectedTab);

    if (_tabController.index !=
        (state.selectedTab == SharedExplorerTab.sharedToMe ? 0 : 1)) {
      _tabController.index =
      state.selectedTab == SharedExplorerTab.sharedToMe ? 0 : 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_alt_outlined, color: theme.textColor, size: 35),
            const SizedBox(width: 8),
            Text(
              "Shares".tr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: theme.themeColor,
            labelColor: theme.textColor,
            unselectedLabelColor: theme.textColor.withAlpha(160),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                text:
                '${"Shared to me".tr} (${state.sharedToMe.totalCount})',
              ),
              Tab(
                text: '${"I shared".tr} (${state.iShared.totalCount})',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (currentBucket.isLoading)
          Center(child: AppLottie.loading())
        else if (currentBucket.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              border: Border.all(color: theme.dashboardBoarder, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              currentBucket.error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          )
        else ...[
            if (currentBucket.path.isNotEmpty) ...[
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.textColor),
                    onPressed: () {
                      ref.read(sharedExplorerProvider.notifier).goBackSharedFolder();
                    },
                  ),
                  Expanded(
                    child: Text(
                      currentBucket.path.join(' > '),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            _SharedExplorerContent(
              explorer: currentBucket.explorer,
              theme: theme,
              currentFolder: currentBucket.currentFolder,
              isMobile: widget.isMobile
            ),
          ]
      ],
    );
  }
}

class _SharedExplorerContent extends ConsumerWidget {
  final SharedExplorerResponse? explorer;
  final ThemeColors theme;
  final SharedFolder? currentFolder;
  final bool isMobile;

  const _SharedExplorerContent({
    required this.explorer,
    required this.theme,
    required this.currentFolder,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final files = explorer?.files ?? [];
    final folders = explorer?.subfolders ?? [];

    if (files.isEmpty && folders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          border: Border.all(color: theme.dashboardBoarder, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Column(
            children: [
              AppLottie.noResults(),
              Text(
                "No shared files found".tr,
                style: TextStyle(color: theme.textColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (folders.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Folders".tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ScrollConfiguration(
            behavior: AppScrollBehavior(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 80,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dashboardBoarder, width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Table(
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      columnWidths: const {
                        0: FixedColumnWidth(320), // Folder name
                        1: FixedColumnWidth(120), // Files count
                        2: FixedColumnWidth(130), // Created
                        3: FixedColumnWidth(130), // Updated
                        4: FixedColumnWidth(150), // Shared with
                        5: FixedColumnWidth(130), // Recipient type
                        6: FixedColumnWidth(140), // Permission
                        7: FixedColumnWidth(130), // Shared at
                        8: FixedColumnWidth(130), // Expires
                        9: FixedColumnWidth(220), // Note
                        10: FixedColumnWidth(120), // Public
                        11: FixedColumnWidth(120), // User
                        12: FixedColumnWidth(120), // Company
                        13: FixedColumnWidth(120), // Team
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: theme.dashboardBoarder.withAlpha(40),
                          ),
                          children: [
                            _tableHeader(theme, "Folder name".tr),
                            _tableHeader(theme, "Files".tr),
                            _tableHeader(theme, "Created".tr),
                            _tableHeader(theme, "Updated".tr),
                            _tableHeader(theme, "Shared with".tr),
                            _tableHeader(theme, "Recipient".tr),
                            _tableHeader(theme, "Permission".tr),
                            _tableHeader(theme, "Shared at".tr),
                            _tableHeader(theme, "Expires".tr),
                            _tableHeader(theme, "Note".tr),
                            _tableHeader(theme, "Public".tr),
                            _tableHeader(theme, "user".tr),
                            _tableHeader(theme, "Company".tr),
                            _tableHeader(theme, "Team".tr),
                          ],
                        ),
                        ...folders.map((folder) {
                          final share = folder.share;

                          return TableRow(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: theme.dashboardBoarder.withAlpha(80),
                                ),
                              ),
                            ),
                            children: [
                              _folderNameCell(context,folder, theme,ref),
                              _tableCell(theme, folder.filesCount.toString()),
                              _tableCell(theme, _formatDate(folder.createdAt)),
                              _tableCell(theme, _formatDate(folder.updatedAt)),
                              _tableCell(theme, _shareRecipientLabel(share)),
                              _tableCell(theme, share?.recipientType ?? "-"),
                              _tableCell(
                                theme,
                                share == null
                                    ? "-"
                                    : share.canEdit
                                    ? "Can edit".tr
                                    : "View only".tr,
                              ),
                              _tableCell(theme, _formatDate(share?.createdAt)),
                              _tableCell(theme, _formatDate(share?.expiresAt)),
                              _tableCell(
                                theme,
                                _cleanText(share?.note),
                                maxLines: 2,
                              ),
                              _tableCell(theme, folder.isPublic ? "Yes".tr : "No".tr),
                              _tableCell(theme, folder.user?.toString() ?? "-"),
                              _tableCell(theme, folder.company?.toString() ?? "-"),
                              _tableCell(theme, folder.team?.toString() ?? "-"),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        if (files.isNotEmpty) ...[
          if (folders.isNotEmpty) const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Files".tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ScrollConfiguration(
            behavior: AppScrollBehavior(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 80,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dashboardBoarder, width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Table(
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      columnWidths: const {
                        0: FixedColumnWidth(320), // File name
                        1: FixedColumnWidth(120), // Type
                        2: FixedColumnWidth(150), // MIME
                        3: FixedColumnWidth(110), // Size
                        4: FixedColumnWidth(130), // Created
                        5: FixedColumnWidth(130), // Updated
                        6: FixedColumnWidth(150), // Shared with
                        7: FixedColumnWidth(130), // Recipient type
                        8: FixedColumnWidth(140), // Permission
                        9: FixedColumnWidth(130), // Share created
                        10: FixedColumnWidth(130), // Expires
                        11: FixedColumnWidth(220), // Note
                        12: FixedColumnWidth(180), // Description
                        13: FixedColumnWidth(180), // Tags
                        14: FixedColumnWidth(120), // Public
                        15: FixedColumnWidth(120), // Deleted
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: theme.dashboardBoarder.withAlpha(40),
                          ),
                          children: [
                            _tableHeader(theme, "File name".tr),
                            _tableHeader(theme, "Type".tr),
                            _tableHeader(theme, "MIME type".tr),
                            _tableHeader(theme, "Size".tr),
                            _tableHeader(theme, "Created".tr),
                            _tableHeader(theme, "Updated".tr),
                            _tableHeader(theme, "Shared with".tr),
                            _tableHeader(theme, "Recipient".tr),
                            _tableHeader(theme, "Permission".tr),
                            _tableHeader(theme, "Shared at".tr),
                            _tableHeader(theme, "Expires".tr),
                            _tableHeader(theme, "Note".tr),
                            _tableHeader(theme, "Description".tr),
                            _tableHeader(theme, "Tags".tr),
                            _tableHeader(theme, "Public".tr),
                            _tableHeader(theme, "Deleted".tr),
                          ],
                        ),
                        ...files.map((file) {
                          final share = file.share;

                          return TableRow(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: theme.dashboardBoarder.withAlpha(80),
                                ),
                              ),
                            ),
                            children: [
                              _fileNameCell(context,file, theme,currentFolder,isMobile),
                              _tableCell(theme, file.fileType),
                              _tableCell(theme, file.mimeType ?? "-"),
                              _tableCell(theme, _formatBytes(file.size)),
                              _tableCell(theme, _formatDate(file.createdAt)),
                              _tableCell(theme, _formatDate(file.updatedAt)),
                              _tableCell(theme, share?.recipientLabel ?? "-"),
                              _tableCell(theme, share?.recipientType ?? "-"),
                              _tableCell(
                                theme,
                                share == null
                                    ? "-"
                                    : share.canEdit
                                    ? "Can edit".tr
                                    : "View only".tr,
                              ),
                              _tableCell(theme, _formatDate(share?.createdAt)),
                              _tableCell(theme, _formatDate(share?.expiresAt)),
                              _tableCell(
                                theme,
                                _cleanText(share?.note),
                                maxLines: 2,
                              ),
                              _tableCell(
                                theme,
                                _cleanText(file.description),
                                maxLines: 2,
                              ),
                              _tableCell(
                                theme,
                                file.tags.isEmpty ? "-" : file.tags.join(", "),
                                maxLines: 2,
                              ),
                              _tableCell(theme, file.isPublic ? "Yes".tr : "No".tr),
                              _tableCell(theme, file.isDeleted ? "Yes".tr : "No".tr),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tableHeader(ThemeColors theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tableCell(
      ThemeColors theme,
      String text, {
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _fileNameCell(
      BuildContext context,
      dynamic file,
      ThemeColors theme,
      SharedFolder? currentFolder,
      bool isMobile
      ) {
    return PieMenu(
      theme: PieTheme.of(context).copyWith(
        overlayColor: Colors.black.withValues(alpha: 0.70),
      ),
      onPressedWithDevice: (_)async {
        final cloudFile = _sharedFileToCloudFile(file);
        if(isMobile){
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              return DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.9,
                maxChildSize: 0.95,
                expand: false,
                builder: (ctx, scrollController) {
                  return FileViewerDialog(
                    isMobile: true,
                    file: cloudFile,
                  );
                },
              );
            },
          );
        }else{
          showDialog(
            context: context,
            builder: (_) => FileViewerDialog(file: cloudFile),
          );
        }


      },
      actions: [
        PieAction(
          tooltip: Text(
            'Edit'.tr,
            style: TextStyle(color: theme.textColor),
          ),
          onSelect: () {
            _openShareEditDialog(context, file, currentFolder);
          },
          child: const Icon(
            Icons.edit_outlined,
            color: AppColors.white,
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Row(
          children: [
            _fileIcon(file, theme),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openShareEditDialog(
      BuildContext context,
      dynamic file,
      SharedFolder? currentFolder,
      ) {
    final fileShareId = file.share?.shareId;
    final folderShareId = currentFolder?.share?.shareId;

    final hasFileShare =
        fileShareId != null && fileShareId.toString().isNotEmpty;

    final shareId = hasFileShare ? fileShareId : folderShareId;

    if (shareId == null || shareId.toString().isEmpty) {
      debugPrint('❌ Missing shareId for file: ${file.name}');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => ShareFileDialog(
        resourceId: hasFileShare ? file.id : currentFolder!.id,
        resourceName: file.name,
        resourceType:
        hasFileShare ? ShareResourceType.file : ShareResourceType.folder,
        isPreviewFile: !hasFileShare,
        parentContext: context,
        isEditMode: true,
        shareId: shareId,
        initialCanEdit:
        file.share?.canEdit ?? currentFolder?.share?.canEdit ?? false,
        initialNote: file.share?.note ?? currentFolder?.share?.note ?? '',
        initialExpiresAt:
        file.share?.expiresAt ?? currentFolder?.share?.expiresAt,
        resourceUrl: file.thumbnailUrl,
        mimeType: file.mimeType,
        fileType: file.fileType,
      ),
    );
  }

  Widget _fileIcon(dynamic file, ThemeColors theme) {
    final mimeType = (file.mimeType ?? '').toLowerCase();
    final fileType = (file.fileType ?? '').toLowerCase();

    if (fileType == 'image' || mimeType.startsWith('image/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          file.url,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.image_outlined,
            color: theme.themeColor,
            size: 24,
          ),
        ),
      );
    }

    if (mimeType.contains('pdf')) {
      return Icon(
        Icons.picture_as_pdf_outlined,
        color: theme.themeColor,
        size: 24,
      );
    }

    if (fileType == 'video' || mimeType.startsWith('video/')) {
      return Icon(
        Icons.video_file_outlined,
        color: theme.themeColor,
        size: 24,
      );
    }

    return Icon(
      Icons.insert_drive_file_outlined,
      color: theme.themeColor,
      size: 24,
    );
  }

  String _cleanText(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) return "-";
    return cleaned;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return "-";

    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }
  Widget _folderNameCell(BuildContext context, dynamic folder, ThemeColors theme,WidgetRef ref) {
    return InkWell(
      onTap: () async {
        await ref
            .read(sharedExplorerProvider.notifier)
            .openSharedFolder(folder);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Row(
          children: [
            Icon(Icons.folder_open, color: theme.themeColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                folder.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CloudFile _sharedFileToCloudFile(dynamic file) {
    return CloudFile.fromJson({
      'id': file.id,
      'folder': file.folder,
      'user': file.user,
      'file_type': file.fileType,
      'original_name': file.originalName,
      'name': file.name,
      'url': file.url,
      'thumbnail_url': file.thumbnailUrl,
      'mime_type': file.mimeType,
      'size': file.size,
      'checksum': file.checksum,
      'description': file.description,
      'tags': file.tags,
      'is_public': file.isPublic,
      'is_deleted': file.isDeleted,
      'created_at': file.createdAt?.toIso8601String(),
      'updated_at': file.updatedAt?.toIso8601String(),
    });
  }

  String _shareRecipientLabel(dynamic share) {
    if (share == null) return "-";

    final recipientType = share.recipientType?.toString();

    if (recipientType == "email") {
      return share.email?.toString() ??
          share.recipientValue?.toString() ??
          "-";
    }

    if (recipientType == "user") {
      return "User #${share.recipientValue ?? share.user ?? "-"}";
    }

    if (recipientType == "company") {
      return "Company #${share.recipientValue ?? share.company ?? "-"}";
    }

    if (recipientType == "team") {
      return "Team #${share.recipientValue ?? share.team ?? "-"}";
    }

    return share.recipientValue?.toString() ?? "-";
  }
}
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}