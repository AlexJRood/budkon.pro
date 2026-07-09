import 'package:flutter/foundation.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:payments/emma/anchores/payments_emma_anchors.dart';
import 'package:payments/go_pro/checkout/components/checkout_components.dart';
import 'package:payments/provider/checkout_pc_provider.dart';
import 'package:payments/provider/stripe_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/values.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

// Track which saved payment method card is selected
final selectedSavedPaymentMethodIdProvider = StateProvider<String?>((ref) => null);

class RightPaymentSection extends ConsumerWidget {
  final ThemeColors theme;
  final List<FocusNode> checkoutnodes;
  final TextEditingController promoController;
  final TextEditingController nameController; 
  final String? selectedPriceId;
  final bool Function(BuildContext, String?) validateCardFields;
  final Future<void> Function(
      BuildContext,
      SavedPaymentMethod, {
      String? forcedPriceId,
      }) showProductsDialogForMethod;

  const RightPaymentSection({
    super.key,
    required this.theme,
    required this.checkoutnodes,
    required this.promoController,
    required this.nameController,
    required this.selectedPriceId,
    required this.validateCardFields,
    required this.showProductsDialogForMethod,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stripe / UI state from providers
    final stripeState = ref.watch(stripeProvider);
    final selectedtype = ref.watch(selectedTypeProvider);
    final paymentmethod = ref.watch(paymentMethodProvider);
    final selectedCountrycard = ref.watch(selectedCountryCardProvider);
    final isSubmitting = ref.watch(isSubmittingProvider);
    final isAddingNewCard = ref.watch(isAddingNewCardProvider);
    final nameError = ref.watch(nameOnCardErrorProvider);
    final selectedSavedMethodId = ref.watch(selectedSavedPaymentMethodIdProvider);

    final savedMethods = stripeState.paymentMethods;

    // If there are no saved methods, make sure no card is selected
    if (savedMethods.isEmpty &&
        selectedSavedMethodId != null &&
        selectedSavedMethodId!.isNotEmpty) {
      ref.read(selectedSavedPaymentMethodIdProvider.notifier).state = null;
    }

    final hasSelectedPlan =
        selectedPriceId != null && selectedPriceId!.isNotEmpty;

    final hasSelectedCard = paymentmethod == 'Card'.tr &&
        savedMethods.isNotEmpty &&
        selectedSavedMethodId != null &&
        selectedSavedMethodId!.isNotEmpty;

    // Subscribe button disabled when:
    // - loading OR submitting OR no plan OR (Card mode and no selected card)
    final isDisabled = stripeState.isLoading ||
        isSubmitting ||
        !hasSelectedPlan ||
        (paymentmethod == 'Card'.tr && !hasSelectedCard);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Google button
        GestureDetector(
          onTap: () {},
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: theme.fillColor,
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Image.asset('assets/images/search.png', scale: 10),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'continue_with_google'.tr,
                    style: TextStyle(
                      color: theme.textFieldColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Divider(color: Theme.of(context).iconTheme.color)),
            const SizedBox(width: 4),
            Text(
              'or_label'.tr,
              style: TextStyle(color: Theme.of(context).iconTheme.color),
            ),
            const SizedBox(width: 4),
            Expanded(child: Divider(color: Theme.of(context).iconTheme.color)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'payment_method_label'.tr,
          style: TextStyle(color: Theme.of(context).iconTheme.color),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              EmmaUiAnchorTarget(
                anchorKey: PaymentsEmmaAnchors.cardPaymentOption.anchorKey,

                spec: PaymentsEmmaAnchors.cardPaymentOption,
                runtimeMode: PaymentsEmmaAnchors.cardPaymentOption.runtimeMode,
                tapMode: PaymentsEmmaAnchors.cardPaymentOption.tapMode,
                child: RadioListTile(
                  contentPadding: const EdgeInsets.all(0),
                  value: "Card".tr,
                  groupValue: paymentmethod,
                  onChanged: (value) {
                    ref.read(paymentMethodProvider.notifier).state = 'Card'.tr;
                  },
                  activeColor: Theme.of(context).iconTheme.color,
                  title: Text(
                    'card_payment_option'.tr,
                    style: TextStyle(color: Theme.of(context).iconTheme.color),
                  ),
                ),
              ),

              /// ============================
              /// CARD FLOW (Stripe CardField)
              /// ============================
              if (paymentmethod == 'Card'.tr) ...[
                // If we already have methods and user is NOT adding a new one -> show list
                if (!isAddingNewCard && savedMethods.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final m in savedMethods)
                    EmmaUiAnchorTarget(
                      anchorKey: '${PaymentsEmmaAnchors.savedPaymentMethod.anchorKey}.${m.id}',
                      runtimeMode: PaymentsEmmaAnchors.savedPaymentMethod.runtimeMode,
                      tapMode: PaymentsEmmaAnchors.savedPaymentMethod.tapMode,
                      child: InkWell(
                        onTap: () {
                          final selectedNotifier =
                          ref.read(selectedSavedPaymentMethodIdProvider.notifier);
                      
                          // 🔁 Toggle selection on same card
                          if (selectedNotifier.state == m.id) {
                            selectedNotifier.state = null; // unselect
                          } else {
                            selectedNotifier.state = m.id; // select
                          }
                      
                          debugPrint('---- TOGGLED PAYMENT METHOD ----');
                          debugPrint('id      : ${m.id}');
                          debugPrint('brand   : ${m.brand}');
                          debugPrint('last4   : ${m.last4}');
                          debugPrint('expMonth: ${m.expMonth}');
                          debugPrint('expYear : ${m.expYear}');
                          debugPrint('selected: ${selectedNotifier.state}');
                          debugPrint('--------------------------------');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: m.id == selectedSavedMethodId
                                  ? theme.themeColor
                                  : Theme.of(context).iconTheme.color!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                m.brand.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '**** **** **** ${m.last4}',
                                style: AppTextStyles.interMedium.copyWith(
                                  color: theme.textColor,
                                ),
                              ),
                              const Spacer(),
                              if (m.expMonth != null && m.expYear != null)
                                Text(
                                  '${m.expMonth!.toString().padLeft(2, '0')}/${(m.expYear! % 100).toString().padLeft(2, '0')}',
                                  style: AppTextStyles.interMedium.copyWith(
                                    color: theme.textColor,
                                  ),
                                ),
                              if (m.id == selectedSavedMethodId) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: theme.themeColor,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                  EmmaUiAnchorTarget(
                    anchorKey: PaymentsEmmaAnchors.addPaymentMethodButton.anchorKey,

                    spec: PaymentsEmmaAnchors.addPaymentMethodButton,
                    runtimeMode: PaymentsEmmaAnchors.addPaymentMethodButton.runtimeMode,
                    tapMode: PaymentsEmmaAnchors.addPaymentMethodButton.tapMode,
                    child: TextButton.icon(
                      onPressed: () {
                        ref.read(isAddingNewCardProvider.notifier).state = true;
                        // When adding a new card, previous selection may stay (user can re-select later)
                      },
                      icon: Icon(Icons.add, color: theme.textColor),
                      label: Text(
                        'add_another_payment_method'.tr,
                        style: AppTextStyles.interMedium.copyWith(
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  ),
                ],

                // If adding new card OR there are no methods yet -> show CardField + form
                if (isAddingNewCard || savedMethods.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Theme.of(context).iconTheme.color!,
                      ),
                    ),
                    child: CardField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'card_details_hint'.tr,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Name on card
                  EmmaUiAnchorTarget(
                    anchorKey: PaymentsEmmaAnchors.nameOnCardInput.anchorKey,

                    spec: PaymentsEmmaAnchors.nameOnCardInput,
                    runtimeMode: PaymentsEmmaAnchors.nameOnCardInput.runtimeMode,
                    tapMode: PaymentsEmmaAnchors.nameOnCardInput.tapMode,
                    child: GradientTextFieldcheckout(
                      focusNode: checkoutnodes[3],
                      reqNode: checkoutnodes[4],
                      controller: nameController,
                      hintText: 'name_on_card_label'.tr,
                      errorText: nameError,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Country
                  EmmaUiAnchorTarget(
                    anchorKey: PaymentsEmmaAnchors.countrySelection.anchorKey,

                    spec: PaymentsEmmaAnchors.countrySelection,
                    runtimeMode: PaymentsEmmaAnchors.countrySelection.runtimeMode,
                    tapMode: PaymentsEmmaAnchors.countrySelection.tapMode,
                    child: GradientDropdownCountrycheckout(
                      hintText: 'country_label'.tr,
                      countries: countries,
                      selectedCountry: selectedCountrycard,
                      onChanged: (value) => ref
                          .read(selectedCountryCardProvider.notifier)
                          .state = value,
                    ),
                  ),
                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: () async {
                      final selectedCountry =
                      ref.read(selectedCountryCardProvider);

                      final valid = validateCardFields(
                        context,
                        selectedCountry,
                      );
                      if (!valid) return;

                      debugPrint('--- Payment Method Data ---');
                      debugPrint(
                        'Card: handled by Stripe CardField (not visible to app)',
                      );
                      debugPrint('Name on Card: ${nameController.text}');
                      debugPrint('Country: ${selectedCountry ?? ""}');
                      debugPrint('Plan Type: $selectedtype');
                      debugPrint('Payment Method Type: $paymentmethod');
                      if (promoController.text.trim().isNotEmpty) {
                        debugPrint('Promotion Code: ${promoController.text}');
                      }
                      debugPrint('---------------------------');

                      try {
                        final pmId = await ref
                            .read(stripeProvider.notifier)
                            .createPaymentMethodFromCardField(
                          context: context,
                          nameOnCard: nameController.text.trim(),
                          country: selectedCountry,
                        );

                        if (pmId != null) {
                          // Print Payment Method ID and switch to list view
                          debugPrint('🎯 Payment Method ID: $pmId');
                          ref.read(isAddingNewCardProvider.notifier).state =
                          false;
                        }
                      } catch (e) {
                        debugPrint('Add payment method error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('failed_to_save_payment_method'.tr),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'create_payment_method_button'.tr,
                        style: TextStyle(
                          color: theme.themeTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        Divider(color: Theme.of(context).iconTheme.color),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              EmmaUiAnchorTarget(
                anchorKey: PaymentsEmmaAnchors.paypalPaymentOption.anchorKey,

                spec: PaymentsEmmaAnchors.paypalPaymentOption,
                runtimeMode: PaymentsEmmaAnchors.paypalPaymentOption.runtimeMode,
                tapMode: PaymentsEmmaAnchors.paypalPaymentOption.tapMode,
                child: RadioListTile(
                  contentPadding: const EdgeInsets.all(0),
                  value: "Paypal".tr,
                  groupValue: paymentmethod,
                  onChanged: (value) {
                    ref.read(paymentMethodProvider.notifier).state = 'PayPal';
                    // Optional: clear selected card when switching to PayPal
                    ref
                        .read(selectedSavedPaymentMethodIdProvider.notifier)
                        .state = null;
                  },
                  activeColor: Theme.of(context).iconTheme.color,
                  title: Text(
                    'paypal_payment_option'.tr,
                    style: TextStyle(color: Theme.of(context).iconTheme.color),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (paymentmethod == 'PayPal') ...[
                GradientDropdownCountrycheckout(
                  hintText: 'Country'.tr,
                  countries: countries,
                  selectedCountry: selectedCountrycard,
                  onChanged: (value) => ref
                      .read(selectedCountryCardProvider.notifier)
                      .state = value,
                ),
                const SizedBox(height: 15),
              ],
              EmmaUiAnchorTarget(
                anchorKey: PaymentsEmmaAnchors.subscribeButton.anchorKey,

                spec: PaymentsEmmaAnchors.subscribeButton,
                runtimeMode: PaymentsEmmaAnchors.subscribeButton.runtimeMode,
                tapMode: PaymentsEmmaAnchors.subscribeButton.tapMode,
                child: ElevatedButton(
                  onPressed: isDisabled
                      ? null
                      : () async {
                    // start processing state
                    final submittingNotifier =
                    ref.read(isSubmittingProvider.notifier);
                    submittingNotifier.state = true;
                
                    try {
                      if (!hasSelectedPlan) {
                        // Should not happen because button is disabled, but just in case
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'no_plan_selected_error'.tr,
                            ),
                          ),
                        );
                        return;
                      }
                
                      if (paymentmethod == 'Card'.tr) {
                        if (!hasSelectedCard) {
                          // Also should not happen because button is disabled
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('select_payment_card_error'.tr),
                            ),
                          );
                          return;
                        }
                
                        final selectedMethod = savedMethods.firstWhere(
                              (m) => m.id == selectedSavedMethodId,
                          orElse: () => savedMethods.first,
                        );
                
                        // DIRECT SUBSCRIPTION CALL HERE (no confirmation popup)
                        try {
                          final success =  await ref
                              .read(stripeProvider.notifier)
                              .stripeSubscriptionCreate(
                            context,
                            selectedPriceId!,
                            selectedMethod.id,
                          );
                          if(success){
                            ref
                                .read(navigationService)
                                .pushNamedScreen(Routes.success);
                          }
                
                        } catch (e) {
                          debugPrint('Subscription error: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'subscription_failed_error'.tr,
                              ),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('paypal_not_implemented_message'.tr),
                          ),
                        );
                      }
                    } finally {
                      // always turn off processing state
                      submittingNotifier.state = false;
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    isDisabled ? theme.fillColor : theme.themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isSubmitting ? 'processing_label'.tr : 'subscribe_button'.tr,
                      style: TextStyle(
                        color: theme.themeTextColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
