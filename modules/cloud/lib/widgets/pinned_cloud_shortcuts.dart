// cloud/components/pinned_cloud_shortcuts.dart

import 'dart:async';

import 'package:cloud/dashboard/shortcut_widget.dart';
import 'package:cloud/models/cloud_shortcut.dart';
import 'package:cloud/providers/providers.dart';
import 'package:cloud/utils/pin/cloud_shortcut.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/models/dnd_target_type.dart';
import 'package:core/dndservice/widgets/dnd_receiver.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class PinnedCloudShortcutsSection extends ConsumerStatefulWidget {
  final bool isMobile;
  final int maxItems;

  const PinnedCloudShortcutsSection({
    super.key,
    this.isMobile = false,
    this.maxItems = 24,
  });

  @override
  ConsumerState<PinnedCloudShortcutsSection> createState() =>
      _PinnedCloudShortcutsSectionState();
}

class _PinnedCloudShortcutsSectionState
    extends ConsumerState<PinnedCloudShortcutsSection> {
  bool _isPinning = false;
  bool _initialized = false;
  bool _isCollapsed = false;
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

  List<CloudShortcut> _localShortcuts = [];

  Future<void> _refresh() async {
    refreshCloudShortcuts(ref);
  }

  void _showSnack(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final theme = ref.read(themeColorsProvider);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: isError ? Colors.redAccent : theme.themeColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String? _nullableString(dynamic raw) {
    if (raw == null) return null;

    final value = raw.toString().trim();
    if (value.isEmpty || value == 'null' || value == 'None') return null;

    return value;
  }

  List<String> _extractIdsFromList(dynamic raw) {
    final result = <String>{};

    if (raw == null) return const [];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final id = _nullableString(
            item['id'] ??
                item['uuid'] ??
                item['file'] ??
                item['folder'] ??
                item['resource_id'],
          );

          if (id != null) result.add(id);
        } else {
          final id = _nullableString(item);
          if (id != null) result.add(id);
        }
      }
    } else if (raw is String) {
      for (final part in raw.split(',')) {
        final id = _nullableString(part);
        if (id != null) result.add(id);
      }
    }

    return result.toList();
  }

  List<String> _extractIdsByKeys(Map<String, dynamic> data, List<String> keys) {
    final result = <String>{};

    for (final key in keys) {
      result.addAll(_extractIdsFromList(data[key]));
    }

    return result.toList();
  }

  String? _labelFromPayload(DndPayload payload) {
    final data = payload.data ?? const <String, dynamic>{};

    return _nullableString(
      data['name'] ??
          data['original_name'] ??
          data['originalName'] ??
          data['title'] ??
          data['subject'],
    );
  }

  String? _subtitleFromPayload(DndPayload payload) {
    final data = payload.data ?? const <String, dynamic>{};

    return _nullableString(
      data['mime_type'] ??
          data['mimeType'] ??
          data['file_type'] ??
          data['fileType'] ??
          data['extension'],
    );
  }

  Future<CloudShortcut> _pinSingle({
    required String resourceType,
    required String resourceId,
    String? label,
    String? subtitle,
  }) async {
    return pinCloudShortcut(
      ref: ref,
      resourceType: resourceType,
      resourceId: resourceId,
      destination: CloudShortcutPinDestination.cloudQuickAccess,
      label: label,
      subtitle: subtitle,
    );
  }

  Future<List<CloudShortcut>> _pinPayload(DndPayload payload) async {
    if (payload.type == DndPayloadType.multipleCloudItems) {
      final data = payload.data ?? const <String, dynamic>{};

      final fileIds = _extractIdsByKeys(data, const [
        'files',
        'fileIds',
        'file_ids',
        'selectedFileIds',
        'selected_file_ids',
      ]);

      final folderIds = _extractIdsByKeys(data, const [
        'folders',
        'folderIds',
        'folder_ids',
        'selectedFolderIds',
        'selected_folder_ids',
      ]);

      final pinned = <CloudShortcut>[];

      for (final id in fileIds) {
        pinned.add(
          await _pinSingle(
            resourceType: 'file',
            resourceId: id,
            subtitle: 'File'.tr,
          ),
        );
      }

      for (final id in folderIds) {
        pinned.add(
          await _pinSingle(
            resourceType: 'folder',
            resourceId: id,
            subtitle: 'Folder'.tr,
          ),
        );
      }

      return pinned;
    }

    if (payload.type == DndPayloadType.cloudFile ||
        payload.type == DndPayloadType.file) {
      return [
        await _pinSingle(
          resourceType: 'file',
          resourceId: payload.id,
          label: _labelFromPayload(payload),
          subtitle: _subtitleFromPayload(payload) ?? 'File'.tr,
        ),
      ];
    }

    if (payload.type == DndPayloadType.cloudFolder ||
        payload.type == DndPayloadType.folder) {
      return [
        await _pinSingle(
          resourceType: 'folder',
          resourceId: payload.id,
          label: _labelFromPayload(payload),
          subtitle: 'Folder'.tr,
        ),
      ];
    }

    throw StateError('Unsupported payload type: ${payload.type.name}');
  }

  Future<void> _handleDrop(DndPayload payload) async {
    if (_isPinning) return;

    setState(() => _isPinning = true);

    try {
      final newShortcuts = await _pinPayload(payload);

      // Optimistically add to local list — provider will sync from server shortly
      final existingIds = _localShortcuts.map((s) => s.id).toSet();
      setState(() {
        _localShortcuts = [
          ..._localShortcuts,
          ...newShortcuts.where((s) => !existingIds.contains(s.id)),
        ];
      });

      if (!mounted) return;

      _showSnack(
        newShortcuts.length == 1
            ? 'Pinned to Cloud quick access'.tr
            : '${newShortcuts.length} ${'items pinned to Cloud quick access'.tr}',
      );
    } catch (e) {
      if (!mounted) return;

      _showSnack('${'Could not pin shortcut'.tr}: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isPinning = false);
      }
    }
  }

  Future<void> _unpin(CloudShortcut shortcut) async {
    final snapshot = List<CloudShortcut>.from(_localShortcuts);
    setState(() {
      _localShortcuts =
          _localShortcuts.where((s) => s.id != shortcut.id).toList();
    });

    try {
      await ref.read(cloudShortcutsApiProvider).unpin(shortcut.id);
      if (!mounted) return;
      _showSnack('Shortcut removed'.tr);
    } catch (e) {
      if (!mounted) return;
      setState(() => _localShortcuts = snapshot);
      _showSnack('${'Could not remove shortcut'.tr}: $e', isError: true);
    }
  }

  Future<void> _unpinSelected() async {
    final ids = Set<String>.from(_selectedIds);
    final snapshot = List<CloudShortcut>.from(_localShortcuts);

    setState(() {
      _localShortcuts =
          _localShortcuts.where((s) => !ids.contains(s.id)).toList();
      _selectedIds.clear();
      _isSelectMode = false;
    });

    try {
      for (final id in ids) {
        await ref.read(cloudShortcutsApiProvider).unpin(id);
      }
      if (!mounted) return;
      _showSnack('${ids.length} ${'shortcuts removed'.tr}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _localShortcuts = snapshot);
      _showSnack('${'Could not remove shortcuts'.tr}: $e', isError: true);
    }
  }

  Future<void> _unpinAll() async {
    final snapshot = List<CloudShortcut>.from(_localShortcuts);
    final allIds = _localShortcuts.map((s) => s.id).toList();

    setState(() {
      _localShortcuts = [];
      _selectedIds.clear();
      _isSelectMode = false;
    });

    try {
      for (final id in allIds) {
        await ref.read(cloudShortcutsApiProvider).unpin(id);
      }
      if (!mounted) return;
      _showSnack('All shortcuts removed'.tr);
    } catch (e) {
      if (!mounted) return;
      setState(() => _localShortcuts = snapshot);
      _showSnack('${'Could not remove shortcuts'.tr}: $e', isError: true);
    }
  }

  Future<void> _openShortcut(CloudShortcut shortcut) async {
    try {
      await ref.read(cloudShortcutsApiProvider).open(shortcut.id);
    } catch (_) {}
  }

  List<PieAction> _pieActionsFor(CloudShortcut shortcut) {
    return [
      PieAction(
        tooltip: Text('Open'.tr),
        onSelect: () => _openShortcut(shortcut),
        child: const Icon(Icons.open_in_new_rounded, color: Colors.white),
      ),
      PieAction(
        tooltip: Text('Remove shortcut'.tr),
        onSelect: () => _unpin(shortcut),
        child: const Icon(Icons.push_pin_outlined, color: Colors.white),
      ),
    ];
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(_localShortcuts.map((s) => s.id));
    });
  }

  Widget _buildEmptyState(ThemeColors theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(140)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.push_pin_outlined,
            size: 34,
            color: theme.textColor.withAlpha(160),
          ),
          const SizedBox(height: 10),
          Text(
            'No pinned files yet'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Drag files or folders here to pin them as quick access shortcuts.'
                .tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor.withAlpha(150),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutGrid(ThemeColors theme, List<CloudShortcut> shortcuts) {
    final visible = shortcuts.take(widget.maxItems).toList();

    if (visible.isEmpty) {
      return _buildEmptyState(theme);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final minTileWidth = widget.isMobile ? 130.0 : 145.0;
        final spacing = widget.isMobile ? 8.0 : 10.0;

        final columns = (constraints.maxWidth / minTileWidth).floor().clamp(
          1,
          widget.isMobile ? 2 : 6,
        );

        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              visible.map((shortcut) {
                final settings = {
                  ...shortcut.toDashboardSettingsFallback(),
                  'shortcutId': shortcut.id,
                  'cloudRoute': '/cloud',
                };

                final isSelected = _selectedIds.contains(shortcut.id);

                return SizedBox(
                  width: tileWidth,
                  height: widget.isMobile ? 112 : 118,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PieMenu(
                          theme: PieTheme.of(context).copyWith(
                            overlayColor:
                                (() {
                                  final bool uiIsDark =
                                      theme.textColor.computeLuminance() > 0.5;
                                  final base =
                                      uiIsDark ? Colors.black : Colors.white;
                                  return base.withValues(alpha: 0.70);
                                })(),
                          ),
                          onPressedWithDevice: (_) => _openShortcut(shortcut),
                          actions: _pieActionsFor(shortcut),
                          child: DndSender(
                            useLongPress: true,
                            payload: DndPayload(
                              type: DndPayloadType.cloudQuickAccess,
                              id: shortcut.id,
                              data: {
                                'shortcutId': shortcut.id,
                                'resourceType': shortcut.resourceType,
                                'id': shortcut.itemId ?? shortcut.id,
                                'name': shortcut.resourceName,
                                'mimeType': shortcut.mimeType,
                                'fileType': shortcut.fileType,
                                'extension': shortcut.extension,
                                'thumbnailUrl': shortcut.thumbnailUrl,
                              },
                            ),
                            child: DashboardCloudShortcutWidget(
                              settings: settings,
                              isMobile: widget.isMobile,
                              isEditMode: false,
                            ),
                          ),
                        ),
                      ),
                      if (_isSelectMode)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => _toggleSelection(shortcut.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? theme.themeColor.withAlpha(40)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? theme.themeColor
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_isSelectMode)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: IgnorePointer(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? theme.themeColor
                                        : theme.dashboardContainer.withAlpha(
                                          220,
                                        ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? theme.themeColor
                                          : theme.textColor.withAlpha(100),
                                ),
                              ),
                              child:
                                  isSelected
                                      ? const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                          ),
                        )
                      else
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Material(
                            color: theme.dashboardContainer.withAlpha(220),
                            borderRadius: BorderRadius.circular(9),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(9),
                              onTap: () => _unpin(shortcut),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: theme.textColor.withAlpha(170),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildContent(ThemeColors theme) {
    final shortcutsAsync = ref.watch(
      cloudShortcutsByDashboardProvider(kDefaultCloudQuickAccessKey),
    );

    return shortcutsAsync.when(
      skipLoadingOnRefresh: true,
      loading: () {
        if (_initialized) return _buildShortcutGrid(theme, _localShortcuts);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: AppLottie.loading(size: 420)),
        );
      },
      error: (error, stack) {
        if (_initialized) return _buildShortcutGrid(theme, _localShortcuts);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.adPopBackground.withAlpha(100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withAlpha(110)),
          ),
          child: Text(
            '${'Error loading pinned files'.tr}: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        );
      },
      data: (_) => _buildShortcutGrid(theme, _localShortcuts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    // Sync local list from server when provider delivers fresh data
    ref.listen<AsyncValue<List<CloudShortcut>>>(
      cloudShortcutsByDashboardProvider(kDefaultCloudQuickAccessKey),
      (_, next) {
        next.whenData((shortcuts) {
          if (mounted) {
            setState(() {
              _localShortcuts = shortcuts;
              _initialized = true;
            });
          }
        });
      },
    );

    return DndReceiver(
      targets: const [DndTargetType.cloudQuickAccess],
      showSnackbar: false,
      showHoverFeedback: false,
      onDrop: _handleDrop,
      builder: (context, hoveringPayload, isHovering, canAcceptDrop, child) {
        final borderColor =
            isHovering
                ? canAcceptDrop
                    ? theme.themeColor
                    : Colors.redAccent
                : theme.dashboardBoarder;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isHovering ? 2 : 1.4),
            boxShadow:
                isHovering
                    ? [
                      BoxShadow(
                        color: borderColor.withAlpha(35),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ]
                    : null,
          ),
          child: child,
        );
      },
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
                  Icons.push_pin_rounded,
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
                      'Pinned files & folders'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quick access available on all your devices'.tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(160),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isPinning)
                SizedBox(
                  width: 26,
                  height: 26,
                  child: AppLottie.loading(size: 260),
                )
              else ...[
                if (!_isSelectMode && _localShortcuts.isNotEmpty) ...[
                  IconButton(
                    tooltip: 'Select'.tr,
                    onPressed: _toggleSelectMode,
                    icon: Icon(
                      Icons.checklist_rounded,
                      color: theme.textColor,
                      size: 22,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove all'.tr,
                    onPressed: _unpinAll,
                    icon: Icon(
                      Icons.delete_sweep_rounded,
                      color: theme.textColor,
                      size: 22,
                    ),
                  ),
                ],
                if (_isSelectMode) ...[
                  if (_selectedIds.length < _localShortcuts.length)
                    TextButton(
                      onPressed: _selectAll,
                      child: Text(
                        'Select all'.tr,
                        style: TextStyle(color: theme.themeColor),
                      ),
                    ),
                  TextButton(
                    onPressed: _selectedIds.isEmpty ? null : _unpinSelected,
                    child: Text(
                      '${'Remove'.tr} (${_selectedIds.length})',
                      style: TextStyle(
                        color:
                            _selectedIds.isEmpty
                                ? theme.textColor.withAlpha(100)
                                : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cancel'.tr,
                    onPressed: _toggleSelectMode,
                    icon: Icon(Icons.close_rounded, color: theme.textColor),
                  ),
                ] else ...[
                  IconButton(
                    tooltip: 'Refresh'.tr,
                    onPressed: _refresh,
                    icon: Icon(Icons.refresh_rounded, color: theme.textColor),
                  ),
                ],
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
