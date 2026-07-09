import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:network_monitoring/screens/feed_pop/providers/fav/provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import '../providers/hide/provider.dart';
import 'package:network_monitoring/pie_menu/network_monitoring.dart';

class MidLikeSectionFeedPopNM extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  final dynamic adFeedPop;
  final WidgetRef ref;
  final BuildContext context;

  const MidLikeSectionFeedPopNM({
    super.key,
    required this.adFeedPop,
    required this.ref,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: () {
              handleFavoriteActionNM(ref, adFeedPop.id, null, null, context,);
            },
            child: FutureBuilder<bool>(
              future: ref
                  .watch(nMFavAdsProvider.notifier)
                  .isFavoriteNM(adFeedPop.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              FaIcon(
                                  snapshot.data!
                                      ? FontAwesomeIcons.heartCircleCheck
                                      : FontAwesomeIcons.heart,
                                  color: theme.textColor),
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
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: () {
              handleHideActionNM(ref, adFeedPop.id, null, null, context);
            },
            child: FutureBuilder<bool>(
              future: ref.read(nMHideAdsProvider(const HideScope()).notifier).isInHidePrefs(adFeedPop.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              FaIcon(
                                  snapshot.data!
                                      ? FontAwesomeIcons.eyeSlash
                                      : FontAwesomeIcons.eye,
                                  color: theme.textColor),
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
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: () {
              handleShareActionNM(adFeedPop.id, context);
            },
            child:  Padding(
              padding: EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
