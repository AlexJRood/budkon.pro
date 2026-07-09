import 'dart:math';

import 'package:cloud/components/drag_n_drop.dart';
import 'package:cloud/models/cloud_shortcut.dart';
import 'package:cloud/models/explorer.dart';
import 'package:cloud/models/file.dart';
import 'package:cloud/models/folder.dart';
import 'package:cloud/providers/providers.dart';
import 'package:cloud/widgets/file_viewer.dart';
import 'package:cloud/widgets/flie_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

bool get _isDesktopOrWeb =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;

/// Shows an in-place preview of the shortcut resource.
/// On desktop/web: opens as a resizable dialog.
/// On mobile: opens as a draggable bottom sheet.
Future<void> showCloudShortcutPreviewSheet({
  required BuildContext context,
  required WidgetRef ref,
  required CloudShortcut shortcut,
  required VoidCallback onNavigateToCloud,
}) {
  final isFolder =
      shortcut.itemType == 'folder' || shortcut.resourceType == 'folder';

  if (_isDesktopOrWeb) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _PreviewDialogFrame(
        shortcut: shortcut,
        isFolder: isFolder,
        outerRef: ref,
        onNavigateToCloud: onNavigateToCloud,
      ),
    );
  }

  final isMobile = MediaQuery.sizeOf(context).width < 700;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: isFolder ? 0.78 : (isMobile ? 0.92 : 0.88),
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (sheetCtx, sc) => _PreviewSheetFrame(
        shortcut: shortcut,
        isFolder: isFolder,
        outerRef: ref,
        scrollController: sc,
        onNavigateToCloud: onNavigateToCloud,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Desktop: Dialog frame
// ---------------------------------------------------------------------------

class _PreviewDialogFrame extends ConsumerWidget {
  const _PreviewDialogFrame({
    required this.shortcut,
    required this.isFolder,
    required this.outerRef,
    required this.onNavigateToCloud,
  });

  final CloudShortcut shortcut;
  final bool isFolder;
  final WidgetRef outerRef;
  final VoidCallback onNavigateToCloud;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width * 0.82, 1100.0);
    final h = min(size.height * 0.86, 800.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: w,
          height: h,
          child: Material(
            color: theme.dashboardContainer,
            child: isFolder
                ? _FolderPreviewBody(
                    shortcut: shortcut,
                    outerRef: outerRef,
                    scrollController: null,
                    showHandle: false,
                    onClose: () => Navigator.of(context).pop(),
                    onNavigateToCloud: () {
                      Navigator.of(context).pop();
                      onNavigateToCloud();
                    },
                  )
                : _FilePreviewBody(
                    shortcut: shortcut,
                    isMobile: false,
                    onClose: () => Navigator.of(context).pop(),
                    onNavigateToCloud: () {
                      Navigator.of(context).pop();
                      onNavigateToCloud();
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile: Bottom sheet frame
// ---------------------------------------------------------------------------

class _PreviewSheetFrame extends ConsumerWidget {
  const _PreviewSheetFrame({
    required this.shortcut,
    required this.isFolder,
    required this.outerRef,
    required this.scrollController,
    required this.onNavigateToCloud,
  });

  final CloudShortcut shortcut;
  final bool isFolder;
  final WidgetRef outerRef;
  final ScrollController scrollController;
  final VoidCallback onNavigateToCloud;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return Material(
      color: theme.dashboardContainer,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: isFolder
          ? _FolderPreviewBody(
              shortcut: shortcut,
              outerRef: outerRef,
              scrollController: scrollController,
              showHandle: true,
              onClose: () => Navigator.of(context).pop(),
              onNavigateToCloud: () {
                Navigator.of(context).pop();
                onNavigateToCloud();
              },
            )
          : _FilePreviewBody(
              shortcut: shortcut,
              isMobile: isMobile,
              onClose: () => Navigator.of(context).pop(),
              onNavigateToCloud: () {
                Navigator.of(context).pop();
                onNavigateToCloud();
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// File preview body
// ---------------------------------------------------------------------------

class _FilePreviewBody extends ConsumerWidget {
  const _FilePreviewBody({
    required this.shortcut,
    required this.isMobile,
    required this.onClose,
    required this.onNavigateToCloud,
  });

  final CloudShortcut shortcut;
  final bool isMobile;
  final VoidCallback onClose;
  final VoidCallback onNavigateToCloud;

  CloudFile _buildFile() => CloudFile(
        id: shortcut.itemId ?? shortcut.id,
        name: shortcut.resourceName,
        size: shortcut.sizeBytes ?? 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sharedWith: const [],
        folderId: shortcut.parentId,
        mimeType: shortcut.mimeType,
        fileType: shortcut.fileType,
        url: shortcut.url ?? '',
        thumbnailUrl: shortcut.thumbnailUrl,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isMobile ? 22 : 0),
            ),
            child: FileViewerDialog(file: _buildFile(), isMobile: isMobile),
          ),
        ),
        // Floating chips at top-right so they don't block the viewer header
        Positioned(
          top: 10,
          right: 12,
          child: Row(
            children: [
              _OverlayChip(
                icon: Icons.open_in_new_rounded,
                label: 'open_in_cloud'.tr,
                color: theme.themeColor,
                onTap: onNavigateToCloud,
              ),
              const SizedBox(width: 6),
              _OverlayChip(
                icon: Icons.close_rounded,
                label: '',
                color: theme.textColor,
                onTap: onClose,
                labelHidden: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Folder preview body
// ---------------------------------------------------------------------------

class _FolderPreviewBody extends ConsumerStatefulWidget {
  const _FolderPreviewBody({
    required this.shortcut,
    required this.outerRef,
    required this.scrollController,
    required this.showHandle,
    required this.onClose,
    required this.onNavigateToCloud,
  });

  final CloudShortcut shortcut;
  final WidgetRef outerRef;
  final ScrollController? scrollController;
  final bool showHandle;
  final VoidCallback onClose;
  final VoidCallback onNavigateToCloud;

  @override
  ConsumerState<_FolderPreviewBody> createState() => _FolderPreviewBodyState();
}

class _FolderPreviewBodyState extends ConsumerState<_FolderPreviewBody> {
  String? _folderId;
  final List<_Crumb> _crumbs = [];

  @override
  void initState() {
    super.initState();
    _folderId = widget.shortcut.itemId;
  }

  void _enter(CloudFolder folder) => setState(() {
        _crumbs.add(_Crumb(id: _folderId, name: folder.name));
        _folderId = folder.id;
      });

  void _back() {
    if (_crumbs.isEmpty) return;
    setState(() {
      _folderId = _crumbs.removeLast().id;
    });
  }

  Future<void> _pickAndUpload(BuildContext ctx) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null || !mounted) return;

    final notifier = ref.read(uploadQueueProvider.notifier);
    for (final f in result.files) {
      notifier.addFile(f, extra: UploadExtra(folderId: _folderId));
    }
    if (mounted) showFileUploadOverlay(ctx, ref);
  }

  void _openFile(BuildContext ctx, WidgetRef r, CloudFile file) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => _FilePreviewBody(
          shortcut: CloudShortcut(
            id: widget.shortcut.id,
            resourceType: 'file',
            itemId: file.id,
            itemType: 'file',
            resourceName: file.name,
            parentId: file.folderId,
            fileType: file.fileType,
            mimeType: file.mimeType,
            extension: file.extension,
            sizeBytes: file.size,
            thumbnailUrl: file.thumbnailUrl,
            url: file.url,
            dashboardKey: widget.shortcut.dashboardKey,
            zoneKey: widget.shortcut.zoneKey,
            label: file.name,
            subtitle: '',
            icon: '',
            color: '',
            isAvailable: true,
            openTarget: null,
            widgetSettings: const {},
            dashboardWidget: const {},
          ),
          isMobile: MediaQuery.sizeOf(ctx).width < 700,
          onClose: () => Navigator.of(ctx).pop(),
          onNavigateToCloud: () {
            Navigator.of(ctx).pop();
            widget.onNavigateToCloud();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    // Refresh folder view when uploads complete.
    ref.listen<List<FileUploadTask>>(uploadQueueProvider, (prev, next) {
      if (next.isEmpty) return;
      final allSettled =
          next.every((t) => t.status == 'done' || t.status == 'error');
      if (allSettled) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) ref.invalidate(cloudPickerExplorerProvider(_folderId));
        });
      }
    });

    final explorerAsync = ref.watch(cloudPickerExplorerProvider(_folderId));
    final currentName =
        _crumbs.isEmpty ? widget.shortcut.resourceName : _crumbs.last.name;

    final content = Column(
      children: [
        if (widget.showHandle) _Handle(theme: theme),
        _PreviewTopBar(
          title: currentName,
          theme: theme,
          canGoBack: _crumbs.isNotEmpty,
          onBack: _back,
          onClose: widget.onClose,
          onNavigateToCloud: widget.onNavigateToCloud,
          onUpload: () => _pickAndUpload(context),
        ),
        Divider(color: theme.dashboardBoarder, height: 1),
        Expanded(
          child: explorerAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: theme.themeColor)),
            error: (_, __) => _ErrorView(
              theme: theme,
              onRetry: () =>
                  ref.invalidate(cloudPickerExplorerProvider(_folderId)),
            ),
            data: (response) {
              final listView = _FolderContents(
                response: response,
                theme: theme,
                sc: widget.scrollController,
                onEnterFolder: _enter,
                onOpenFile: (f) => _openFile(context, ref, f),
              );

              // On desktop/web, wrap with drag-drop zone.
              if (_isDesktopOrWeb) {
                return UniversalFileDropZone(
                  autoOpenOverlay: true,
                  extra: UploadExtra(folderId: _folderId),
                  child: listView,
                );
              }
              return listView;
            },
          ),
        ),
      ],
    );

    // On desktop the dialog already clips; on mobile add the border radius.
    return widget.showHandle
        ? ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(22)),
            child: content,
          )
        : content;
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _PreviewTopBar extends StatelessWidget {
  const _PreviewTopBar({
    required this.title,
    required this.theme,
    required this.canGoBack,
    required this.onBack,
    required this.onClose,
    required this.onNavigateToCloud,
    this.onUpload,
  });

  final String title;
  final ThemeColors theme;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final VoidCallback onNavigateToCloud;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: canGoBack ? onBack : onClose,
            icon: Icon(
              canGoBack
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.close_rounded,
              size: 18,
              color: theme.textColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onUpload != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: 'upload_files'.tr,
              child: IconButton(
                onPressed: onUpload,
                icon: Icon(
                  Icons.upload_file_rounded,
                  size: 20,
                  color: theme.textColor.withAlpha(180),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          ],
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: onNavigateToCloud,
            icon: Icon(Icons.open_in_new_rounded,
                size: 14, color: theme.themeColor),
            label: Text(
              'open_in_cloud'.tr,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.themeColor,
                  fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: theme.themeColor.withAlpha(100)),
              ),
            ),
          ),
          if (canGoBack) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onClose,
              icon:
                  Icon(Icons.close_rounded, size: 18, color: theme.textColor),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.labelHidden = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool labelHidden;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: labelHidden ? 8 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(160),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            if (!labelHidden && label.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.theme});
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: theme.textColor.withAlpha(60),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.theme, required this.onRetry});
  final ThemeColors theme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 52, color: theme.textColor.withAlpha(100)),
          const SizedBox(height: 12),
          Text('cloud_load_error'.tr,
              style: TextStyle(color: theme.textColor)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text('retry'.tr)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Folder contents list
// ---------------------------------------------------------------------------

class _FolderContents extends StatelessWidget {
  const _FolderContents({
    required this.response,
    required this.theme,
    required this.sc,
    required this.onEnterFolder,
    required this.onOpenFile,
  });

  final CloudExplorerResponse response;
  final ThemeColors theme;
  final ScrollController? sc;
  final ValueChanged<CloudFolder> onEnterFolder;
  final ValueChanged<CloudFile> onOpenFile;

  IconData _fileIcon(CloudFile file) {
    final ext = file.extension.toLowerCase();
    final mime = (file.mimeType ?? '').toLowerCase();
    if (mime.contains('image') ||
        ['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg'].contains(ext)) {
      return Icons.image_outlined;
    }
    if (mime.contains('pdf') || ext == 'pdf') return Icons.picture_as_pdf_outlined;
    if (mime.contains('spreadsheet') || ['xls', 'xlsx', 'csv'].contains(ext)) {
      return Icons.table_chart_outlined;
    }
    if (mime.contains('word') || ['doc', 'docx', 'txt'].contains(ext)) {
      return Icons.article_outlined;
    }
    if (mime.contains('video') || ['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      return Icons.movie_creation_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    if (response.subfolders.isEmpty && response.files.isEmpty) {
      return Center(
        child: Text(
          'cloud_folder_empty'.tr,
          style: TextStyle(color: theme.textColor.withAlpha(140)),
        ),
      );
    }

    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 32),
      children: [
        for (final folder in response.subfolders)
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            leading: Icon(Icons.folder_rounded,
                color: Colors.amber.shade600, size: 28),
            title: Text(folder.name,
                style: TextStyle(
                    color: theme.textColor, fontWeight: FontWeight.w500)),
            subtitle: folder.filesCount != null
                ? Text('${folder.filesCount} files',
                    style: TextStyle(
                        color: theme.textColor.withAlpha(130), fontSize: 12))
                : null,
            trailing: Icon(Icons.chevron_right_rounded,
                color: theme.textColor.withAlpha(120), size: 20),
            onTap: () => onEnterFolder(folder),
          ),
        if (response.subfolders.isNotEmpty && response.files.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: theme.dashboardBoarder, height: 1),
          ),
        for (final file in response.files)
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            leading:
                Icon(_fileIcon(file), size: 26, color: theme.themeColor),
            title: Text(file.name,
                style: TextStyle(
                    color: theme.textColor, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            subtitle: Text(file.sizeString,
                style: TextStyle(
                    color: theme.textColor.withAlpha(130), fontSize: 12)),
            trailing: Icon(Icons.open_in_new_rounded,
                size: 16, color: theme.textColor.withAlpha(100)),
            onTap: () => onOpenFile(file),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _Crumb {
  const _Crumb({required this.id, required this.name});
  final String? id;
  final String name;
}
