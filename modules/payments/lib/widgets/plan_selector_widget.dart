
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:payments/emma/anchores/payments_emma_anchors.dart';
import 'package:payments/go_pro/checkout/components/checkout_components.dart';
import 'package:core/theme/icons.dart';

class PlanSelector extends StatelessWidget {
  final String selectedtype;
  final bool hasPromo;
  final TextEditingController promoController;
  final VoidCallback onBack;
  final ValueChanged<String> onTypeChange;
  final VoidCallback onTogglePromo;
  final bool loading;

  /// Dynamic amounts from API (null = fall back to 89 / 890)
  final double? monthlyAmount;
  final double? yearlyAmount;

  /// Currency codes from API, e.g. "pln", "usd"
  final String? monthlyCurrency;
  final String? yearlyCurrency;

  const PlanSelector({
    super.key,
    required this.selectedtype,
    required this.hasPromo,
    required this.promoController,
    required this.onBack,
    required this.onTypeChange,
    required this.onTogglePromo,
    required this.loading,
    this.monthlyAmount,
    this.yearlyAmount,
    this.monthlyCurrency,
    this.yearlyCurrency,
  });

  String _formatAmount(
      double? value,
      String? currency,
      double fallbackAmount,
      String fallbackCurrency,
      ) {
    final amt = value ?? fallbackAmount;
    final cur = (currency ?? fallbackCurrency).toUpperCase();
    return '${amt.toStringAsFixed(2)} $cur';
  }

  @override
  Widget build(BuildContext context) {
    // Which prices actually exist from API
    final bool hasMonthly = monthlyAmount != null;
    final bool hasYearly = yearlyAmount != null;

    // Choose a fallback currency if API didn’t provide one
    final fallbackCurrency =
    (monthlyCurrency ?? yearlyCurrency ?? 'USD').toUpperCase();

    // If yearly not provided but monthly is, we still compute effective value
    // for internal usage, but we will NOT show Yearly radio when hasYearly == false
    final effectiveYearlyAmount =
        yearlyAmount ?? (monthlyAmount != null ? monthlyAmount! * 12 : null);

    final monthlyText = _formatAmount(
      monthlyAmount,
      monthlyCurrency,
      89.0,
      fallbackCurrency,
    );

    final yearlyText = _formatAmount(
      effectiveYearlyAmount,
      yearlyCurrency ?? monthlyCurrency,
      890.0,
      fallbackCurrency,
    );

    // Subtotal: respect what prices actually exist
    String subtotalText;
    if (hasMonthly && hasYearly) {
      subtotalText =
      selectedtype == 'Monthly'.tr ? monthlyText : yearlyText;
    } else if (hasMonthly) {
      subtotalText = monthlyText;
    } else if (hasYearly) {
      subtotalText = yearlyText;
    } else {
      subtotalText = '--';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: TopAppBarSize.clearPage(context) + 20),
        InkWell(
          onTap: onBack,
          child: Row(
            children: [
              AppIcons.arrowBack(),
              const SizedBox(width: 5),
              Text(
                'Back'.tr,
                style: TextStyle(
                  color: Theme.of(context).iconTheme.color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          "Premium Plan".tr,
          style: TextStyle(
            color: Theme.of(context).iconTheme.color,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We'll email you a reminder 3 days before your trial ends.".tr,
          style: TextStyle(
            color: Theme.of(context)
                .iconTheme
                .color!
                .withAlpha((255 * 0.7).toInt()),
          ),
        ),
        const SizedBox(height: 16),

        // ✅ Show Monthly radio ONLY if monthlyAmount exists
        if (hasMonthly) ...[
          EmmaUiAnchorTarget(
            anchorKey: PaymentsEmmaAnchors.monthlyBillingOption.anchorKey,

            spec: PaymentsEmmaAnchors.monthlyBillingOption,
            runtimeMode: PaymentsEmmaAnchors.monthlyBillingOption.runtimeMode,
            tapMode: PaymentsEmmaAnchors.monthlyBillingOption.tapMode,
            child: RadioListTile(
              contentPadding: const EdgeInsets.all(0),
              hoverColor: Theme.of(context)
                  .primaryColor
                  .withAlpha((255 * 0.1).toInt()),
              value: "Monthly".tr,
              groupValue: selectedtype,
              onChanged: (value) => onTypeChange('Monthly'.tr),
              activeColor: Theme.of(context).iconTheme.color,
              title: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Monthly".tr,
                        style: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "All features for one month".tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .iconTheme
                              .color!
                              .withAlpha((255 * 0.7).toInt()),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    monthlyText,
                    style: TextStyle(
                      color: Theme.of(context).iconTheme.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Divider(color: Theme.of(context).iconTheme.color),
        ],

        // ✅ Show Yearly radio ONLY if yearlyAmount exists
        if (hasYearly) ...[
          EmmaUiAnchorTarget(
            anchorKey: PaymentsEmmaAnchors.yearlyBillingOption.anchorKey,

            spec: PaymentsEmmaAnchors.yearlyBillingOption,
            runtimeMode: PaymentsEmmaAnchors.yearlyBillingOption.runtimeMode,
            tapMode: PaymentsEmmaAnchors.yearlyBillingOption.tapMode,
            child: RadioListTile(
              contentPadding: const EdgeInsets.all(0),
              hoverColor: Theme.of(context)
                  .primaryColor
                  .withAlpha((255 * 0.1).toInt()),
              value: "Yearly".tr,
              groupValue: selectedtype,
              onChanged: (value) => onTypeChange('Yearly'.tr),
              activeColor: Theme.of(context).iconTheme.color,
              title: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Yearly".tr,
                        style: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "All features for one year".tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .iconTheme
                              .color!
                              .withAlpha((255 * 0.7).toInt()),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    yearlyText,
                    style: TextStyle(
                      color: Theme.of(context).iconTheme.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Divider(color: Theme.of(context).iconTheme.color),
        ],

        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              "Subtotal".tr,
              style: TextStyle(
                color: Theme.of(context).iconTheme.color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            Text(
              subtotalText,
              style: TextStyle(
                color: Theme.of(context).iconTheme.color,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
          EmmaUiAnchorTarget(
          anchorKey: PaymentsEmmaAnchors.promotionCodeInput.anchorKey,

          spec: PaymentsEmmaAnchors.promotionCodeInput,
          runtimeMode: PaymentsEmmaAnchors.promotionCodeInput.runtimeMode,
          tapMode: PaymentsEmmaAnchors.promotionCodeInput.tapMode,
          child: !hasPromo
              ? InkWell(
                  child: Text(
                    "Add promotion code".tr,
                    style: const TextStyle(color: Colors.blue),
                  ),
                  onTap: onTogglePromo,
                )
              : GradientTextFieldcheckout(
                  controller: promoController,
                  hintText: 'Promotion Code'.tr,
                  keyboardType: TextInputType.text,
                ),
        ),
        const SizedBox(height: 6),
        Divider(
          color: Theme.of(context)
              .iconTheme
              .color!
              .withAlpha((255 * 0.7).toInt()),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              "Total due today".tr,
              style: TextStyle(
                color: Theme.of(context).iconTheme.color,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            Text(
              subtotalText,
              style: TextStyle(
                color: Theme.of(context).iconTheme.color,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 16),
        Text(
          "Guaranteed to be safe & secure, ensuring that all transactions are protected with the highest level of security."
              .tr,
          style: TextStyle(
            color: Theme.of(context)
                .iconTheme
                .color!
                .withAlpha((255 * 0.7).toInt()),
          ),
        ),
        const SizedBox(height: 8),
        if (loading)
          Row(
            children:[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('loading_prices_label'.tr),
            ],
          ),
      ],
    );
  }
}
