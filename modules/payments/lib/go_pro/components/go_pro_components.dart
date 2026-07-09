import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:payments/emma/anchores/payments_emma_anchors.dart';
import 'package:payments/models/stripe_models.dart';
import 'package:payments/provider/checkout_pc_provider.dart';
import 'package:payments/provider/plan_provider.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import 'go_pro_cards.dart';

class Tabview extends ConsumerWidget {
  final bool isMobile;
  final bool isTablet;
  const Tabview({super.key, required this.isMobile, this.isTablet = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    final asyncCategories = ref.watch(categoryTabsProvider);

    return SizedBox(
      height: screenHeight,
      child: asyncCategories.when(
        loading: () => Center(child: AppLottie.loading(size: 450)),
        error: (e, _) => Center(child: Text('${'error_loading_categories'.tr} $e')),
        data: (categories) {
          if (categories.isEmpty) {
            const fallback = <CategoryTab>[
              CategoryTab('agent', 'agent'),
              CategoryTab('Landlord', 'Landlord'),
            ];
            return _buildTabs(theme, fallback, isMobile, isTablet);
          }

          return _buildTabs(theme, categories, isMobile, isTablet);
        },
      ),
    );
  }

  Widget _buildTabs(
    ThemeColors theme,
    List<CategoryTab> categories,
    bool isMobile,
    bool isTablet,
  ) {
    return Center(
      child: DefaultTabController(
        length: categories.length,
        child: Column(
          children: [
            Container(
              color: theme.popupcontainercolor.withAlpha((255 * 0.3).toInt()),
              child: TabBar(
                tabAlignment: TabAlignment.center,
                dividerColor: Colors.transparent,
                unselectedLabelColor: theme.textColor.withAlpha(
                  (255 * 0.6).toInt(),
                ),
                labelColor: theme.textColor,
                indicator: BoxDecoration(
                  color: theme.popupcontainercolor.withAlpha(
                    (255 * 0.5).toInt(),
                  ),
                ),
                isScrollable: true,
                tabs: [
                  for (final c in categories)
                    SizedBox(
                      width: isMobile ? 130 : 160,
                      child: Tab(height: 40, text: c.label),
                    ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final c in categories)
                    SubscriptionPlans(
                      categoryKey: c.key,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionPlans extends ConsumerWidget {
  final String categoryKey; // e.g. "agent", "Landlord"
  final bool isMobile;
  final bool isTablet;
  const SubscriptionPlans({
    super.key,
    required this.categoryKey,
    required this.isMobile,
    this.isTablet = false,
  });

  static const _tierOrder = ['standard', 'premium', 'gold'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interval = ref.watch(billingIntervalProvider);
    final asyncProducts = ref.watch(subscriptionProductsProvider);
    final theme = ref.watch(themeColorsProvider);

    // Pick a price ONLY for the requested interval.
    StripePrice? pickPrice(StripeProduct p, String interval) {
      StripePrice? byInterval(String value) {
        try {
          return p.prices.firstWhere((pr) => pr.interval == value);
        } catch (_) {
          return null;
        }
      }

      if (interval == 'month') {
        return byInterval('month');
      }

      if (interval == 'year') {
        return byInterval('year');
      }

      return null;
    }

    String fmt(StripePrice? pr) {
      if (pr == null) return '--';
      return '${pr.amount.toStringAsFixed(2)} ${pr.currency.toUpperCase()}';
    }

    return asyncProducts.when(
      loading: () => Center(child: AppLottie.loading(size: 450)),
      error: (e, _) => Center(child: Text('${'error_loading_plans'.tr} $e')),
      data: (allProducts) {
        if (allProducts.isEmpty) {
          return Center(
            child: Text('no_subscription_plans_available'.tr),
          );
        }

        final keyNorm = categoryKey.toLowerCase();
        final filtered =
            allProducts.where((p) {
              final cat = (p.category ?? '').toLowerCase();
              return cat == keyNorm;
            }).toList();

        if (filtered.isEmpty) {
          return Center(child: AppLottie.noResults(size: isMobile ? 250 : 450));
        }

        final productsWithPrice =
            filtered.where((p) => pickPrice(p, interval) != null).toList();
        final products = productsWithPrice;

        products.sort((a, b) {
          final at = a.tier?.toLowerCase();
          final bt = b.tier?.toLowerCase();

          final ai = _tierOrder.indexOf(at ?? '');
          final bi = _tierOrder.indexOf(bt ?? '');

          final aUnknown = ai == -1;
          final bUnknown = bi == -1;

          if (aUnknown && bUnknown) {
            return a.name.compareTo(b.name);
          }
          if (aUnknown && !bUnknown) return 1;
          if (!aUnknown && bUnknown) return -1;

          return ai.compareTo(bi);
        });

        final display = products.take(3).toList();
        final noPlansForInterval = display.isEmpty;

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'pay_monthly_label'.tr,
                    style: TextStyle(color: Theme.of(context).iconTheme.color),
                  ),
                  const SizedBox(width: 12),
                  EmmaUiAnchorTarget(
                    anchorKey: PaymentsEmmaAnchors.billingIntervalToggle.anchorKey,

                    spec: PaymentsEmmaAnchors.billingIntervalToggle,
                    runtimeMode: PaymentsEmmaAnchors.billingIntervalToggle.runtimeMode,
                    tapMode: PaymentsEmmaAnchors.billingIntervalToggle.tapMode,
                    child: Switch(
                      activeColor: theme.themeColor,
                      activeTrackColor: theme.dashboardContainer,
                      inactiveThumbColor: theme.themeColorText,
                      inactiveTrackColor: theme.textColor,
                      value: interval == 'year',
                      onChanged:
                          (v) =>
                              ref.read(billingIntervalProvider.notifier).state =
                                  v ? 'year' : 'month',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'pay_yearly_label'.tr,
                    style: TextStyle(color: Theme.of(context).iconTheme.color),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (noPlansForInterval)
                Row(
                  children: [
                    const Spacer(),
                    AppLottie.noResults(size: isMobile ? 250 : 450),
                    const Spacer(),
                  ],
                )
              else if (isTablet || isMobile)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      for (int i = 0; i < display.length; i++) ...[
                        _PlanCard(
                          product: display[i],
                          interval: interval,
                          fmt: fmt,
                          pickPrice: pickPrice,
                          highlight: i == 1,
                          isWide: true,
                          isTablet: isTablet,
                        ),
                        if (i != display.length - 1) const SizedBox(height: 20),
                      ],
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    const Spacer(),
                    for (int i = 0; i < display.length; i++) ...[
                      _PlanCard(
                        product: display[i],
                        interval: interval,
                        fmt: fmt,
                        pickPrice: pickPrice,
                        highlight: i == 1,
                        isTablet: isTablet,
                      ),
                      if (i != display.length - 1) const SizedBox(width: 20),
                    ],
                    const Spacer(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final StripeProduct product;
  final String interval;
  final String Function(StripePrice?) fmt;
  final StripePrice? Function(StripeProduct, String) pickPrice;
  final bool highlight;
  final bool isTablet;
  final bool isWide;

  const _PlanCard({
    required this.product,
    required this.interval,
    required this.fmt,
    required this.pickPrice,
    required this.highlight,
    this.isTablet = false,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = pickPrice(product, interval);

    String tierTitle(StripeProduct p) {
      final t = p.tier?.toLowerCase();
      switch (t) {
        case 'standard':
          return 'Standard';
        case 'premium':
          return 'Premium';
        case 'gold':
          return 'Gold';
        default:
          return p.name;
      }
    }

    final title = tierTitle(product);
    final ribbon = interval == 'year' ? 'yearly_discount_label'.tr : null;

    String anchorKey;
    switch (product.tier?.toLowerCase()) {
      case 'standard':
        anchorKey = PaymentsEmmaAnchors.standardPlanCard.anchorKey;
        break;
      case 'premium':
        anchorKey = PaymentsEmmaAnchors.premiumPlanCard.anchorKey;
        break;
      case 'gold':
        anchorKey = PaymentsEmmaAnchors.goldPlanCard.anchorKey;
        break;
      default:
        anchorKey = PaymentsEmmaAnchors.standardPlanCard.anchorKey;
    }

    final features = product.features.isNotEmpty
        ? product.features
        : <String>[
            'advanced_analytics_feature'.tr,
            'priority_visibility_feature'.tr,
          ];

    Widget cardWidget;

    if (isWide) {
      cardWidget = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: PremiumCardWide(
          ispremium: highlight,
          mostPopular: highlight,
          title: title,
          crossedOutPriceText: null,
          currentPriceText: fmt(price),
          pricingDescription:
              interval == 'month' ? 'per_month_per_user_label'.tr : 'per_year_per_user_label'.tr,
          features: features,
          onPressed:
              price == null
                  ? null
                  : () => _goCheckout(context, ref, product, price),
          topRibbonText: ribbon,
        ),
      );
    } else {
      cardWidget = PremiumCard(
        mainContainerHeight: highlight ? 500 : 450,
        ispremium: highlight,
        mostPopular: highlight,
        title: title,
        width: isTablet ? 250 : 300,
        crossedOutPriceText: null,
        currentPriceText: fmt(price),
        pricingDescription:
            interval == 'month' ? 'per_month_per_user_label'.tr : 'per_year_per_user_label'.tr,
        features: features,
        onPressed:
            price == null
                ? null
                : () => _goCheckout(context, ref, product, price),
        topRibbonText: ribbon,
      );
    }

    return EmmaUiAnchorTarget(
      anchorKey: anchorKey,
      runtimeMode: PaymentsEmmaAnchors.standardPlanCard.runtimeMode,
      tapMode: PaymentsEmmaAnchors.standardPlanCard.tapMode,
      child: cardWidget,
    );
  }

  void _goCheckout(
    BuildContext context,
    WidgetRef ref,
    StripeProduct product,
    StripePrice price,
  ) {
    ref.read(selectedTypeProvider.notifier).state = 'Monthly';
    if (ref.watch(billingIntervalProvider) != 'month') {
      ref.read(selectedTypeProvider.notifier).state = 'Yearly';
    }

    ref
        .read(navigationService)
        .pushNamedScreen("${Routes.checkOut}?price_id=${price.id}");

    ref.read(navigationHistoryProvider.notifier).addPage(Routes.checkOut);
  }
}
