import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';

class DesktopDropWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final Future<void> Function(List<dynamic> files) onDropFiles;

  const DesktopDropWrapper({
    super.key,
    required this.child,
    required this.onDropFiles,
  });

  bool get _isDnDSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  ConsumerState<DesktopDropWrapper> createState() => _DesktopDropWrapperState();
}

class _DesktopDropWrapperState extends ConsumerState<DesktopDropWrapper> {
  bool _highlight = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    if (!widget._isDnDSupported) return widget.child;

    return DropTarget(
      onDragEntered: (_) => setState(() => _highlight = true),
      onDragExited: (_) => setState(() => _highlight = false),
      onDragDone: (details) async {
        if (!mounted) return;
        setState(() => _highlight = false);

        if (details.files.isEmpty) return;
        await widget.onDropFiles(details.files);
      },
      child: Stack(
        children: [
          widget.child,
          if (_highlight)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: theme.dashboardContainer,
                  alignment: Alignment.center,
                  child: Text(
                    'drop_image_here'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
