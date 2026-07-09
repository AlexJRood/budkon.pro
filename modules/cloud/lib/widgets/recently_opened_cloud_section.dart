import 'package:cloud/models/cloud_shortcut.dart';
import 'package:cloud/providers/providers.dart';
import 'package:cloud/utils/pin/destination_dialog.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class RecentlyOpenedCloudSection extends ConsumerStatefulWidget {
  final bool isMobile;
  final int maxItems;

  const RecentlyOpenedCloudSection({
    super.key,
    this.isMobile = false,
    this.maxItems = 12,
  });

  @override
  ConsumerState<RecentlyOpenedCloudSection> createState() =>
      _RecentlyOpenedCloudSectionState();
}

class _RecentlyOpenedCloudSectionState
    extends ConsumerState<RecentlyOpenedCloudSection> {
  bool _isCollapsed = false;

  Future<void> _refresh() async {
    refreshCloudRecentlyOpened(ref);
  }

  IconData _iconForType(CloudShortcut shortcut) {
    if (shortcut.resourceType == 'folder') return Icons.folder_rounded;
    final ft = (shortcut.fileType ?? shortcut.mimeType ?? '').toLowerCase();
    if (ft.contains('image')) return Icons.image_rounded;
    if (ft.contains('video')) return Icons.videocam_rounded;
    if (ft.contains('audio')) return Icons.audiotrack_rounded;
    if (ft.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (ft.contains('word') || ft.contains('doc'))
      return Icons.description_rounded;
    if (ft.contains('sheet') || ft.contains('excel') || ft.contains('csv')) {
      return Icons.table_chart_rounded;
    }
    if (ft.contains('zip') || ft.contains('rar') || ft.contains('archive')) {
      return Icons.archive_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _colorForType(CloudShortcut shortcut, ThemeColors theme) {
    if (shortcut.resourceType == 'folder') return Colors.amber;
    final ft = (shortcut.fileType ?? shortcut.mimeType ?? '').toLowerCase();
    if (ft.contains('image')) return Colors.purple;
    if (ft.contains('video')) return Colors.red;
    if (ft.contains('audio')) return Colors.orange;
    if (ft.contains('pdf')) return Colors.redAccent;
    if (ft.contains('word') || ft.contains('doc')) return Colors.blue;
    if (ft.contains('sheet') || ft.contains('excel') || ft.contains('csv')) {
      return Colors.green;
    }
    return theme.themeColor;
  }

  Future<void> _openShortcut(CloudShortcut shortcut) async {
    try {
      await ref.read(cloudShortcutsApiProvider).open(shortcut.id);
    } catch (_) {}
  }

  DndPayload _dragPayloadFor(CloudShortcut shortcut) {
    final isFolder = shortcut.resourceType == 'folder';
    final id = shortcut.itemId ?? shortcut.id;
    final now = DateTime.now().toIso8601String();

    return DndPayload(
      type: isFolder ? DndPayloadType.cloudFolder : DndPayloadType.cloudFile,
      id: id,
      action: 'move',
      data:
          isFolder
              ? {
                'id': id,
                'name': shortcut.resourceName,
                'parent': shortcut.parentId,
                'files_count': 0,
              }
              : {
                'id': id,
                'original_name': shortcut.resourceName,
                'size': shortcut.sizeBytes ?? 0,
                'created_at': now,
                'updated_at': now,
                'folder': shortcut.parentId,
                'mime_type': shortcut.mimeType,
                'file_type': shortcut.fileType,
                'url': shortcut.url ?? '',
                'thumbnail_url': shortcut.thumbnailUrl,
              },
      subActions: const ['pin_cloud_shortcut'],
    );
  }

  List<PieAction> _pieActionsFor(ThemeColors theme, CloudShortcut shortcut) {
    return [
      PieAction(
        tooltip: Text('Open'.tr, style: TextStyle(color: theme.textColor)),
        onSelect: () => _openShortcut(shortcut),
        child: const Icon(Icons.open_in_new_rounded, color: Colors.white),
      ),
      PieAction(
        tooltip: Text(
          'Pin shortcut'.tr,
          style: TextStyle(color: theme.textColor),
        ),
        onSelect: () async {
          final ctx = context;
          if (!mounted) return;
          await showCloudShortcutPinDialog(
            context: ctx,
            ref: ref,
            resourceType: shortcut.resourceType,
            resourceId: shortcut.itemId ?? shortcut.id,
            label:
                shortcut.label.isNotEmpty
                    ? shortcut.label
                    : shortcut.resourceName,
            subtitle: shortcut.subtitle.isNotEmpty ? shortcut.subtitle : null,
          );
        },
        child: const Icon(Icons.push_pin_rounded, color: Colors.white),
      ),
    ];
  }

  Widget _buildItem(
    ThemeColors theme,
    CloudShortcut shortcut, {
    required bool isLast,
  }) {
    final icon = _iconForType(shortcut);
    final color = _colorForType(shortcut, theme);
    final name =
        shortcut.label.isNotEmpty ? shortcut.label : shortcut.resourceName;
    final subtitle =
        shortcut.subtitle.isNotEmpty
            ? shortcut.subtitle
            : shortcut.resourceType == 'folder'
            ? 'Folder'.tr
            : 'File'.tr;

    return PieMenu(
      theme: PieTheme.of(context).copyWith(
        overlayColor:
            (() {
              final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;
              final base = uiIsDark ? Colors.black : Colors.white;
              return base.withValues(alpha: 0.70);
            })(),
      ),
      onPressedWithDevice: (_) => _openShortcut(shortcut),
      actions: _pieActionsFor(theme, shortcut),
      child: DndSender(
        useLongPress: true,
        payload: _dragPayloadFor(shortcut),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _openShortcut(shortcut),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withAlpha(24),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: color.withAlpha(70)),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(140),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: theme.textColor.withAlpha(100),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          'No recently opened files'.tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(140),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildList(ThemeColors theme, List<CloudShortcut> items) {
    if (items.isEmpty) return _buildEmptyState(theme);

    final visible = items.take(widget.maxItems).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(60),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(120)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < visible.length; i++) ...[
            _buildItem(theme, visible[i], isLast: i == visible.length - 1),
            if (i < visible.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: theme.dashboardBoarder.withAlpha(80),
                indent: 56,
                endIndent: 0,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(ThemeColors theme) {
    final recentAsync = ref.watch(cloudRecentlyOpenedProvider);

    return recentAsync.when(
      skipLoadingOnRefresh: true,
      loading:
          () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: AppLottie.loading(size: 420)),
          ),
      error: (_, __) => _buildEmptyState(theme),
      data: (items) => _buildList(theme, items),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.themeColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: theme.themeColor.withAlpha(85)),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: theme.themeColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recently opened'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Files and folders you opened recently'.tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(160),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh'.tr,
                onPressed: _refresh,
                icon: Icon(Icons.refresh_rounded, color: theme.textColor),
              ),
              IconButton(
                tooltip: _isCollapsed ? 'Expand'.tr : 'Collapse'.tr,
                onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                icon: AnimatedRotation(
                  turns: _isCollapsed ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_less_rounded,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                _isCollapsed
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [const SizedBox(height: 14), _buildContent(theme)],
            ),
          ),
        ],
      ),
    );
  }
}
