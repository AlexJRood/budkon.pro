import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:payments/provider/checkout_pc_provider.dart';
import 'package:payments/provider/stripe_provider.dart';
import 'package:payments/models/stripe_models.dart';
import 'package:payments/widgets/plan_selector_widget.dart';
import 'package:payments/widgets/right_payment_section_widget.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class CheckoutPc extends ConsumerStatefulWidget {
  const CheckoutPc({super.key});

  @override
  ConsumerState<CheckoutPc> createState() => _CheckoutPcState();
}

class _CheckoutPcState extends ConsumerState<CheckoutPc> {
  List<FocusNode> checkoutnodes = List.generate(14, (index) => FocusNode());
  // These controllers remain but card details are now entered via Stripe CardField
  final TextEditingController cardNumbercontroller = TextEditingController();
  final TextEditingController promoController = TextEditingController();
  final TextEditingController experyDatecontroller = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  // make GlobalKey stable across rebuilds
  late final GlobalKey<SideMenuState> sideMenuKey;

  // Holds the Stripe Price ID chosen on the plan screen
  String? _selectedPriceId;

  StripePrice? _findPriceById(List<StripeProduct> products, String priceId) {
    for (final p in products) {
      for (final pr in p.prices) {
        if (pr.id == priceId) return pr;
      }
    }
    return null;
  }

  StripeProduct? _findProductForPrice(
      List<StripeProduct> products,
      String priceId,
      ) {
    for (final p in products) {
      for (final pr in p.prices) {
        if (pr.id == priceId) return p;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    checkoutnodes = List.generate(10, (_) => FocusNode());
    sideMenuKey = GlobalKey<SideMenuState>();

    // Load route query param + existing payment methods + products on first build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Read price_id from current navigation path (e.g. /checkout?price_id=xxx)
      try {
        final nav = ref.read(navigationService);
        final currentPath = nav.currentPath;
        final uri = Uri.parse(currentPath);
        final qpPrice = uri.queryParameters['price_id'];
        if (qpPrice != null && qpPrice.isNotEmpty) {
          _selectedPriceId = qpPrice;
          debugPrint('🔗 Checkout selected priceId from URL: $_selectedPriceId');
        }
      } catch (e) {
        debugPrint('Failed to parse price_id from currentPath: $e');
      }

      final notifier = ref.read(stripeProvider.notifier);
      // ensure we have products + saved payment methods
      await notifier.fetchStripeProducts();
      await notifier.fetchSavedPaymentMethods();
      if (notifier.state.paymentMethods.isNotEmpty) {
        ref.read(isAddingNewCardProvider.notifier).state = false;
      }
    });
  }

  @override
  void dispose() {
    cardNumbercontroller.dispose();
    promoController.dispose();
    experyDatecontroller.dispose();
    cvvController.dispose();
    nameController.dispose();
    for (final node in checkoutnodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// On web we **do not** validate card number / expiry / cvv ourselves.
  /// Stripe's CardField handles that. We only validate name (and optionally country).
  bool _validateCardFields(BuildContext context, String? selectedCountry) {
    final name = nameController.text.trim();

    bool isValid = true;

    // Clear previous errors
    ref.read(nameOnCardErrorProvider.notifier).state = null;

    if (name.isEmpty) {
      ref.read(nameOnCardErrorProvider.notifier).state =
          'name_on_card_required_error'.tr;
      isValid = false;
    }

    return isValid;
  }

  /// Opens a dialog where user confirms subscription for a given card+price,
  /// or (if no forced price) chooses a product/price.
  Future<void> _showProductsDialogForMethod(
      BuildContext context,
      SavedPaymentMethod method, {
        String? forcedPriceId,
      }) async {
    final notifier = ref.read(stripeProvider.notifier);

    // Ensure products are loaded
    if (notifier.state.products.isEmpty) {
      await notifier.fetchStripeProducts();
    }

    final products = notifier.state.products;

    if (!mounted) return;

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('no_products_available'.tr)),
      );
      return;
    }

    // If we already know exactly which price to use (from price_id),
    // show a CONFIRMATION dialog with product name + selected type + price.
    if (forcedPriceId != null && forcedPriceId.isNotEmpty) {
      final selectedPrice = _findPriceById(products, forcedPriceId);
      final selectedProduct = _findProductForPrice(products, forcedPriceId);
      final selectedType = ref.read(selectedTypeProvider); // 'Monthly'/'Yearly'

      if (selectedProduct == null && selectedPrice == null) {
        debugPrint(
          '⚠️ forcedPriceId=$forcedPriceId not found in products, falling back to chooser dialog.',
        );
      } else {
        final theme = ref.watch(themeColorsProvider);

        // 🔸 Choose correct price based on selectedType:
        StripePrice? monthly;
        StripePrice? yearly;

        if (selectedProduct != null) {
          for (final pr in selectedProduct.prices) {
            if (pr.interval == 'month' && monthly == null) {
              monthly = pr;
            } else if (pr.interval == 'year' && yearly == null) {
              yearly = pr;
            }
          }
        }

        final bool isYearly = selectedType == 'Yearly'.tr;
        StripePrice? effectivePrice;

        if (isYearly) {
          effectivePrice = yearly ?? monthly ?? selectedPrice;
        } else {
          effectivePrice = monthly ?? yearly ?? selectedPrice;
        }

        // Final ultimate fallback if still null
        effectivePrice ??=
        selectedProduct?.prices.isNotEmpty == true
            ? selectedProduct!.prices.first
            : null;

        if (effectivePrice == null) {
          debugPrint(
            '⚠️ No effective price found for product ${selectedProduct?.id} and type $selectedType',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('no_valid_price_found_for_plan'.tr),
            ),
          );
          return;
        }

        // ✅ use currency from API (no hard-coded $)
        final priceText =
            '${effectivePrice.amount.toStringAsFixed(2)} ${effectivePrice.currency.toUpperCase()}';

        await showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              backgroundColor: theme.adPopBackground,
              title: Text(
                selectedProduct?.name ?? 'selected_plan_label'.tr,
                style: AppTextStyles.interBold.copyWith(color: theme.textColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'plan_type_label'.tr} $selectedType',
                    style: AppTextStyles.interMedium.copyWith(
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${'price_label'.tr} $priceText',
                    style: AppTextStyles.interMedium.copyWith(
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Cancel'.tr,
                    style: AppTextStyles.interMedium.copyWith(
                      color: theme.textColor,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.themeColor,
                    foregroundColor: theme.themeTextColor,
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    debugPrint(
                      '▶️ Subscribing with card ${method.id} and price ${effectivePrice?.id}',
                    );
                    ref.read(isSubmittingProvider.notifier).state = true;
                    try {
                      await ref
                          .read(stripeProvider.notifier)
                          .stripeSubscriptionCreate(
                        context,
                        '${effectivePrice?.id}',
                        method.id,
                      );
                    } finally {
                      if (mounted) {
                        ref.read(isSubmittingProvider.notifier).state = false;
                      }
                    }
                  },
                  child: Text(
                    'Subscribe'.tr,
                    style: AppTextStyles.interMedium.copyWith(
                      color: theme.themeTextColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
        return;
      }
    }

    // Default behavior – show dialog with all products/prices (fallback)
    await showDialog(
      context: context,
      builder: (ctx) {
        final theme = ref.watch(themeColorsProvider);
        return AlertDialog(
          backgroundColor: theme.adPopBackground,
          title: Text(
            'choose_a_plan_title'.tr,
            style: AppTextStyles.interBold.copyWith(color: theme.textColor),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: products
                    .map(
                      (product) => Card(
                    color: theme.popupcontainercolor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: AppTextStyles.interMedium.copyWith(
                              color: theme.textColor,
                            ),
                          ),
                          if (product.description != null &&
                              product.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                bottom: 8.0,
                              ),
                              child: Text(
                                product.description!,
                                style: AppTextStyles.interMedium
                                    .copyWith(color: theme.textColor),
                              ),
                            ),
                          if (product.prices.isEmpty)
                            Text(
                              'no_prices_for_this_product'.tr,
                              style: AppTextStyles.interMedium.copyWith(
                                color: theme.textColor,
                              ),
                            ),
                          for (final price in product.prices)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${price.amount.toStringAsFixed(2)} ${price.currency.toUpperCase()}',
                                style: AppTextStyles.interMedium
                                    .copyWith(color: theme.textColor),
                              ),
                              subtitle: Text(
                                price.interval != null ? price.interval! : '',
                                style: AppTextStyles.interMedium
                                    .copyWith(color: theme.textColor),
                              ),
                              trailing: ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                    theme.themeColor,
                                  ),
                                  foregroundColor: WidgetStatePropertyAll(
                                    theme.themeTextColor,
                                  ),
                                ),
                                onPressed: () async {
                                  Navigator.of(ctx).pop();
                                  debugPrint(
                                    '▶️ Subscribing with card ${method.id} and price ${price.id}',
                                  );
                                  ref
                                      .read(isSubmittingProvider.notifier)
                                      .state = true;
                                  try {
                                    await ref
                                        .read(stripeProvider.notifier)
                                        .stripeSubscriptionCreate(
                                      context,
                                      price.id,
                                      method.id,
                                    );
                                  } finally {
                                    if (mounted) {
                                      ref
                                          .read(isSubmittingProvider.notifier)
                                          .state = false;
                                    }
                                  }
                                },
                                child: Text(
                                'choose_button'.tr,
                                  style: AppTextStyles.interMedium.copyWith(
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    // Stripe state (already Riverpod)
    final stripeState = ref.watch(stripeProvider);

    // UI state from providers (needed on left side)
    final selectedtype = ref.watch(selectedTypeProvider);
    final hasPromo = ref.watch(hasPromoProvider);

    // 🔹 Resolve dynamic monthly / yearly amounts & currencies
    double? monthlyAmount;
    double? yearlyAmount;
    String? monthlyCurrency;
    String? yearlyCurrency;
    String? monthlyPriceId; // NEW
    String? yearlyPriceId; // NEW

    if (_selectedPriceId != null && stripeState.products.isNotEmpty) {
      final selectedPrice =
      _findPriceById(stripeState.products, _selectedPriceId!);
      final selectedProduct =
      _findProductForPrice(stripeState.products, _selectedPriceId!);

      if (selectedProduct != null) {
        for (final pr in selectedProduct.prices) {
          if (pr.interval == 'month') {
            monthlyAmount = pr.amount;
            monthlyCurrency = pr.currency;
            monthlyPriceId = pr.id; // NEW
          } else if (pr.interval == 'year') {
            yearlyAmount = pr.amount;
            yearlyCurrency = pr.currency;
            yearlyPriceId = pr.id; // NEW
          }
        }
      } else if (selectedPrice != null) {
        if (selectedPrice.interval == 'month') {
          monthlyAmount = selectedPrice.amount;
          monthlyCurrency = selectedPrice.currency;
          monthlyPriceId = selectedPrice.id; // NEW
        } else if (selectedPrice.interval == 'year') {
          yearlyAmount = selectedPrice.amount;
          yearlyCurrency = selectedPrice.currency;
          yearlyPriceId = selectedPrice.id; // NEW
        }
      }
    }

    final isYearly = selectedtype == 'Yearly'.tr;

    final selectedPriceIdForPayment = isYearly
        ? (yearlyPriceId ?? monthlyPriceId ?? _selectedPriceId)
        : (monthlyPriceId ?? yearlyPriceId ?? _selectedPriceId);

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,

      // ✅ PC stays exactly your Row layout
      childPc: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 950,
              height: 650,
              child: Row(
                children: [
                  // Left Section: Plan Selection
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: PlanSelector(
                        selectedtype: selectedtype,
                        hasPromo: hasPromo,
                        promoController: promoController,
                        onBack: () => ref.read(navigationService).beamPop(),
                        onTypeChange: (val) =>
                        ref.read(selectedTypeProvider.notifier).state = val,
                        onTogglePromo: () {
                          final current = ref.read(hasPromoProvider);
                          ref.read(hasPromoProvider.notifier).state = !current;
                        },
                        loading: stripeState.isLoading,
                        monthlyAmount: monthlyAmount,
                        yearlyAmount: yearlyAmount,
                        monthlyCurrency: monthlyCurrency,
                        yearlyCurrency: yearlyCurrency,
                      ),
                    ),
                  ),
                  VerticalDivider(color: Theme.of(context).iconTheme.color),
                  // Right Section: Payments (separate widget)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: RightPaymentSection(
                        theme: theme,
                        checkoutnodes: checkoutnodes,
                        promoController: promoController,
                        nameController: nameController,
                        selectedPriceId:
                        selectedPriceIdForPayment, // ✅ use dynamic id
                        validateCardFields: _validateCardFields,
                        showProductsDialogForMethod: _showProductsDialogForMethod,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ✅ Mobile: same widgets, stacked in a Column (scrollable)
      childMobile: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              PlanSelector(
                selectedtype: selectedtype,
                hasPromo: hasPromo,
                promoController: promoController,
                onBack: () => ref.read(navigationService).beamPop(),
                onTypeChange: (val) =>
                ref.read(selectedTypeProvider.notifier).state = val,
                onTogglePromo: () {
                  final current = ref.read(hasPromoProvider);
                  ref.read(hasPromoProvider.notifier).state = !current;
                },
                loading: stripeState.isLoading,
                monthlyAmount: monthlyAmount,
                yearlyAmount: yearlyAmount,
                monthlyCurrency: monthlyCurrency,
                yearlyCurrency: yearlyCurrency,
              ),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).iconTheme.color),
              const SizedBox(height: 16),
              RightPaymentSection(
                theme: theme,
                checkoutnodes: checkoutnodes,
                promoController: promoController,
                nameController: nameController,
                selectedPriceId: selectedPriceIdForPayment, // ✅ use dynamic id
                validateCardFields: _validateCardFields,
                showProductsDialogForMethod: _showProductsDialogForMethod,
              ),
              const SizedBox(height: 56),

            ],
          ),
        ),
      ),
    );
  }
}
