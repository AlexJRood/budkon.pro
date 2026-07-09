import 'package:core/common/chrome/logo_hously.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'checkout_single_buy_widget.dart';

class SetTagLabelWidget3 extends ConsumerWidget {
  const SetTagLabelWidget3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final selectedMethod = ref.watch(paymentMethodProvider);
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

    return Scaffold(
      backgroundColor: theme.clientbackground,
      body: Column(
        children: [
          SizedBox(
            height: 74.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    ref.read(navigationService).beamPop();
                  },
                  child: AppIcons.iosArrowLeft(
                    color: theme.textColor,
                    height: 48.h,
                    width: 48.w,
                  ),
                ),
                LogoHouslyWidget(),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 220.0.w,
                      vertical: 40.h,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT COLUMN
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Checkout',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: theme.textColor,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'We’ll email you a reminder 3 days before your trial ends.',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: theme.textColor,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                spacing: 230.w,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        SizedBox(height: 24.h),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            color: theme.themeColor,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Ad name',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.5),
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                'Parker Rd. Allentown',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.copyWith(
                                                  color: Colors.white,
                                                  fontSize: 20.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Warszawa, Mokotów, Poland',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.5),
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Divider(
                                                color: Colors.white.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ),
                                              _buildRow(
                                                context,
                                                theme,
                                                'Label',
                                                '6 \$',
                                              ),
                                              _buildRow(
                                                context,
                                                theme,
                                                'Time',
                                                '3 days',
                                              ),
                                              _buildRow(
                                                context,
                                                theme,
                                                'Start day',
                                                '01/04/2025',
                                              ),
                                              _buildRow(
                                                context,
                                                theme,
                                                'Due to',
                                                '31/04/2025',
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 24.h),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Payment method',
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
                                                color: theme.clientbackground,
                                                border: Border.all(
                                                  color:
                                                      selectedMethod == 'card'
                                                          ? theme.textColor
                                                          : Colors.grey,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Column(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(20.0),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        RadioListTile<String>(
                                                          contentPadding:
                                                              EdgeInsets.zero,
                                                          value: 'card',
                                                          tileColor:
                                                              theme.textColor,
                                                          groupValue:
                                                              selectedMethod,
                                                          fillColor:
                                                              WidgetStateProperty.all(
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
                                                            'Card',
                                                            style: TextStyle(
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        TextField(
                                                          decoration:
                                                              inputStyle(
                                                                "Card Number",
                                                              ),
                                                          style: TextStyle(
                                                            color:
                                                                theme.textColor,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: TextField(
                                                                decoration:
                                                                    inputStyle(
                                                                      "MM/YY",
                                                                    ),
                                                                style: TextStyle(
                                                                  color:
                                                                      theme
                                                                          .textColor,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Expanded(
                                                              child: TextField(
                                                                decoration:
                                                                    inputStyle(
                                                                      "CVV",
                                                                    ),
                                                                style: TextStyle(
                                                                  color:
                                                                      theme
                                                                          .textColor,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        TextField(
                                                          decoration:
                                                              inputStyle(
                                                                "Name on card",
                                                              ),
                                                          style: TextStyle(
                                                            color:
                                                                theme.textColor,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        DropdownButtonFormField<
                                                          String
                                                        >(
                                                          dropdownColor:
                                                              theme.themeColor,
                                                          style: TextStyle(
                                                            color:
                                                                theme.textColor,
                                                          ),
                                                          decoration:
                                                              inputStyle(
                                                                "Country",
                                                              ),
                                                          items: [
                                                            DropdownMenuItem(
                                                              value: "USA",
                                                              child: Text(
                                                                "USA",
                                                                style: TextStyle(
                                                                  color:
                                                                      theme
                                                                          .textColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DropdownMenuItem(
                                                              value: "UK",
                                                              child: Text(
                                                                "UK",
                                                                style: TextStyle(
                                                                  color:
                                                                      theme
                                                                          .textColor,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                          onChanged: (_) {},
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Divider(
                                                    color: theme.textColor,
                                                  ),
                                                  RadioListTile<String>(
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                        ),
                                                    value: 'paypal',
                                                    groupValue: selectedMethod,
                                                    fillColor:
                                                        WidgetStateProperty.all(
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
                                                      'PayPal',
                                                      style: TextStyle(
                                                        color: theme.textColor,
                                                      ),
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
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(10),
                                                            ),
                                                      ),
                                                  backgroundColor:
                                                      theme.buttonGradient,
                                                ),
                                                onPressed: () {},
                                                child: Text(
                                                  'Buy',
                                                  style: TextStyle(
                                                    color:
                                                        theme.buttonTextColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        SizedBox(height: 24.h),
                                        SizedBox(
                                          height: 350.h,
                                          width: 350.w,
                                          child: Image.asset(
                                            'assets/images/growth_chart_icon.png',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    ThemeColors theme,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
