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
          data: (list) => list.any((ad) => ad.id == adFeedPop.id),
          orElse: () => false,
        );

    final isHidden = ref
        .watch(hideAdsProvider)
        .maybeWhen(
          data: (list) => list.any((ad) => ad.id == adFeedPop.id),
          orElse: () => false,
        );

    return Column(
      children: [
        _actionButton(
          context,
          label: isFavorite ? 'remove_from_favorites'.tr : 'add_to_favorites'.tr,
          icon:
              isFavorite
                  ? FontAwesomeIcons.heartCircleCheck
                  : FontAwesomeIcons.heart,
          onPressed: () => handleFavoriteAction(ref, adFeedPop, context),
          theme: theme,
        ),
        const SizedBox(height: 15),
        _actionButton(
          context,
          label: isHidden ? 'show_ad'.tr : 'hide_ad'.tr,
          icon: isHidden ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
          onPressed: () => handleHideAction(ref, adFeedPop, context),
          theme: theme,
        ),
        const SizedBox(height: 15),
        _actionButton(
          context,
          label: 'Share'.tr,
          icon: FontAwesomeIcons.share,
          onPressed: () => handleShareAction(adFeedPop, context),
          theme: theme,
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeColors theme,
  }) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        style: elevatedButtonStyleRounded10.copyWith(
          iconColor: WidgetStateProperty.all(theme.textColor),
        ),
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.interMedium.copyWith(
                    fontSize: 12,
                    color: theme.textColor,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Center(child: FaIcon(icon, color: theme.textColor)),
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
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
