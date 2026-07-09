
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:portal/screens/add_offer/components/plan_card.dart';
import 'package:portal/screens/add_offer/components/progress_indicator.dart';
import 'package:portal/screens/add_offer/pages/pc/add_offer_plan_screen.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/backgroundgradient.dart';

class AddofferPlanScreenMobile extends ConsumerWidget {
  const AddofferPlanScreenMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final selectedIndex = ref.watch(selectedPlanIndexProvider);
    final isAutoRenew = ref.watch(autoRenewProvider);
    final acceptedTerms = ref.watch(acceptedTermsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a package to activate your ad'.tr,
              style: TextStyle(
                fontSize: 20,
                color: CustomColors.secondaryWidgetTextColor(context, ref),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Boost your ad to reach more buyers faster and sell your property with ease!'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(204),
              ),
            ),
            const SizedBox(height: 30),

            // Show plans vertically
            for (int i = 0; i < plansDummy.length; i++) ...[
              PlanCard(
                index: i,
                isSelected: selectedIndex == i,
                onSelect:
                    () => ref.read(selectedPlanIndexProvider.notifier).state = i,

                description: plansDummy[i].description,
                title: plansDummy[i].title,
                subtitle: plansDummy[i].subtitle,
                features: plansDummy[i].features,
                price: plansDummy[i].price,
                oldPrice: plansDummy[i].oldPrice,
                isPopular: plansDummy[i].isPopular,
                popularLabel: plansDummy[i].popularLabel,
              ),
              const SizedBox(height: 16),
            ],

          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Automatic package renewal'.tr,
                style: TextStyle(color: CustomColors.secondaryWidgetTextColor(context, ref),),
              ),
              Spacer(),
              Switch(
                value: isAutoRenew,
                onChanged:
                    (val) => ref.read(autoRenewProvider.notifier).state = val,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Checkbox(
                value: acceptedTerms,
                onChanged:
                    (val) =>
                        ref.read(acceptedTermsProvider.notifier).state =
                            val ?? false,
              ),
              const SizedBox(width: 4),
              Text(
                'i_accept_rules_for_posting_ads'.tr,
                style: TextStyle(
                  color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(204),
                ),
              ),
            ],
          ),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ref.read(progressProvider.notifier).state -= 1;
                  },
                  child: Text(
                    'Back'.tr,
                    style: TextStyle(color: CustomColors.secondaryWidgetTextColor(context, ref),),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 250,
                  child: SettingsButton(
                    isPc: true,
                    buttonheight: 50,
                    onTap: () {
                      if (selectedIndex == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          Customsnackbar().showSnackBar(
                            'Warning'.tr,
                            'Please select a plan to continue.'.tr,
                            'warning'.tr,
                            () {},
                          ),
                        );
                        return;
                      }
                      if (!acceptedTerms) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          Customsnackbar().showSnackBar(
                            'Warning'.tr,
                            'Please accept the rules for posting ads.'.tr,
                            'warning'.tr,
                            () {},
                          ),
                        );
                        return;
                      }
                      ref.read(progressProvider.notifier).state += 1;
                    },
                    text: 'Continue'.tr,
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
