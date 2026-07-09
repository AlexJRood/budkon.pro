import 'package:core/ui/device_type_util.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:wall/emma/anchors/anchors_wall.dart';
import 'package:wall/wall_screen/screens/widgets/all_screens_list.dart';

final List<String> feedLabels = [
  "all".tr,
  "favorites".tr,
  "groups".tr,
  "developers".tr,
  "flipers".tr,
  "agents".tr,
];

final List<Widget> mobileFeedViews = [
  buildFeedTab("all".tr, "all", isMobile: true),
  buildFeedTab("favorites".tr, "favourites", isMobile: true),
  buildFeedTab("groups".tr, "groups", isMobile: true),
  buildFeedTab("developers".tr, "developers", isMobile: true),
  buildFeedTab("flipers".tr, "flipers", isMobile: true),
  buildFeedTab("agents".tr, "agents", isMobile: true),
];

/// Selected "tab" index for mobile (replaces TabController).
final wallFeedIndexProvider = StateProvider<int>((ref) => 0);

class WallScreenCommunityMobile extends ConsumerWidget {
  const WallScreenCommunityMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final idx = ref.watch(wallFeedIndexProvider);

    final screenHeight = MediaQuery.of(context).size.height;

    return EmmaUiAnchorTarget(
      anchorKey: WallEmmaAnchors.wallScreenMobile.anchorKey,

      spec: WallEmmaAnchors.wallScreenMobile,
      runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: Container(
        constraints: BoxConstraints(minHeight: screenHeight - 60),
        child: Column(
          children: [
            SizedBox(height: TopAppBarSize.resolve(context)),
      
      
            // Content of the selected "tab"
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: EmmaUiAnchorTarget(
                   anchorKey: '${WallEmmaAnchors.feedList.anchorKey}_$idx',
                   runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                   tapMode: EmmaUiAnchorTapMode.disabled,
                  child: KeyedSubtree(
                    key: ValueKey<int>(idx),
                    child: mobileFeedViews[idx],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
