import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';

import 'package:get/get_utils/get_utils.dart';

import '../../../filter_landing_page/components/filters_components.dart';


class HereToHelpWidget extends ConsumerWidget {
  final double paddingDynamic;

  const HereToHelpWidget({
    super.key,
    required this.paddingDynamic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final dynamicVerticalPadding = paddingDynamic / 2;

    void goToFeedWithOfferType(String offerType) {
      final nav = ref.read(navigationService);

      ref.read(filterCacheProvider.notifier).clearFilters();
      ref.read(filterButtonProvider.notifier).clearUiFilters();

      ref
          .read(filterButtonProvider.notifier)
          .updateFilter('offer_type', [offerType]);

      ref
          .read(filterCacheProvider.notifier)
          .addFilter('offer_type', offerType);

      nav.pushNamedScreen('/feed');
    }

    final cards = <_LandingHelpCardData>[
      _LandingHelpCardData(
        title: 'landing_here_to_help_buy_title'.tr,
        intro: 'landing_here_to_help_buy_intro'.tr,
        bulletPoints: [
          'landing_here_to_help_buy_bullet_search'.tr,
          'landing_here_to_help_buy_bullet_compare'.tr,
          'landing_here_to_help_buy_bullet_ai'.tr,
        ],
        buttonText: 'landing_here_to_help_buy_button'.tr,
        onTap: () => goToFeedWithOfferType('buy'),
      ),
      _LandingHelpCardData(
        title: 'landing_here_to_help_sell_title'.tr,
        intro: 'landing_here_to_help_sell_intro'.tr,
        bulletPoints: [
          'landing_here_to_help_sell_bullet_publish'.tr,
          'landing_here_to_help_sell_bullet_price'.tr,
          'landing_here_to_help_sell_bullet_manage'.tr,
        ],
        buttonText: 'landing_here_to_help_sell_button'.tr,
        onTap: () {
          ref.read(navigationHistoryProvider.notifier).addPage(Routes.add);
          ref.read(navigationService).pushNamedReplacementScreen(Routes.add);
        },
      ),
      _LandingHelpCardData(
        title: 'landing_here_to_help_rent_title'.tr,
        intro: 'landing_here_to_help_rent_intro'.tr,
        bulletPoints: [
          'landing_here_to_help_rent_bullet_filter'.tr,
          'landing_here_to_help_rent_bullet_match'.tr,
          'landing_here_to_help_rent_bullet_ai'.tr,
        ],
        buttonText: 'landing_here_to_help_rent_button'.tr,
        onTap: () => goToFeedWithOfferType('rent'),
      ),
    ];

    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: paddingDynamic,
            vertical: dynamicVerticalPadding,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'landing_here_to_help_title'.tr,
                  style: AppTextStyles.libreCaslonHeading.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 34),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isStacked = constraints.maxWidth < 900;

                    if (isStacked) {
                      return Column(
                        children: [
                          for (int i = 0; i < cards.length; i++) ...[
                            InfoCardWidget(
                              title: cards[i].title,
                              intro: cards[i].intro,
                              bulletPoints: cards[i].bulletPoints,
                              buttonText: cards[i].buttonText,
                              onTap: cards[i].onTap,
                              fillHeight: false,
                            ),
                            if (i != cards.length - 1)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 26,
                                ),
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: theme.textColor.withOpacity(0.25),
                                ),
                              ),
                              
                          ],
                        ],
                      );
                    }

                    return ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 330,
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (int i = 0; i < cards.length; i++) ...[
                              Expanded(
                                child: InfoCardWidget(
                                  title: cards[i].title,
                                  intro: cards[i].intro,
                                  bulletPoints: cards[i].bulletPoints,
                                  buttonText: cards[i].buttonText,
                                  onTap: cards[i].onTap,
                                  fillHeight: true,
                                ),
                              ),
                              if (i != cards.length - 1)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: VerticalDivider(
                                    width: 1,
                                    thickness: 1.5,
                                    color: theme.textColor.withOpacity(0.35),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LandingHelpCardData {
  final String title;
  final String intro;
  final List<String> bulletPoints;
  final String buttonText;
  final VoidCallback? onTap;

  const _LandingHelpCardData({
    required this.title,
    required this.intro,
    required this.bulletPoints,
    required this.buttonText,
    required this.onTap,
  });
}

class InfoCardWidget extends ConsumerWidget {
  final String title;
  final String intro;
  final List<String> bulletPoints;
  final String buttonText;
  final VoidCallback? onTap;
  final bool fillHeight;

  const InfoCardWidget({
    super.key,
    required this.title,
    required this.intro,
    required this.bulletPoints,
    required this.buttonText,
    required this.onTap,
    required this.fillHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final accentColor = CustomColors.landingPageSubHeadingColor(context, ref);

    return Column(
      mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.libreCaslonHeading.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 2,
          width: 62,
          color: accentColor,
        ),
        const SizedBox(height: 24),
        Text(
          intro,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.35,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 18),
        Column(
          children: bulletPoints
              .map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BulletPoint(
                    text: point,
                    dotColor: accentColor,
                    textColor: theme.textColor,
                  ),
                ),
              )
              .toList(),
        ),

        // Important:
        // On desktop this pushes all buttons to the bottom,
        // so every card looks equal even if the text has different length.
        if (fillHeight)
          const Spacer()
        else
          const SizedBox(height: 18),

        _LandingActionButton(
          text: buttonText,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  final Color dotColor;
  final Color textColor;

  const _BulletPoint({
    required this.text,
    required this.dotColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 7),
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _LandingActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _LandingActionButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.redBeige,
                  AppColors.redBeige,
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}