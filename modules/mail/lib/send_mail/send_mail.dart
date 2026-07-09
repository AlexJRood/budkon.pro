import 'dart:ui' as ui;

import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:mail/components/email_address_section.dart';
import 'package:mail/emma/anchors/anchors_mail.dart';
import 'package:mail/provider/email_compose_provider.dart';
import 'package:mail/utils/api_services.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:mail/settings/settings_mail_pc.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/ui/device_type_util.dart';

final emailOverlayPositionProvider =
    StateProvider.family<Offset?, String>((ref, id) => null);

final emailOverlaySizeProvider =
    StateProvider.family<Size?, String>((ref, id) => null);

final emailOverlayUserMovedProvider =
    StateProvider.family<bool, String>((ref, id) => false);

final emailOverlayDidAutoSnapProvider =
    StateProvider.family<bool, String>((ref, id) => false);

/// Position of the minimized mobile "bubble" (chat-head). Kept separate from
/// [emailOverlayPositionProvider] which drives the desktop floating window.
final emailOverlayBubblePositionProvider =
    StateProvider.family<Offset?, String>((ref, id) => null);

void _disposeEmailOverlayState(WidgetRef ref, String id) {
  ref.invalidate(emailComposeProvider(id));
  ref.invalidate(emailOverlayExpandedProvider(id));
  ref.invalidate(emailOverlayPositionProvider(id));
  ref.invalidate(emailOverlaySizeProvider(id));
  ref.invalidate(emailOverlayUserMovedProvider(id));
  ref.invalidate(emailOverlayDidAutoSnapProvider(id));
  ref.invalidate(emailOverlayBubblePositionProvider(id));
}

void showEmailOverlay(
  BuildContext context,
  WidgetRef ref, {
  int? leadId,
  dynamic lead,
  String? overlayId,
  String? initialSubject,
  String? initialBody,
  List<String>? initialEmails,
  List<String>? initialCC,
  List<String>? initialBCC,
  int? initialEmailAccountId,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final overlayState = navigator.overlay;
  final rootContext = navigator.context;

  if (overlayState == null) return;

  final id = overlayId ?? UniqueKey().toString();

  late final OverlayEntry entry;
  bool removed = false;

  void closeOverlay(WidgetRef refToUse) {
    if (removed) return;
    removed = true;

    entry.remove();

    Future.microtask(() {
      _disposeEmailOverlayState(refToUse, id);
    });
  }

  double safeClamp({
    required double value,
    required double min,
    required double max,
  }) {
    if (max < min) return min;
    return value.clamp(min, max).toDouble();
  }

  entry = OverlayEntry(
    builder: (overlayContext) {
      return Consumer(
        builder: (context, ref2, __) {
          final media =
              MediaQuery.maybeOf(context) ?? MediaQuery.of(rootContext);

          final screen = media.size;
          final isMobile = screen.width < 800;
          final expanded = ref2.watch(emailOverlayExpandedProvider(id));

          final topMargin = isMobile
              ? media.padding.top + 8
              : TopAppBarSize.resolve(rootContext) + 8;

          final bottomMargin = isMobile
              ? BottomBarSize.resolve(rootContext) + media.padding.bottom + 10
              : 20.0;

          final rightMargin = isMobile ? 8.0 : 82.0;
          const leftMargin = 8.0;

          if (isMobile) {
            final compose = ref2.watch(emailComposeProvider(id));
            final theme = ref2.watch(themeColorsProvider);

            // Minimized -> draggable round bubble (chat-head). Tap reopens the
            // drawer; the draft is preserved (compose state is not disposed).
            if (compose.isCollapsed) {
              const bubbleSize = 60.0;
              final defaultBubblePos = Offset(
                screen.width - bubbleSize - 16,
                screen.height - bubbleSize - bottomMargin,
              );
              final rawBubble =
                  ref2.watch(emailOverlayBubblePositionProvider(id)) ??
                      defaultBubblePos;
              final bubblePos = Offset(
                safeClamp(
                  value: rawBubble.dx,
                  min: 8,
                  max: screen.width - bubbleSize - 8,
                ),
                safeClamp(
                  value: rawBubble.dy,
                  min: topMargin,
                  max: screen.height - bubbleSize - 8,
                ),
              );

              return Positioned(
                left: bubblePos.dx,
                top: bubblePos.dy,
                child: _ComposeBubble(
                  size: bubbleSize,
                  theme: theme,
                  onTap: () => ref2
                      .read(emailComposeProvider(id).notifier)
                      .toggleCollapse(),
                  onDragDelta: (delta) {
                    final current =
                        ref2.read(emailOverlayBubblePositionProvider(id)) ??
                            bubblePos;
                    ref2
                        .read(emailOverlayBubblePositionProvider(id).notifier)
                        .state = current + delta;
                  },
                ),
              );
            }

            // Expanded -> full-width drawer hugging the bottom (like the filter
            // sheet), lifting above the keyboard when it is open.
            final keyboard = media.viewInsets.bottom;
            final maxHeight = (screen.height - topMargin - keyboard).clamp(
              260.0,
              screen.height,
            );

            return Positioned(
              left: 0,
              right: 0,
              bottom: keyboard,
              child: Material(
                type: MaterialType.transparency,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight.toDouble()),
                  child: EmailSendOverlay(
                    overlayId: id,
                    leadId: leadId,
                    rootContext: rootContext,
                    lead: lead,
                    initialSubject: initialSubject,
                    initialBody: initialBody,
                    initialEmails: initialEmails,
                    initialCC: initialCC,
                    initialBCC: initialBCC,
                    initialEmailAccountId: initialEmailAccountId,
                    onClose: () => closeOverlay(ref2),
                    isExpanded: false,
                    onToggleExpand: null,
                    isMobileView: true,
                  ),
                ),
              ),
            );
          }

          if (expanded) {
            final maxExpandedWidth = screen.width - 32;
            final maxExpandedHeight = screen.height - topMargin - 24;

            final width = maxExpandedWidth < 360
                ? maxExpandedWidth
                : (screen.width * 0.78)
                    .clamp(360.0, maxExpandedWidth)
                    .toDouble();

            final height = maxExpandedHeight < 360
                ? maxExpandedHeight
                : (screen.height * 0.86)
                    .clamp(360.0, maxExpandedHeight)
                    .toDouble();

            return Positioned.fill(
              child: Material(
                color: Colors.black.withAlpha(140),
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          ref2
                              .read(emailOverlayExpandedProvider(id).notifier)
                              .state = false;
                        },
                        child: const SizedBox(),
                      ),
                    ),
                    Positioned(
                      top: topMargin,
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Center(
                        child: Material(
                          type: MaterialType.transparency,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.transparent,
                          child: SizedBox(
                            width: width,
                            height: height,
                            child: EmailSendOverlay(
                              overlayId: id,
                              leadId: leadId,
                              rootContext: rootContext,
                              lead: lead,
                              initialSubject: initialSubject,
                              initialBody: initialBody,
                              initialEmails: initialEmails,
                              initialCC: initialCC,
                              initialBCC: initialBCC,
                              initialEmailAccountId: initialEmailAccountId,
                              onClose: () => closeOverlay(ref2),
                              isExpanded: true,
                              onToggleExpand: () {
                                ref2
                                    .read(
                                      emailOverlayExpandedProvider(id).notifier,
                                    )
                                    .state = false;
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final compose = ref2.watch(emailComposeProvider(id));
          final tiny = compose.isCollapsed;

          final overlayWidth = tiny ? 350.0 : 650.0;

          Size currentSize() {
            final measured = ref2.watch(emailOverlaySizeProvider(id));
            if (measured != null) return measured;

            return Size(overlayWidth, tiny ? 72.0 : 700.0);
          }

          Offset bottomRightPos() {
            final size = currentSize();

            final left = safeClamp(
              value: screen.width - size.width - rightMargin,
              min: leftMargin,
              max: screen.width - size.width - leftMargin,
            );

            final top = safeClamp(
              value: screen.height - size.height - bottomMargin,
              min: topMargin,
              max: screen.height - size.height - bottomMargin,
            );

            return Offset(left, top);
          }

          Offset clampPos(Offset next) {
            final size = currentSize();

            final minLeft = leftMargin;
            final maxLeft = screen.width - size.width - rightMargin;

            final minTop = topMargin;
            final maxTop = screen.height - size.height - bottomMargin;

            return Offset(
              safeClamp(value: next.dx, min: minLeft, max: maxLeft),
              safeClamp(value: next.dy, min: minTop, max: maxTop),
            );
          }

          final stored = ref2.watch(emailOverlayPositionProvider(id));

          if (stored == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (removed) return;

              ref2.read(emailOverlayPositionProvider(id).notifier).state =
                  bottomRightPos();
            });
          }

          final didSnap = ref2.watch(emailOverlayDidAutoSnapProvider(id));
          final userMoved = ref2.watch(emailOverlayUserMovedProvider(id));
          final measuredSize = ref2.watch(emailOverlaySizeProvider(id));

          if (!didSnap && !userMoved && measuredSize != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (removed) return;

              final movedNow = ref2.read(emailOverlayUserMovedProvider(id));
              final snappedNow = ref2.read(emailOverlayDidAutoSnapProvider(id));

              if (snappedNow || movedNow) return;

              ref2.read(emailOverlayPositionProvider(id).notifier).state =
                  bottomRightPos();

              ref2.read(emailOverlayDidAutoSnapProvider(id).notifier).state =
                  true;
            });
          }

          final rawPos = stored ?? bottomRightPos();
          final pos = clampPos(rawPos);

          if (stored != null && stored != pos) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (removed) return;

              ref2.read(emailOverlayPositionProvider(id).notifier).state = pos;
            });
          }

          final maxWidth =
              (screen.width - rightMargin - leftMargin).clamp(320.0, 900.0);

          return Positioned(
            left: pos.dx,
            top: pos.dy,
            child: Opacity(
              opacity: didSnap ? 1.0 : 0.0,
              child: Material(
                type: MaterialType.transparency,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth.toDouble(),
                    maxHeight: (screen.height - pos.dy - bottomMargin)
                        .clamp(0.0, double.infinity)
                        .toDouble(),
                  ),
                  child: EmailSendOverlay(
                    overlayId: id,
                    leadId: leadId,
                    rootContext: rootContext,
                    lead: lead,
                    initialSubject: initialSubject,
                    initialBody: initialBody,
                    initialEmails: initialEmails,
                    initialCC: initialCC,
                    initialBCC: initialBCC,
                    initialEmailAccountId: initialEmailAccountId,
                    onClose: () => closeOverlay(ref2),
                    isExpanded: false,
                    onDragDelta: (delta) {
                      ref2
                          .read(emailOverlayUserMovedProvider(id).notifier)
                          .state = true;

                      final current =
                          ref2.read(emailOverlayPositionProvider(id)) ?? pos;

                      final next = clampPos(current + delta);

                      ref2
                          .read(emailOverlayPositionProvider(id).notifier)
                          .state = next;
                    },
                    onToggleExpand: () {
                      ref2
                          .read(emailOverlayExpandedProvider(id).notifier)
                          .state = true;
                    },
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  overlayState.insert(entry);
}

class EmailSendOverlay extends ConsumerStatefulWidget {
  final String overlayId;

  final int? leadId;
  final dynamic lead;
  final String? initialSubject;
  final String? initialBody;
  final List<String>? initialEmails;
  final List<String>? initialCC;
  final List<String>? initialBCC;
  final VoidCallback? onClose;
  final ScrollController? scrollController;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final BuildContext rootContext;
  final int? initialEmailAccountId;
  final ValueChanged<Offset>? onDragDelta;
  final bool isMobileView;

  const EmailSendOverlay({
    super.key,
    required this.overlayId,
    this.leadId,
    this.lead,
    this.initialSubject,
    this.initialBody,
    this.initialEmails,
    this.initialCC,
    this.initialBCC,
    this.onClose,
    this.scrollController,
    this.isExpanded = false,
    this.onToggleExpand,
    required this.rootContext,
    this.initialEmailAccountId,
    this.onDragDelta,
    this.isMobileView = false,
  });

  @override
  ConsumerState<EmailSendOverlay> createState() => _EmailSendOverlayState();
}

class _EmailSendOverlayState extends ConsumerState<EmailSendOverlay>
    with TickerProviderStateMixin {
  final LayerLink sendMenuLink = LayerLink();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _boxKey = GlobalKey();

  late final FocusNode _subjectFocusNode;
  late final FocusNode _bodyFocusNode;

  @override
  void initState() {
    super.initState();

    _subjectFocusNode = FocusNode();
    _bodyFocusNode = FocusNode();

    _subjectFocusNode.addListener(() {
      if (_subjectFocusNode.hasFocus) {
        _ensureVisibleForContext(_subjectFocusNode.context);
      }
    });

    _bodyFocusNode.addListener(() {
      if (_bodyFocusNode.hasFocus) {
        _ensureVisibleForContext(_bodyFocusNode.context);
      }
    });

    final composeNotifier =
        ref.read(emailComposeProvider(widget.overlayId).notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      composeNotifier.initialize(
        lead: widget.lead,
        initialSubject: widget.initialSubject,
        initialBody: widget.initialBody,
        initialEmails: widget.initialEmails,
        initialCC: widget.initialCC,
        initialBCC: widget.initialBCC,
        initialEmailAccountId: widget.initialEmailAccountId,
      );
    });
  }

  void _ensureVisibleForContext(BuildContext? targetContext) {
    if (targetContext == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.15,
      );
    });
  }

  void _reportSizeIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final ctx = _boxKey.currentContext;
      if (ctx == null) return;

      final size = ctx.size;
      if (size == null) return;

      final prev = ref.read(emailOverlaySizeProvider(widget.overlayId));

      if (prev == null ||
          prev.width != size.width ||
          prev.height != size.height) {
        ref.read(emailOverlaySizeProvider(widget.overlayId).notifier).state =
            size;
      }
    });
  }

  void _toggleCollapseAnchored(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final isMobile = screenSize.width < 800;

    final topMargin =
        isMobile ? media.padding.top + 8 : TopAppBarSize.resolve(context) + 8;

    final bottomMargin = isMobile
        ? BottomBarSize.resolve(context) + media.padding.bottom + 10
        : 20.0;

    final rightMargin = isMobile ? 8.0 : 82.0;
    const leftMargin = 8.0;

    double safeClamp({
      required double value,
      required double min,
      required double max,
    }) {
      if (max < min) return min;
      return value.clamp(min, max).toDouble();
    }

    final compose = ref.read(emailComposeProvider(widget.overlayId));
    final wasCollapsed = compose.isCollapsed;

    final beforePos = ref.read(emailOverlayPositionProvider(widget.overlayId));

    if (beforePos == null) {
      ref
          .read(emailComposeProvider(widget.overlayId).notifier)
          .toggleCollapse();
      return;
    }

    const collapsedWidth = 350.0;
    const collapsedHeight = 72.0;

    final expandedWidth =
        screenSize.width > 700 ? 650.0 : screenSize.width - 16;
    final expandedHeight =
        screenSize.height > 716 ? 700.0 : screenSize.height - 16;

    final beforeSize = Size(
      wasCollapsed ? collapsedWidth : expandedWidth,
      wasCollapsed ? collapsedHeight : expandedHeight,
    );

    final afterSize = Size(
      wasCollapsed ? expandedWidth : collapsedWidth,
      wasCollapsed ? expandedHeight : collapsedHeight,
    );

    double newLeft;
    double newTop;

    if (wasCollapsed) {
      newLeft = beforePos.dx + beforeSize.width - afterSize.width;
      newTop = beforePos.dy + beforeSize.height - afterSize.height;
    } else {
      // Smart corner anchoring: collapse to the nearest screen corner
      final formCenterX = beforePos.dx + beforeSize.width / 2;
      final formCenterY = beforePos.dy + beforeSize.height / 2;

      newLeft = formCenterX < screenSize.width / 2
          ? leftMargin
          : screenSize.width - afterSize.width - rightMargin;

      newTop = formCenterY < screenSize.height / 2
          ? topMargin
          : screenSize.height - afterSize.height - bottomMargin;
    }

    newLeft = safeClamp(
      value: newLeft,
      min: leftMargin,
      max: screenSize.width - afterSize.width - rightMargin,
    );

    newTop = safeClamp(
      value: newTop,
      min: topMargin,
      max: screenSize.height - afterSize.height - bottomMargin,
    );

    // Reset stale measured size so clampPos in showEmailOverlay uses correct
    // bounds for the new form dimensions immediately, not the old ones.
    ref.read(emailOverlaySizeProvider(widget.overlayId).notifier).state =
        afterSize;

    ref.read(emailOverlayPositionProvider(widget.overlayId).notifier).state =
        Offset(newLeft, newTop);

    ref.read(emailComposeProvider(widget.overlayId).notifier).toggleCollapse();
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];

    double value = bytes.toDouble();
    int index = 0;

    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }

    return '${value.toStringAsFixed(index == 0 ? 0 : 1)} ${units[index]}';
  }

  @override
  void dispose() {
    _subjectFocusNode.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    final composeNotifier =
        ref.read(emailComposeProvider(widget.overlayId).notifier);
    final compose = ref.watch(emailComposeProvider(widget.overlayId));

    final bool tiny = !widget.isExpanded && !isMobile && compose.isCollapsed;
    final double overlayWidth = compose.isCollapsed ? 350 : 650;

    final selectedEmailAccountId = ref.watch(selectedEmailAccountIdProvider);
    final emailAccountsAsync = ref.watch(emailAccountListProvider);

    _reportSizeIfNeeded();

    Widget animatedChild(Widget child) {
      return AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: child,
      );
    }

    return EmmaUiAnchorTarget(
      anchorKey: EmmaAnchors.mailComposeOverlayRoot.anchorKey,
      spec: EmmaAnchors.mailComposeOverlayRoot,
      runtimeMode: EmmaAnchors.mailComposeOverlayRoot.runtimeMode,
      tapMode: EmmaAnchors.mailComposeOverlayRoot.tapMode,
      child: PointerInterceptor(
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Form(
            key: _formKey,
            child: Align(
              alignment:
                  widget.isExpanded ? Alignment.center : Alignment.topLeft,
              widthFactor: widget.isExpanded ? null : 1.0,
              heightFactor: widget.isExpanded ? null : 1.0,
              child: Material(
                type: MaterialType.transparency,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: isMobile
                      ? const BorderRadius.vertical(top: Radius.circular(16))
                      : BorderRadius.circular(6),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: animatedChild(
                      Container(
                        key: _boxKey,
                        width: isMobile
                            ? screenWidth
                            : widget.isExpanded
                                ? screenWidth * 0.78
                                : overlayWidth,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          // On mobile match the filters drawer: solid background,
                          // rounded top only.
                          color: isMobile
                              ? theme.dashboardContainer
                              : theme.dashboardContainer.withAlpha(75),
                          border: Border.all(
                            color: theme.dashboardBoarder,
                            width: isMobile ? 1.2 : 1.5,
                          ),
                          borderRadius: isMobile
                              ? const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                )
                              : BorderRadius.circular(6),
                        ),
                        child: tiny
                            ? _CollapsedHeaderOnly(
                                theme: theme,
                                compose: compose,
                                isExpanded: widget.isExpanded,
                                isMobile: isMobile,
                                onToggleCollapse: () {
                                  _toggleCollapseAnchored(context);
                                },
                                onToggleExpand: widget.onToggleExpand,
                                onClose: widget.onClose,
                                onDragDelta: widget.onDragDelta,
                              )
                            : ConstrainedBox(
                                constraints: widget.isExpanded
                                    ? const BoxConstraints()
                                    : BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                                0.75,
                                      ),
                                child: ScrollConfiguration(
                                  behavior:
                                      ScrollConfiguration.of(context).copyWith(
                                    dragDevices: {
                                      ui.PointerDeviceKind.touch,
                                      ui.PointerDeviceKind.stylus
                                    },
                                  ),
                                  child: SingleChildScrollView(
                                    controller: widget.scrollController,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        EmmaUiAnchorTarget(
                                          anchorKey: EmmaAnchors
                                              .mailComposeHeader.anchorKey,
                                          spec: EmmaAnchors.mailComposeHeader,
                                          runtimeMode: EmmaAnchors
                                              .mailComposeHeader.runtimeMode,
                                          tapMode: EmmaAnchors
                                              .mailComposeHeader.tapMode,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onPanUpdate: (details) =>
                                                widget.onDragDelta?.call(
                                              details.delta,
                                            ),
                                            onTap: widget.isExpanded || isMobile
                                                ? null
                                                : () {
                                                    _toggleCollapseAnchored(
                                                        context);
                                                  },
                                            child: MouseRegion(
                                              cursor: widget.onDragDelta != null
                                                  ? SystemMouseCursors.grab
                                                  : SystemMouseCursors.click,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  color: theme
                                                      .dashboardContainer
                                                      .withAlpha(50),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      compose.isCollapsed
                                                          ? Icons.expand_less
                                                          : Icons.expand_more,
                                                      color: theme.textColor,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        compose.isCollapsed &&
                                                                (compose.lastSubject
                                                                        ?.isNotEmpty ==
                                                                    true)
                                                            ? compose
                                                                .lastSubject!
                                                            : 'new_message'.tr,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color:
                                                              theme.textColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (widget
                                                                .onToggleExpand !=
                                                            null) ...[
                                                          IconButton(
                                                            icon: Icon(
                                                              widget.isExpanded
                                                                  ? Icons
                                                                      .close_fullscreen
                                                                  : Icons
                                                                      .open_in_full,
                                                              color: theme
                                                                  .textColor,
                                                            ),
                                                            onPressed: widget
                                                                .onToggleExpand,
                                                            padding:
                                                                EdgeInsets.zero,
                                                            constraints:
                                                                const BoxConstraints(
                                                              minWidth: 36,
                                                              minHeight: 36,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 6),
                                                        ],
                                                        if (isMobile) ...[
                                                          IconButton(
                                                            icon: Icon(
                                                              Icons.remove,
                                                              color: theme
                                                                  .textColor,
                                                            ),
                                                            tooltip:
                                                                'minimize'.tr,
                                                            onPressed: () =>
                                                                composeNotifier
                                                                    .toggleCollapse(),
                                                            padding:
                                                                EdgeInsets.zero,
                                                            constraints:
                                                                const BoxConstraints(
                                                              minWidth: 36,
                                                              minHeight: 36,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 6),
                                                        ],
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.close,
                                                            color:
                                                                theme.textColor,
                                                          ),
                                                          onPressed: () =>
                                                              widget.onClose
                                                                  ?.call(),
                                                          padding:
                                                              EdgeInsets.zero,
                                                          constraints:
                                                              const BoxConstraints(
                                                            minWidth: 36,
                                                            minHeight: 36,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (!compose.isCollapsed) ...[
                                          const SizedBox(height: 12),
                                          EmmaUiAnchorTarget(
                                            anchorKey: EmmaAnchors
                                                .mailComposeToSection.anchorKey,
                                            spec: EmmaAnchors
                                                .mailComposeToSection,
                                            runtimeMode: EmmaAnchors
                                                .mailComposeToSection
                                                .runtimeMode,
                                            tapMode: EmmaAnchors
                                                .mailComposeToSection.tapMode,
                                            child: EmailAddressSection(
                                              label: 'to_label'.tr,
                                              controllers:
                                                  composeNotifier.toControllers,
                                              theme: theme,
                                              isRequired: true,
                                              onAdd: () =>
                                                  composeNotifier.addEmailField(
                                                composeNotifier.toControllers,
                                              ),
                                              onRemove: (i) => composeNotifier
                                                  .removeEmailField(
                                                composeNotifier.toControllers,
                                                i,
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (!compose.showCC)
                                                    TextButton(
                                                      onPressed: composeNotifier
                                                          .showCc,
                                                      style:
                                                          TextButton.styleFrom(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        minimumSize:
                                                            const Size(0, 0),
                                                        tapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                      ),
                                                      child: Text(
                                                        'cc_label'.tr,
                                                        style: TextStyle(
                                                          color: theme.textColor
                                                              .withAlpha(170),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  if (!compose.showBCC)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        left: 10,
                                                      ),
                                                      child: TextButton(
                                                        onPressed:
                                                            composeNotifier
                                                                .showBcc,
                                                        style: TextButton
                                                            .styleFrom(
                                                          padding:
                                                              EdgeInsets.zero,
                                                          minimumSize:
                                                              const Size(0, 0),
                                                          tapTargetSize:
                                                              MaterialTapTargetSize
                                                                  .shrinkWrap,
                                                        ),
                                                        child: Text(
                                                          'bcc_label'.tr,
                                                          style: TextStyle(
                                                            color: theme
                                                                .textColor
                                                                .withAlpha(170),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (compose.showCC) ...[
                                            const SizedBox(height: 12),
                                            EmailAddressSection(
                                              label: 'cc_label'.tr,
                                              controllers:
                                                  composeNotifier.ccControllers,
                                              theme: theme,
                                              isRequired: false,
                                              onAdd: () =>
                                                  composeNotifier.addEmailField(
                                                composeNotifier.ccControllers,
                                              ),
                                              onRemove: (i) => composeNotifier
                                                  .removeEmailField(
                                                composeNotifier.ccControllers,
                                                i,
                                              ),
                                              trailing: IconButton(
                                                icon: Icon(
                                                  Icons.close,
                                                  color: theme.textColor
                                                      .withAlpha(170),
                                                  size: 18,
                                                ),
                                                onPressed: () =>
                                                    composeNotifier.removeCc(
                                                  context,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 36,
                                                  minHeight: 36,
                                                ),
                                                tooltip: 'remove_cc_tooltip'.tr,
                                              ),
                                            ),
                                          ],
                                          if (compose.showBCC) ...[
                                            const SizedBox(height: 12),
                                            EmailAddressSection(
                                              label: 'bcc_label'.tr,
                                              controllers: composeNotifier
                                                  .bccControllers,
                                              theme: theme,
                                              isRequired: false,
                                              onAdd: () =>
                                                  composeNotifier.addEmailField(
                                                composeNotifier.bccControllers,
                                              ),
                                              onRemove: (i) => composeNotifier
                                                  .removeEmailField(
                                                composeNotifier.bccControllers,
                                                i,
                                              ),
                                              trailing: IconButton(
                                                icon: Icon(
                                                  Icons.close,
                                                  color: theme.textColor
                                                      .withAlpha(170),
                                                  size: 18,
                                                ),
                                                onPressed: () =>
                                                    composeNotifier.removeBcc(
                                                  context,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 36,
                                                  minHeight: 36,
                                                ),
                                                tooltip:
                                                    'remove_bcc_tooltip'.tr,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 16),
                                          EmmaUiAnchorTarget(
                                            anchorKey: EmmaAnchors
                                                .mailComposeSubjectInput
                                                .anchorKey,
                                            spec: EmmaAnchors
                                                .mailComposeSubjectInput,
                                            runtimeMode: EmmaAnchors
                                                .mailComposeSubjectInput
                                                .runtimeMode,
                                            tapMode: EmmaAnchors
                                                .mailComposeSubjectInput
                                                .tapMode,
                                            child: TextFormField(
                                              controller: composeNotifier
                                                  .subjectController,
                                              focusNode: _subjectFocusNode,
                                              style: TextStyle(
                                                  color: theme.textColor),
                                              textInputAction:
                                                  TextInputAction.next,
                                              onFieldSubmitted: (_) =>
                                                  _bodyFocusNode.requestFocus(),
                                              scrollPadding:
                                                  const EdgeInsets.only(
                                                left: 20,
                                                top: 20,
                                                right: 20,
                                                bottom: 120,
                                              ),
                                              onTap: () =>
                                                  _ensureVisibleForContext(
                                                _subjectFocusNode.context,
                                              ),
                                              validator: (value) {
                                                if ((value ?? '')
                                                    .trim()
                                                    .isEmpty) {
                                                  return 'subject_is_required'
                                                      .tr;
                                                }
                                                return null;
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'subject_label'.tr,
                                                labelStyle: TextStyle(
                                                  color: theme.textColor,
                                                ),
                                                floatingLabelStyle: TextStyle(
                                                  color: theme.textColor
                                                      .withAlpha(120),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                                hintText: 'subject_hint'.tr,
                                                hintStyle: TextStyle(
                                                  color: theme.textColor
                                                      .withAlpha(120),
                                                ),
                                                filled: true,
                                                fillColor:
                                                    theme.dashboardContainer,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                    color: theme.textColor
                                                        .withAlpha(120),
                                                  ),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                    color: theme.textColor
                                                        .withAlpha(120),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          EmmaUiAnchorTarget(
                                            anchorKey: EmmaAnchors
                                                .mailComposeBodyInput.anchorKey,
                                            spec: EmmaAnchors
                                                .mailComposeBodyInput,
                                            runtimeMode: EmmaAnchors
                                                .mailComposeBodyInput
                                                .runtimeMode,
                                            tapMode: EmmaAnchors
                                                .mailComposeBodyInput.tapMode,
                                            child: TextFormField(
                                              controller: composeNotifier
                                                  .bodyController,
                                              focusNode: _bodyFocusNode,
                                              maxLines: 14,
                                              style: TextStyle(
                                                  color: theme.textColor),
                                              scrollPadding:
                                                  const EdgeInsets.only(
                                                left: 20,
                                                top: 20,
                                                right: 20,
                                                bottom: 120,
                                              ),
                                              onTap: () =>
                                                  _ensureVisibleForContext(
                                                _bodyFocusNode.context,
                                              ),
                                              validator: (value) {
                                                if ((value ?? '')
                                                    .trim()
                                                    .isEmpty) {
                                                  return 'body_is_required'.tr;
                                                }
                                                return null;
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'body_label'.tr,
                                                labelStyle: TextStyle(
                                                  color: theme.textColor,
                                                ),
                                                floatingLabelStyle: TextStyle(
                                                  color: theme.textColor
                                                      .withAlpha(120),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                                hintText: 'body_hint'.tr,
                                                hintStyle: TextStyle(
                                                  color: theme.textColor
                                                      .withAlpha(120),
                                                ),
                                                filled: true,
                                                fillColor:
                                                    theme.dashboardContainer,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                    color: theme.textColor
                                                        .withAlpha(120),
                                                  ),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                    color: theme.textColor
                                                        .withAlpha(120),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              EmmaUiAnchorTarget(
                                                anchorKey: EmmaAnchors
                                                    .mailComposeAttachmentsButton
                                                    .anchorKey,
                                                spec: EmmaAnchors
                                                    .mailComposeAttachmentsButton,
                                                runtimeMode: EmmaAnchors
                                                    .mailComposeAttachmentsButton
                                                    .runtimeMode,
                                                tapMode: EmmaAnchors
                                                    .mailComposeAttachmentsButton
                                                    .tapMode,
                                                child: OutlinedButton.icon(
                                                  onPressed: compose
                                                              .isSending ||
                                                          compose
                                                              .isUploadingAttachments
                                                      ? null
                                                      : () => composeNotifier
                                                              .pickAndUploadAttachments(
                                                            context,
                                                          ),
                                                  icon: compose
                                                          .isUploadingAttachments
                                                      ? SizedBox(
                                                          width: 14,
                                                          height: 14,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                theme.textColor,
                                                          ),
                                                        )
                                                      : Icon(
                                                          Icons.attach_file,
                                                          color:
                                                              theme.textColor,
                                                        ),
                                                  label: Text(
                                                    compose.isUploadingAttachments
                                                        ? 'adding'.tr
                                                        : 'add_attachments'.tr,
                                                    style: TextStyle(
                                                      color: theme.textColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'attachment_info_text'.tr,
                                                  style: TextStyle(
                                                    color: theme.textColor
                                                        .withAlpha(170),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (compose
                                              .attachments.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: compose.attachments
                                                    .map((file) {
                                                  final isLink = file
                                                          .deliveryMode ==
                                                      ComposeAttachmentDeliveryMode
                                                          .link;

                                                  return Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: theme
                                                          .dashboardContainer,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                        color: theme
                                                            .dashboardBoarder,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          isLink
                                                              ? Icons
                                                                  .cloud_outlined
                                                              : Icons
                                                                  .attach_file,
                                                          size: 16,
                                                          color:
                                                              theme.textColor,
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        ConstrainedBox(
                                                          constraints:
                                                              const BoxConstraints(
                                                            maxWidth: 180,
                                                          ),
                                                          child: Text(
                                                            file.name,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: theme
                                                                  .textColor,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        if (file.sizeBytes > 0)
                                                          Text(
                                                            _formatSize(
                                                              file.sizeBytes,
                                                            ),
                                                            style: TextStyle(
                                                              color: theme
                                                                  .textColor
                                                                  .withAlpha(
                                                                      170),
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 6,
                                                            vertical: 3,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: isLink
                                                                ? Colors.orange
                                                                    .withAlpha(
                                                                        40)
                                                                : Colors.green
                                                                    .withAlpha(
                                                                        40),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        999),
                                                          ),
                                                          child: Text(
                                                            isLink
                                                                ? 'link_label'
                                                                    .tr
                                                                : 'attachment_label'
                                                                    .tr,
                                                            style: TextStyle(
                                                              color: theme
                                                                  .textColor,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 6),
                                                        IconButton(
                                                          visualDensity:
                                                              VisualDensity
                                                                  .compact,
                                                          padding:
                                                              EdgeInsets.zero,
                                                          constraints:
                                                              const BoxConstraints(
                                                            minWidth: 24,
                                                            minHeight: 24,
                                                          ),
                                                          icon: Icon(
                                                            Icons.close,
                                                            size: 16,
                                                            color: theme
                                                                .textColor
                                                                .withAlpha(180),
                                                          ),
                                                          onPressed: compose
                                                                  .isSending
                                                              ? null
                                                              : () =>
                                                                  composeNotifier
                                                                      .removeAttachment(
                                                                    file.fileId,
                                                                  ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(growable: false),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 16),
                                          if (widget.isMobileView) ...[
                                            emailAccountsAsync.when(
                                              data: (accounts) {
                                                return DropdownButtonFormField<
                                                    int>(
                                                  value: accounts.any(
                                                    (e) =>
                                                        e.id ==
                                                        selectedEmailAccountId,
                                                  )
                                                      ? selectedEmailAccountId
                                                      : null,
                                                  dropdownColor:
                                                      theme.dashboardContainer,
                                                  style: TextStyle(
                                                    color: theme.textColor,
                                                  ),
                                                  decoration: InputDecoration(
                                                    label: Text(
                                                      'send_from_label'.tr,
                                                      style: TextStyle(
                                                        color: theme.textColor,
                                                      ),
                                                    ),
                                                    labelStyle: TextStyle(
                                                      color: theme.textColor,
                                                    ),
                                                    filled: true,
                                                    fillColor: theme
                                                        .dashboardContainer,
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        10,
                                                      ),
                                                      borderSide: BorderSide(
                                                        color: theme.textColor
                                                            .withAlpha(120),
                                                      ),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        10,
                                                      ),
                                                      borderSide: BorderSide(
                                                        color: theme.textColor
                                                            .withAlpha(120),
                                                      ),
                                                    ),
                                                  ),
                                                  items: accounts
                                                      .map(
                                                        (account) =>
                                                            DropdownMenuItem<
                                                                int>(
                                                          value: account.id,
                                                          child: Text(
                                                            account.email,
                                                            style: TextStyle(
                                                              color: theme
                                                                  .textColor,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(growable: false),
                                                  onChanged: (value) {
                                                    ref
                                                        .read(
                                                          selectedEmailAccountIdProvider
                                                              .notifier,
                                                        )
                                                        .state = value;
                                                  },
                                                  validator: (value) {
                                                    if (value == null) {
                                                      return 'select_sender_account'
                                                          .tr;
                                                    }
                                                    return null;
                                                  },
                                                );
                                              },
                                              loading: () => Container(
                                                height: 52,
                                                alignment: Alignment.centerLeft,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      theme.dashboardContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: theme.textColor
                                                        .withAlpha(120),
                                                  ),
                                                ),
                                                child: SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: theme.textColor,
                                                  ),
                                                ),
                                              ),
                                              error: (_, __) => Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color:
                                                      theme.dashboardContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                                child: Text(
                                                  'failed_to_load_email_accounts'
                                                      .tr,
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                          SizedBox(
                                              height:
                                                  widget.isMobileView ? 16 : 0),
                                          Row(
                                            mainAxisAlignment: widget
                                                    .isMobileView
                                                ? MainAxisAlignment.spaceBetween
                                                : MainAxisAlignment.end,
                                            children: [
                                              EmmaUiAnchorTarget(
                                                anchorKey: EmmaAnchors
                                                    .mailComposeCancelButton
                                                    .anchorKey,
                                                spec: EmmaAnchors
                                                    .mailComposeCancelButton,
                                                runtimeMode: EmmaAnchors
                                                    .mailComposeCancelButton
                                                    .runtimeMode,
                                                tapMode: EmmaAnchors
                                                    .mailComposeCancelButton
                                                    .tapMode,
                                                child: ElevatedButton(
                                                  style:
                                                      elevatedButtonStyleRounded10
                                                          .copyWith(
                                                    backgroundColor:
                                                        WidgetStateProperty.all(
                                                      theme.dashboardContainer,
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      widget.onClose?.call(),
                                                  child: Container(
                                                    height: 40,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 25,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        'Cancel'.tr,
                                                        style: TextStyle(
                                                          color:
                                                              theme.textColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (!widget.isMobileView) ...[
                                                EmmaUiAnchorTarget(
                                                  anchorKey: EmmaAnchors
                                                      .mailComposeSenderDropdown
                                                      .anchorKey,
                                                  spec: EmmaAnchors
                                                      .mailComposeSenderDropdown,
                                                  runtimeMode: EmmaAnchors
                                                      .mailComposeSenderDropdown
                                                      .runtimeMode,
                                                  tapMode: EmmaAnchors
                                                      .mailComposeSenderDropdown
                                                      .tapMode,
                                                  child: Expanded(
                                                    child:
                                                        emailAccountsAsync.when(
                                                      data: (accounts) {
                                                        return DropdownButtonFormField<
                                                            int>(
                                                          value: accounts.any(
                                                            (e) =>
                                                                e.id ==
                                                                selectedEmailAccountId,
                                                          )
                                                              ? selectedEmailAccountId
                                                              : null,
                                                          dropdownColor: theme
                                                              .dashboardContainer,
                                                          style: TextStyle(
                                                            color:
                                                                theme.textColor,
                                                          ),
                                                          decoration:
                                                              InputDecoration(
                                                            labelText:
                                                                'send_from_label'
                                                                    .tr,
                                                            labelStyle:
                                                                TextStyle(
                                                              color: theme
                                                                  .textColor,
                                                            ),
                                                            filled: true,
                                                            fillColor: theme
                                                                .dashboardContainer,
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                10,
                                                              ),
                                                              borderSide:
                                                                  BorderSide(
                                                                color: theme
                                                                    .textColor
                                                                    .withAlpha(
                                                                        120),
                                                              ),
                                                            ),
                                                            focusedBorder:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                10,
                                                              ),
                                                              borderSide:
                                                                  BorderSide(
                                                                color: theme
                                                                    .textColor
                                                                    .withAlpha(
                                                                        120),
                                                              ),
                                                            ),
                                                          ),
                                                          items: accounts
                                                              .map(
                                                                (account) =>
                                                                    DropdownMenuItem<
                                                                        int>(
                                                                  value: account
                                                                      .id,
                                                                  child: Text(
                                                                    account
                                                                        .email,
                                                                    style:
                                                                        TextStyle(
                                                                      color: theme
                                                                          .textColor,
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(
                                                                  growable:
                                                                      false),
                                                          onChanged: (value) {
                                                            ref
                                                                .read(
                                                                  selectedEmailAccountIdProvider
                                                                      .notifier,
                                                                )
                                                                .state = value;
                                                          },
                                                          validator: (value) {
                                                            if (value == null) {
                                                              return 'select_sender_account'
                                                                  .tr;
                                                            }
                                                            return null;
                                                          },
                                                        );
                                                      },
                                                      loading: () => Container(
                                                        height: 52,
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 12,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: theme
                                                              .dashboardContainer,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          border: Border.all(
                                                            color: theme
                                                                .textColor
                                                                .withAlpha(120),
                                                          ),
                                                        ),
                                                        child: SizedBox(
                                                          height: 16,
                                                          width: 16,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                theme.textColor,
                                                          ),
                                                        ),
                                                      ),
                                                      error: (_, __) =>
                                                          Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: theme
                                                              .dashboardContainer,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          border: Border.all(
                                                            color: Colors
                                                                .redAccent,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'failed_to_load_email_accounts'
                                                              .tr,
                                                          style: TextStyle(
                                                            color: Colors
                                                                .redAccent,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(width: 8),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  EmmaUiAnchorTarget(
                                                    anchorKey: EmmaAnchors
                                                        .mailComposeSendButton
                                                        .anchorKey,
                                                    spec: EmmaAnchors
                                                        .mailComposeSendButton,
                                                    runtimeMode: EmmaAnchors
                                                        .mailComposeSendButton
                                                        .runtimeMode,
                                                    tapMode: EmmaAnchors
                                                        .mailComposeSendButton
                                                        .tapMode,
                                                    child: ElevatedButton(
                                                      style:
                                                          buttonStyleRounded10ThemeRed
                                                              .copyWith(
                                                        shape:
                                                            WidgetStateProperty
                                                                .all(
                                                          const RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .only(
                                                              topLeft: Radius
                                                                  .circular(10),
                                                              bottomLeft: Radius
                                                                  .circular(10),
                                                              topRight: Radius
                                                                  .circular(0),
                                                              bottomRight:
                                                                  Radius
                                                                      .circular(
                                                                          0),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      onPressed: compose
                                                                  .isSending ||
                                                              compose
                                                                  .isUploadingAttachments
                                                          ? null
                                                          : () async {
                                                              final ok = _formKey
                                                                      .currentState
                                                                      ?.validate() ??
                                                                  false;

                                                              if (!ok) return;

                                                              final sent =
                                                                  await composeNotifier
                                                                      .sendNow(
                                                                context: widget
                                                                    .rootContext,
                                                                leadId: widget
                                                                    .leadId,
                                                              );

                                                              if (!mounted)
                                                                return;

                                                              if (sent) {
                                                                widget.onClose
                                                                    ?.call();
                                                              }
                                                            },
                                                      child: Container(
                                                        height: 40,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 20,
                                                        ),
                                                        child: Center(
                                                          child: compose
                                                                  .isSending
                                                              ? const SizedBox(
                                                                  width: 16,
                                                                  height: 16,
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    valueColor:
                                                                        AlwaysStoppedAnimation<
                                                                            Color>(
                                                                      AppColors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                )
                                                              : Text(
                                                                  'send_button'
                                                                      .tr,
                                                                  style:
                                                                      TextStyle(
                                                                    color: AppColors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                  ),
                                                                ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  EmmaUiAnchorTarget(
                                                    anchorKey: EmmaAnchors
                                                        .mailComposeSendMenuButton
                                                        .anchorKey,
                                                    spec: EmmaAnchors
                                                        .mailComposeSendMenuButton,
                                                    runtimeMode: EmmaAnchors
                                                        .mailComposeSendMenuButton
                                                        .runtimeMode,
                                                    tapMode: EmmaAnchors
                                                        .mailComposeSendMenuButton
                                                        .tapMode,
                                                    child:
                                                        CompositedTransformTarget(
                                                      link: sendMenuLink,
                                                      child: Container(
                                                        height: 40,
                                                        width: 20,
                                                        margin: const EdgeInsets
                                                            .only(
                                                          left: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .only(
                                                            topRight:
                                                                Radius.circular(
                                                                    10),
                                                            bottomRight:
                                                                Radius.circular(
                                                                    10),
                                                          ),
                                                          color:
                                                              theme.themeColor,
                                                        ),
                                                        child: InkWell(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            10,
                                                          ),
                                                          onTap: compose
                                                                      .isSending ||
                                                                  compose
                                                                      .isUploadingAttachments
                                                              ? null
                                                              : () =>
                                                                  composeNotifier
                                                                      .toggleSendMenu(
                                                                    context: widget
                                                                        .rootContext,
                                                                    link:
                                                                        sendMenuLink,
                                                                    rootContext:
                                                                        widget
                                                                            .rootContext,
                                                                    onCloseComposer:
                                                                        widget
                                                                            .onClose,
                                                                    formKey:
                                                                        _formKey,
                                                                  ),
                                                          child: const Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimized mobile representation of the compose drawer: a small, draggable
/// round bubble (chat-head). Tapping it reopens the drawer.
class _ComposeBubble extends StatelessWidget {
  final double size;
  final ThemeColors theme;
  final VoidCallback onTap;
  final ValueChanged<Offset> onDragDelta;

  const _ComposeBubble({
    required this.size,
    required this.theme,
    required this.onTap,
    required this.onDragDelta,
  });

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onPanUpdate: (details) => onDragDelta(details.delta),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: theme.themeColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dashboardBoarder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.edit_outlined,
              color: theme.themeTextColor,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsedHeaderOnly extends StatelessWidget {
  final ThemeColors theme;
  final dynamic compose;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onClose;
  final VoidCallback onToggleCollapse;
  final bool isExpanded;
  final bool isMobile;
  final ValueChanged<Offset>? onDragDelta;

  const _CollapsedHeaderOnly({
    required this.theme,
    required this.compose,
    required this.onToggleExpand,
    required this.onClose,
    required this.onToggleCollapse,
    required this.isExpanded,
    required this.isMobile,
    this.onDragDelta,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => onDragDelta?.call(details.delta),
      onTap: isExpanded || isMobile ? null : onToggleCollapse,
      child: MouseRegion(
        cursor: onDragDelta != null
            ? SystemMouseCursors.grab
            : SystemMouseCursors.click,
        child: Row(
          children: [
            Icon(Icons.expand_less, color: theme.textColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                (compose.lastSubject?.isNotEmpty == true)
                    ? compose.lastSubject!
                    : 'new_message'.tr,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onToggleExpand != null) ...[
              IconButton(
                icon: Icon(Icons.open_in_full, color: theme.textColor),
                onPressed: onToggleExpand,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              const SizedBox(width: 6),
            ],
            IconButton(
              icon: Icon(Icons.close, color: theme.textColor),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
