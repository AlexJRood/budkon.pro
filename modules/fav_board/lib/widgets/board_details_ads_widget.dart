import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:fav_board/models/portal_fav_board_model.dart';
import 'package:fav_board/providers/portal_board_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:portal/screens/feed/components/cards/selected_card.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/lottie.dart';

class BoardDetailsAds extends ConsumerWidget {
  final bool isDefaultDarkSystem;
  final Color color;
  final Color textColor;
  final Color textFieldColor;

  const BoardDetailsAds({
    super.key,
    required this.isDefaultDarkSystem,
    required this.color,
    required this.textColor,
    required this.textFieldColor,
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
    final selectedBoard = ref.watch(selectedBoardProvider);
    final selectedType = ref.watch(selectedPropertyTypeProvider);
    final selectedSort = ref.watch(selectedSortProvider);

    if (selectedBoard == null) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredAds = selectedType == null
        ? List<BoardDetails>.from(selectedBoard.advertisements ?? [])
        : List<BoardDetails>.from(
      selectedBoard.advertisements
          ?.where((ad) => ad.estateType == selectedType)
          .toList() ??
          [],
    );

    if (filteredAds.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(child: AppLottie.noResults(size: 450)),
      );
    }

    filteredAds.sort((a, b) {
      final aPrice = a.price;
      final bPrice = b.price;

      switch (selectedSort) {
        case 'price_low_to_high':
          return aPrice.compareTo(bPrice);
        case 'price_high_to_low':
          return bPrice.compareTo(aPrice);
        default:
          return 0;
      }
    });

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;

        if (constraints.crossAxisExtent > 1000) {
          crossAxisCount = 3;
        } else if (constraints.crossAxisExtent > 600) {
          crossAxisCount = 1;
        }

        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final ad = filteredAds[index];
              final adModel = fromBoardDetails(ad);
              final tag = 'fullSize${ad.id}';

              final rawImage = ad.advertisementImages.isNotEmpty
                  ? ad.advertisementImages[0]
                  : null;

              final mainImageUrl =
                  rawImage ?? 'https://your-default-image.com/fallback.jpg';

              return DndSender(
                payload: DndPayload(
                  type: DndPayloadType.favAd,
                  id: ad.id.toString(),
                  action: 'assign_fav_ad',
                  data: {'title': ad.title},
                ),
                child: SelectedCardWidget(
                  isMobile: false,
                  aspectRatio: 1,
                  ad: adModel,
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
                  buildPieMenuActions: buildPieMenuActions(
                    ref,
                    adModel,
                    context,
                  ),
                ),
              );
            },
            childCount: filteredAds.length,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
        );
      },
    );
  }
}