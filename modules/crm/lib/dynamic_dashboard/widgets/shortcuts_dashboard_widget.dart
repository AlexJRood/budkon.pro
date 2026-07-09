import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/navigation_history_provider.dart';

import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:crm/dynamic_dashboard/registry/dashboard_widget_spec.dart';
import 'package:core/shell/customizer/add_dock_item_dialog.dart';
import 'package:core/shell/manager/bar_manager.dart' show CustomDockItem;

/// Settings key names stored in [DashboardWidgetInstance.settings].
const _kShortcutsKey = 'shortcuts';

/// Dashboard widget that shows user-defined navigation shortcut tiles.
///
/// Each shortcut is a [CustomDockItem]-compatible map stored in the
/// widget's own settings: { id, label, icon, route }.
///
/// Users can add/remove shortcuts from the widget in edit mode.
class ShortcutsDashboardWidgetSpec extends DashboardWidgetSpec {
  const ShortcutsDashboardWidgetSpec();

  @override
  String get type => 'shortcuts';

  @override
  String get title => 'shortcuts_widget_title'.tr;

  @override
  IconData get icon => Icons.bookmark_outline;

  @override
  bool get allowMultiple => true;

  @override
  bool get hasSettings => true;

  @override
  bool get needsFirstSetup => false;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) {
    switch (breakpoint) {
      case DashboardBreakpoint.mobile:
        return const DashboardGridSize(w: 4, h: 2);
      case DashboardBreakpoint.tablet:
        return const DashboardGridSize(w: 6, h: 2);
      case DashboardBreakpoint.desktop:
        return const DashboardGridSize(w: 4, h: 2);
    }
  }

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2,
        maxW: 12,
        minH: 1,
        maxH: 4,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) {
    return _ShortcutsWidget(
      instance: instance,
      isEditMode: isEditMode,
    );
  }

  @override
  Widget buildSettingsPanel(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    ValueChanged<Map<String, dynamic>> onSettingsChanged,
  ) {
    return _ShortcutsSettingsPanel(
      instance: instance,
      onSettingsChanged: onSettingsChanged,
    );
  }
}

// ── Widget ─────────────────────────────────────────────────────────────────

class _ShortcutsWidget extends ConsumerWidget {
  final DashboardWidgetInstance instance;
  final bool isEditMode;

  const _ShortcutsWidget({
    required this.instance,
    required this.isEditMode,
  });

  List<CustomDockItem> _parseShortcuts() {
    final raw = instance.settings[_kShortcutsKey] as List<dynamic>? ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => CustomDockItem(
            id: (e['id'] as String?) ?? '',
            label: (e['label'] as String?) ?? '',
            iconKey: (e['icon'] as String?) ?? 'star',
            route: (e['route'] as String?) ?? '',
          ),
        )
        .where((e) => e.id.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final shortcuts = _parseShortcuts();

    if (shortcuts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_add_outlined,
              color: theme.textColor.withAlpha(80),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'no_shortcuts_yet'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(100),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 110,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1,
        ),
        itemCount: shortcuts.length,
        itemBuilder: (context, i) {
          return _ShortcutTile(
            item: shortcuts[i],
            theme: theme,
          );
        },
      ),
    );
  }
}

class _ShortcutTile extends ConsumerStatefulWidget {
  final CustomDockItem item;
  final ThemeColors theme;

  const _ShortcutTile({required this.item, required this.theme});

  @override
  ConsumerState<_ShortcutTile> createState() => _ShortcutTileState();
}

class _ShortcutTileState extends ConsumerState<_ShortcutTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ref
              .read(navigationHistoryProvider.notifier)
              .addPage(widget.item.route);
          ref.read(navigationService).pushNamedScreen(widget.item.route);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.theme.themeColor.withAlpha(28)
                : widget.theme.dashboardContainer.withAlpha(200),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? widget.theme.themeColor.withAlpha(80)
                  : widget.theme.textColor.withAlpha(20),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ShortcutIcon(
                iconKey: widget.item.iconKey,
                color: _hovered
                    ? widget.theme.themeColor
                    : widget.theme.textColor.withAlpha(200),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.theme.textColor.withAlpha(200),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Settings panel ─────────────────────────────────────────────────────────

class _ShortcutsSettingsPanel extends StatefulWidget {
  final DashboardWidgetInstance instance;
  final ValueChanged<Map<String, dynamic>> onSettingsChanged;

  const _ShortcutsSettingsPanel({
    required this.instance,
    required this.onSettingsChanged,
  });

  @override
  State<_ShortcutsSettingsPanel> createState() =>
      _ShortcutsSettingsPanelState();
}

class _ShortcutsSettingsPanelState extends State<_ShortcutsSettingsPanel> {
  late List<CustomDockItem> _shortcuts;

  @override
  void initState() {
    super.initState();
    _shortcuts = _parse(widget.instance.settings);
  }

  List<CustomDockItem> _parse(Map<String, dynamic> settings) {
    final raw = settings[_kShortcutsKey] as List<dynamic>? ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => CustomDockItem(
            id: (e['id'] as String?) ?? '',
            label: (e['label'] as String?) ?? '',
            iconKey: (e['icon'] as String?) ?? 'star',
            route: (e['route'] as String?) ?? '',
          ),
        )
        .where((e) => e.id.isNotEmpty)
        .toList();
  }

  void _emitChange() {
    widget.onSettingsChanged({
      _kShortcutsKey: _shortcuts
          .map((e) => {
                'id': e.id,
                'label': e.label,
                'icon': e.iconKey,
                'route': e.route,
              })
          .toList(),
    });
  }

  Future<void> _addShortcut() async {
    final result = await showDialog<CustomDockItem>(
      context: context,
      builder: (_) => const AddDockItemDialog(),
    );
    if (result != null) {
      setState(() => _shortcuts.add(result));
      _emitChange();
    }
  }

  Future<void> _editShortcut(int index) async {
    final result = await showDialog<CustomDockItem>(
      context: context,
      builder: (_) => AddDockItemDialog(existing: _shortcuts[index]),
    );
    if (result != null) {
      setState(() => _shortcuts[index] = result);
      _emitChange();
    }
  }

  void _removeShortcut(int index) {
    setState(() => _shortcuts.removeAt(index));
    _emitChange();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _shortcuts.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            setState(() {
              final moved = _shortcuts.removeAt(oldIndex);
              _shortcuts.insert(newIndex, moved);
            });
            _emitChange();
          },
          itemBuilder: (context, i) {
            final item = _shortcuts[i];
            return ListTile(
              key: ValueKey(item.id),
              dense: true,
              leading: Icon(Icons.drag_handle,
                  color: Colors.grey.withAlpha(120), size: 20),
              title: Text(item.label, style: const TextStyle(fontSize: 13)),
              subtitle: Text(
                item.route,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _editShortcut(i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.redAccent),
                    onPressed: () => _removeShortcut(i),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: OutlinedButton.icon(
            onPressed: _addShortcut,
            icon: const Icon(Icons.add, size: 16),
            label: Text('add_shortcut'.tr),
          ),
        ),
      ],
    );
  }
}

// ── Icon renderer ──────────────────────────────────────────────────────────

class _ShortcutIcon extends StatelessWidget {
  final String iconKey;
  final Color color;

  const _ShortcutIcon({required this.iconKey, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (iconKey) {
      case 'home':
        return AppIcons.home(color: color);
      case 'star':
        return AppIcons.star(color: color);
      case 'calendar':
        return AppIcons.calendar(color: color);
      case 'document':
        return AppIcons.document(color: color);
      case 'task':
        return AppIcons.task(color: color);
      case 'search':
        return AppIcons.search(color: color);
      case 'settings':
        return Icon(Icons.settings_outlined, color: color, size: 22);
      case 'person':
        return AppIcons.person(color: color);
      case 'dollar':
        return AppIcons.dollar(color: color);
      case 'mail':
      case 'email':
        return Icon(Icons.mail_outline, color: color, size: 22);
      case 'chat':
      case 'message':
        return AppIcons.sendAbove(color: color);
      case 'heart':
        return AppIcons.heart(color: color);
      case 'notification':
        return AppIcons.notification(color: color);
      case 'ai':
        return Icon(Icons.auto_awesome_outlined, color: color, size: 22);
      case 'folder':
        return AppIcons.folder(color: color);
      case 'grid':
        return AppIcons.gridView(color: color);
      case 'trend':
        return AppIcons.arrowTrendUp(color: color);
      case 'phone':
        return Icon(Icons.phone_outlined, color: color, size: 22);
      case 'location':
        return AppIcons.location(color: color);
      case 'pie':
        return AppIcons.pie(color: color);
      case 'add':
        return AppIcons.add(color: color);
      case 'viewList':
        return AppIcons.viewList(color: color);
      default:
        return Icon(Icons.circle_outlined, color: color, size: 22);
    }
  }
}
