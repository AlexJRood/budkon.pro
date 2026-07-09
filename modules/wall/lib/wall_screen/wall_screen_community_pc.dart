import 'package:core/ui/device_type_util.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:wall/emma/anchors/anchors_wall.dart';
import 'package:wall/wall_screen/providers/post_create_provider.dart';
import 'package:wall/wall_screen/screens/widgets/all_screens_list.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/footer_widget.dart';
import 'package:wall/wall_screen/screens/widgets/create_post_dialog/post_create_dialog.dart';
import 'package:get/get_utils/get_utils.dart';

final selectedIndexProviderWall = StateProvider<int>((ref) => 0);
final dialogProvider = StateProvider<bool>((ref) => false);

class WallScreenCommunityPc extends ConsumerStatefulWidget {
  final bool isDialog;
  final bool isTablet;
  const WallScreenCommunityPc({
    super.key,
    this.isDialog = false,
    this.isTablet = false,
  });

  @override
  ConsumerState<WallScreenCommunityPc> createState() =>
      _WallScreenCommunityPcState();
}

class _WallScreenCommunityPcState extends ConsumerState<WallScreenCommunityPc> {


  final List<Widget> pcFeedViews = [
    buildFeedTab("All", "all"),
    buildFeedTab("Favourites", "favourites"),
    buildFeedTab("Groups", "groups"),
    buildFeedTab("Developers", "developers"),
    buildFeedTab("Flipers", "flipers"),
    buildFeedTab("Agents", "agents"),
    buildFeedTab("Hously", "hously"),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.isDialog && !ref.read(dialogProvider)) {
        ref.read(dialogProvider.notifier).state = true;
        ref.read(postCreateStateProvider.notifier).clearController();
        ref.read(postCreateStateProvider.notifier).clearForm();

        showDialog(
          context: context,
          builder: (context) => const Dialog(
            backgroundColor: Colors.transparent,
            child: PostCreateDialog(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProviderWall);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = ref.read(themeColorsProvider);
    final double dynamicPadding = screenWidth / 6;
    final double padding = widget.isTablet ? 40.0 : (screenWidth / 7);
    final feedLabels = [
      "all".tr,
      "favourites".tr,
      "groups".tr,
      "developers".tr,
      "flipers".tr,
      "agents".tr,
      "Hously",
    ];
    return EmmaUiAnchorTarget(
      anchorKey: WallEmmaAnchors.wallScreenPc.anchorKey,

      spec: WallEmmaAnchors.wallScreenPc,
      runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: Container(
              constraints: BoxConstraints(minHeight: screenHeight - TopAppBarSize.resolve(context)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                    const EdgeInsets.only(left: 16,),
                    child: EmmaUiAnchorTarget(
                       anchorKey: WallEmmaAnchors.wallSidebar.anchorKey,

                       spec: WallEmmaAnchors.wallSidebar,
                       runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
                       tapMode: EmmaUiAnchorTapMode.disabled,
                      child: Container(
                        height: screenHeight - TopAppBarSize.resolve(context) + 10,
                        width: 240,
                        decoration: BoxDecoration(
                          color: theme.dashboardContainer,
                          border: Border.all(
                            color: theme.dashboardBoarder,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "feeds".tr,
                              style: TextStyle(
                                fontSize: 20,
                                color: CustomColors.secondaryWidgetTextColor(
                                  context,
                                  ref,
                                  
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            for (int i = 0; i < feedLabels.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: EmmaUiAnchorTarget(
                                   anchorKey: '${WallEmmaAnchors.feedSelectorItem.anchorKey}_$i',
                                   runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                                   tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                                  child: GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(
                                        selectedIndexProviderWall.notifier,
                                      )
                                          .state =
                                          i;
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: selectedIndex == i
                                            ? CustomColors.thirdWidgetColor(
                                          context,
                                          ref,
                                        )
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          HugeIcon(
                                            icon: HugeIcons.strokeRoundedGrid02,
                                            color: selectedIndex == i
                                                ? CustomColors.thirdWidgetTextColor(
                                              context,
                                              ref,
                                            )
                                                : CustomColors
                                                .secondaryWidgetTextColor(
                                              context,
                                              ref,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            feedLabels[i],
                                            style: TextStyle(
                                              color: selectedIndex == i
                                                  ? CustomColors.thirdWidgetTextColor(
                                                context,
                                                ref,
                                              )
                                                  : CustomColors
                                                  .secondaryWidgetTextColor(
                                                context,
                                                ref,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                 
                  Expanded(
                    child: SizedBox(
                      height: screenHeight,
                      child: pcFeedViews[selectedIndex],
                    ),
                  ),
                ],
              ),
            
      ),
    );
  }
}
