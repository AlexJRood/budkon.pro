import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:seller/emma/anchors/seller_emma_anchors.dart';
import 'package:seller/screens/seller_profile_screen.dart';
import 'package:seller/widgets/seller_advertisements_widget.dart';
import 'package:seller/providers/seller_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class SellerProfileMobile extends ConsumerWidget {
  final int sellerId;
  final ThemeColors theme;
  final List<String> tabs;
  final int grid;
  final int selectedTab;

  const SellerProfileMobile({
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

        return EmmaUiAnchorTarget(
          anchorKey: SellerEmmaAnchors.sellerProfilePage.anchorKey,

          spec: SellerEmmaAnchors.sellerProfilePage,
          runtimeMode: SellerEmmaAnchors.sellerProfilePage.runtimeMode,
          tapMode: SellerEmmaAnchors.sellerProfilePage.tapMode,
          child: Column(
            children: [
              SizedBox(
                height: 315.h,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    EmmaUiAnchorTarget(
                      anchorKey: SellerEmmaAnchors.sellerProfileHeader.anchorKey,

                      spec: SellerEmmaAnchors.sellerProfileHeader,
                      runtimeMode: SellerEmmaAnchors.sellerProfileHeader.runtimeMode,
                      tapMode: SellerEmmaAnchors.sellerProfileHeader.tapMode,
                      child: Container(
                        height: 150.h,
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
                                children: [
                                  Container(
                                    height: 52.w,
                                    width: 52.w,
                                    decoration: BoxDecoration(
                                      color: theme.buttonBackground,
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 28.w,
                                    ),
                                  ),
                                  Text(
                                    'Seller Profile',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(color: Colors.white, fontSize: 14.sp),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      top: 125.h,
                      child: Container(
                        height: 140.w,
                        width: 140.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: EmmaUiAnchorTarget(
                          anchorKey: SellerEmmaAnchors.sellerAvatar.anchorKey,

                          spec: SellerEmmaAnchors.sellerAvatar,
                          runtimeMode: SellerEmmaAnchors.sellerAvatar.runtimeMode,
                          tapMode: SellerEmmaAnchors.sellerAvatar.tapMode,
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
                    ),
                  ],
                ),
              ),
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
              SizedBox(height: 30.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EmmaUiAnchorTarget(
                      anchorKey: SellerEmmaAnchors.propertiesInfoBox.anchorKey,

                      spec: SellerEmmaAnchors.propertiesInfoBox,
                      runtimeMode: SellerEmmaAnchors.propertiesInfoBox.runtimeMode,
                      tapMode: SellerEmmaAnchors.propertiesInfoBox.tapMode,
                      child: _buildInfoBox(context, '${seller.adsCount}', 'Properties')),
                  ],
                ),
              ),
              SizedBox(height: 30.h),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: EmmaUiAnchorTarget(
                  anchorKey: SellerEmmaAnchors.sellerTabsContainer.anchorKey,

                  spec: SellerEmmaAnchors.sellerTabsContainer,
                  runtimeMode: SellerEmmaAnchors.sellerTabsContainer.runtimeMode,
                  tapMode: SellerEmmaAnchors.sellerTabsContainer.tapMode,
                  child: SellerTabsScreen(theme: theme, tabs: tabs)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: EmmaUiAnchorTarget(
                  anchorKey: SellerEmmaAnchors.advertisementsGrid.anchorKey,

                  spec: SellerEmmaAnchors.advertisementsGrid,
                  runtimeMode: SellerEmmaAnchors.advertisementsGrid.runtimeMode,
                  tapMode: SellerEmmaAnchors.advertisementsGrid.tapMode,
                  child: SellerAdvertisementsWidget(
                    grid: grid,
                    advertisements: seller.advertisements?.results ?? [],
                    filterType: AdvertisementFilterType.all,
                  ),
                ),
              ),
              SizedBox(height: 60.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBox(BuildContext context, String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: theme.textColor,
            fontSize: 17.sp,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: theme.textColor,
            fontSize: 15.sp,
          ),
        ),
      ],
    );
  }
}
