import 'dart:developer';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:seller/emma/anchors/seller_emma_anchors.dart';
import 'package:seller/providers/seller_provider.dart';
import 'package:seller/widgets/seller_advertisements_widget.dart';
import 'package:seller/screens/seller_profile_screen.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/lottie.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/footer_widget.dart';

class SellerProfilePc extends ConsumerWidget {
  final int sellerId;
  final ThemeColors theme;
  final List<String> tabs;
  final int grid;
  final int selectedTab;

  const SellerProfilePc({
    super.key,
    required this.sellerId,
    required this.theme,
    required this.tabs,
    required this.grid,
    required this.selectedTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(sellerProvider(sellerId));

    return sellerAsync.when(
      error: (error, stackTrace) => Center(child: AppLottie.error(size: 450)),
      loading: () => Center(child: AppLottie.loading(size: 450)),
      data: (seller) {
        if (seller == null) {
          return Center(child: AppLottie.error(size: 450));
        }

        final parsedDate = DateTime.now(); // Since we don't have dateCreated in seller model
        final formattedDate = DateFormat.yMMMMd().format(parsedDate);

        debugPrint('Seller data: ${seller.fullName}');
        debugPrint('Seller avatar: ${seller.avatarUrl}');
        debugPrint('Seller background: ${seller.backgroundImage}');
        log("width ${300.h}");

        return EmmaUiAnchorTarget(
          anchorKey: SellerEmmaAnchors.sellerProfilePage.anchorKey,

          spec: SellerEmmaAnchors.sellerProfilePage,
          runtimeMode: SellerEmmaAnchors.sellerProfilePage.runtimeMode,
          tapMode: SellerEmmaAnchors.sellerProfilePage.tapMode,
          child: Column(
            children: [
              SizedBox(
                height: 300.h,
                child: Stack(
                  children: [
                    EmmaUiAnchorTarget(
                      anchorKey: SellerEmmaAnchors.sellerProfileHeader.anchorKey,

                      spec: SellerEmmaAnchors.sellerProfileHeader,
                      runtimeMode: SellerEmmaAnchors.sellerProfileHeader.runtimeMode,
                      tapMode: SellerEmmaAnchors.sellerProfileHeader.tapMode,
                      child: Container(
                        height: 200.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(79, 79, 79, 1),
                          image: seller.backgroundImage != null
                              ? DecorationImage(
                                  image: NetworkImage(seller.backgroundImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: seller.backgroundImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 44.w,
                                    width: 44.w,
                                    decoration: BoxDecoration(
                                      color: theme.buttonBackground,
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24.w,
                                    ),
                                  ),
                                  Text(
                                    'Seller Profile',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.white,
                                      fontSize: 18.sp,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      top: 135.h,
                      left: 40.w,
                      child: SizedBox(
                        child: Column(
                          spacing: 20.h,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 140.w,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                EmmaUiAnchorTarget(
                                  anchorKey: SellerEmmaAnchors.sellerAvatar.anchorKey,

                                  spec: SellerEmmaAnchors.sellerAvatar,
                                  runtimeMode: SellerEmmaAnchors.sellerAvatar.runtimeMode,
                                  tapMode: SellerEmmaAnchors.sellerAvatar.tapMode,
                                  child: Container(
                                    height: 140.w,
                                    width: 140.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: seller.avatarUrl != null
                                          ? Image.network(
                                              seller.avatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey,
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 60.w,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey,
                                              child: Icon(
                                                Icons.person,
                                                size: 60.w,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                EmmaUiAnchorTarget(
                                  anchorKey: SellerEmmaAnchors.sellerTabsContainer.anchorKey,

                                  spec: SellerEmmaAnchors.sellerTabsContainer,
                                  runtimeMode: SellerEmmaAnchors.sellerTabsContainer.runtimeMode,
                                  tapMode: SellerEmmaAnchors.sellerTabsContainer.tapMode,
                                  child: SellerTabsScreen(theme: theme, tabs: tabs)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 40.w),
                  Expanded(
                    child: Column(
                      spacing: 20.h,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          spacing: 5.h,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EmmaUiAnchorTarget(
                              anchorKey: SellerEmmaAnchors.sellerFullName.anchorKey,

                              spec: SellerEmmaAnchors.sellerFullName,
                              runtimeMode: SellerEmmaAnchors.sellerFullName.runtimeMode,
                              tapMode: SellerEmmaAnchors.sellerFullName.tapMode,
                              child: Text(
                                seller.fullName,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: theme.textColor,
                                  fontSize: 24.sp,
                                ),
                              ),
                            ),
                            EmmaUiAnchorTarget(
                              anchorKey: SellerEmmaAnchors.sellerEmail.anchorKey,

                              spec: SellerEmmaAnchors.sellerEmail,
                              runtimeMode: SellerEmmaAnchors.sellerEmail.runtimeMode,
                              tapMode: SellerEmmaAnchors.sellerEmail.tapMode,
                              child: Text(
                                seller.email,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: theme.textColor.withAlpha(128),
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                            if (seller.phoneNumber.isNotEmpty)
                              EmmaUiAnchorTarget(
                                anchorKey: SellerEmmaAnchors.sellerPhoneNumber.anchorKey,

                                spec: SellerEmmaAnchors.sellerPhoneNumber,
                                runtimeMode: SellerEmmaAnchors.sellerPhoneNumber.runtimeMode,
                                tapMode: SellerEmmaAnchors.sellerPhoneNumber.tapMode,
                                child: Text(
                                  seller.phoneNumber,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: theme.textColor.withAlpha(178),
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 5.h),
                        Column(
                          spacing: 6.h,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Properties',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: theme.textColor,
                                    fontSize: 15.sp,
                                  ),
                                ),
                                EmmaUiAnchorTarget(
                                  anchorKey: SellerEmmaAnchors.propertiesInfoBox.anchorKey,

                                  spec: SellerEmmaAnchors.propertiesInfoBox,
                                  runtimeMode: SellerEmmaAnchors.propertiesInfoBox.runtimeMode,
                                  tapMode: SellerEmmaAnchors.propertiesInfoBox.tapMode,
                                  child: Text(
                                    '${seller.adsCount}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: theme.textColor,
                                      fontSize: 17.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 5.h),
                        EmmaUiAnchorTarget(
                          anchorKey: SellerEmmaAnchors.memberSinceDate.anchorKey,

                          spec: SellerEmmaAnchors.memberSinceDate,
                          runtimeMode: SellerEmmaAnchors.memberSinceDate.runtimeMode,
                          tapMode: SellerEmmaAnchors.memberSinceDate.tapMode,
                          child: Text(
                            'MEMBER SINCE: $formattedDate',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 12.sp,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 80.w),
                  Expanded(
                    flex: 8,
                    child: DefaultTabController(
                      length: tabs.length,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 18.0,
                              bottom: 18,
                              right: 18,
                            ),
                            child: EmmaUiAnchorTarget(
                              anchorKey: SellerEmmaAnchors.advertisementsGrid.anchorKey,

                              spec: SellerEmmaAnchors.advertisementsGrid,
                              runtimeMode: SellerEmmaAnchors.advertisementsGrid.runtimeMode,
                              tapMode: SellerEmmaAnchors.advertisementsGrid.tapMode,
                              child: _buildTabContent(0, grid, seller.advertisements?.results ?? [])),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              EmmaUiAnchorTarget(
                anchorKey: SellerEmmaAnchors.sellerProfileFooter.anchorKey,

                spec: SellerEmmaAnchors.sellerProfileFooter,
                runtimeMode: SellerEmmaAnchors.sellerProfileFooter.runtimeMode,
                tapMode: SellerEmmaAnchors.sellerProfileFooter.tapMode,
                child: FooterWidget(
                  paddingDynamic: MediaQuery.of(context).size.width / 7,
                  isProfile: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabContent(int index, int grid, List advertisements) {
    log("_buildTabContent - Advertisements count: ${advertisements.length}");
    log("_buildTabContent - Advertisements type: ${advertisements.runtimeType}");
    if (advertisements.isNotEmpty) {
      log("_buildTabContent - First item type: ${advertisements.first.runtimeType}");
    }
    
    return SellerAdvertisementsWidget(
      grid: grid,
      advertisements: advertisements,
      filterType: AdvertisementFilterType.all,
    );
  }
}
