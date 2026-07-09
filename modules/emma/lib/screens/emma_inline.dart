// emma/screens/emma_inline.dart 

import 'package:core/ui/device_type_util.dart';
import 'package:emma/provider/context.dart';
import 'package:emma/widgets/message_list.dart';
import 'package:emma/widgets/send_message_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

/// Simple inline Emma chat used in bottom-sheet / overlay.
/// [dynamicAppId], [pageId] – dynamic_app context for prompt.
///
/// node context:
/// - [nodeId]   – stable id in dynamic tree
/// - [nodePath] – path in tree (preferred for fast lookup)
/// - [nodeKind] – e.g. "item.text"
class EmmaChatInline extends ConsumerStatefulWidget {
  final int? dynamicAppId;
  final int? pageId;

  /// ✅ node context (dynamic tree)
  final String? nodeId;
  final List<int>? nodePath;
  final String? nodeKind;

  /// When true, the widget expands to fill its parent instead of capping at 520px.
  /// Use this when embedding as a permanent side panel (not in a popup/overlay).
  final bool fillParent;

  const EmmaChatInline({
    super.key,
    this.dynamicAppId,
    this.pageId,
    this.nodeId,
    this.nodePath,
    this.nodeKind,
    this.fillParent = false,
  });

  @override
  ConsumerState<EmmaChatInline> createState() => _EmmaChatInlineState();
}

class _EmmaChatInlineState extends ConsumerState<EmmaChatInline> {
  late final String _ownerKey =
      'emma_inline_${DateTime.now().microsecondsSinceEpoch}_${identityHashCode(this)}';

  @override
  void initState() {
    super.initState();
    _applyContext();
  }

  @override
  void didUpdateWidget(covariant EmmaChatInline oldWidget) {
    super.didUpdateWidget(oldWidget);

    final changed = oldWidget.dynamicAppId != widget.dynamicAppId ||
        oldWidget.pageId != widget.pageId ||
        oldWidget.nodeId != widget.nodeId ||
        !_samePath(oldWidget.nodePath, widget.nodePath) ||
        oldWidget.nodeKind != widget.nodeKind;

    if (changed) _applyContext();
  }

  bool _samePath(List<int>? a, List<int>? b) {
    if (identical(a, b)) return true;
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _applyContext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final hasAnyContext = widget.dynamicAppId != null ||
          widget.pageId != null ||
          (widget.nodeId != null && widget.nodeId!.trim().isNotEmpty) ||
          (widget.nodeKind != null && widget.nodeKind!.trim().isNotEmpty) ||
          (widget.nodePath != null && widget.nodePath!.isNotEmpty);

      final notifier = ref.read(emmaContextProvider.notifier);

      // Jeśli ktoś odpalił chat bez kontekstu → czyść ownerKey, żeby nie leakowało.
      if (!hasAnyContext) {
        notifier.clearDynamicAppContext(ownerKey: _ownerKey);
        return;
      }

      notifier.setDynamicAppContext(
        ownerKey: _ownerKey,
        appId: widget.dynamicAppId,
        pageId: widget.pageId,
        nodeId: widget.nodeId,
        nodePath: widget.nodePath == null ? null : List<int>.from(widget.nodePath!),
        nodeKind: widget.nodeKind,
      );
    });
  }

  @override
  void dispose() {
    // Clear context to avoid leaking old ids into other chats
    try {
      ref
          .read(emmaContextProvider.notifier)
          .clearDynamicAppContext(ownerKey: _ownerKey);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use actual available width so narrow panels (side panel, bottom sheet)
        // get compact layout even on desktop screens.
        final isNarrow = constraints.maxWidth.isFinite
            ? constraints.maxWidth < 600
            : DeviceTypeUtil.isMobile(context);

        final inner = DecoratedBox(
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: widget.fillParent
                ? BorderRadius.zero
                : BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: MessageListView(isMobile: isNarrow),
                ),
              ),
              SendMessageBox(isMobile: isNarrow),
            ],
          ),
        );

        if (widget.fillParent) return inner;

        final height = constraints.maxHeight.isInfinite
            ? 520.0
            : constraints.maxHeight.clamp(260.0, 520.0);
        return SizedBox(height: height, child: inner);
      },
    );
  }
}
