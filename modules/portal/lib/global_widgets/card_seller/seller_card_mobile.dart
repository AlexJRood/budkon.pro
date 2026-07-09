import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/platform/url.dart';
import 'package:core/theme/design.dart';
import 'package:portal/global_providers/seller_provider.dart';

class SellerCardMobile extends ConsumerWidget {
  final int sellerId;
  final VoidCallback onTap;

  const SellerCardMobile({
    super.key,
    required this.sellerId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerFuture = ref.watch(sellerProviderFamily(sellerId));
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 3;
    final dynamicFontSize = screenWidth < 400 ? 16.0 : 20.0;
    final theme = ref.watch(themeColorsProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: sellerFuture.when(
        data: (seller) {
          final rawAvatarUrl = seller?.avatarUrl?.trim() ?? '';
          final avatarUrl = rawAvatarUrl.isNotEmpty
              ? rawAvatarUrl
              : 'assets/images/default_user_avatar.jpg';

          final firstName = seller?.firstName ?? '';
          final lastName = seller?.lastName ?? '';

          final avatarSize = screenWidth < 400 ? itemWidth * 0.8 : itemWidth;
          final cacheSize =
          (avatarSize * MediaQuery.of(context).devicePixelRatio)
              .round()
              .clamp(80, 512);

          Widget defaultAvatar() {
            return Image.asset(
              'assets/images/default_user_avatar.jpg',
              width: avatarSize,
              height: avatarSize,
              fit: BoxFit.cover,
              cacheWidth: cacheSize,
              filterQuality: FilterQuality.low,
              gaplessPlayback: true,
            );
          }

          Widget avatar;

          if (avatarUrl.startsWith(URLs.httpOrHttps)) {
            avatar = Image.network(
              avatarUrl,
              width: avatarSize,
              height: avatarSize,
              fit: BoxFit.cover,
              cacheWidth: cacheSize,
              filterQuality: FilterQuality.low,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  return child;
                }

                return defaultAvatar();
              },
              errorBuilder: (_, error, stack) {
                debugPrint('Seller avatar error: $error');
                return defaultAvatar();
              },
            );
          } else {
            avatar = Image.asset(
              avatarUrl,
              width: avatarSize,
              height: avatarSize,
              fit: BoxFit.cover,
              cacheWidth: cacheSize,
              filterQuality: FilterQuality.low,
              gaplessPlayback: true,
              errorBuilder: (_, error, stack) {
                debugPrint('Seller asset avatar error: $error');
                return defaultAvatar();
              },
            );
          }

          return RepaintBoundary(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: avatarSize,
                      height: avatarSize,
                      child: avatar,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (firstName.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          '$firstName $lastName',
                          style: AppTextStyles.interSemiBold.copyWith(
                            fontSize: dynamicFontSize,
                            color: theme.textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'property_interest_question'.tr,
                          style: AppTextStyles.interRegular.copyWith(
                            fontSize: dynamicFontSize / 3 * 2,
                            color: theme.textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'write_to_me'.tr,
                          style: AppTextStyles.interRegular.copyWith(
                            fontSize: dynamicFontSize / 3 * 2,
                            color: theme.textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => SizedBox(
          height: 80,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: theme.popUpIconColor,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
        error: (error, stackTrace) => Text('${'Error'.tr}: $error'.tr),
      ),
    );
  }
}