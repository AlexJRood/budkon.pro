import 'dart:async';
import 'package:core/ui/device_type_util.dart';
import 'package:emma/tools/emma_overlay_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GenericAiOverlayScope extends InheritedWidget {
  final VoidCallback closeOverlay;

  const GenericAiOverlayScope({
    super.key,
    required this.closeOverlay,
    required super.child,
  });

  static GenericAiOverlayScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GenericAiOverlayScope>();
  }

  @override
  bool updateShouldNotify(covariant GenericAiOverlayScope oldWidget) => false;
}

Future<T?> showGenericAiSheet<T>({
  required BuildContext context,
  BuildContext? presentationContext,
  required ThemeColors theme,
  required Widget child,
  required String title,
  String? headerTag,
  VoidCallback? onSave,
  String? saveLabel,
  Widget? extraAction,
  ProviderContainer? container,
  bool useScroll = true,
  bool cancelRow = false,
  bool? isMobileOverride,
}) {
  final sourceContext = context;
  final targetContext = presentationContext ?? context;
  final isMobile =
      isMobileOverride ?? DeviceTypeUtil.isMobile(sourceContext);

  if (!isMobile) {
    final overlay =
        Navigator.maybeOf(targetContext, rootNavigator: true)?.overlay ??
            Overlay.maybeOf(targetContext, rootOverlay: true);

    if (overlay == null) {
      return _showGenericAiBottomSheet(
        context: targetContext,
        theme: theme,
        child: child,
        title: title,
        headerTag: headerTag,
        onSave: onSave,
        saveLabel: saveLabel,
        extraAction: extraAction,
        useScroll: useScroll,
        container: container,
        cancelRow: cancelRow,
      );
    }

    final completer = Completer<T?>();
    late OverlayEntry entry;

    void close([T? result]) {
      entry.remove();
      EmmaOverlayManager.onOverlayClosed();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    entry = OverlayEntry(
      builder: (ctx) {
        final content = _DesktopFloatingAiBubble(
          theme: theme,
          cancelRow: cancelRow,
          title: title,
          headerTag: headerTag,
          child: child,
          onSave: onSave == null
              ? null
              : () {
                  onSave();
                  close();
                },
          saveLabel: saveLabel,
          extraAction: extraAction,
          useScroll: useScroll,
          onClose: () => close(),
        );

        final wrappedContent = container == null
            ? content
            : UncontrolledProviderScope(
                container: container,
                child: content,
              );

        return GenericAiOverlayScope(
          closeOverlay: () => close(),
          child: wrappedContent,
        );
      },
    );

    EmmaOverlayManager.registerOverlay(close);
    overlay.insert(entry);
    return completer.future;
  }

  return _showGenericAiBottomSheet(
    context: targetContext,
    theme: theme,
    child: child,
    title: title,
    headerTag: headerTag,
    onSave: onSave,
    saveLabel: saveLabel,
    extraAction: extraAction,
    useScroll: useScroll,
    container: container,
    cancelRow: cancelRow,
  );
}

Future<T?> _showGenericAiBottomSheet<T>({
  required BuildContext context,
  required ThemeColors theme,
  required Widget child,
  required String title,
  String? headerTag,
  VoidCallback? onSave,
  String? saveLabel,
  Widget? extraAction,
  bool useScroll = true,
  ProviderContainer? container,
  bool cancelRow = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: theme.dashboardContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final content = _GenericSheetContent(
        theme: theme,
        title: title,
        headerTag: headerTag,
        onSave: onSave,
        saveLabel: saveLabel,
        extraAction: extraAction,
        child: child,
        useScroll: useScroll,
        cancelRow: cancelRow,
      );

      final wrappedContent = container == null
          ? content
          : UncontrolledProviderScope(
              container: container,
              child: content,
            );

      return GenericAiOverlayScope(
        closeOverlay: () => Navigator.of(ctx, rootNavigator: true).pop(),
        child: wrappedContent,
      );
    },
  );
}

class _GenericSheetContent extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String? headerTag;
  final Widget child;
  final VoidCallback? onSave;
  final String? saveLabel;
  final Widget? extraAction;
  final bool useScroll;
  final bool cancelRow;

  const _GenericSheetContent({
    required this.theme,
    required this.title,
    required this.child,
    this.headerTag,
    this.onSave,
    this.saveLabel,
    this.extraAction,
    this.useScroll = true,
    this.cancelRow = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 16;

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (headerTag != null) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: theme.themeColor,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: Text(
                    headerTag!,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (extraAction != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: extraAction,
            ),
          ],
          const SizedBox(height: 16),
          Flexible(
            child: NotificationListener<OverscrollNotification>(
              onNotification: (notification) {
                if (notification.dragDetails != null &&
                    notification.overscroll < 0) {
                  Navigator.of(context).maybePop();
                  return true;
                }
                return false;
              },
              child: useScroll
                  ? SingleChildScrollView(child: child)
                  : child,
            ),
          ),
          const SizedBox(height: 24),
          if (cancelRow)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: elevatedButtonStyleRounded10,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'cancel'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
                if (onSave != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: buttonStyleRounded10ThemeRedWithPadding15,
                    onPressed: onSave,
                    icon:
                        const Icon(Icons.check_rounded, color: AppColors.white),
                    label: Text(
                      saveLabel ?? 'save'.tr,
                      style: const TextStyle(color: AppColors.white),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _DesktopFloatingAiBubble extends StatefulWidget {
  final ThemeColors theme;
  final String title;
  final String? headerTag;
  final Widget child;
  final VoidCallback? onSave;
  final String? saveLabel;
  final Widget? extraAction;
  final bool useScroll;
  final VoidCallback onClose;
  final bool cancelRow;

  const _DesktopFloatingAiBubble({
    required this.theme,
    required this.title,
    required this.child,
    required this.onClose,
    this.headerTag,
    this.onSave,
    this.saveLabel,
    this.extraAction,
    this.useScroll = true,
    this.cancelRow = false,
  });

  @override
  State<_DesktopFloatingAiBubble> createState() =>
      _DesktopFloatingAiBubbleState();
}

class _DesktopFloatingAiBubbleState extends State<_DesktopFloatingAiBubble> {
  Offset _offset = Offset.zero;
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final size = MediaQuery.of(context).size;
    final maxHeight = size.height * 0.7;

    if (_minimized) {
      return Align(
        alignment: Alignment.bottomRight,
        child: Transform.translate(
          offset: _offset,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, right: 16),
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _offset += details.delta;
                });
              },
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _minimized = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.dashboardBoarder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(64),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 18, color: theme.themeColor),
                        const SizedBox(width: 8),
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.expand_less_rounded,
                            size: 18,
                            color: theme.textColor.withAlpha(204)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomRight,
      child: Transform.translate(
        offset: _offset,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16, right: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: maxHeight,
              minWidth: 360,
            ),
            child: Material(
              color: theme.adPopBackground,
              elevation: 14,
              borderRadius: BorderRadius.circular(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _offset += details.delta;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.dashboardContainer,
                          border: Border(
                            bottom: BorderSide(color: theme.dashboardBoarder),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.smart_toy_rounded,
                              color: theme.themeColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.headerTag != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: theme.themeColor,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Text(
                                  widget.headerTag!,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            IconButton(
                              tooltip: 'minimize'.tr,
                              icon: Icon(
                                Icons.remove_rounded,
                                size: 18,
                                color: theme.textColor.withAlpha(204),
                              ),
                              onPressed: () {
                                setState(() {
                                  _minimized = true;
                                });
                              },
                            ),
                            IconButton(
                              tooltip: 'close'.tr,
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: theme.textColor.withAlpha(204),
                              ),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.extraAction != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 12, right: 12, top: 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: widget.extraAction,
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: widget.useScroll
                            ? SingleChildScrollView(child: widget.child)
                            : widget.child,
                      ),
                    ),
                    if (widget.cancelRow)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              style: elevatedButtonStyleRounded10,
                              onPressed: widget.onClose,
                              child: Text(
                                'cancel'.tr,
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                            if (widget.onSave != null) ...[
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: buttonStyleRounded10ThemeRedWithPadding15,
                                onPressed: widget.onSave,
                                icon: const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.white,
                                ),
                                label: Text(
                                  widget.saveLabel ?? 'save'.tr,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}