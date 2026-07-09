import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:portal/screens/feed/provider/feed_pop/fav_provider.dart';
import 'package:portal/screens/feed/provider/feed_pop/hide_provider.dart';
import 'package:portal/pie_menu/feed.dart';

class MidLikeSectionFeedPop extends ConsumerWidget {
  final dynamic adFeedPop;

  const MidLikeSectionFeedPop({
    super.key,
    required this.adFeedPop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isFavorite = ref.watch(favAdsProvider).maybeWhen(
      data: (list) => list.any((ad) => ad.id == adFeedPop),
      orElse: () => false,
    );

    final isHidden = ref.watch(hideAdsProvider).maybeWhen(
      data: (list) => list.any((ad) => ad.id == adFeedPop),
      orElse: () => false,
    );

    return Column(
      children: [
        _iconButton(
          context: context,
          icon: isFavorite
              ? FontAwesomeIcons.heartCircleCheck
              : FontAwesomeIcons.heart,
          onPressed: () {
            handleFavoriteAction(ref, adFeedPop, context);
          },
            theme: theme
        ),
        const SizedBox(height: 5),
        _iconButton(
          context: context,
          icon:
          isHidden ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
          onPressed: () {
            handleHideAction(ref, adFeedPop, context);
          },
            theme: theme
        ),
        const SizedBox(height: 5),
        _iconButton(
          context: context,
          icon: FontAwesomeIcons.share,
          onPressed: () {
            handleShareAction(adFeedPop, context);
          },
          theme: theme
        ),
      ],
    );
  }

  Widget _iconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeColors theme
  }) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        style: elevatedButtonStyleRounded10,
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: FaIcon(icon, color: theme.textColor),
                ),
              ),
            ],
          ),
        ),
      ),
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
