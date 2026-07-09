import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
final paymentMethodProvider = StateProvider<String>((ref) => 'card');

class CheckoutSingleBuyWidget extends ConsumerWidget {
  const CheckoutSingleBuyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMethod = ref.watch(paymentMethodProvider);
    final theme = ref.watch(themeColorsProvider);

    InputDecoration inputStyle(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: theme.textFieldColor,
      hintStyle: TextStyle(color: theme.textColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
    final sideMenuKey = GlobalKey<SideMenuState>();
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.agentCrm,
      childrenPc: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 200.0.w, vertical: 60.0.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  spacing: 20.h,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        AppIcons.arrowBack(color: theme.textColor),
                        Text(
                          'Back',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: theme.textColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      spacing: 20.h,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Checkout'.tr,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: theme.textColor,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'We’ll email you a reminder 3 days before your trial ends.'.tr,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: theme.textColor,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        Container(
                          height: 230.h,
                          width: 160.w,
                          decoration: BoxDecoration(
                            color: theme.themeColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.all(8),
                          child: Column(
                            spacing: 20.h,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Plus'.tr,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'for 7 days',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: false,
                                          onChanged: (value) {},
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Twice as many views at the top with Booster'.tr,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.copyWith(
                                              color: Colors.white,
                                              fontSize: 7.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: false,
                                          onChanged: (value) {},
                                        ),
                                        Expanded(
                                          child: Text(
                                            '1 repost per day during peak category traffic'.tr,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.copyWith(
                                              color: Colors.white,
                                              fontSize: 7.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: false,
                                          onChanged: (value) {},
                                        ),
                                        Expanded(
                                          child: Text(
                                            'A tag on your ad'.tr,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.copyWith(
                                              color: Colors.white,
                                              fontSize: 7.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              Row(
                                children: [
                                  Text(
                                    '\$14.00'.tr,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 8), // spacing between prices
                                  Text(
                                    '\$11.00'.tr,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Plan and price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Radio(
                                      value: false,
                                      groupValue: false,
                                      onChanged: (value) {},
                                      fillColor: WidgetStateProperty.all(
                                        theme.textColor,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Plus'.tr,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.sp,
                                            color: theme.textColor,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          'All features for 7 days'.tr,
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  '\$11.00'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            const Divider(color: Colors.grey),

                            // Subtotal
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15.sp,
                                    color: theme.textColor,
                                  ),
                                ),
                                Text(
                                  '\$11.00'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15.sp,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            Text(
                              'Add promotion code'.tr,
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 16),
                            const Divider(color: Colors.grey),

                            // Total due today
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total due today'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: theme.textColor,
                                  ),
                                ),
                                Text(
                                  '\$11.00',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            Text(
                              'Guaranteed to be safe & secure, ensuring that all transactions are protected with the highest level of security.'.tr,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.sp,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height/1.6.h,
                child: Padding(
                  padding:  EdgeInsets.symmetric(horizontal: 30.0.w),
                  child: VerticalDivider(
                    color: theme.textColor.withValues(alpha:
                    0.75,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment method'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Card option
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                selectedMethod == 'card'
                                    ? theme.textColor
                                    : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RadioListTile<String>(
                                    contentPadding: EdgeInsets.zero,
                                    value: 'card',
                                    tileColor: theme.textColor,
                                    groupValue: selectedMethod,
                                    fillColor: WidgetStateProperty.all(
                                      theme.textColor,
                                    ),
                                    onChanged:
                                        (value) =>
                                            ref
                                                .read(
                                                  paymentMethodProvider
                                                      .notifier,
                                                )
                                                .state = value!,
                                    title: Text(
                                      'Card'.tr,
                                      style: TextStyle(color: theme.textColor),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    decoration: inputStyle("Card Number".tr),
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          decoration: inputStyle("MM/YY"),
                                          style: TextStyle(
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          decoration: inputStyle("CVV"),
                                          style: TextStyle(
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    decoration: inputStyle("Name on card".tr),
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    dropdownColor: theme.themeColor,
                                    style: TextStyle(color: theme.textColor),
                                    decoration: inputStyle("Country".tr),
                                    items: [
                                      DropdownMenuItem(
                                        value: "USA",
                                        child: Text(
                                          "USA",
                                          style: TextStyle(
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: "UK",
                                        child: Text(
                                          "UK",
                                          style: TextStyle(
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (_) {},
                                  ),
                                ],
                              ),
                            ),
                            Divider(color: theme.textColor),
                            RadioListTile<String>(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              value: 'paypal',
                              groupValue: selectedMethod,
                              fillColor: WidgetStateProperty.all(
                                theme.textColor,
                              ),
                              onChanged:
                                  (value) =>
                                      ref
                                          .read(paymentMethodProvider.notifier)
                                          .state = value!,
                              title: Text(
                                'PayPal',
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // PayPal option
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            backgroundColor: theme.buttonGradient,
                          ),
                          onPressed: () {},
                          child: Text(
                            'Buy',
                            style: TextStyle(color: theme.buttonTextColor),
                          ),
                        ),
                      ),
                    ],
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

extension on String {
  String get tr => "";
}
