import 'package:cloud/utils/pin/cloud_shortcut.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

enum _PinTargetKind {
  cloud,
  dashboard,
}

class _PinTargetOption {
  final _PinTargetKind kind;
  final String id;
  final String label;
  final String? dashboardKey;
  final IconData icon;

  const _PinTargetOption({
    required this.kind,
    required this.id,
    required this.label,
    required this.icon,
    this.dashboardKey,
  });
}

bool get _isDesktopOrWeb =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;

/// Shows the "pin shortcut" destination picker.
/// On desktop/web: opens as a dialog.
/// On mobile: opens as a draggable bottom sheet.
Future<void> showCloudShortcutPinDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String resourceType,
  required String resourceId,
  String? label,
  String? subtitle,
}) async {
  final options = <_PinTargetOption>[
    _PinTargetOption(
      kind: _PinTargetKind.cloud,
      id: kDefaultCloudQuickAccessKey,
      label: 'Cloud quick access'.tr,
      icon: Icons.cloud_outlined,
    ),
    ...kDefaultCloudDashboardPinTargets.map(
      (target) => _PinTargetOption(
        kind: _PinTargetKind.dashboard,
        id: target.id,
        label: target.label.tr,
        dashboardKey: target.dashboardKey,
        icon: Icons.dashboard_customize_outlined,
      ),
    ),
  ];

  if (_isDesktopOrWeb) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => _PinDialogFrame(
        outerRef: ref,
        options: options,
        resourceType: resourceType,
        resourceId: resourceId,
        label: label,
        subtitle: subtitle,
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (sheetCtx, sc) => _PinSheetFrame(
        outerRef: ref,
        options: options,
        resourceType: resourceType,
        resourceId: resourceId,
        label: label,
        subtitle: subtitle,
        scrollController: sc,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Shared body: selection list + submit logic
// ---------------------------------------------------------------------------

class _PinBody extends ConsumerStatefulWidget {
  const _PinBody({
    required this.outerRef,
    required this.options,
    required this.resourceType,
    required this.resourceId,
    required this.theme,
    this.label,
    this.subtitle,
    this.scrollController,
  });

  final WidgetRef outerRef;
  final List<_PinTargetOption> options;
  final String resourceType;
  final String resourceId;
  final ThemeColors theme;
  final String? label;
  final String? subtitle;
  final ScrollController? scrollController;

  @override
  ConsumerState<_PinBody> createState() => _PinBodyState();
}

class _PinBodyState extends ConsumerState<_PinBody> {
  late _PinTargetOption _selected = widget.options.first;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_selected.kind == _PinTargetKind.cloud) {
        await pinCloudShortcut(
          ref: widget.outerRef,
          resourceType: widget.resourceType,
          resourceId: widget.resourceId,
          destination: CloudShortcutPinDestination.cloudQuickAccess,
          label: widget.label,
          subtitle: widget.subtitle,
        );
      } else {
        await pinCloudShortcut(
          ref: widget.outerRef,
          resourceType: widget.resourceType,
          resourceId: widget.resourceId,
          destination: CloudShortcutPinDestination.dashboard,
          dashboardKey: _selected.dashboardKey,
          label: widget.label,
          subtitle: widget.subtitle,
        );
      }

      if (!mounted) return;

      final navigatorContext = context;
      Navigator.of(navigatorContext).pop();

      final messenger = ScaffoldMessenger.maybeOf(navigatorContext);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _selected.kind == _PinTargetKind.cloud
                  ? 'Pinned to Cloud quick access'.tr
                  : 'Pinned to dashboard'.tr,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: widget.theme.themeColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose where this shortcut should be pinned.'.tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(170),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 14),
        Flexible(
          child: ListView.separated(
            controller: widget.scrollController,
            shrinkWrap: widget.scrollController == null,
            physics: widget.scrollController == null
                ? const NeverScrollableScrollPhysics()
                : null,
            itemCount: widget.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final option = widget.options[index];
              final checked = _selected.id == option.id;

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _loading
                    ? null
                    : () {
                        setState(() => _selected = option);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: checked
                        ? theme.themeColor.withAlpha(30)
                        : theme.adPopBackground.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: checked ? theme.themeColor : theme.dashboardBoarder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option.icon,
                        color: checked ? theme.themeColor : theme.textColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight:
                                checked ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                      Radio<String>(
                        value: option.id,
                        groupValue: _selected.id,
                        activeColor: theme.themeColor,
                        onChanged: _loading
                            ? null
                            : (_) {
                                setState(() => _selected = option);
                              },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.themeColor,
              foregroundColor: theme.themeTextColor,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.themeTextColor,
                    ),
                  )
                : const Icon(Icons.push_pin_rounded, size: 17),
            label: Text('Pin'.tr),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop: Dialog frame
// ---------------------------------------------------------------------------

class _PinDialogFrame extends ConsumerWidget {
  const _PinDialogFrame({
    required this.outerRef,
    required this.options,
    required this.resourceType,
    required this.resourceId,
    this.label,
    this.subtitle,
  });

  final WidgetRef outerRef;
  final List<_PinTargetOption> options;
  final String resourceType;
  final String resourceId;
  final String? label;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return AlertDialog(
      backgroundColor: theme.dashboardContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      title: Text(
        'Pin shortcut'.tr,
        style: TextStyle(
          color: theme.textColor,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SizedBox(
        width: 440,
        child: _PinBody(
          outerRef: outerRef,
          options: options,
          resourceType: resourceType,
          resourceId: resourceId,
          theme: theme,
          label: label,
          subtitle: subtitle,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel'.tr,
            style: TextStyle(color: theme.textColor),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile: Draggable bottom sheet frame
// ---------------------------------------------------------------------------

class _PinSheetFrame extends ConsumerWidget {
  const _PinSheetFrame({
    required this.outerRef,
    required this.options,
    required this.resourceType,
    required this.resourceId,
    required this.scrollController,
    this.label,
    this.subtitle,
  });

  final WidgetRef outerRef;
  final List<_PinTargetOption> options;
  final String resourceType;
  final String resourceId;
  final ScrollController scrollController;
  final String? label;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      color: theme.dashboardContainer,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textColor.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Pin shortcut'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.textColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: theme.textColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Divider(color: theme.dashboardBoarder, height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _PinBody(
                outerRef: outerRef,
                options: options,
                resourceType: resourceType,
                resourceId: resourceId,
                theme: theme,
                label: label,
                subtitle: subtitle,
                scrollController: scrollController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
