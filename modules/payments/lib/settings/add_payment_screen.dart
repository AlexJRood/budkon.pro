import 'package:flutter/material.dart';
import 'package:core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/ui/forms/form_fields_mobile.dart';
import 'package:core/ui/buttons/action_buttons.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';

class AddPaymentScreen extends ConsumerWidget {
  const AddPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: CustomBackgroundGradients.getMainMenuBackground(
            context,
            ref,
          ),
        ),
        child: Column(
          children: [
            // AppBar Section
            MobileSettingsAppbar(
              title: "Add Payment".tr,
              onPressed: () {
                ref.read(navigationService).beamPop();
              },
            ),

            // Scrollable Fields Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "two_factor_authentication".tr,
                          style: TextStyle(color: theme.mobileTextcolor),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "secure_your_account_with_two_factor_authentication".tr,
                          style: TextStyle(
                            color: theme.mobileTextcolor,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 25),
                        PaymentButton(
                          isPc: false,
                          icon: Icons.credit_card,
                          text: 'Card'.tr,
                          theme: theme,
                          onPressed: () {
                            ref
                                .watch(navigationService)
                                .pushNamedScreen(Routes.addCard);
                          },
                        ),
                        const SizedBox(height: 10),
                        PaymentButton(
                          isPc: false,
                          icon: Icons.credit_card,
                          text: 'Paypal'.tr,
                          theme: theme,
                          onPressed: () {
                            ref
                                .read(navigationService)
                                .pushNamedScreen(Routes.addCard);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Fixed Bottom Button Section
          ],
        ),
      ),
    );
  }
}

class AddcardScreen extends ConsumerStatefulWidget {
  final bool isCard;

  const AddcardScreen({super.key, required this.isCard});

  @override
  ConsumerState<AddcardScreen> createState() => _AddcardScreenState();
}

class _AddcardScreenState extends ConsumerState<AddcardScreen> {
  late final TextEditingController cardnumbercontroller;
  late final TextEditingController expirycontroller;
  late final TextEditingController cvvcontroller;
  late final TextEditingController namecontroller;
  late final TextEditingController paypalcontroller;
  late final List<FocusNode> passwordfocusnode;

  @override
  void initState() {
    super.initState();

    cardnumbercontroller = TextEditingController();
    expirycontroller = TextEditingController();
    cvvcontroller = TextEditingController();
    namecontroller = TextEditingController();
    paypalcontroller = TextEditingController();

    passwordfocusnode = List.generate(5, (_) => FocusNode());
  }

  @override
  void dispose() {
    cardnumbercontroller.dispose();
    expirycontroller.dispose();
    cvvcontroller.dispose();
    namecontroller.dispose();
    paypalcontroller.dispose();

    for (final node in passwordfocusnode) {
      node.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: CustomBackgroundGradients.getMainMenuBackground(
            context,
            ref,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              MobileSettingsAppbar(
                title: "add_payment_method".tr,
                onPressed: () {
                  ref.read(navigationService).beamPop();
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        bottom:
                        MediaQuery.of(context).viewInsets.bottom + 140,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "add_payment_method".tr,
                            style: TextStyle(color: theme.mobileTextcolor),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "make_payments_faster_by_saving_a_payment_method"
                                .tr,
                            style: TextStyle(
                              color: theme.mobileTextcolor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (widget.isCard) ...[
                            GradientTextFieldMobile(
                              isSuffix: false,
                              focusNode: passwordfocusnode[0],
                              value: "",
                              reqNode: passwordfocusnode[1],
                              controller: cardnumbercontroller,
                              hintText: "Card Number".tr,
                            ),
                            GradientTextFieldMobile(
                              isSuffix: false,
                              focusNode: passwordfocusnode[1],
                              value: "",
                              reqNode: passwordfocusnode[2],
                              controller: expirycontroller,
                              hintText: "MM/YY",
                            ),
                            GradientTextFieldMobile(
                              isObscure: true,
                              focusNode: passwordfocusnode[2],
                              value: "",
                              reqNode: passwordfocusnode[3],
                              controller: cvvcontroller,
                              hintText: "CVV".tr,
                            ),
                            GradientTextFieldMobile(
                              isSuffix: false,
                              focusNode: passwordfocusnode[3],
                              value: "",
                              reqNode: null,
                              controller: namecontroller,
                              hintText: "name".tr,
                            ),
                          ],
                          if (!widget.isCard) ...[
                            GradientTextFieldMobile(
                              isObscure: true,
                              focusNode: passwordfocusnode[0],
                              value: "",
                              reqNode: null,
                              controller: paypalcontroller,
                              hintText: "Paypal".tr,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
