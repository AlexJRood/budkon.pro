import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:portal/screens/feed/provider/feed_pop/fav_provider.dart';
import 'package:portal/screens/feed/provider/feed_pop/hide_provider.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

class FullLikeSectionFeedPop extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  final dynamic adFeedPop;
  final WidgetRef ref;
  final BuildContext context;

  const FullLikeSectionFeedPop({
    super.key,
    required this.adFeedPop,
    required this.ref,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: () {
              handleFavoriteAction(ref, adFeedPop, context);
            },
            child: FutureBuilder<bool>(
              future: ref.watch(favAdsProvider.notifier).isFavorite(adFeedPop),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'add_to_favorites_button'.tr,
                          style: AppTextStyles.interMedium.copyWith(
                            fontSize: 12,
                            color: AppColors.light.withAlpha(
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
                                snapshot.data!
                                    ? FontAwesomeIcons.heartCircleCheck
                                    : FontAwesomeIcons.heart,
                                color: AppColors.light,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 15),
        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: () {
              handleHideAction(ref, adFeedPop, context);
            },
            child: FutureBuilder<bool>(
              future: ref.watch(hideAdsProvider.notifier).isHide(adFeedPop),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'hide_button'.tr,
                          style: AppTextStyles.interMedium.copyWith(
                            fontSize: 12,
                            color: AppColors.light.withAlpha(
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
                                snapshot.data!
                                    ? FontAwesomeIcons.eyeSlash
                                    : FontAwesomeIcons.eye,
                                color: AppColors.light,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 15),
        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: () {
              handleShareAction(adFeedPop, context);
            },
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'share_button'.tr,
                    style: AppTextStyles.interMedium.copyWith(
                      fontSize: 12,
                      color: AppColors.light.withAlpha((255 * 0.35).toInt()),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const SizedBox(
                    width: 40,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.share, color: AppColors.light),
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
