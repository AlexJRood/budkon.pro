import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/screens/feed_pop/providers/fav/provider.dart';
import 'package:network_monitoring/screens/feed_pop/providers/hide/provider.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:network_monitoring/pie_menu/network_monitoring.dart';

class MobileLikeSectionFeedPopNM extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  final dynamic adFeedPop;
  final WidgetRef ref;
  final BuildContext context;

  const MobileLikeSectionFeedPopNM({
    super.key,
    required this.adFeedPop,
    required this.ref,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 61.0,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
          ),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed: () {
                ref.read(navigationService).beamPop();
              },
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: FutureBuilder<bool>(
                  future: ref
                      .read(nMFavAdsProvider.notifier)
                      .isFavoriteNM(adFeedPop.id),
                  builder: (context, snapshot) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 40,
                          child: Icon(
                            Icons.phone,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text('call'.tr,
                            style: AppTextStyles.interMedium.copyWith(
                                fontSize: 8,
                                color: AppColors.light.withAlpha((255 * 0.35).toInt())))
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed: () {
                ref.read(navigationService).beamPop();
              },
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: FutureBuilder<bool>(
                  future: ref
                      .read(nMFavAdsProvider.notifier)
                      .isFavoriteNM(adFeedPop.id),
                  builder: (context, snapshot) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 40,
                          child: Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text('Message'.tr,
                            style: AppTextStyles.interMedium.copyWith(
                                fontSize: 8,
                                color: AppColors.light.withAlpha((255 * 0.35).toInt())))
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed: () {
                handleShareActionNM(adFeedPop.id, context);
              },
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.share,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text('Share'.tr,
                        style: AppTextStyles.interMedium.copyWith(
                            fontSize: 8,
                            color: AppColors.light.withAlpha((255 * 0.35).toInt())))
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed: () {
              handleFavoriteActionNM(ref, adFeedPop.id, null, null, context,);
              },
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: FutureBuilder<bool>(
                  future: ref.read(nMHideAdsProvider(const HideScope()).notifier).isInHidePrefs(adFeedPop.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Column(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  snapshot.data!
                                      ? FontAwesomeIcons.eye
                                      : FontAwesomeIcons.eyeSlash,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text('hide'.tr,
                              style: AppTextStyles.interMedium.copyWith(
                                  fontSize: 8,
                                  color: AppColors.light.withAlpha((255 * 0.35).toInt())))
                        ],
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed: () {
              handleFavoriteActionNM(ref, adFeedPop.id, null, null, context,);
              },
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: FutureBuilder<bool>(
                  future: ref
                      .watch(nMFavAdsProvider.notifier)
                      .isFavoriteNM(adFeedPop.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Column(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  snapshot.data!
                                      ? FontAwesomeIcons.solidHeart
                                      : FontAwesomeIcons.heart,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text('Favorite'.tr,
                              style: AppTextStyles.interMedium.copyWith(
                                  fontSize: 8,
                                  color: AppColors.light.withAlpha((255 * 0.35).toInt())))
                        ],
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 20,
          ),
        ],
      ),
    );
  }
}
