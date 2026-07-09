import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/screens/feed/components/cards/selected_card.dart';
import 'package:seller/emma/anchors/seller_emma_anchors.dart';
import 'package:core/theme/apptheme.dart';
import 'dart:developer';


import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:pie_menu/pie_menu.dart';

enum AdvertisementFilterType { all, active, sold }

class SellerAdvertisementsWidget extends ConsumerWidget {
  final int grid;
  final List<dynamic> advertisements;
  final AdvertisementFilterType filterType;

  const SellerAdvertisementsWidget({
    super.key,
    required this.grid,
    required this.advertisements,
    required this.filterType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    log(
      "SellerAdvertisementsWidget - Raw advertisements count: ${advertisements.length}",
    );
    log(
      "SellerAdvertisementsWidget - Raw advertisements type: ${advertisements.runtimeType}",
    );

    double screenWidth = MediaQuery.of(context).size.width;
    const double maxWidth = 1920;
    const double minWidth = 1080;
    const double maxDynamicPadding = 65;
    const double minDynamicPadding = 5;
    double dynamicPadding =
        (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxDynamicPadding - minDynamicPadding) +
        minDynamicPadding;
    final adFiledSize = (((screenWidth) - (dynamicPadding * 2)) - 80);

    // Check if advertisements is already a list of AdsListViewModel
    List<AdsListViewModel> adsViewModels;

    if (advertisements.isNotEmpty && advertisements.first is AdsListViewModel) {
      // Already converted AdsListViewModel objects
      adsViewModels = advertisements.cast<AdsListViewModel>();
      log(
        "Using pre-converted AdsListViewModel objects: ${adsViewModels.length}",
      );
    } else {
      // Convert dynamic list to AdsListViewModel list
      adsViewModels = advertisements
          .whereType<Map<String, dynamic>>()
          .map((ad) => AdsListViewModel.fromJson(ad))
          .toList();
      log(
        "Converted ${adsViewModels.length} advertisements from Map to AdsListViewModel",
      );
    }

    if (adsViewModels.isEmpty) {
      log("No advertisements to display - showing empty state");
      return EmmaUiAnchorTarget(
        anchorKey: SellerEmmaAnchors.emptyStateContainer.anchorKey,

        spec: SellerEmmaAnchors.emptyStateContainer,
        runtimeMode: SellerEmmaAnchors.emptyStateContainer.runtimeMode,
        tapMode: SellerEmmaAnchors.emptyStateContainer.tapMode,
        child: _buildEmptyState(context, ref));
    }

    log("Displaying ${adsViewModels.length} advertisements");
    return EmmaUiAnchorTarget(
      anchorKey: SellerEmmaAnchors.advertisementsGrid.anchorKey,

      spec: SellerEmmaAnchors.advertisementsGrid,
      runtimeMode: SellerEmmaAnchors.advertisementsGrid.runtimeMode,
      tapMode: SellerEmmaAnchors.advertisementsGrid.tapMode,
      child: GridView.builder(
        itemCount: adsViewModels.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: grid,
          crossAxisSpacing: 7,
          mainAxisSpacing: 7,
        ),
        itemBuilder: (context, index) {
          final ad = adsViewModels[index];
          final theme = ref.watch(themeColorsProvider);
          final isDefaultDarkSystem = ref.watch(isDefaultDarkSystemProvider);
      
          final color = theme.secondaryWidgetColor;
          final textColor = theme.textColor;
          final textFieldColor = theme.textFieldColor;
          final tag = 'seller_ad_${ad.id}_$index';
          final mainImageUrl = ad.images.isNotEmpty
              ? ad.images[0]
              : 'default_image_url';
          final isPro = ad.isPro;
      
          return EmmaUiAnchorTarget(
            anchorKey: '${SellerEmmaAnchors.advertisementCard.anchorKey}.${ad.id}',
            runtimeMode: SellerEmmaAnchors.advertisementCard.runtimeMode,
            tapMode: SellerEmmaAnchors.advertisementCard.tapMode,
            child: SelectedCardWidget(
              isMobile: false,
              aspectRatio: 1.2,
              ad: ad,
              tag: tag,
              mainImageUrl: mainImageUrl,
              isPro: isPro,
              isDefaultDarkSystem: isDefaultDarkSystem,
              color: color,
              textColor: textColor,
              textFieldColor: textFieldColor,
              buildShimmerPlaceholder: _buildShimmerPlaceholder(),
              buildPieMenuActions: _buildPieMenuActions(ref, ad, context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return SizedBox(
      height: 300.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 80.w,
            color: theme.textColor.withAlpha(76),
          ),
          SizedBox(height: 16.h),
          Text(
            _getEmptyStateMessage(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: theme.textColor.withAlpha(153),
              fontSize: 16.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getEmptyStateMessage() {
    switch (filterType) {
      case AdvertisementFilterType.all:
        return 'No advertisements found';
      case AdvertisementFilterType.active:
        return 'No active properties found';
      case AdvertisementFilterType.sold:
        return 'No sold properties found';
    }
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  // Helper function for pie menu actions
  List<PieAction> _buildPieMenuActions(
    WidgetRef ref,
    AdsListViewModel ad,
    BuildContext context,
  ) {
    return [
      PieAction(
        tooltip: Text("hello"),
        onSelect: () {},
        child: EmmaUiAnchorTarget(
          anchorKey: '${SellerEmmaAnchors.favoriteButton.anchorKey}.${ad.id}',
          runtimeMode: SellerEmmaAnchors.favoriteButton.runtimeMode,
          tapMode: SellerEmmaAnchors.favoriteButton.tapMode,
          child: FaIcon(FontAwesomeIcons.solidHeart)),
      ),
      PieAction(
        tooltip: Text('Dodaj do listy przeglądania'.tr),
        onSelect: () {},
        child: EmmaUiAnchorTarget(
          anchorKey: '${SellerEmmaAnchors.addToWatchlistButton.anchorKey}.${ad.id}',
          runtimeMode: SellerEmmaAnchors.addToWatchlistButton.runtimeMode,
          tapMode: SellerEmmaAnchors.addToWatchlistButton.tapMode,
          child: FaIcon(FontAwesomeIcons.list)),
      ),
      PieAction(
        tooltip: Text('Ukryj ogłoszenie'.tr),
        onSelect: () {},
        child: EmmaUiAnchorTarget(
          anchorKey: '${SellerEmmaAnchors.hideAdvertisementButton.anchorKey}.${ad.id}',
          runtimeMode: SellerEmmaAnchors.hideAdvertisementButton.runtimeMode,
          tapMode: SellerEmmaAnchors.hideAdvertisementButton.tapMode,
          child: FaIcon(FontAwesomeIcons.eyeSlash)),
      ),
      PieAction(
        tooltip: Text('Udostępnij ogłoszenie'.tr),
        onSelect: () {},
        child: EmmaUiAnchorTarget(
          anchorKey: '${SellerEmmaAnchors.shareAdvertisementButton.anchorKey}.${ad.id}',
          runtimeMode: SellerEmmaAnchors.shareAdvertisementButton.runtimeMode,
          tapMode: SellerEmmaAnchors.shareAdvertisementButton.tapMode,
          child: const FaIcon(FontAwesomeIcons.shareNodes)),
      ),
    ];
  }
}
