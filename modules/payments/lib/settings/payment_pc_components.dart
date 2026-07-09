import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/apptheme.dart';

import 'package:get/get_utils/get_utils.dart';

class CreditCardWidget extends StatelessWidget {
  final String cardNumber;
  final String validThru;
  final String cardHolderName;
  final Gradient gradient;
  const CreditCardWidget({
    super.key,
    required this.cardNumber,
    required this.validThru,
    required this.gradient,
    required this.cardHolderName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 180,
        width: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: gradient,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              cardNumber,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).iconTheme.color,
                letterSpacing: 2,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                'valid_thru'.tr + validThru,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  cardHolderName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).iconTheme.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Image.asset(
                    'assets/images/visa.png',
                    width: 50,
                    height: 60,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NewCardWidget extends ConsumerWidget {
  final VoidCallback onAddCard;

  const NewCardWidget({
    super.key,
    required this.onAddCard,
  });

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 180,
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.popupcontainercolor, width: 2),
          color: theme.popupcontainercolor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card,
              color: theme.popupcontainertextcolor,
              size: 25,
            ),
            const SizedBox(height: 15),
            Text(
              'New card'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.popupcontainertextcolor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a new card option for more\ntransactions'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: theme.popupcontainertextcolor,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onAddCard,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).primaryColor,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add card'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
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

class InvoiceTable extends ConsumerWidget {
  const InvoiceTable({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final List<Map<String, String>> invoices = [
      {
        'invoiceNumber': 'INV-00012345',
        'date': 'DD/MM/YYYY',
        'paymentMethod': 'Visa ****6698',
        'amount': '\$9.99',
        'status': 'Successful'.tr
      },
      {
        'invoiceNumber': 'INV-00012346',
        'date': 'DD/MM/YYYY',
        'paymentMethod': 'PayPal',
        'amount': '\$99.99',
        'status': 'Failed'.tr
      },
      {
        'invoiceNumber': 'INV-00012347',
        'date': 'DD/MM/YYYY',
        'paymentMethod': 'Visa ****6698',
        'amount': '\$79.99',
        'status': 'Successful'.tr
      },
      {
        'invoiceNumber': 'INV-00012348',
        'date': 'DD/MM/YYYY',
        'paymentMethod': 'Visa ****6698',
        'amount': '\$99.99',
        'status': 'Successful'.tr
      },
      {
        'invoiceNumber': 'INV-00012349',
        'date': 'DD/MM/YYYY',
        'paymentMethod': 'PayPal',
        'amount': '\$79.99',
        'status': 'Successful'.tr
      },
      {
        'invoiceNumber': 'INV-00012350',
        'date': 'DD/MM/YYYY',
        'paymentMethod': 'MasterCard ****1234',
        'amount': '\$49.99',
        'status': 'Successful'.tr
      },
      {
        'invoiceNumber': 'INV-00012351',
        'date': 'DD/MM/YYYY',
        'paymentMethod': 'Visa ****5567',
        'amount': '\$59.99',
        'status': 'Pending'.tr
      },
      {
        'invoiceNumber': 'INV-00012352',
        'date': 'DD/MM/YYYY',
        'paymentMethod': 'PayPal',
        'amount': '\$199.99',
        'status': 'Successful'.tr
      },
      {
        'invoiceNumber': 'INV-00012353',
        'date': 'DD/MM/YYYY',
        'paymentMethod': 'Visa ****7788',
        'amount': '\$129.99',
        'status': 'Successful'.tr
      },
      {
        'invoiceNumber': 'INV-00012354',
        'date': 'DD/MM/YYYY',
        'paymentMethod': 'MasterCard ****4321',
        'amount': '\$399.99',
        'status': 'Failed'.tr
      },
      {
        'invoiceNumber': 'INV-00012355',
        'date': 'DD/MM/YYYY',
        'paymentMethod': 'Visa ****9988',
        'amount': '\$15.99',
        'status': 'Successful'.tr
      },
    ];

    return Expanded(
      child: GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.translucent,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient:
                  CustomBackgroundGradients.textFieldGradient(context, ref)),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        children: [
                          Expanded(flex: 7, child: const SizedBox()),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 40,
                              width: 100,
                              child: TextField(
                                style: TextStyle(
                                    color: Theme.of(context).iconTheme.color),
                                decoration: InputDecoration(
                                    fillColor: Theme.of(context)
                                        .iconTheme
                                        .color!
                                        .withAlpha((255 * 0.2).toInt()),
                                    suffixIcon: Icon(
                                      Icons.search,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                    hintText: 'Search...'.tr,
                                    hintStyle: TextStyle(
                                        color:
                                            Theme.of(context).iconTheme.color!),
                                    border: InputBorder.none,
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius:
                                            BorderRadius.circular(10))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text('Invoice Number'.tr,
                                  style: TextStyle(
                                    color: Theme.of(context).iconTheme.color,
                                    fontWeight: FontWeight.bold,
                                  ))),
                          Expanded(
                              child: Text('Date'.tr,
                                  style: TextStyle(
                                    color: Theme.of(context).iconTheme.color,
                                    fontWeight: FontWeight.bold,
                                  ))),
                          Expanded(
                              child: Text('Payment Method'.tr,
                                  style: TextStyle(
                                    color: Theme.of(context).iconTheme.color,
                                    fontWeight: FontWeight.bold,
                                  ))),
                          Expanded(
                              child: Text('Amount'.tr,
                                  style: TextStyle(
                                    color: Theme.of(context).iconTheme.color,
                                    fontWeight: FontWeight.bold,
                                  ))),
                          Expanded(
                              child: Text('Status'.tr,
                                  style: TextStyle(
                                    color: Theme.of(context).iconTheme.color,
                                    fontWeight: FontWeight.bold,
                                  ))),
                          AppIcons.moreVertical(color: Theme.of(context).iconTheme.color),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  addAutomaticKeepAlives: false,
                  cacheExtent: 300.0,
                  padding: const EdgeInsets.all(15),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(invoice['invoiceNumber']!,
                                  style: TextStyle(
                                    color: Theme.of(context).iconTheme.color,
                                  )),
                            ),
                            Expanded(
                              child: Text(invoice['date']!,
                                  style: TextStyle(
                                    color: Theme.of(context).iconTheme.color,
                                  )),
                            ),
                            Expanded(
                              child: Text(invoice['paymentMethod']!,
                                  style: TextStyle(
                                    color: Theme.of(context).iconTheme.color,
                                  )),
                            ),
                            Expanded(
                              child: Text(invoice['amount']!,
                                  style: TextStyle(
                                    color: Theme.of(context).iconTheme.color,
                                  )),
                            ),
                            Expanded(
                              child: Text(invoice['status']!,
                                  style: TextStyle(
                                    color: Theme.of(context).iconTheme.color,
                                  )),
                            ),
                            AppIcons.moreVertical(color: Theme.of(context)
                                    .iconTheme
                                    .color!
                                    .withAlpha((255 * 0.8).toInt())),
                          ],
                        ),
                        Divider(
                            color: Theme.of(context)
                                .iconTheme
                                .color!
                                .withAlpha((255 * 0.8).toInt())),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VisaCardTile extends ConsumerWidget {
  final String number;
  final String money;

  const VisaCardTile({
    super.key,
    required this.number,
    required this.money,
  });

  @override
  Widget build(BuildContext context, ref) {
    final currenttheme = ref.watch(themeProvider);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                currenttheme == ThemeMode.light ||
                        currenttheme == ThemeMode.system
                    ? Image.asset(
                        'assets/images/visaa.png',
                        height: 40,
                        width: 40,
                      )
                    : Image.asset(
                        'assets/images/visa.png',
                        height: 40,
                        width: 40,
                      ),
                const SizedBox(width: 20),
                Flexible(
                  child: Text(
                    'visa_ending_in'.tr + number,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    overflow: TextOverflow.ellipsis, // Handle overflow
                    maxLines: 1,
                  ),
                ),
                const Flexible(child: SizedBox(width: 100)),
                Flexible(
                  child: Text(
                    money,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    overflow: TextOverflow.ellipsis, // Handle overflow
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              SettingsButton(
                isPc: true,
                buttonheight: 30,
                onTap: () {},
                text: 'Edit'.tr,
                isborder: false,
                backgroundcolor: false,
              ),
              const SizedBox(
                width: 10,
              ),
              SettingsButton(
                isPc: true,
                buttonheight: 30,
                onTap: () {},
                text: 'Remove'.tr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
