import 'package:cloud/dashboard/cloud_shortcut_preview.dart';
import 'package:cloud/models/cloud_shortcut.dart';
import 'package:cloud/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';

enum CloudShortcutItemType {
  file,
  folder;

  static CloudShortcutItemType fromRaw(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'folder':
        return CloudShortcutItemType.folder;
      case 'file':
      default:
        return CloudShortcutItemType.file;
    }
  }

  String get key {
    switch (this) {
      case CloudShortcutItemType.file:
        return 'file';
      case CloudShortcutItemType.folder:
        return 'folder';
    }
  }

  String get label {
    switch (this) {
      case CloudShortcutItemType.file:
        return 'File';
      case CloudShortcutItemType.folder:
        return 'Folder';
    }
  }
}

class DashboardCloudShortcutWidget extends ConsumerWidget {
  final Map<String, dynamic> settings;
  final bool isMobile;
  final bool isEditMode;
  final Future<void> Function(BuildContext context, WidgetRef ref)? onReconfigure;

  const DashboardCloudShortcutWidget({
    super.key,
    required this.settings,
    required this.isMobile,
    required this.isEditMode,
    this.onReconfigure,
  });

  String? get _shortcutId => _nullableString(settings['shortcutId']);
  String? get _fallbackItemId => _nullableString(settings['itemId']);

  Map<String, dynamic> _effectiveSettings(CloudShortcut? shortcut) {
    if (shortcut == null) return settings;

    final resolved = shortcut.widgetSettings.isNotEmpty
        ? shortcut.widgetSettings
        : shortcut.toDashboardSettingsFallback();

    return {
      ...settings,
      ...resolved,
      'shortcutId': shortcut.id,
      'itemType': shortcut.resourceType,
      'itemId': shortcut.itemId,
      'parentId': shortcut.parentId,
      'name': shortcut.resourceName,
      'subtitle': shortcut.subtitle,
      'extension': shortcut.extension,
      'mimeType': shortcut.mimeType,
      'fileType': shortcut.fileType,
      'sizeBytes': shortcut.sizeBytes,
      'thumbnailUrl': shortcut.thumbnailUrl,
    };
  }

  CloudShortcutItemType _typeOf(Map<String, dynamic> data) {
    return CloudShortcutItemType.fromRaw(data['itemType']);
  }

  String _nameOf(Map<String, dynamic> data) {
    final raw = (data['name'] ?? '').toString().trim();
    if (raw.isNotEmpty) return raw;

    final type = _typeOf(data);
    return type == CloudShortcutItemType.folder ? 'Folder'.tr : 'File'.tr;
  }

  String _subtitleOf(Map<String, dynamic> data) {
    final raw = (data['subtitle'] ?? '').toString().trim();
    if (raw.isNotEmpty) return raw;

    final ext = (data['extension'] ?? '').toString().trim();
    if (ext.isNotEmpty) return ext.toUpperCase();

    final mimeType = (data['mimeType'] ?? '').toString().trim();
    if (mimeType.isNotEmpty) return mimeType;

    return _typeOf(data).label.tr;
  }

  String _cloudRouteOf(Map<String, dynamic> data) {
    final raw = (data['cloudRoute'] ?? '').toString().trim();
    return raw.isNotEmpty ? raw : '/cloud';
  }

  IconData _iconOf(Map<String, dynamic> data) {
    final type = _typeOf(data);

    if (type == CloudShortcutItemType.folder) {
      return Icons.folder_rounded;
    }

    final mimeType = (data['mimeType'] ?? '').toString().toLowerCase();
    final extension = (data['extension'] ?? '').toString().toLowerCase();

    if (mimeType.contains('image') ||
        ['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg'].contains(extension)) {
      return Icons.image_outlined;
    }

    if (mimeType.contains('pdf') || extension == 'pdf') {
      return Icons.picture_as_pdf_outlined;
    }

    if (mimeType.contains('spreadsheet') ||
        ['xls', 'xlsx', 'csv'].contains(extension)) {
      return Icons.table_chart_outlined;
    }

    if (mimeType.contains('word') ||
        ['doc', 'docx', 'txt', 'rtf'].contains(extension)) {
      return Icons.article_outlined;
    }

    if (mimeType.contains('video') ||
        ['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      return Icons.movie_creation_outlined;
    }

    if (mimeType.contains('audio') ||
        ['mp3', 'wav', 'ogg'].contains(extension)) {
      return Icons.audiotrack_outlined;
    }

    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(extension)) {
      return Icons.archive_outlined;
    }

    return Icons.insert_drive_file_outlined;
  }

  Color _accentOf(Map<String, dynamic> data, ThemeColors theme) {
    final type = _typeOf(data);

    if (type == CloudShortcutItemType.folder) {
      return Colors.amber;
    }

    final extension = (data['extension'] ?? '').toString().toLowerCase();
    final mimeType = (data['mimeType'] ?? '').toString().toLowerCase();

    if (mimeType.contains('pdf') || extension == 'pdf') {
      return Colors.redAccent;
    }

    if (mimeType.contains('image')) {
      return Colors.purpleAccent;
    }

    if (mimeType.contains('spreadsheet') ||
        ['xls', 'xlsx', 'csv'].contains(extension)) {
      return Colors.green;
    }

    return theme.themeColor;
  }

  String _formatSize(dynamic raw) {
    final bytes = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
    if (bytes == null || bytes <= 0) return '';

    const kb = 1024;
    const mb = 1024 * 1024;
    const gb = 1024 * 1024 * 1024;

    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';

    return '$bytes B';
  }

  Future<void> _openWithTarget({
    required BuildContext context,
    required WidgetRef ref,
    required CloudShortcutOpenTarget? target,
    required Map<String, dynamic> data,
  }) async {
    if (isEditMode) return;

    final nav = ref.read(navigationService);
    final params = ref.read(cloudExplorerParamsProvider);
    final route = _cloudRouteOf(data);

    final fallbackType = _typeOf(data);
    final fallbackItemId = _nullableString(data['itemId']);
    final fallbackParentId = _nullableString(data['parentId']);
    final fallbackName = _nameOf(data);

    if (target != null) {
      ref.read(cloudExplorerParamsProvider.notifier).state = params.copyWith(
            parent: target.parent,
            showAllFiles: target.showAllFiles,
            fileType: null,
            isDeleted: false,
            search: target.search,
          );

      nav.pushNamedScreen(route);
      return;
    }

    if (fallbackType == CloudShortcutItemType.folder && fallbackItemId != null) {
      ref.read(cloudExplorerParamsProvider.notifier).state = params.copyWith(
            parent: fallbackItemId,
            showAllFiles: false,
            fileType: null,
            isDeleted: false,
            search: null,
          );

      nav.pushNamedScreen(route);
      return;
    }

    ref.read(cloudExplorerParamsProvider.notifier).state = params.copyWith(
          parent: fallbackParentId,
          showAllFiles: fallbackParentId == null,
          fileType: null,
          isDeleted: false,
          search: fallbackName,
        );

    nav.pushNamedScreen(route);
  }

  Future<void> _open({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> data,
    required CloudShortcut? shortcut,
  }) async {
    if (isEditMode) return;

    final shortcutId = shortcut?.id ?? _shortcutId;

    CloudShortcutOpenTarget? target;

    if (shortcutId != null) {
      try {
        target = await ref.read(cloudShortcutsApiProvider).open(shortcutId);
      } catch (_) {
        target = shortcut?.openTarget;
      }
    }

    if (!context.mounted) return;

    // When a resolved shortcut is available, show the in-place preview sheet.
    if (shortcut != null && shortcut.isAvailable) {
      final resolvedTarget = target;
      await showCloudShortcutPreviewSheet(
        context: context,
        ref: ref,
        shortcut: shortcut,
        onNavigateToCloud: () => _openWithTarget(
          context: context,
          ref: ref,
          target: resolvedTarget,
          data: data,
        ),
      );
      return;
    }

    // Fallback: navigate directly (error / no shortcut case).
    await _openWithTarget(
      context: context,
      ref: ref,
      target: target,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcutId = _shortcutId;

    if (shortcutId == null) {
      return _ShortcutTile(
        settings: settings,
        shortcut: null,
        isMobile: isMobile,
        isEditMode: isEditMode,
        isLoading: false,
        errorText: null,
        disableOpen: false,
        effectiveSettingsBuilder: _effectiveSettings,
        typeOf: _typeOf,
        nameOf: _nameOf,
        subtitleOf: _subtitleOf,
        iconOf: _iconOf,
        accentOf: _accentOf,
        formatSize: _formatSize,
        onOpen: (data) => _open(
          context: context,
          ref: ref,
          data: data,
          shortcut: null,
        ),
        onReconfigure: onReconfigure != null
            ? (ctx, r) => onReconfigure!(ctx, r)
            : null,
      );
    }

    final shortcutAsync = ref.watch(cloudShortcutProvider(shortcutId));

    return shortcutAsync.when(
      loading: () => _ShortcutTile(
        settings: settings,
        shortcut: null,
        isMobile: isMobile,
        isEditMode: isEditMode,
        isLoading: true,
        errorText: null,
        disableOpen: true,
        effectiveSettingsBuilder: _effectiveSettings,
        typeOf: _typeOf,
        nameOf: _nameOf,
        subtitleOf: _subtitleOf,
        iconOf: _iconOf,
        accentOf: _accentOf,
        formatSize: _formatSize,
        onOpen: (data) => _open(
          context: context,
          ref: ref,
          data: data,
          shortcut: null,
        ),
        onReconfigure: null,
      ),
      error: (_, __) {
        final canFallbackOpen = _fallbackItemId != null;

        return _ShortcutTile(
          settings: settings,
          shortcut: null,
          isMobile: isMobile,
          isEditMode: isEditMode,
          isLoading: false,
          errorText: 'Shortcut unavailable'.tr,
          disableOpen: !canFallbackOpen,
          effectiveSettingsBuilder: _effectiveSettings,
          typeOf: _typeOf,
          nameOf: _nameOf,
          subtitleOf: _subtitleOf,
          iconOf: _iconOf,
          accentOf: _accentOf,
          formatSize: _formatSize,
          onOpen: (data) => _open(
            context: context,
            ref: ref,
            data: data,
            shortcut: null,
          ),
          onReconfigure: onReconfigure != null
              ? (ctx, r) => onReconfigure!(ctx, r)
              : null,
        );
      },
      data: (shortcut) => _ShortcutTile(
        settings: settings,
        shortcut: shortcut,
        isMobile: isMobile,
        isEditMode: isEditMode,
        isLoading: false,
        errorText: shortcut.isAvailable ? null : 'No access'.tr,
        disableOpen: !shortcut.isAvailable,
        effectiveSettingsBuilder: _effectiveSettings,
        typeOf: _typeOf,
        nameOf: _nameOf,
        subtitleOf: _subtitleOf,
        iconOf: _iconOf,
        accentOf: _accentOf,
        formatSize: _formatSize,
        onOpen: shortcut.isAvailable
            ? (data) => _open(
                  context: context,
                  ref: ref,
                  data: data,
                  shortcut: shortcut,
                )
            : null,
        onReconfigure: onReconfigure != null
            ? (ctx, r) => onReconfigure!(ctx, r)
            : null,
      ),
    );
  }
}

class _ShortcutTile extends ConsumerWidget {
  final Map<String, dynamic> settings;
  final CloudShortcut? shortcut;
  final bool isMobile;
  final bool isEditMode;
  final bool isLoading;
  final String? errorText;
  final bool disableOpen;

  final Map<String, dynamic> Function(CloudShortcut? shortcut)
      effectiveSettingsBuilder;
  final CloudShortcutItemType Function(Map<String, dynamic> data) typeOf;
  final String Function(Map<String, dynamic> data) nameOf;
  final String Function(Map<String, dynamic> data) subtitleOf;
  final IconData Function(Map<String, dynamic> data) iconOf;
  final Color Function(Map<String, dynamic> data, ThemeColors theme) accentOf;
  final String Function(dynamic raw) formatSize;
  final Future<void> Function(Map<String, dynamic> data)? onOpen;
  final Future<void> Function(BuildContext context, WidgetRef ref)? onReconfigure;

  const _ShortcutTile({
    required this.settings,
    required this.shortcut,
    required this.isMobile,
    required this.isEditMode,
    required this.isLoading,
    required this.errorText,
    required this.disableOpen,
    required this.effectiveSettingsBuilder,
    required this.typeOf,
    required this.nameOf,
    required this.subtitleOf,
    required this.iconOf,
    required this.accentOf,
    required this.formatSize,
    required this.onOpen,
    required this.onReconfigure,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final data = effectiveSettingsBuilder(shortcut);

    final type = typeOf(data);
    final name = nameOf(data);
    final subtitle = subtitleOf(data);
    final icon = iconOf(data);
    final accent = accentOf(data, theme);
    final sizeText = formatSize(data['sizeBytes']);
    final thumbnailUrl = (data['thumbnailUrl'] ?? '').toString().trim();

    final itemId = _nullableString(data['itemId']);
    final shortcutId = _nullableString(data['shortcutId']);
    final hasAnyTarget = itemId != null || shortcutId != null;
    final hasMissingTarget = !hasAnyTarget && !isLoading;

    final hasError = errorText != null && errorText!.trim().isNotEmpty;
    final displayError = hasError && !isLoading;
    final showErrorAsTitle = displayError && disableOpen;

    final canReconfigure = hasMissingTarget && onReconfigure != null && !isEditMode;
    final disabled = (hasMissingTarget && !canReconfigure) ||
        isLoading ||
        (!hasMissingTarget && (disableOpen || onOpen == null)) ||
        isEditMode;

    final titleText = hasMissingTarget
        ? 'Configure shortcut'.tr
        : showErrorAsTitle
            ? errorText!
            : name;

    final subtitleText = displayError && !disableOpen
        ? errorText!
        : sizeText.isNotEmpty
            ? sizeText
            : subtitle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final verySmall =
            constraints.maxHeight < 92 || constraints.maxWidth < 130;

        return Tooltip(
          message: hasMissingTarget
              ? (canReconfigure
                  ? 'tap_to_configure_shortcut'.tr
                  : 'Shortcut not configured'.tr)
              : displayError
                  ? errorText!
                  : '${type.label.tr}: $name',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: double.infinity,
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasMissingTarget || showErrorAsTitle
                    ? Colors.redAccent.withAlpha(120)
                    : accent.withAlpha(110),
                width: 1.2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: disabled
                    ? null
                    : canReconfigure
                        ? () => onReconfigure!(context, ref)
                        : () => onOpen!(data),
                child: Padding(
                  padding: EdgeInsets.all(verySmall ? 8 : 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: verySmall ? 34 : 40,
                            height: verySmall ? 34 : 40,
                            decoration: BoxDecoration(
                              color: accent.withAlpha(28),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accent.withAlpha(80),
                              ),
                            ),
                            child: isLoading
                                ? Padding(
                                    padding: const EdgeInsets.all(9),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: accent,
                                    ),
                                  )
                                : thumbnailUrl.isNotEmpty && !showErrorAsTitle
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Image.network(
                                          thumbnailUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            icon,
                                            color: accent,
                                            size: verySmall ? 18 : 22,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        hasMissingTarget || showErrorAsTitle
                                            ? Icons.error_outline_rounded
                                            : icon,
                                        color: hasMissingTarget ||
                                                showErrorAsTitle
                                            ? Colors.redAccent
                                            : accent,
                                        size: verySmall ? 18 : 22,
                                      ),
                          ),
                          const Spacer(),
                          Icon(
                            isEditMode
                                ? Icons.push_pin_outlined
                                : Icons.open_in_new_rounded,
                            size: isEditMode ? 16 : 15,
                            color: theme.textColor.withAlpha(
                              disabled ? 80 : 145,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        titleText,
                        maxLines: verySmall ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: showErrorAsTitle
                              ? Colors.redAccent
                              : theme.textColor,
                          fontSize: verySmall ? 11 : 12,
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                        ),
                      ),
                      SizedBox(height: verySmall ? 3 : 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subtitleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: displayError && !disableOpen
                                    ? Colors.orangeAccent
                                    : theme.textColor.withAlpha(150),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (type == CloudShortcutItemType.folder &&
                              !showErrorAsTitle)
                            Icon(
                              Icons.folder_open_rounded,
                              size: 13,
                              color: accent,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String? _nullableString(dynamic raw) {
  if (raw == null) return null;

  final value = raw.toString().trim();
  if (value.isEmpty || value == 'null' || value == 'None') {
    return null;
  }

  return value;
}