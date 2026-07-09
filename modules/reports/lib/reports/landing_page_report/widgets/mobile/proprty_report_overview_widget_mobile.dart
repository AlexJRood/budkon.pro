import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:reports/reports/report_pdf_page/all_report_pdf_screen.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

class PropertyReportOverviewWidgetMobile extends ConsumerWidget {
  const PropertyReportOverviewWidgetMobile({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What does a Property Report provide?'.tr,
                      style: TextStyle(
                        color: CustomColors.gradientTextcolor(context, ref),
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      "A Property Report provides a comprehensive overview of your home's market value, recent sales comparisons, improvement recommendations, buyer insights, and key data to help you sell faster and smarter.",
                      style: TextStyle(
                        color: CustomColors.gradientTextcolor(context, ref),
                        fontSize: 14.0,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 45,
                          child: CustomElevatedButton(
                            onTap: () {
                              ref
                                  .read(navigationService)
                                  .pushNamedScreen(Routes.createReport);
                            },
                            text: 'Create a Report'.tr,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SettingsButton(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => const AllReportPdfScreen(
                                      isSampleData: true,
                                    ),
                              ),
                            );
                          },
                          isPc: true,
                          buttonheight: 45,
                          text: 'View Sample Report'.tr,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: constraints.maxWidth * 0.8,
                child: Image.asset('assets/images/report_house.png'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PropertySearchStepsWidgetMobile extends ConsumerWidget {
  const PropertySearchStepsWidgetMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP 1'.tr,
                      style: AppTextStyles.libreCaslonHeading.copyWith(
                        color: Colors.blue[300],
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Search for a property'.tr,
                      style: AppTextStyles.libreCaslonHeading.copyWith(
                        color: CustomColors.gradientTextcolor(context, ref),
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    SizedBox(
                      width: 80,
                      child: Divider(
                        color: CustomColors.gradientTextcolor(context, ref),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Locate your desired property by entering its street address into the search bar.'.tr,
                      style: TextStyle(
                        color: CustomColors.gradientTextcolor(context, ref),
                        fontSize: 14.0,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          iconAlignment: IconAlignment.end,
                          onPressed: () {},
                          icon: AppIcons.simpleArrowForward(
                            color: CustomColors.gradientTextcolor(context, ref),
                          ),
                          label:  Text('Search Property'.tr),
                          style: TextButton.styleFrom(
                            foregroundColor: CustomColors.gradientTextcolor(
                              context,
                              ref,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: CustomColors.gradientTextcolor(context, ref),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: constraints.maxWidth * 0.8,
                child: Image.asset('assets/images/search_property.png'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PropertyPurchaseWidgetMobile extends ConsumerWidget {
  const PropertyPurchaseWidgetMobile({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP 3',
                      style: AppTextStyles.libreCaslonHeading.copyWith(
                        color: Colors.blue[300],
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Purchase The Property Report'.tr,
                      style: AppTextStyles.libreCaslonHeading.copyWith(
                        color: CustomColors.gradientTextcolor(context, ref),
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    SizedBox(
                      width: 100,
                      child: Divider(
                        color: CustomColors.gradientTextcolor(context, ref),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'You will be redirected to a secure payment page to complete the transaction. upon successful payment, an invoice will be emailed to you, with report as an attachment.'.tr,
                      style: TextStyle(
                        color: CustomColors.gradientTextcolor(context, ref),
                        fontSize: 14.0,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          iconAlignment: IconAlignment.end,
                          onPressed: () {},
                          icon: AppIcons.simpleArrowForward(
                            color: CustomColors.gradientTextcolor(context, ref),
                          ),
                          label:  Text('Get My First Report'.tr),
                          style: TextButton.styleFrom(
                            foregroundColor: CustomColors.gradientTextcolor(
                              context,
                              ref,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: CustomColors.gradientTextcolor(context, ref),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: constraints.maxWidth * 0.8,
                child: Image.asset('assets/images/purchase_property.png'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PropertySelectWidgetMobile extends ConsumerWidget {
  const PropertySelectWidgetMobile({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP 2',
                      style: AppTextStyles.libreCaslonHeading.copyWith(
                        color: Colors.blue[300],
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Select a property'.tr,
                      style: AppTextStyles.libreCaslonHeading.copyWith(
                        color: CustomColors.gradientTextcolor(context, ref),
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    SizedBox(
                      width: 80,
                      child: Divider(
                        color: CustomColors.gradientTextcolor(context, ref),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Choose the property for Which youd like to Obtain a report- Youll be directed to a detailed page with comprehensive information about the property and the report.'.tr,
                      style: TextStyle(
                        color: CustomColors.gradientTextcolor(context, ref),
                        fontSize: 14.0,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          iconAlignment: IconAlignment.end,
                          onPressed: () {},
                          icon: AppIcons.simpleArrowForward(
                            color: CustomColors.gradientTextcolor(context, ref),
                          ),
                          label: Text('See Saved Proprties'.tr),
                          style: TextButton.styleFrom(
                            foregroundColor: CustomColors.gradientTextcolor(
                              context,
                              ref,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: CustomColors.gradientTextcolor(context, ref),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: constraints.maxWidth * 0.8,
                child: Image.asset('assets/images/select_property.png'),
              ),
            ],
          );
        },
      ),
    );
  }
}
