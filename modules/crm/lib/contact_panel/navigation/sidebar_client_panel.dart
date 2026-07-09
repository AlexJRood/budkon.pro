import 'package:core/shell/manager/bar_manager.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

import 'enum.dart';

class SidebarClientAgentCrm extends ConsumerStatefulWidget {
  final Function(String) onTabSelected;
  final String activeSection;
  final ContactType contactType;

  const SidebarClientAgentCrm({
    super.key,
    required this.onTabSelected,
    required this.activeSection,
    this.contactType = ContactType.client,
  });

  @override
  ConsumerState<SidebarClientAgentCrm> createState() =>
      _SidebarClientAgentCrmState();
}

class _SidebarClientAgentCrmState
    extends ConsumerState<SidebarClientAgentCrm> {
  final GlobalKey _railKey = GlobalKey();

  String? _hoveredItemId;
  double? _hoveredLocalY;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final config = buildClientAgentCrmSidebarDockConfig(
      type: widget.contactType,
    );

    final centerItems =
        config.section(SidebarDockSectionPosition.center)?.items ?? const [];
    final bottomItems =
        config.section(SidebarDockSectionPosition.bottom)?.items ?? const [];

    final double overlayWidth = config.ui.expandedWidth > config.ui.railWidth
        ? config.ui.expandedWidth
        : config.ui.railWidth;

    return Padding(
      padding: const EdgeInsets.only(left: 15.0, right: 15, bottom: 15),
      child: SizedBox(
        key: _railKey,
        width: overlayWidth,
        height: MediaQuery.of(context).size.height - 75,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double railHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height;

            final bool isHovering = _hoveredItemId != null;
            final double targetStretchWidth =
                isHovering ? overlayWidth : config.ui.railWidth;
            final double targetCenterY =
                (_hoveredLocalY ?? (railHeight * 0.5)).clamp(0.0, railHeight);

            final double bottomTuck =
                ((config.ui.itemExtent - 44.0) / 2.0).clamp(0.0, 8.0);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: TweenAnimationBuilder<Offset>(
                      tween: Tween<Offset>(
                        end: Offset(targetStretchWidth, targetCenterY),
                      ),
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOutQuart,
                      builder: (context, animated, _) {
                        return SidebarDockStretchBackground(
                          side: config.side,
                          sidebarColor: theme.sidebar.withAlpha(125),
                          glowColor: theme.themeColor.withAlpha(
                            isHovering ? 24 : 10,
                          ),
                          shadowColor: Colors.black.withAlpha(
                            isHovering ? 18 : 8,
                            
                          ),
                          borderColor: theme.dashboardBoarder,
                          railWidth: config.ui.railWidth,
                          stretchWidth: animated.dx,
                          centerY: animated.dy,
                          stretchHeight: config.ui.stretchHeight,
                          blurEnabled: config.ui.blurBackground,
                        );
                      },
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: overlayWidth,
                      height: railHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildSection(
                                config: config,
                                items: centerItems,
                                overlayWidth: overlayWidth,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, bottomTuck),
                            child: _buildSection(
                              config: config,
                              items: bottomItems,
                              overlayWidth: overlayWidth,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection({
    required SidebarDockConfig config,
    required List<SidebarDockItemConfig> items,
    required double overlayWidth,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    final int hoveredIndex = _hoveredItemId == null
        ? -1
        : items.indexWhere((e) => e.id == _hoveredItemId);

    return SizedBox(
      width: overlayWidth,
      height: items.length * config.ui.itemExtent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final bool isActive =
              item.route != null &&
              item.route != '__chat__' &&
              item.route == widget.activeSection;

          final double scale = _computeDockScale(
            ui: config.ui,
            currentIndex: index,
            hoveredIndex: hoveredIndex,
          );

          final double labelStrength = _computeLabelStrength(
            currentIndex: index,
            hoveredIndex: hoveredIndex,
          );

          final Color iconColor = isActive ? AppColors.white : ref.read(themeColorsProvider).textColor;
          final theme = ref.read(themeColorsProvider);

          return SizedBox(
            width: overlayWidth,
            height: config.ui.itemExtent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IgnorePointer(
                  ignoring: true,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SidebarDockHoverButton(
                      bubbleBackgroundColor: isActive ? theme.themeColor : Colors.transparent,
                      bubbleGlowColor: isActive ? theme.textColor.withAlpha(100) : Colors.transparent,
                      bubbleBorderColor: isActive ? theme.dashboardBoarder : Colors.transparent,
                      labelColor: isActive
                          ? Colors.white
                          : theme.textColor,
                      icon: resolveSidebarDockIcon(
                        iconKey: item.iconKey,
                        color: iconColor,
                      ),
                      label: item.label.tr,
                      labelStrength: labelStrength,
                      isActive: isActive,
                      side: config.side,
                      railWidth: config.ui.railWidth,
                      expandedWidth: overlayWidth,
                      height: config.ui.itemExtent,
                      iconScale: scale,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: config.ui.railWidth,
                    height: config.ui.itemExtent,
                    child: MouseRegion(
                      opaque: true,
                      onEnter: (event) => _updateHover(item.id, event.position),
                      onHover: (event) => _updateHover(item.id, event.position),
                      onExit: (_) {
                        if (_hoveredItemId != item.id) return;
                        setState(() {
                          _hoveredItemId = null;
                          _hoveredLocalY = null;
                        });
                      },
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _handleTap(context, item),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _handleTap(BuildContext context, SidebarDockItemConfig item) {
    final route = item.route;

    if (route == null || route.isEmpty) return;

    if (route == '__chat__') {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => const ChatPage(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
      return;
    }

    widget.onTabSelected(route);
  }

  void _updateHover(String itemId, Offset globalPosition) {
    final ctx = _railKey.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final local = box.globalToLocal(globalPosition);

    setState(() {
      _hoveredItemId = itemId;
      _hoveredLocalY = local.dy.clamp(0.0, box.size.height);
    });
  }

  double _computeDockScale({
    required SidebarDockUiConfig ui,
    required int currentIndex,
    required int hoveredIndex,
  }) {
    if (!ui.enableMagnify || hoveredIndex < 0) {
      return ui.baseIconScale;
    }

    final int delta = (currentIndex - hoveredIndex).abs();

    if (delta == 0) return ui.hoveredIconScale;
    if (delta == 1) return ui.neighborIconScale;
    if (delta == 2) return ui.secondNeighborIconScale;
    return ui.baseIconScale;
  }

  double _computeLabelStrength({
    required int currentIndex,
    required int hoveredIndex,
  }) {
    if (hoveredIndex < 0) return 0.0;

    final int delta = (currentIndex - hoveredIndex).abs();

    if (delta == 0) return 1.0;
    if (delta == 1) return 0.58;
    if (delta == 2) return 0.24;
    return 0.0;
  }
}