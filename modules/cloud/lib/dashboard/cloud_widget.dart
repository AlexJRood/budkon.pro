import 'package:cloud/components/drag_n_drop.dart';
import 'package:cloud/components/folders_grid.dart';
import 'package:cloud/components/recent_docs.dart';
import 'package:cloud/components/storage_quota.dart';
import 'package:cloud/providers/providers.dart';
import 'package:cloud/providers/refresh_provider.dart';
import 'package:cloud/widgets/flie_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';

enum DashboardCloudRecentMode {
  mixed,
  files,
  folders,
}

extension DashboardCloudRecentModeX on DashboardCloudRecentMode {
  String get key {
    switch (this) {
      case DashboardCloudRecentMode.mixed:
        return 'mixed';
      case DashboardCloudRecentMode.files:
        return 'files';
      case DashboardCloudRecentMode.folders:
        return 'folders';
    }
  }

  String get label {
    switch (this) {
      case DashboardCloudRecentMode.mixed:
        return 'Files & folders';
      case DashboardCloudRecentMode.files:
        return 'Recent files';
      case DashboardCloudRecentMode.folders:
        return 'Folders';
    }
  }

  IconData get icon {
    switch (this) {
      case DashboardCloudRecentMode.mixed:
        return Icons.folder_copy_outlined;
      case DashboardCloudRecentMode.files:
        return Icons.description_outlined;
      case DashboardCloudRecentMode.folders:
        return Icons.folder_open_outlined;
    }
  }

  static DashboardCloudRecentMode fromRaw(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'files':
      case 'recent_files':
        return DashboardCloudRecentMode.files;
      case 'folders':
      case 'recent_folders':
        return DashboardCloudRecentMode.folders;
      case 'mixed':
      default:
        return DashboardCloudRecentMode.mixed;
    }
  }
}

enum DashboardCloudRecentLayout {
  auto,
  vertical,
  horizontal,
}

extension DashboardCloudRecentLayoutX on DashboardCloudRecentLayout {
  String get key {
    switch (this) {
      case DashboardCloudRecentLayout.auto:
        return 'auto';
      case DashboardCloudRecentLayout.vertical:
        return 'vertical';
      case DashboardCloudRecentLayout.horizontal:
        return 'horizontal';
    }
  }

  String get label {
    switch (this) {
      case DashboardCloudRecentLayout.auto:
        return 'Auto';
      case DashboardCloudRecentLayout.vertical:
        return 'Vertical';
      case DashboardCloudRecentLayout.horizontal:
        return 'Horizontal';
    }
  }

  IconData get icon {
    switch (this) {
      case DashboardCloudRecentLayout.auto:
        return Icons.auto_awesome_motion_outlined;
      case DashboardCloudRecentLayout.vertical:
        return Icons.view_agenda_outlined;
      case DashboardCloudRecentLayout.horizontal:
        return Icons.view_column_outlined;
    }
  }

  static DashboardCloudRecentLayout fromRaw(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'vertical':
        return DashboardCloudRecentLayout.vertical;
      case 'horizontal':
        return DashboardCloudRecentLayout.horizontal;
      case 'auto':
      default:
        return DashboardCloudRecentLayout.auto;
    }
  }
}

class DashboardCloudRecentWidget extends ConsumerStatefulWidget {
  final bool isMobile;
  final bool isEditMode;
  final Map<String, dynamic> settings;
  final String defaultCloudRoute;

  const DashboardCloudRecentWidget({
    super.key,
    required this.isMobile,
    this.isEditMode = false,
    this.settings = const {},
    this.defaultCloudRoute = '/cloud',
  });

  @override
  ConsumerState<DashboardCloudRecentWidget> createState() =>
      _DashboardCloudRecentWidgetState();
}

class _DashboardCloudRecentWidgetState
    extends ConsumerState<DashboardCloudRecentWidget> {
  DashboardCloudRecentMode? _runtimeMode;
  DashboardCloudRecentLayout? _runtimeLayout;
  bool _isRefreshing = false;

  DashboardCloudRecentMode get _mode {
    return _runtimeMode ??
        DashboardCloudRecentModeX.fromRaw(widget.settings['mode']);
  }

  DashboardCloudRecentLayout get _layout {
    return _runtimeLayout ??
        DashboardCloudRecentLayoutX.fromRaw(widget.settings['layout']);
  }

  bool get _showQuota {
    final raw = widget.settings['showQuota'];
    if (raw is bool) return raw;
    return true;
  }

  bool get _showUpload {
    final raw = widget.settings['showUpload'];
    if (raw is bool) return raw;
    return true;
  }

  bool get _enableDrop {
    final raw = widget.settings['enableDrop'];
    if (raw is bool) return raw;
    return true;
  }

  bool get _compact {
    final raw = widget.settings['compact'];
    if (raw is bool) return raw;
    return false;
  }

  String get _cloudRoute {
    final raw = widget.settings['cloudRoute'];
    final value = raw?.toString().trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return widget.defaultCloudRoute;
  }

  UploadExtra _uploadExtra() {
    return const UploadExtra(folderId: null);
  }

  void _openCloud() {
    if (widget.isEditMode) return;
    ref.read(navigationService).pushNamedScreen(_cloudRoute);
  }

  void _refreshCloud() {
    if (widget.isEditMode) return;
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    final container = ProviderScope.containerOf(context, listen: false);
    refreshSidebarOnUploadComplete(container);

    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
    });
  }

  DashboardCloudRecentLayout _resolveLayout(BoxConstraints constraints) {
    final configured = _layout;

    if (configured != DashboardCloudRecentLayout.auto) {
      return configured;
    }

    if (widget.isMobile) {
      return DashboardCloudRecentLayout.vertical;
    }

    final canUseHorizontal =
        constraints.maxWidth >= 760 && constraints.maxHeight >= 360;

    return canUseHorizontal
        ? DashboardCloudRecentLayout.horizontal
        : DashboardCloudRecentLayout.vertical;
  }

  Widget _buildFoldersSection({
    required ThemeColors theme,
    required bool compact,
  }) {
    return _CloudSectionShell(
      theme: theme,
      compact: compact,
      title: 'Folders'.tr,
      subtitle: 'Recently used folders'.tr,
      icon: Icons.folder_open_outlined,
      child: const FoldersSection(),
    );
  }

  Widget _buildRecentFilesSection({
    required ThemeColors theme,
    required bool compact,
  }) {
    return _CloudSectionShell(
      theme: theme,
      compact: compact,
      title: 'Recent documents'.tr,
      subtitle: 'Documents recent added'.tr,
      icon: Icons.description_outlined,
      child: RecentDocumentsTable(isMobile: widget.isMobile),
    );
  }

  Widget _buildBody({
    required ThemeColors theme,
    required BoxConstraints constraints,
    required DashboardCloudRecentLayout resolvedLayout,
    required bool compact,
  }) {
    final mode = _mode;

    if (mode == DashboardCloudRecentMode.files) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 8 : 10),
        child: _buildRecentFilesSection(theme: theme, compact: compact),
      );
    }

    if (mode == DashboardCloudRecentMode.folders) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 8 : 10),
        child: _buildFoldersSection(theme: theme, compact: compact),
      );
    }

    if (resolvedLayout == DashboardCloudRecentLayout.horizontal &&
        !widget.isMobile) {
      return Row(
        children: [
          SizedBox(
            width: constraints.maxWidth * 0.42,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 8 : 10),
              child: _buildFoldersSection(theme: theme, compact: compact),
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: theme.dashboardBoarder,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 8 : 10),
              child: _buildRecentFilesSection(theme: theme, compact: compact),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 8 : 10),
      child: Column(
        children: [
          _buildFoldersSection(theme: theme, compact: compact),
          SizedBox(height: compact ? 10 : 14),
          _buildRecentFilesSection(theme: theme, compact: compact),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final isDownloading = ref.watch(isDownloadingProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedLayout = _resolveLayout(constraints);
        final compact = _compact || constraints.maxHeight < 420;

        Widget content = Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dashboardBoarder,
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MouseRegion(
              cursor: isDownloading
                  ? SystemMouseCursors.progress
                  : SystemMouseCursors.basic,
              child: Column(
                children: [
                  _CloudDashboardHeader(
                    theme: theme,
                    mode: _mode,
                    layout: _layout,
                    compact: compact,
                    showUpload: _showUpload,
                    isRefreshing: _isRefreshing,
                    isEditMode: widget.isEditMode,
                    uploadExtra: _uploadExtra(),
                    onModeChanged: (value) {
                      setState(() => _runtimeMode = value);
                    },
                    onLayoutChanged: (value) {
                      setState(() => _runtimeLayout = value);
                    },
                    onOpenCloud: _openCloud,
                    onRefresh: _refreshCloud,
                  ),
                  if (_showQuota && !compact)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                      decoration: BoxDecoration(
                        color: theme.adPopBackground.withAlpha(70),
                        border: Border(
                          bottom: BorderSide(
                            color: theme.dashboardBoarder.withAlpha(120),
                          ),
                        ),
                      ),
                      child: const StorageQuotaWidgetConnected(),
                    ),
                  Expanded(
                    child: _buildBody(
                      theme: theme,
                      constraints: constraints,
                      resolvedLayout: resolvedLayout,
                      compact: compact,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (_enableDrop && !widget.isEditMode) {
          content = UniversalFileDropZone(
            extra: _uploadExtra(),
            child: content,
          );
        }

        return content;
      },
    );
  }
}

class _CloudDashboardHeader extends StatelessWidget {
  final ThemeColors theme;
  final DashboardCloudRecentMode mode;
  final DashboardCloudRecentLayout layout;
  final bool compact;
  final bool showUpload;
  final bool isRefreshing;
  final bool isEditMode;
  final UploadExtra uploadExtra;
  final ValueChanged<DashboardCloudRecentMode> onModeChanged;
  final ValueChanged<DashboardCloudRecentLayout> onLayoutChanged;
  final VoidCallback onOpenCloud;
  final VoidCallback onRefresh;

  const _CloudDashboardHeader({
    required this.theme,
    required this.mode,
    required this.layout,
    required this.compact,
    required this.showUpload,
    required this.isRefreshing,
    required this.isEditMode,
    required this.uploadExtra,
    required this.onModeChanged,
    required this.onLayoutChanged,
    required this.onOpenCloud,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 440;
        final tiny = constraints.maxWidth < 340;

        final canShowMode = !tiny;
        final canShowLayout = !narrow;
        final canShowUpload = showUpload && !narrow && !isEditMode;

        return Container(
          height: compact ? 56 : 66,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            border: Border(
              bottom: BorderSide(
                color: theme.dashboardBoarder.withAlpha(160),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 34 : 42,
                height: compact ? 34 : 42,
                decoration: BoxDecoration(
                  color: theme.themeColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.themeColor.withAlpha(80),
                  ),
                ),
                child: Icon(
                  Icons.cloud_outlined,
                  color: theme.themeColor,
                  size: compact ? 18 : 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: compact
                    ? Text(
                        'Cloud'.tr,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Recent files'.tr,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mode.label.tr,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.textColor.withAlpha(165),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
              if (canShowMode) ...[
                _CloudPopupButton<DashboardCloudRecentMode>(
                  theme: theme,
                  tooltip: 'View'.tr,
                  icon: mode.icon,
                  selected: mode,
                  items: DashboardCloudRecentMode.values,
                  labelBuilder: (item) => item.label.tr,
                  iconBuilder: (item) => item.icon,
                  enabled: !isEditMode,
                  onSelected: onModeChanged,
                ),
                const SizedBox(width: 6),
              ],
              if (canShowLayout) ...[
                _CloudPopupButton<DashboardCloudRecentLayout>(
                  theme: theme,
                  tooltip: 'Layout'.tr,
                  icon: layout.icon,
                  selected: layout,
                  items: DashboardCloudRecentLayout.values,
                  labelBuilder: (item) => item.label.tr,
                  iconBuilder: (item) => item.icon,
                  enabled: !isEditMode,
                  onSelected: onLayoutChanged,
                ),
                const SizedBox(width: 6),
              ],
              _CloudHeaderIconButton(
                theme: theme,
                tooltip: 'Refresh'.tr,
                icon: Icons.refresh_rounded,
                isLoading: isRefreshing,
                onTap: isRefreshing || isEditMode ? null : onRefresh,
              ),
              const SizedBox(width: 6),
              _CloudHeaderIconButton(
                theme: theme,
                tooltip: 'Go to cloud'.tr,
                icon: Icons.open_in_new_rounded,
                onTap: isEditMode ? null : onOpenCloud,
              ),
              if (canShowUpload) ...[
                const SizedBox(width: 6),
                _CloudUploadHeaderButton(
                  theme: theme,
                  uploadExtra: uploadExtra,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CloudUploadHeaderButton extends ConsumerWidget {
  final ThemeColors theme;
  final UploadExtra uploadExtra;

  const _CloudUploadHeaderButton({
    required this.theme,
    required this.uploadExtra,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Upload'.tr,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: theme.themeColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.themeColor.withAlpha(160),
          ),
        ),
        child: Center(
          child: FilePickerButton(
            color: theme.themeTextColor,
            onFilesPicked: (files, [controller]) {
              if (!context.mounted) return;

              final container =
                  ProviderScope.containerOf(context, listen: false);

              for (final file in files) {
                ref.read(uploadQueueProvider.notifier).addFile(
                      file,
                      extra: uploadExtra,
                    );
              }

              showFileUploadOverlay(context, ref);
              refreshSidebarOnUploadComplete(container);
            },
          ),
        ),
      ),
    );
  }
}

class _CloudHeaderIconButton extends StatelessWidget {
  final ThemeColors theme;
  final String tooltip;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _CloudHeaderIconButton({
    required this.theme,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.dashboardBoarder.withAlpha(150),
            ),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.textColor,
                    ),
                  )
                : Icon(
                    icon,
                    color: enabled
                        ? theme.textColor
                        : theme.textColor.withAlpha(75),
                    size: 18,
                  ),
          ),
        ),
      ),
    );
  }
}

class _CloudPopupButton<T> extends StatelessWidget {
  final ThemeColors theme;
  final String tooltip;
  final IconData icon;
  final T selected;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final IconData Function(T item) iconBuilder;
  final ValueChanged<T> onSelected;
  final bool enabled;

  const _CloudPopupButton({
    required this.theme,
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.items,
    required this.labelBuilder,
    required this.iconBuilder,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PopupMenuButton<T>(
        color: theme.adPopBackground,
        tooltip: tooltip,
        enabled: enabled,
        onSelected: enabled ? onSelected : null,
        itemBuilder: (_) {
          return items.map((item) {
            final isSelected = item == selected;

            return PopupMenuItem<T>(
              value: item,
              child: Row(
                children: [
                  Icon(
                    iconBuilder(item),
                    size: 17,
                    color: isSelected ? theme.themeColor : theme.textColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      labelBuilder(item),
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: theme.themeColor,
                    ),
                ],
              ),
            );
          }).toList();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.dashboardBoarder.withAlpha(150),
            ),
          ),
          child: Icon(
            icon,
            color: enabled ? theme.textColor : theme.textColor.withAlpha(75),
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _CloudSectionShell extends StatelessWidget {
  final ThemeColors theme;
  final bool compact;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _CloudSectionShell({
    required this.theme,
    required this.compact,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(115),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha(135),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact)
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.themeColor.withAlpha(24),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: theme.themeColor,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(160),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (!compact) const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}