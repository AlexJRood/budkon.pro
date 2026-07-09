import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:portal/screens/add_offer/components/plan_card.dart';
import 'package:portal/screens/add_offer/components/progress_indicator.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';

final selectedPlanIndexProvider = StateProvider<int?>((ref) => null);
final autoRenewProvider = StateProvider<bool>((ref) => false);
final acceptedTermsProvider = StateProvider<bool>((ref) => false);

class AddofferPlanScreen extends ConsumerWidget {
  final bool isTablet;
  const AddofferPlanScreen({super.key, this.isTablet=false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final dynamicPadding = isTablet ? screenWidth/15 : screenWidth / 7;

    final selectedIndex = ref.watch(selectedPlanIndexProvider);
    final isAutoRenew = ref.watch(autoRenewProvider);
    final acceptedTerms = ref.watch(acceptedTermsProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Text(
            'Select a package to activate your ad'.tr,
            style: TextStyle(
              fontSize: 25,
              color:CustomColors.secondaryWidgetTextColor(context, ref),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Boost your ad to reach more buyers faster and sell your property with ease!'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(204),
            ),
          ),
          const SizedBox(height: 30),
          isTablet?
          Center(
            child:Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.start,
              children: [
                for (int i = 0; i < plansDummy.length; i++) ...[
                  SizedBox(

                    child: PlanCard(
                      isTablet: isTablet,
                      index: i,
                      isSelected: selectedIndex == i,
                      onSelect:
                          () =>
                      ref.read(selectedPlanIndexProvider.notifier).state =
                          i,

                      description: plansDummy[i].description,
                      title: plansDummy[i].title,
                      subtitle: plansDummy[i].subtitle,
                      features: plansDummy[i].features,
                      price: plansDummy[i].price,
                      oldPrice: plansDummy[i].oldPrice,
                      isPopular: plansDummy[i].isPopular,
                      popularLabel: plansDummy[i].popularLabel,
                    ),
                  ),
                  if (i != plansDummy.length - 1) const SizedBox(width: 16),
                ],
              ],
            ),
          ):Row(
            // PC LAYOUT: Uses Expanded to fill space perfectly side-by-side
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < plansDummy.length; i++) ...[
                Expanded(
                  child: PlanCard(
                    isTablet: false,
                    index: i,
                    isSelected: selectedIndex == i,
                    onSelect: () => ref.read(selectedPlanIndexProvider.notifier).state = i,
                    description: plansDummy[i].description,
                    title: plansDummy[i].title,
                    subtitle: plansDummy[i].subtitle,
                    features: plansDummy[i].features,
                    price: plansDummy[i].price,
                    oldPrice: plansDummy[i].oldPrice,
                    isPopular: plansDummy[i].isPopular,
                    popularLabel: plansDummy[i].popularLabel,
                  ),
                ),
                if (i != plansDummy.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Text(
                'Automatic package renewal'.tr,
                style: TextStyle(color: CustomColors.secondaryWidgetTextColor(context, ref)),
              ),
              const SizedBox(width: 12),
              Switch(
                activeTrackColor: theme.themeColor,
                value: isAutoRenew,
                onChanged:
                    (val) => ref.read(autoRenewProvider.notifier).state = val,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: acceptedTerms,
                activeColor: theme.themeColor,
                checkColor: theme.themeTextColor,
                onChanged: (val) {
                  ref.read(acceptedTermsProvider.notifier).state = val ?? false;
                },
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ref.read(acceptedTermsProvider.notifier).state = !acceptedTerms;
                  },
                  child: Text(
                    'I have read and understood the rules for posting ads on the HOUSLY.PRO website'.tr,
                    style: TextStyle(
                      color: CustomColors.secondaryWidgetTextColor(context, ref)
                          .withAlpha(204),
                    ),
                  ),
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
    );
  }
}
