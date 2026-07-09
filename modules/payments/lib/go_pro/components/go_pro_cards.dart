import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/apptheme.dart';

// comments in EN per your style guide
class PremiumCard extends ConsumerWidget {
  final double mainContainerHeight;
  final String title;
  final String? crossedOutPriceText; // e.g. old price text like "$79.99"
  final String currentPriceText; // e.g. "$99.99"
  final String pricingDescription; // e.g. "/month per user"
  final List<String> features;
  final bool ispremium;
  final bool mostPopular;
  final VoidCallback? onPressed;
  final String? topRibbonText; // e.g. "Roczna zniżka"
  final double width;

  const PremiumCard({
    super.key,
    this.ispremium = false,
    required this.onPressed,
    required this.mainContainerHeight,
    required this.title,
    this.crossedOutPriceText,
    required this.currentPriceText,
    required this.pricingDescription,
    required this.features,
    required this.mostPopular,
    this.topRibbonText,
    this.width = 300,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 25,
              bottom: 2,
              right: 2,
              left: 2,
            ),
            decoration: BoxDecoration(
              color: mostPopular 
                    ? theme.dashboardBoarder 
                    : theme.dashboardContainer, 
              borderRadius: BorderRadius.circular(16),
            ),
            height: mainContainerHeight,
            width: width,
            child: Container(
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ispremium
                      ? Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.themeColor,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(5),
                              bottomRight: Radius.circular(5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: const Icon(
                            Icons.safety_check_sharp,
                            color: AppColors.white,
                          ),
                        ),
                      )
                      : const SizedBox(height: 30),

                  // Title
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Prices row (left = crossed out, right = current)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 10),
                      if (crossedOutPriceText != null) ...[
                        Flexible(
                          child: Text(
                            crossedOutPriceText!,
                            style: TextStyle(
                              color: Theme.of(context).iconTheme.color,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 20,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          currentPriceText,
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Description under price
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          pricingDescription,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // CTA
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.themeColor,
                            foregroundColor: theme.themeTextColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: onPressed,
                          child: Text(
                            'get_started_button'.tr,
                            style: TextStyle(
                              color: theme.themeTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(color: Theme.of(context).iconTheme.color),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const SizedBox(width: 10),
                      Text(
                        'features_you_will_love_label'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).iconTheme.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        features.map((f) => _featureItem(f, context)).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Top ribbon text (e.g. yearly deal)
          if (topRibbonText != null)
            Positioned(
              top: 5,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  topRibbonText!.tr,
                  style: TextStyle(
                    color:theme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _featureItem(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          AppIcons.check(
            color: Theme.of(context).iconTheme.color,
            height: 18,
            width: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).iconTheme.color,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class RealEstateGoalsWidget extends ConsumerWidget {
  final bool isMobile;
  const RealEstateGoalsWidget({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, ref) {
    return Container(
      height: isMobile?240:160,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CustomBackgroundGradients.appBarGradientcustom(context, ref),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isMobile) ...[const SizedBox(height: 80)],
          Text(
            'real_estate_goals_title'.tr,
            style: TextStyle(
              color: Theme.of(context).iconTheme.color,
              fontSize: isMobile?16:24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'real_estate_goals_subtitle'.tr,
            style: TextStyle(
              color: Theme.of(
                context,
              ).iconTheme.color!.withAlpha((255 * 0.8).toInt()),
              fontSize: isMobile?14:16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PremiumCardWide extends ConsumerWidget {
  final String title;
  final String? crossedOutPriceText;
  final String currentPriceText;
  final String pricingDescription;
  final List<String> features;
  final bool ispremium;
  final bool mostPopular;
  final VoidCallback? onPressed;
  final String? topRibbonText;

  const PremiumCardWide({
    super.key,
    this.ispremium = false,
    required this.onPressed,
    required this.title,
    this.crossedOutPriceText,
    required this.currentPriceText,
    required this.pricingDescription,
    required this.features,
    required this.mostPopular,
    this.topRibbonText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        return Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.only(
                  top: 25,
                  bottom: 2,
                  right: 2,
                  left: 2,
                ),
                decoration: BoxDecoration(
                  color:
                      mostPopular ? theme.themeColor : theme.dashboardBoarder,
                  borderRadius: BorderRadius.circular(16),
                ),
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child:
                      isNarrow
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(theme, context),
                              const SizedBox(height: 16),
                              _buildFeatures(context),
                              const SizedBox(height: 16),
                              _buildCTA(context),
                            ],
                          )
                          : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left side: Title, Price, Description
                              Expanded(flex: 1, child: _buildHeader(theme, context)),

                              // Divider
                              Container(
                                height: 100,
                                width: 1,
                                color: theme.textColor.withAlpha(50),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                              ),

                              // Middle: Features
                              Expanded(flex: 2, child: _buildFeatures(context)),

                              // Right side: CTA
                              _buildCTA(context),
                            ],
                          ),
                ),
              ),

              // Top ribbon text
              if (topRibbonText != null)
                Positioned(
                  top: 5,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      topRibbonText!.tr,
                      style: TextStyle(
                        color: mostPopular ? AppColors.white : theme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeColors theme, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ispremium)
          Container(
            decoration: BoxDecoration(
              color: theme.themeColor,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(bottom: 8),
            child: const Icon(
              Icons.safety_check_sharp,
              color: AppColors.white,
              size: 20,
            ),
          ),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (crossedOutPriceText != null) ...[
              Text(
                crossedOutPriceText!,
                style: TextStyle(
                  color: Theme.of(context).iconTheme.color,
                  decoration: TextDecoration.lineThrough,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              currentPriceText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ],
        ),
        Text(
          pricingDescription,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Funkcje, które pokochasz:'.tr,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).iconTheme.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 20,
          runSpacing: 10,
          children: features.map((f) => _featureItem(f, context)).toList(),
        ),
      ],
    );
  }

  Widget _buildCTA(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: undefined_identifier
    final themeColors = theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light; // Placeholder logic
    // Actually I should get themeColors from ref but this is a helper. 
    // Let's just use the context theme or pass themeColors.
    
    return Consumer(builder: (context, ref, child) {
      final t = ref.watch(themeColorsProvider);
      return SizedBox(
        width: 150,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: t.themeColor,
            foregroundColor: t.themeTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: onPressed,
          child: Text(
            'Zaczynamy'.tr,
            style: TextStyle(
              color: t.themeTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }

  Widget _featureItem(String text, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcons.check(
          color: Theme.of(context).iconTheme.color,
          height: 18,
          width: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).iconTheme.color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
