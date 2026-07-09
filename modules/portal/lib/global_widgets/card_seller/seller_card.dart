import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/global_providers/seller_provider.dart';
import 'package:core/platform/url.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

class SellerCard extends ConsumerWidget {
  final int sellerId;
  final VoidCallback onTap;

  const SellerCard({super.key, required this.sellerId, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerFuture = ref.watch(sellerProviderFamily(sellerId));
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = screenWidth / 1920 * 180;
    itemWidth = max(120.0, min(itemWidth, 180.0));
    double minBaseTextSize = 12;
    double maxBaseTextSize = 16;
    double dynamicFontSize =
        minBaseTextSize +
        (itemWidth - 120) / (180 - 120) * (maxBaseTextSize - minBaseTextSize);
    dynamicFontSize = max(
      minBaseTextSize,
      min(dynamicFontSize, maxBaseTextSize),
    );
    final theme = ref.watch(themeColorsProvider);

    return ElevatedButton(
      style: elevatedButtonStyleRounded20,
      onPressed: onTap,
      child: sellerFuture.when(
        data: (seller) {
          debugPrint(
            'Mahdi: When: ${seller?.avatarUrl ?? 'Nothing'} : ${seller?.firstName ?? 'Nothing'} : ${seller?.lastName ?? 'Nothing'} : ',
          );

          final avatarUrl = resolveAvatarUrl(seller?.avatarUrl);
          final firstName = seller?.firstName ?? '';
          final lastName = seller?.lastName ?? '';

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child:
                avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')
                        ? CachedNetworkAvatar(
                          avatarUrl: avatarUrl,
                          itemWidth: itemWidth - 10,
                        )
                        : AssetAvatar(
                          assetPath: avatarUrl,
                          itemWidth: itemWidth - 10,
                        ),
              ),
              const SizedBox(height: 10),
              if (firstName.isNotEmpty) ...[
                Text(
                  '$firstName $lastName',
                  style: AppTextStyles.interMedium.copyWith(
                    fontSize: dynamicFontSize,
                    color: theme.textColor,
                  ),
                ),
              ] else ...[
                Text(
                  'login_to_view'.tr,
                  style: AppTextStyles.interMedium.copyWith(
                    fontSize: dynamicFontSize - 4,
                    color: theme.textColor,
                  ),
                ),
                Text(
                  'seller_details'.tr,
                  style: AppTextStyles.interMedium.copyWith(
                    fontSize: dynamicFontSize - 4,
                    color: theme.textColor,
                  ),
                ),
              ],
              const SizedBox(height: 5),
            ],
          );
        },
        loading:
            () => Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: ShimmerPlaceholder(
                    width: itemWidth,
                    height: itemWidth,
                  ),
                ),
                const SizedBox(height: 10),
                ShimmerPlaceholder(
                  width: itemWidth * 0.8,
                  height: dynamicFontSize + 1,
                ),
                const SizedBox(height: 5),
                ShimmerPlaceholder(
                  width: itemWidth * 0.8,
                  height: dynamicFontSize + 1,
                ),
              ],
            ),
        error: (error, stackTrace) => Text('${'Error'.tr}: $error'.tr),
      ),
    );
  }
  resolveAvatarUrl(String? url) {
    final value = url?.trim();

    if (value == null || value.isEmpty) {
      return 'assets/images/default_user_avatar.jpg';
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    return 'assets/images/default_user_avatar.jpg';
  }

}

/// Widget to display a cached network image avatar.
class CachedNetworkAvatar extends StatelessWidget {
  final String avatarUrl;
  final double itemWidth;

  const CachedNetworkAvatar({
    super.key,
    required this.avatarUrl,
    required this.itemWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: avatarUrl,
        width: itemWidth,
        height: itemWidth,
        fit: BoxFit.cover,
        placeholder:
            (context, url) =>
                ShimmerPlaceholder(width: itemWidth, height: itemWidth),
        errorWidget: (context, url, error) => AssetAvatar(
          assetPath: 'assets/images/default_user_avatar.jpg',
          itemWidth: itemWidth,
        ),
      ),
    );
  }
}

/// Widget to display an asset image avatar.
class AssetAvatar extends StatelessWidget {
  final String assetPath;
  final double itemWidth;

  const AssetAvatar({
    super.key,
    required this.assetPath,
    required this.itemWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: itemWidth,
      height: itemWidth,
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(assetPath), fit: BoxFit.cover),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
