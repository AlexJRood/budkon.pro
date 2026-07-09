import 'package:flutter/material.dart';
import 'package:core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'package:core/theme/colors.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/ui/buttons/action_buttons.dart';
import 'package:payments/settings/payment_pc_components.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class SettingsPaymentPc extends ConsumerStatefulWidget {
  const SettingsPaymentPc({super.key});

  @override
  _SettingsPaymentPcState createState() => _SettingsPaymentPcState();
}

bool ishistory = false;

class _SettingsPaymentPcState extends ConsumerState<SettingsPaymentPc> {
  @override
  Widget build(BuildContext context) {
    final curentthememode = ref.watch(themeProvider);
    final isToggled = ref.watch(toggleProvider);

    final List<Map<String, String>> cardData = [
      {
        'cardNumber': '**** **** **** 6698',
        'validThru': '06/25',
        'cardHolderName': 'JOHN DOE',
      },
      {
        'cardNumber': '**** **** **** 1234',
        'validThru': '12/27',
        'cardHolderName': 'JANE SMITH',
      },
      {
        'cardNumber': '**** **** **** 9876',
        'validThru': '03/28',
        'cardHolderName': 'SAM WILSON',
      },
    ];

    return GestureDetector(
      onTap: () {
        setState(() {
          ishistory = false;
        });
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isToggled == true) ...[
                const SizedBox(
                  height: 1,
                ),
              ],
              HeadingText(text: 'payment_methods'.tr),
              const SizedBox(height: 15),
              if (cardData.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: HeadingText(
                            text: 'no_saved_payment_method'.tr,
                            fontsize: 13,
                          ),
                        ),
                        const Expanded(flex: 3, child: SizedBox()),
                        if (cardData.isEmpty)
                          Expanded(
                            flex: 1,
                            child: CustomElevatedButton(
                              text: 'add_payment_method_button'.tr,
                              onTap: () {},
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SubtitleText(text: 'make_payments_faster_by_saving_a_payment_method'.tr),
                  ],
                )
              else
                SubtitleText(text: 'manage_your_payment_methods_here'.tr),
              const SizedBox(height: 10),
              if (cardData.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    addAutomaticKeepAlives: false,
                    cacheExtent: 300.0,
                    scrollDirection: Axis.horizontal,
                    itemCount: cardData.length + 1,
                    itemBuilder: (context, index) {
                      if (index < cardData.length) {
                        return CreditCardWidget(
                          gradient: curentthememode == ThemeMode.system ||
                                  curentthememode == ThemeMode.light
                              ? lighterGradients[
                                  index % lighterGradients.length]
                              : darkerGradients[index % darkerGradients.length],
                          cardNumber: cardData[index]['cardNumber']!,
                          validThru: cardData[index]['validThru']!,
                          cardHolderName: cardData[index]['cardHolderName']!,
                        );
                      } else {
                        return NewCardWidget(
                          onAddCard: () {
                            if (kDebugMode) print("Add card button tapped!");
                          },
                        );
                      }
                    },
                  ),
                ),
              const SizedBox(height: 40),
              HeadingText(text: 'transaction_history'.tr),
              const SizedBox(height: 15),
              SubtitleText(text: 'view_details_of_your_previous_payments_and_invoices'.tr),
              const SizedBox(height: 10),
              if (ishistory == false) ...[
                SettingsButton(
                  isPc: true,
                  buttonheight: 40,
                  onTap: () {
                    setState(() {
                      ishistory = true;
                    });
                  },
                  text: 'view_history'.tr
                )
              ],
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  if (ishistory == true) ...[const InvoiceTable()]
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
