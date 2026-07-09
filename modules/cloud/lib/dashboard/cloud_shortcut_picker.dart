import 'package:cloud/models/explorer.dart';
import 'package:cloud/models/file.dart';
import 'package:cloud/models/folder.dart';
import 'package:cloud/providers/providers.dart';
import 'package:cloud/utils/pin/cloud_shortcut.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

/// Shows a modal bottom sheet for browsing cloud storage and picking a file or
/// folder to attach to a dashboard shortcut widget.
///
/// Returns the widget-settings map on selection, or null if the user cancels.
Future<Map<String, dynamic>?> showCloudShortcutPicker({
  required BuildContext context,
  required WidgetRef ref,
  required String dashboardKey,
  required String zoneKey,
}) {
  return showModalBottomSheet<Map<String, dynamic>?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PickerSheet(
      outerRef: ref,
      dashboardKey: dashboardKey,
      zoneKey: zoneKey,
    ),
  );
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

class _PickerSheet extends ConsumerStatefulWidget {
  const _PickerSheet({
    required this.outerRef,
    required this.dashboardKey,
    required this.zoneKey,
  });

  final WidgetRef outerRef;
  final String dashboardKey;
  final String zoneKey;

  @override
  ConsumerState<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends ConsumerState<_PickerSheet> {
  String? _folderId;
  final List<_Crumb> _crumbs = [];
  bool _isPicking = false;

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

  Future<void> _pick(String resourceType, String resourceId) async {
    setState(() => _isPicking = true);
    try {
      final shortcut = await pinCloudShortcut(
        ref: widget.outerRef,
        resourceType: resourceType,
        resourceId: resourceId,
        destination: CloudShortcutPinDestination.dashboard,
        dashboardKey: widget.dashboardKey,
        zoneKey: widget.zoneKey,
      );
      if (mounted) {
        Navigator.of(context).pop(shortcut.toDashboardSettingsFallback());
      }
    } catch (_) {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final explorerAsync = ref.watch(cloudPickerExplorerProvider(_folderId));

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, sc) => Material(
        color: theme.dashboardContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: Column(
          children: [
            _Handle(theme: theme),
            _Header(
              title: _crumbs.isEmpty
                  ? 'cloud_picker_title'.tr
                  : _crumbs.last.name,
              canGoBack: _crumbs.isNotEmpty,
              onBack: _back,
              onClose: () => Navigator.of(context).pop(null),
              theme: theme,
            ),
            Divider(color: theme.dashboardBoarder, height: 1),
            Expanded(
              child: _isPicking
                  ? Center(child: CircularProgressIndicator(color: theme.themeColor))
                  : explorerAsync.when(
                      loading: () => Center(
                        child: CircularProgressIndicator(color: theme.themeColor),
                      ),
                      error: (_, __) => _ErrorView(
                        theme: theme,
                        onRetry: () => ref.invalidate(
                          cloudPickerExplorerProvider(_folderId),
                        ),
                      ),
                      data: (response) => _Contents(
                        response: response,
                        theme: theme,
                        sc: sc,
                        onEnter: _enter,
                        onPickFolder: (f) => _pick('folder', f.id),
                        onPickFile: (f) => _pick('file', f.id),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal data type
// ---------------------------------------------------------------------------

class _Crumb {
  const _Crumb({required this.id, required this.name});
  final String? id;
  final String name;
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

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

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.canGoBack,
    required this.onBack,
    required this.onClose,
    required this.theme,
  });

  final String title;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
      child: Row(
        children: [
          if (canGoBack)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: theme.textColor),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.folder_open_rounded, size: 22, color: theme.themeColor),
            ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: theme.textColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
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
          Icon(Icons.cloud_off_rounded, size: 52, color: theme.textColor.withAlpha(100)),
          const SizedBox(height: 12),
          Text('cloud_load_error'.tr, style: TextStyle(color: theme.textColor)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text('retry'.tr)),
        ],
      ),
    );
  }
}

class _Contents extends StatelessWidget {
  const _Contents({
    required this.response,
    required this.theme,
    required this.sc,
    required this.onEnter,
    required this.onPickFolder,
    required this.onPickFile,
  });

  final CloudExplorerResponse response;
  final ThemeColors theme;
  final ScrollController sc;
  final ValueChanged<CloudFolder> onEnter;
  final ValueChanged<CloudFolder> onPickFolder;
  final ValueChanged<CloudFile> onPickFile;

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
          _FolderTile(
            folder: folder,
            theme: theme,
            onNavigate: () => onEnter(folder),
            onSelect: () => onPickFolder(folder),
          ),
        if (response.subfolders.isNotEmpty && response.files.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: theme.dashboardBoarder, height: 1),
          ),
        for (final file in response.files)
          _FileTile(file: file, theme: theme, onSelect: () => onPickFile(file)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.folder,
    required this.theme,
    required this.onNavigate,
    required this.onSelect,
  });

  final CloudFolder folder;
  final ThemeColors theme;
  final VoidCallback onNavigate;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Icon(Icons.folder_rounded, color: Colors.amber.shade600, size: 28),
      title: Text(
        folder.name,
        style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w500),
      ),
      subtitle: folder.filesCount != null
          ? Text(
              '${folder.filesCount} files',
              style: TextStyle(color: theme.textColor.withAlpha(130), fontSize: 12),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onSelect,
            icon: Icon(Icons.push_pin_outlined, size: 20, color: theme.themeColor),
            tooltip: 'Select'.tr,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: theme.textColor.withAlpha(120), size: 20),
        ],
      ),
      onTap: onNavigate,
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.file,
    required this.theme,
    required this.onSelect,
  });

  final CloudFile file;
  final ThemeColors theme;
  final VoidCallback onSelect;

  IconData get _icon {
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Icon(_icon, size: 26, color: theme.themeColor),
      title: Text(
        file.name,
        style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        file.sizeString,
        style: TextStyle(color: theme.textColor.withAlpha(130), fontSize: 12),
      ),
      trailing: IconButton(
        onPressed: onSelect,
        icon: Icon(Icons.push_pin_outlined, size: 20, color: theme.themeColor),
        tooltip: 'Select'.tr,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      onTap: onSelect,
    );
  }
}
