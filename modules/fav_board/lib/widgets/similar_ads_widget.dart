import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:fav_board/models/portal_fav_board_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:portal/models/ad_list_view_model.dart';

import 'package:portal/pie_menu/feed.dart';
import 'package:portal/screens/feed/components/cards/selected_card.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';

import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/lottie.dart';

class SimilarAdsWidget extends ConsumerWidget {
  final List<BoardDetails> similarAds;
  final ScrollController scrollController;
  final bool isDefaultDarkSystem;
  final Color color;
  final Color textColor;
  final Color textFieldColor;
  final bool isMobile;

  const SimilarAdsWidget({
    super.key,
    required this.similarAds,
    required this.scrollController,
    required this.isDefaultDarkSystem,
    required this.color,
    required this.textColor,
    required this.textFieldColor,
    this.isMobile = false,
  });

  AdsListViewModel fromBoardDetails(BoardDetails ad) {
    return AdsListViewModel(
      id: ad.id,
      slug: ad.slug,
      title: ad.title,
      description: ad.description,
      price: ad.price,
      images: ad.images,
      squareFootage: ad.squareFootage,
      rooms: ad.rooms,
      bathrooms: ad.bathrooms,
      floor: ad.floor,
      totalFloors: ad.totalFloors,
      marketType: ad.marketType,
      offerType: ad.offerType,
      isPro: ad.isPro,
      currency: ad.currency,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 20.h : 50.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
                padding: EdgeInsets.only(left:  isMobile ? 10.w : 50.w),
            child: Text(
              'Similar properties'.tr,
              style: TextStyle(
                fontSize: isMobile ? 20.sp : 24.sp,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 10.h : 20.h),
          SizedBox(
            height: 500.h,
            child: similarAds.isEmpty
                ? Container(
              width: double.infinity,
              color: Colors.transparent,
              child: Center(
                child: AppLottie.noResults(),
              ),
            )
                :GestureDetector(
              onHorizontalDragUpdate: (details) {
                scrollController.jumpTo(
                  scrollController.offset - details.delta.dx,
                );
              },
              child: ListView.separated(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: similarAds.length,
                separatorBuilder: (context, index) => SizedBox(width: 30.w),
                itemBuilder: (context, index) {
                  final ad = similarAds[index];
                  final convertedAd = fromBoardDetails(ad);
                  final tag = 'fullSize${ad.id}${UniqueKey()}';
                  // [FIX 3] REPLACE rawImage calculation
                  final rawImage = ad.advertisementImages.isNotEmpty
                      ? ad.advertisementImages.first
                      : ((ad.images.isNotEmpty ?? false) ? ad.images.first : null);

                  final mainImageUrl = rawImage ?? 'https://your-default-image.com/fallback.jpg';




                  return Padding(
                    padding: EdgeInsets.only(left: index == 0 ? isMobile ? 20.w : 50.w : 0),
                    child: DndSender(
                      payload: DndPayload(
                        type: DndPayloadType.favAd,
                        id: ad.id.toString(),
                        action: 'assign_fav_ad',
                        data: {'title': ad.title},
                      ),
                      child: SelectedCardWidget(
                        isMobile: isMobile,
                        aspectRatio: 1,
                        ad: convertedAd,
                        tag: tag,
                        mainImageUrl: mainImageUrl,
                        isPro: ad.isPro,
                        isDefaultDarkSystem: isDefaultDarkSystem,
                        color: color,
                        textColor: textColor,
                        textFieldColor: textFieldColor,
                        buildShimmerPlaceholder: ShimmerPlaceholder(
                          width: 500.w,
                          height: 500.h,
                        ),
                        buildPieMenuActions: buildPieMenuActions(ref, convertedAd, context),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
