import 'package:fav_board/providers/portal_board_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/browselist/components/card.dart';
import 'package:portal/screens/feed/components/browselist/utils/api.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:network_monitoring/browselist/utils/api.dart';
import 'package:network_monitoring/browselist/components/card.dart';
import 'package:core/theme/design.dart';
import 'package:get/get.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';

import 'move_to_a_board_widget.dart';

import 'package:get/get_utils/get_utils.dart';

final selectedMonitoringAdsProvider = StateProvider<List<MonitoringAdsModel>>(
      (ref) => [],
);

final selectedPortalAdsProvider = StateProvider<List<AdsListViewModel>>(
      (ref) => [],
);

class OrganizeIntoABoardWidget extends ConsumerWidget {
  const OrganizeIntoABoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkScrollController = ScrollController();
    final portalScrollController = ScrollController();
    double networkDragCloseAccum = 0;
    double portalDragCloseAccum = 0;
    NumberFormat customFormat = NumberFormat.decimalPattern('fr');
    final selectedAds = ref.watch(selectedMonitoringAdsProvider);
    final portalSelectedAds = ref.watch(selectedPortalAdsProvider);
    final selectedTabIndex = ref.watch(selectedTabProvider);
    final theme = ref.read(themeColorsProvider);
    final scope = BrowseScope(
      transactionId: null,
      clientId: null,
    );


    return PieCanvas(
      theme: const PieTheme(
        rightClickShowsMenu: true,
        leftClickShowsMenu: false,
        buttonTheme: PieButtonTheme(
          backgroundColor: AppColors.themeColor,
          iconColor: Colors.white,
        ),
        buttonThemeHovered: PieButtonTheme(
          backgroundColor: Color.fromARGB(96, 58, 58, 58),
          iconColor: Colors.white,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.textFieldColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          spacing: 20,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if(selectedAds.isNotEmpty)...[
                  Text('${selectedAds.length} Selected',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if(portalSelectedAds.isNotEmpty)...[
                  Text('${portalSelectedAds.length} Selected',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if(selectedAds.isEmpty && portalSelectedAds.isEmpty)...[
                  Text('Organize into a board'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                GestureDetector(
                  onTap: () {
                    ref.read(selectedMonitoringAdsProvider.notifier).state = [];
                    ref.read(selectedMoveToBoardIdsProvider.notifier).state =
                    [];
                    Navigator.pop(context);
                  },
                  child:
                    AppIcons.close(color: theme.textColor),

                ),
              ],
            ),
            Expanded(
              child: selectedTabIndex == 1
                  ?ref
                  .watch(networkMonitoringBrowseListProvider(scope))
                  .when(
                data: (filteredAdvertisements) {
                  return GridView.builder(
                    addAutomaticKeepAlives: false,
                    addSemanticIndexes: false,
                    cacheExtent: 160,
                    controller: networkScrollController,
                    padding: EdgeInsets.zero,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: filteredAdvertisements.length,
                    itemBuilder: (context, index) {
                      final feedAd = filteredAdvertisements[index];
                      final keyTag =
                          'browselist_nm${feedAd.id}${UniqueKey().toString()}';
                      final isSelected = selectedAds.contains(feedAd);

                      return GestureDetector(
                        onVerticalDragUpdate: (details) {
                          final atTop =
                              !networkScrollController.hasClients ||
                              networkScrollController.offset <= 0;
                          if (atTop && details.delta.dy > 0) {
                            networkDragCloseAccum += details.delta.dy;
                            if (networkDragCloseAccum > 80) {
                              Navigator.pop(context);
                            }
                            return;
                          }
                          networkDragCloseAccum = 0;
                          networkScrollController.jumpTo(
                            (networkScrollController.offset - details.delta.dy)
                                .clamp(
                                  0.0,
                                  networkScrollController
                                      .position
                                      .maxScrollExtent,
                                ),
                          );
                        },
                        onTap: () {
                          final notifier = ref.read(
                            selectedMonitoringAdsProvider.notifier,
                          );
                          if (isSelected) {
                            notifier.state = [...selectedAds]
                              ..remove(feedAd);
                          } else {
                            notifier.state = [...selectedAds, feedAd];
                          }
                        },
                        child: BrowseListCardWidget(
                          isHidden: false,
                          ifIsFav: true,
                          ad: feedAd,
                          keyTag: keyTag,
                          aspectRatio: 1,
                          mainImageUrl: feedAd.images?.isNotEmpty == true
                              ? feedAd.images!.first
                              : 'default_image_url',

                          formattedPrice: customFormat.format(feedAd.price),
                          isSelectable: true,
                          isSelected: isSelected,
                        ),
                      );
                    },
                  );
                },
                loading:
                    () => SizedBox(
                  height: 555.h,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error:
                    (error, stack) => SizedBox(
                  height: 555.h,
                  child: Center(
                    child: Text(
                      'Wystąpił błąd: $error'.tr,
                      style: AppTextStyles.interLight,
                    ),
                  ),
                ),
              )
                  :  ref
                  .watch(browseListProvider)
                  .when(
                data: (filteredAdvertisements) {
                  return SizedBox(
                    height: 555.h,
                    child: GridView.builder(
                      addAutomaticKeepAlives: false,
                      addSemanticIndexes: false,
                      cacheExtent: 160,
                      controller: portalScrollController,
                      padding: EdgeInsets.zero,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: filteredAdvertisements.length,
                      itemBuilder: (context, index) {
                        final feedAd = filteredAdvertisements[index];
                        final keyTag =
                            'browselist_nm${feedAd.id}${UniqueKey().toString()}';
                        String formattedPrice = customFormat.format(feedAd.price);

                        final mainImageUrl =
                        feedAd.images.isNotEmpty
                            ? feedAd.images[0]
                            : 'default_image_url';
                        final isSelected = portalSelectedAds.contains(feedAd);

                        return GestureDetector(
                          onVerticalDragUpdate: (details) {
                            final atTop =
                                !portalScrollController.hasClients ||
                                portalScrollController.offset <= 0;
                            if (atTop && details.delta.dy > 0) {
                              portalDragCloseAccum += details.delta.dy;
                              if (portalDragCloseAccum > 80) {
                                Navigator.pop(context);
                              }
                              return;
                            }
                            portalDragCloseAccum = 0;
                            portalScrollController.jumpTo(
                              (portalScrollController.offset - details.delta.dy)
                                  .clamp(
                                    0.0,
                                    portalScrollController
                                        .position
                                        .maxScrollExtent,
                                  ),
                            );
                          },
                          onTap: () {
                            final notifier = ref.read(
                              selectedPortalAdsProvider.notifier,
                            );
                            if (isSelected) {
                              notifier.state = [...portalSelectedAds]
                                ..remove(feedAd);
                            } else {
                              notifier.state = [...portalSelectedAds, feedAd];
                            }
                          },
                          child: PortalBrowseListCardWidget(
                            isHidden: false,
                            feedAd: feedAd,
                            keyTag: keyTag,
                            mainImageUrl: mainImageUrl,
                            formattedPrice: formattedPrice,
                            isSelectable: true,
                            isSelected: isSelected,
                          ),
                        );
                      },
                    ),
                  );
                },
                loading:
                    () => SizedBox(
                  height: 555.h,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error:
                    (error, stack) => SizedBox(
                  height: 555.h,
                  child: Center(
                    child: Text(
                      'Wystąpił błąd: $error'.tr,
                      style: AppTextStyles.interLight.copyWith(color: theme.textColor),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    ref.read(selectedMonitoringAdsProvider.notifier).state = [];
                    ref.read(selectedMoveToBoardIdsProvider.notifier).state =
                    [];
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 32.h,
                    width: 65.w,
                    decoration: BoxDecoration(color: Colors.transparent),
                    child: Center(
                      child: Text(
                        'Cancel'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap:
                  selectedAds.isNotEmpty || portalSelectedAds.isNotEmpty
                      ? () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) {
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: EdgeInsets.zero,
                          child: Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: 900.h,
                              width: 870.w, // same as your widget width
                              child: MoveToABoardWidget(),
                            ),
                          ),
                        );
                      },
                    );
                  }
                      : null,
                  child: Container(
                    height: 32.h,
                    width: 65.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.r),
                      color: theme.buttonBackground,
                    ),
                    child: Center(
                      child: Text(
                        'Next'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}