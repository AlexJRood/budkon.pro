import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:portal/screens/feed/provider/feed_pop/fav_provider.dart';
import 'package:portal/screens/feed/provider/feed_pop/hide_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

class FullLikeSectionFeedPop extends ConsumerWidget {
  final dynamic adFeedPop;

  const FullLikeSectionFeedPop({super.key, required this.adFeedPop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final isFavorite = ref
        .watch(favAdsProvider)
        .maybeWhen(
          data: (ads) => ads.any((ad) => ad.id == adFeedPop.id),
          orElse: () => false,
        );

    final isHidden = ref
        .watch(hideAdsProvider)
        .maybeWhen(
          data: (ads) => ads.any((ad) => ad.id == adFeedPop.id),
          orElse: () => false,
        );

    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10WithPaddingVertical,
            onPressed: () {
              handleFavoriteAction(ref, adFeedPop, context);
            },
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Dodaj do ulubionych'.tr,
                    style: AppTextStyles.interMedium.copyWith(
                      fontSize: 12,
                      color: theme.popUpIconColor.withAlpha(
                        (255 * 0.35).toInt(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        FaIcon(
                          isFavorite
                              ? FontAwesomeIcons.heartCircleCheck
                              : FontAwesomeIcons.heart,
                          color: theme.popUpIconColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10WithPaddingVertical,
            onPressed: () {
              handleHideAction(ref, adFeedPop, context);
            },
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ukryj'.tr,
                    style: AppTextStyles.interMedium.copyWith(
                      fontSize: 12,
                      color: theme.popUpIconColor.withAlpha(
                        (255 * 0.35).toInt(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  SizedBox(
                    width: 40,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          isHidden
                              ? FontAwesomeIcons.eyeSlash
                              : FontAwesomeIcons.eye,
                          color: theme.popUpIconColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10WithPaddingVertical,
            onPressed: () {
              handleShareAction(adFeedPop, context);
            },
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Udostępnij'.tr,
                    style: AppTextStyles.interMedium.copyWith(
                      fontSize: 12,
                      color: theme.popUpIconColor.withAlpha(
                        (255 * 0.35).toInt(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  SizedBox(
                    width: 40,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.share,
                          color: theme.popUpIconColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

extension ContextExtension on BuildContext {
  void showSnackBarLikeSection(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
