import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:fav_board/providers/portal_board_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:network_monitoring/browselist/components/card.dart';
import 'package:network_monitoring/browselist/utils/api.dart';
import 'package:portal/browselist/components/card.dart';
import 'package:portal/screens/feed/components/browselist/utils/api.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

import 'organize_into_a_board_widget.dart';

class UnOrganizedPropertiesWidget extends ConsumerWidget {
  final bool isMobile;
  const UnOrganizedPropertiesWidget({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkScrollController = ScrollController();
    final portalScrollController = ScrollController();
    NumberFormat customFormat = NumberFormat.decimalPattern('fr');
    final selectedTabIndex = ref.watch(selectedTabProvider);
    final theme = ref.read(themeColorsProvider);
    final tileListHeight = isMobile ? 160.h : 555.h;
    final scope = BrowseScope(
      transactionId: null,
      clientId: null,
    );


    return IntrinsicHeight(
      child: Container(
        padding: EdgeInsets.only(right: 10, left: 10, bottom: 65, top: 10),
        decoration: BoxDecoration(color: theme.textFieldColor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unorganized properties'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: isMobile ? 20.sp : 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
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
                                child: OrganizeIntoABoardWidget(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      height: 52,
                      width: 90.w,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: theme.textColor),
                      ),
                      child: Center(
                        child: Text(
                          'Organize'.tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30.h),
            if (selectedTabIndex == 1) ...[
              ref
                  .watch(networkMonitoringBrowseListProvider(scope))
                  .when(
                    data: (filteredAdvertisements) {
                      return SizedBox(
                        height: tileListHeight,
                        child: ListView.builder(
                          addAutomaticKeepAlives: false,
                          cacheExtent: 300.0,
                          controller: portalScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: filteredAdvertisements.length,
                          itemBuilder: (context, index) {
                            final feedAd = filteredAdvertisements[index];
                            final keyTag =
                                'browselist_nm${feedAd.id}${UniqueKey().toString()}';
                            String formattedPrice = customFormat.format(
                              feedAd.price,
                            );


                            final mainImageUrl = feedAd.images?.isNotEmpty == true
                                ? feedAd.images!.first
                                : 'default_image_url';



                            return GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                portalScrollController.jumpTo(
                                  portalScrollController.offset -
                                      details.delta.dx,
                                );
                              },
                              child: DndSender(
                                enabled: !isMobile,
                                useLongPress: true,
                                payload: DndPayload(
                                  type: DndPayloadType.nm_ad,
                                  id: feedAd.id.toString(),
                                  action: 'add_to_board',
                                ),
                                child: BrowseListCardWidget(
                                  isHidden: false,
                                  ifIsFav: true,
                                  ad: feedAd,
                                  keyTag: keyTag,
                                  mainImageUrl: mainImageUrl,
                                  formattedPrice: formattedPrice,
                                  isUnorganizedWidget: !isMobile,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading:
                        () => SizedBox(
                          height: tileListHeight,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    error:
                        (error, stack) => SizedBox(
                          height: tileListHeight,
                          child: Center(
                            child: Text(
                              'Wystąpił błąd: $error'.tr,
                              style: AppTextStyles.interLight,
                            ),
                          ),
                        ),
                  ),
            ] else ...[
              ref
                  .watch(browseListProvider)
                  .when(
                    data: (filteredAdvertisements) {
                      return SizedBox(
                        height: tileListHeight,
                        child: ListView.builder(
                          addAutomaticKeepAlives: false,
                          cacheExtent: 300.0,
                          controller: networkScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: filteredAdvertisements.length,
                          itemBuilder: (context, index) {
                            final feedAd = filteredAdvertisements[index];
                            final keyTag =
                                'browselist_nm${feedAd.id}${UniqueKey().toString()}';
                            String formattedPrice = customFormat.format(
                              feedAd.price,
                            );

                            final mainImageUrl =
                                feedAd.images.isNotEmpty
                                    ? feedAd.images[0]
                                    : 'default_image_url';

                            return GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                networkScrollController.jumpTo(
                                  networkScrollController.offset -
                                      details.delta.dx,
                                );
                              },
                              child: DndSender(
                                enabled: !isMobile,
                                useLongPress: true,
                                payload: DndPayload(
                                  type: DndPayloadType.advertisement,
                                  id: feedAd.id.toString(),
                                  action: 'add_to_board',
                                ),
                                child: PortalBrowseListCardWidget(
                                  isHidden: false,
                                  feedAd: feedAd,
                                  isMobile: isMobile,
                                  keyTag: keyTag,
                                  mainImageUrl: mainImageUrl,
                                  formattedPrice: formattedPrice,
                                  isUnorganizedProperties: !isMobile,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading:
                        () => SizedBox(
                          height: tileListHeight,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    error:
                        (error, stack) => SizedBox(
                          height: tileListHeight,
                          child: Center(
                            child: Text(
                              'Wystąpił błąd: $error'.tr,
                              style: AppTextStyles.interLight,
                            ),
                          ),
                        ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
