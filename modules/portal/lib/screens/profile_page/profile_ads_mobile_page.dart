import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/screens/profile_page/providers/profile_ad_provider.dart';
import 'package:portal/pie_menu/profile_page/feed_your_ads.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/lottie.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:core/platform/navigation_service.dart';

import 'package:core/user/user_card_mobile.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';

import 'package:get/get_utils/get_utils.dart';

class ProfileAdsMobilePage extends ConsumerWidget {
  const ProfileAdsMobilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScrollController scrollController = ScrollController();
    NumberFormat customFormat = NumberFormat.decimalPattern('fr');
    final theme = ref.read(themeColorsProvider);
    final userAsyncValue = ref.watch(userProvider);

    return GestureDetector(
      onPanUpdate: (details) {
        scrollController.jumpTo(scrollController.offset - details.delta.dy);
      },
      child: ref
          .watch(yourAdsFilterProvider)
          .when(
            data: (yourAdvertisements) {
              if (yourAdvertisements.isEmpty) {
                return Column(
                  children: [
                    AppLottie.noResults(),
                    Text(
                     'you_have_no_active_listings'.tr,
                      style: AppTextStyles.interLight16.copyWith(
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(navigationService)
                            .pushNamedReplacementScreen(Routes.add);
                      },
                      child: Text(
                        'Add An Ad'.tr,
                        style: AppTextStyles.interLight.copyWith(
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 15),
                          userAsyncValue.when(
                            data: (userData) {
                              if (userData != null) {
                                try {
                                  final int userId = int.parse(userData.userId);
                                  return UserCardMobile(
                                    userId: userId,
                                    onTap: () {
                                      // Handle onTap
                                    },
                                  );
                                } catch (e) {
                                  return Text('Invalid userId format'.tr);
                                }
                              } else {
                                return const SizedBox.shrink(); // Use SizedBox.shrink() when userData is null
                              }
                            },
                            loading:
                                () => const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: AppColors.light,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            error: (error, stack) => Text('Error: $error'.tr),
                          ),
                          const SizedBox(height: 45),
                          Text(
                            'my_listings'.tr,
                            style: AppTextStyles.interMedium18,
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.0,
                          mainAxisSpacing: 0.0,
                          crossAxisSpacing: 0.0,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final yourAd = yourAdvertisements[index];
                      final keyTag =
                          'yourAdKey${yourAd.id}-${UniqueKey().toString()}';

                      final mainImageUrl =
                          yourAd.images.isNotEmpty
                              ? yourAd.images[0]
                              : 'default_image_url';
                      String formattedPrice = customFormat.format(yourAd.price);

                      return PieMenu(
                        theme: PieTheme.of(context).copyWith(
                          overlayColor:
                              (() {
                                final theme = ref.watch(themeColorsProvider);
                                final bool uiIsDark =
                                    theme.textColor.computeLuminance() > 0.5;

                                final base =
                                    uiIsDark ? Colors.black : Colors.white;
                                return base.withValues(alpha: 0.70);
                              })(),
                        ),
                        onPressedWithDevice: (kind) {
                          if (kind == PointerDeviceKind.touch) {
                            ref
                                .read(navigationService)
                                .pushNamedScreen(
                                  '${Routes.profile}/${yourAd.id}',
                                  data: {'tag': keyTag, 'ad': yourAd},
                                );
                          }
                        },
                        actions: buildPieMenuYourAds(ref, yourAd, context),
                        child: Hero(
                          tag: keyTag,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(0),
                            child: Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: Image.network(
                                      mainImageUrl,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'No picture'.tr,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 2,
                                  bottom: 2,
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                      top: 5,
                                      bottom: 5,
                                      right: 8,
                                      left: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(
                                        (255 * 0.4).toInt(),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${yourAd.city}, ${yourAd.street}',
                                          style: AppTextStyles.interRegular
                                              .copyWith(
                                                color: AppColors.white,
                                                fontSize: 10,
                                                shadows: [
                                                  Shadow(
                                                    offset: const Offset(
                                                      5.0,
                                                      5.0,
                                                    ),
                                                    blurRadius: 10.0,
                                                    color: Colors.black
                                                        .withAlpha(
                                                          (255 * 1).toInt(),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                        ),
                                        Text(
                                          '$formattedPrice ${yourAd.currency}',
                                          style: AppTextStyles.interBold
                                              .copyWith(
                                                color: AppColors.white,
                                                fontSize: 14,
                                                shadows: [
                                                  Shadow(
                                                    offset: const Offset(
                                                      5.0,
                                                      5.0,
                                                    ),
                                                    blurRadius: 10.0,
                                                    color: Colors.black
                                                        .withAlpha(
                                                          (255 * 1).toInt(),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: yourAdvertisements.length),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 55)),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stack) =>
                    Center(child: Text('${'An error occurred'.tr}: $error'.tr)),
          ),
    );
  }
}
