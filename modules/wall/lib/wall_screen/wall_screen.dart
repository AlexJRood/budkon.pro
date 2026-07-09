import 'dart:developer';

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:wall/emma/anchors/anchors_wall.dart';
import 'package:wall/wall_screen/wall_screen_community_mobile.dart';
import 'package:wall/wall_screen/wall_screen_community_pc.dart';
import 'package:wall/wall_screen/services/confetti/global_confeti_widget.dart';
import 'package:get/get_utils/get_utils.dart';

class WallScreen extends ConsumerWidget {
  const WallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final screenWidth = MediaQuery.of(context).size.width;
    log("screenwidth is ${screenWidth.toString()}");
    return EmmaUiAnchorTarget(
      anchorKey: WallEmmaAnchors.wallScreen.anchorKey,

      spec: WallEmmaAnchors.wallScreen,
      runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: Stack(
        children: [
          BarManager(
            sideMenuKey: sideMenuKey,
            appModule: AppModule.wall,
            isChildExpanded: false,
            verticalButtons: const _WallMobileFeedSheetButton(),
            childPc: const WallScreenCommunityPc(),
            childMobile: const WallScreenCommunityMobile(),
            tabletScaffoldMode: TabletScaffoldMode.mobile,
            // childrenTablet: [
            //   Expanded(
            //     child: WallScreenCommunityPc(
            //       isTablet: true,
            //               ),
            //   )],
          ),
          const GlobalConfettiOverlay(),
        ],
      ),
    );
  }
}

/// Floating button (BarManager.verticalButtons) -> opens DraggableScrollableSheet
class _WallMobileFeedSheetButton extends ConsumerWidget {
  const _WallMobileFeedSheetButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final idx = ref.watch(wallFeedIndexProvider);

    return EmmaUiAnchorTarget(
      anchorKey: WallEmmaAnchors.mobileFeedSheetButton.anchorKey,

      spec: WallEmmaAnchors.mobileFeedSheetButton,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      child: Material(
        color: Colors.transparent,
        child: ElevatedButton(
          style: elevatedButtonStyleRounded6,
          onPressed: () => _openSheet(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              border: Border.all(color: theme.dashboardBoarder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune, color: theme.textColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  feedLabels[idx],
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_up, color: theme.textColor.withAlpha(170), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(120),
      builder: (ctx) {
        return EmmaUiAnchorTarget(
          anchorKey: WallEmmaAnchors.mobileFeedSheet.anchorKey,

          spec: WallEmmaAnchors.mobileFeedSheet,
          runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
          tapMode: EmmaUiAnchorTapMode.disabled,
          child: DraggableScrollableSheet(
            initialChildSize: 0.60,
            minChildSize: 0.35,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              final selected = ref.watch(wallFeedIndexProvider);
          
              return Container(
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  border: Border.all(color: theme.dashboardBoarder),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dashboardBoarder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 12),
          
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(Icons.view_list, color: theme.textColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Select feed'.tr,
                            style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, color: theme.textColor),
                          ),
                        ],
                      ),
                    ),
          
                    const SizedBox(height: 6),
          
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        itemCount: feedLabels.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final isSelected = i == selected;
          
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              ref.read(wallFeedIndexProvider.notifier).state = i;
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.themeColor.withAlpha(40)
                                    : theme.dashboardContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? theme.themeColor : theme.dashboardBoarder,
                                  width: isSelected ? 1.2 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                                    color: isSelected ? theme.themeColor : theme.textColor.withAlpha(150),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      feedLabels[i],
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.star_rounded, color: theme.themeColor, size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height:
                    BottomBarSize.resolve(context),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
