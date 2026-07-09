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
  final WidgetRef ref;
  final BuildContext context;

  const FullLikeSectionFeedPop({
    super.key,
    required this.adFeedPop,
    required this.ref,
    required this.context,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

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
              future: ref
                  .watch(favAdsProvider.notifier)
                  .isFavorite(adFeedPop.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Add to favorites'.tr,
                          style: AppTextStyles.interMedium.copyWith(
                            fontSize: 12,
                            color: theme.textColor,
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
                                color: theme.textColor,
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
              future: ref.watch(hideAdsProvider.notifier).isHide(adFeedPop.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'hide'.tr,
                          style: AppTextStyles.interMedium.copyWith(
                            fontSize: 12,
                            color: theme.textColor,
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
                                color: theme.textColor,
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
                    'share'.tr,
                    style: AppTextStyles.interMedium.copyWith(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  SizedBox(
                    width: 40,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.share, color: theme.textColor),
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
