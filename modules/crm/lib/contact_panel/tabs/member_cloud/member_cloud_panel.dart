import 'package:cloud/widgets/content.dart';
import 'package:crm/contact_panel/tabs/member_cloud/member_cloud_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';

class MemberCloudPanel extends ConsumerStatefulWidget {
  final int memberId;
  final bool isMobile;

  const MemberCloudPanel({
    super.key,
    required this.memberId,
    this.isMobile = false,
  });

  @override
  ConsumerState<MemberCloudPanel> createState() => _MemberCloudPanelState();
}

class _MemberCloudPanelState extends ConsumerState<MemberCloudPanel> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFiltersSheet(
    BuildContext context,
    MemberCloudNotifier notifier,
  ) async {
    final theme = ref.read(themeColorsProvider);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.dashboardContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return _MemberCloudFiltersSheet(
              scrollController: scrollController,
              searchController: _searchController,
              notifier: notifier,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(memberCloudProvider(widget.memberId));
    final notifier = ref.read(memberCloudProvider(widget.memberId).notifier);

    final folders = state.explorer.asData?.value.subfolders ?? const [];

    final explorerContent = Padding(
      padding: EdgeInsets.fromLTRB(
        widget.isMobile ? 10 : 16,
        8,
        widget.isMobile ? 10 : 16,
        12,
      ),
      child: CloudExplorerContent(
        currentFolder: null,
        currentFolderId: state.parent,
        contentsAsync: state.explorer,
        folders: folders,
        isMobile: widget.isMobile,
        readOnly: true,
        showBreadcrumbs: false,
        showAllFiles: true,
        shrinkWrap: widget.isMobile,
        onFolderChanged: notifier.openFolder,
      ),
    );

    final truncatedNotice = state.truncated
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'member_cloud_truncated'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 12,
              ),
            ),
          )
        : null;

    if (widget.isMobile) {
      final hasActiveFilters = state.scope != MemberCloudScope.all ||
          state.fileType != null ||
          state.search.trim().isNotEmpty;

      return Container(
        color: theme.adPopBackground.withAlpha(110),
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _MemberCloudHeader(
                    isMobile: true,
                    state: state,
                    theme: theme,
                    onRefresh: notifier.refresh,
                    showFilterControls: false,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _MemberCloudBreadcrumbs(
                    theme: theme,
                    breadcrumbs: state.breadcrumbs,
                    onRoot: notifier.goRoot,
                    onBreadcrumb: notifier.goToBreadcrumb,
                  ),
                ),
                SliverToBoxAdapter(child: explorerContent),
                if (truncatedNotice != null)
                  SliverToBoxAdapter(child: truncatedNotice),
                const SliverToBoxAdapter(child: SizedBox(height: 64)),
              ],
            ),
            Positioned(
              bottom: 12,
              right: 4,
              child: _MemberCloudVerticalBar(
                theme: theme,
                hasActiveFilters: hasActiveFilters,
                onOpenFilters: () => _openFiltersSheet(context, notifier),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: theme.adPopBackground.withAlpha(110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MemberCloudHeader(
            isMobile: false,
            state: state,
            theme: theme,
            searchController: _searchController,
            onScopeChanged: notifier.selectScope,
            onSearchChanged: notifier.setSearch,
            onRefresh: notifier.refresh,
            onFileTypeChanged: notifier.setFileType,
          ),
          _MemberCloudBreadcrumbs(
            theme: theme,
            breadcrumbs: state.breadcrumbs,
            onRoot: notifier.goRoot,
            onBreadcrumb: notifier.goToBreadcrumb,
          ),
          Expanded(child: explorerContent),
          if (truncatedNotice != null) truncatedNotice,
        ],
      ),
    );
  }
}

class _MemberCloudHeader extends StatelessWidget {
  final bool isMobile;
  final MemberCloudState state;
  final ThemeColors theme;
  final VoidCallback onRefresh;

  /// When false, the scope chips/search/file-type controls are omitted —
  /// used on mobile where they live in the [_MemberCloudFiltersSheet] instead.
  final bool showFilterControls;
  final TextEditingController? searchController;
  final ValueChanged<MemberCloudScope>? onScopeChanged;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String?>? onFileTypeChanged;

  const _MemberCloudHeader({
    required this.isMobile,
    required this.state,
    required this.theme,
    required this.onRefresh,
    this.showFilterControls = true,
    this.searchController,
    this.onScopeChanged,
    this.onSearchChanged,
    this.onFileTypeChanged,
  }) : assert(
          !showFilterControls ||
              (searchController != null &&
                  onScopeChanged != null &&
                  onSearchChanged != null &&
                  onFileTypeChanged != null),
          'searchController/onScopeChanged/onSearchChanged/onFileTypeChanged '
          'are required when showFilterControls is true',
        );

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'member_cloud_title'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'member_cloud_subtitle'.tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(165),
            fontSize: 12,
          ),
        ),
      ],
    );

    final stats = Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _StatBadge(
          icon: Icons.folder_outlined,
          label: '${state.foldersCount}',
          theme: theme,
        ),
        _StatBadge(
          icon: Icons.insert_drive_file_outlined,
          label: '${state.filesCount}',
          theme: theme,
        ),
        _StatBadge(
          icon: Icons.description_outlined,
          label: '${state.documentsCount}',
          theme: theme,
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 18,
        isMobile ? 12 : 18,
        isMobile ? 12 : 18,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile) ...[
            Row(
              children: [
                Expanded(child: title),
                IconButton(
                  tooltip: 'Refresh'.tr,
                  onPressed: onRefresh,
                  icon: Icon(Icons.refresh, color: theme.textColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            stats,
          ] else
            Row(
              children: [
                Expanded(child: title),
                stats,
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Refresh'.tr,
                  onPressed: onRefresh,
                  icon: Icon(Icons.refresh, color: theme.textColor),
                ),
              ],
            ),
          if (showFilterControls) ...[
            const SizedBox(height: 14),
            _MemberCloudFilterControls(
              isMobile: isMobile,
              state: state,
              theme: theme,
              searchController: searchController!,
              onScopeChanged: onScopeChanged!,
              onSearchChanged: onSearchChanged!,
              onFileTypeChanged: onFileTypeChanged!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Scope chips + search + file-type filter row, shared between the inline
/// desktop/tablet header and the mobile [_MemberCloudFiltersSheet].
class _MemberCloudFilterControls extends StatelessWidget {
  final bool isMobile;
  final MemberCloudState state;
  final ThemeColors theme;
  final TextEditingController searchController;
  final ValueChanged<MemberCloudScope> onScopeChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onFileTypeChanged;

  const _MemberCloudFilterControls({
    required this.isMobile,
    required this.state,
    required this.theme,
    required this.searchController,
    required this.onScopeChanged,
    required this.onSearchChanged,
    required this.onFileTypeChanged,
  });

  IconData _scopeIcon(MemberCloudScope scope) {
    switch (scope) {
      case MemberCloudScope.all:
        return Icons.folder_copy_outlined;
      case MemberCloudScope.sharedTo:
        return Icons.call_received_rounded;
      case MemberCloudScope.sharedBy:
        return Icons.call_made_rounded;
      case MemberCloudScope.owned:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: MemberCloudScope.values.map((scope) {
              final selected = scope == state.scope;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected,
                  onSelected: (_) => onScopeChanged(scope),
                  label: Text(scope.translationKey.tr),
                  avatar: Icon(
                    _scopeIcon(scope),
                    size: 18,
                    color: selected
                        ? theme.themeColorText
                        : theme.textColor.withAlpha(180),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? theme.themeColorText : theme.textColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  selectedColor: theme.themeColor,
                  backgroundColor: theme.dashboardContainer,
                  side: BorderSide(
                    color:
                        selected ? theme.themeColor : theme.dashboardBoarder,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (isMobile)
          Column(
            children: [
              _SearchField(
                controller: searchController,
                theme: theme,
                onChanged: onSearchChanged,
              ),
              const SizedBox(height: 8),
              _FileTypeDropdown(
                value: state.fileType,
                theme: theme,
                onChanged: onFileTypeChanged,
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: searchController,
                  theme: theme,
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 210,
                child: _FileTypeDropdown(
                  value: state.fileType,
                  theme: theme,
                  onChanged: onFileTypeChanged,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ThemeColors theme;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: theme.textColor),
      decoration: InputDecoration(
        hintText: 'member_cloud_search'.tr,
        hintStyle: TextStyle(color: theme.textColor.withAlpha(130)),
        prefixIcon: Icon(Icons.search, color: theme.textColor.withAlpha(170)),
        filled: true,
        fillColor: theme.textFieldColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.themeColor, width: 1.4),
        ),
      ),
    );
  }
}

class _FileTypeDropdown extends StatelessWidget {
  final String? value;
  final ThemeColors theme;
  final ValueChanged<String?> onChanged;

  const _FileTypeDropdown({
    required this.value,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      dropdownColor: theme.adPopBackground,
      onChanged: onChanged,
      style: TextStyle(color: theme.textColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.textFieldColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text('member_cloud_all_types'.tr),
        ),
        DropdownMenuItem<String?>(
          value: 'document',
          child: Text('member_cloud_documents'.tr),
        ),
        DropdownMenuItem<String?>(
          value: 'pdf',
          child: const Text('PDF'),
        ),
        DropdownMenuItem<String?>(
          value: 'image',
          child: Text('member_cloud_images'.tr),
        ),
        DropdownMenuItem<String?>(
          value: 'sheet',
          child: Text('member_cloud_sheets'.tr),
        ),
        DropdownMenuItem<String?>(
          value: 'archive',
          child: Text('member_cloud_archives'.tr),
        ),
      ],
    );
  }
}

class _MemberCloudBreadcrumbs extends StatelessWidget {
  final ThemeColors theme;
  final List<MemberCloudBreadcrumb> breadcrumbs;
  final VoidCallback onRoot;
  final ValueChanged<MemberCloudBreadcrumb> onBreadcrumb;

  const _MemberCloudBreadcrumbs({
    required this.theme,
    required this.breadcrumbs,
    required this.onRoot,
    required this.onBreadcrumb,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dashboardBoarder.withAlpha(80)),
          bottom: BorderSide(color: theme.dashboardBoarder.withAlpha(80)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _BreadcrumbButton(
              label: 'member_cloud_root'.tr,
              theme: theme,
              onTap: onRoot,
              strong: breadcrumbs.isEmpty,
            ),
            for (var index = 0; index < breadcrumbs.length; index++) ...[
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.textColor.withAlpha(130),
              ),
              _BreadcrumbButton(
                label: breadcrumbs[index].name,
                theme: theme,
                onTap: () => onBreadcrumb(breadcrumbs[index]),
                strong: index == breadcrumbs.length - 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbButton extends StatelessWidget {
  final String label;
  final ThemeColors theme;
  final VoidCallback onTap;
  final bool strong;

  const _BreadcrumbButton({
    required this.label,
    required this.theme,
    required this.onTap,
    required this.strong,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeColors theme;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.themeColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating mobile-only vertical bar (bar manager vertical buttons
/// convention — mirrors [CalendarVerticalBar]/[DocsVerticalBarMobile]) that
/// opens the scope/search/file-type filters in a [_MemberCloudFiltersSheet].
class _MemberCloudVerticalBar extends StatelessWidget {
  final ThemeColors theme;
  final bool hasActiveFilters;
  final VoidCallback onOpenFilters;

  const _MemberCloudVerticalBar({
    required this.theme,
    required this.hasActiveFilters,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _MemberCloudVerticalActionButton(
          theme: theme,
          tooltip: 'member_cloud_filters'.tr,
          isActive: hasActiveFilters,
          onPressed: onOpenFilters,
          child: Icon(
            Icons.filter_alt_outlined,
            color: hasActiveFilters ? theme.themeColor : theme.textColor,
          ),
        ),
      ],
    );
  }
}

class _MemberCloudVerticalActionButton extends StatelessWidget {
  final ThemeColors theme;
  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;
  final bool isActive;

  const _MemberCloudVerticalActionButton({
    required this.theme,
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 450),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: isActive
              ? theme.themeColor.withAlpha(32)
              : theme.adPopBackground,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          border: Border.all(
            color: isActive ? theme.themeColor.withAlpha(180) : Colors.transparent,
          ),
        ),
        child: IconButton(
          style: elevatedButtonStyleRounded10,
          onPressed: onPressed,
          icon: child,
        ),
      ),
    );
  }
}

class _MemberCloudFiltersSheet extends ConsumerWidget {
  final ScrollController scrollController;
  final TextEditingController searchController;
  final MemberCloudNotifier notifier;

  const _MemberCloudFiltersSheet({
    required this.scrollController,
    required this.searchController,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(memberCloudProvider(notifier.memberId));

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'member_cloud_filters'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  searchController.clear();
                  notifier.setSearch('');
                  notifier.selectScope(MemberCloudScope.all);
                  notifier.setFileType(null);
                },
                icon: Icon(Icons.filter_alt_off, color: Colors.red.shade300),
                label: Text(
                  'member_cloud_clear_filters'.tr,
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MemberCloudFilterControls(
            isMobile: true,
            state: state,
            theme: theme,
            searchController: searchController,
            onScopeChanged: notifier.selectScope,
            onSearchChanged: notifier.setSearch,
            onFileTypeChanged: notifier.setFileType,
          ),
        ],
      ),
    );
  }
}
