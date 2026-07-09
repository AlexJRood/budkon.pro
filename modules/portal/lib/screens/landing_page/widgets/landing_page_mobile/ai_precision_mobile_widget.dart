import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:emma/runner.dart';
import 'package:core/common/gradiant_text_widget.dart';
import 'package:core/platform/api_services.dart';

class AiPrecisionWidgetMobile extends ConsumerWidget {
  const AiPrecisionWidgetMobile({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final isUserLoggedIn = ApiServices.isUserLoggedIn();
    final nav = ref.read(navigationService);
    
    return SizedBox(
      height: 1500,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Image.asset(
                  'assets/images/group_113.webp',
                  height: 230,
                  fit: BoxFit.cover,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const GradientText(
                          "AI ",
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(87, 222, 210, 1),
                              Color.fromRGBO(87, 148, 221, 1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Precision'.tr,
                          style: AppTextStyles.libreCaslonHeading.copyWith(
                              color: CustomColors.landingPageButtonTextcolor(
                                  context, ref),
                              fontSize: 36,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    GradientText(
                      "REASON 1".tr,
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromRGBO(87, 222, 210, 1),
                          Color.fromRGBO(87, 148, 221, 1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      style: AppTextStyles.libreCaslonHeading.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Our AI analyzes your preferences—budget, location, lifestyle—to\nquickly find the best home options for you. Effortless and tailored\nresults!'.tr,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: CustomColors.landingPageSubHeadingColor(
                              context, ref)),
                    ),
                  ],
                ),
                Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      height: 48,
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              if (isUserLoggedIn) {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    opaque: false,
                                    pageBuilder: (_, __, ___) => const ChatAiPage(),
                                    transitionsBuilder: (_, anim, __, child) {
                                      return FadeTransition(opacity: anim, child: child);
                                    },
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  Customsnackbar().showSnackBar(
                                    'Sign in required'.tr,
                                    'Please sign in to use the AI assistant.'.tr,
                                    'warning'.tr,
                                        () {
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    },
                                  ),
                                );
                              }
                            },

                            iconAlignment: IconAlignment.end,
                            label: Text(
                              'Try the AI Experience Now'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: CustomColors.landingPageButtonTextcolor(
                                    context, ref),
                              ),
                            ),
                            icon: Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: CustomColors.landingPageButtonTextcolor(
                                  context, ref),
                            ),
                          )
                        ],
                      ),
                    )),
                const Divider()
              ],
            ),
            Column(
              children: [
                Image.asset(
                  'assets/images/landingpage_ai_section.webp',
                  height: 230,
                  fit: BoxFit.cover,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Network'.tr,
                          style: AppTextStyles.libreCaslonHeading.copyWith(
                              color: CustomColors.landingPageButtonTextcolor(
                                  context, ref),
                              fontSize: 30,
                              fontWeight: FontWeight.bold),
                        ),
                        GradientText(
                          "Monitoring".tr,
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromRGBO(87, 222, 210, 1),
                              Color.fromRGBO(87, 148, 221, 1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          style: AppTextStyles.libreCaslonHeading.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GradientText(
                      "REASON 2".tr,
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromRGBO(87, 222, 210, 1),
                          Color.fromRGBO(87, 148, 221, 1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      style: AppTextStyles.libreCaslonHeading.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'We continuously monitor thousands of listings to ensure the properties you see are accurate, up-to-date, and ready to go. Our network monitoring ensures you never miss a property!'.tr,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: CustomColors.landingPageSubHeadingColor(
                              context, ref)),
                    ),
                  ],
                ),
                Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      height: 48,
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {

                              nav.pushNamedScreen(Routes.homeNetworkMonitoring);

                            },
                            iconAlignment: IconAlignment.end,

                            label: 
                                  Text(
                                    'Explore Our Monitoring Advantage'.tr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                color: CustomColors.landingPageButtonTextcolor(
                                    context, ref),
                                    ),
                                  ),
                            icon: Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: CustomColors.landingPageButtonTextcolor(
                                  context, ref),
                            ),
                          )
                        ],
                      ),
                    )),
                const Divider()
              ],
            ),
            Column(
              children: [
                Image.asset(
                  'assets/images/landingpage_report_section.webp',
                  height: 230,
                  fit: BoxFit.cover,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GradientText(
                          "Detailed".tr,
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromRGBO(87, 222, 210, 1),
                              Color.fromRGBO(87, 148, 221, 1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          style: AppTextStyles.libreCaslonHeading.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Reports'.tr,
                          style: AppTextStyles.libreCaslonHeading.copyWith(
                              color: CustomColors.landingPageButtonTextcolor(
                                  context, ref),
                              fontSize: 36,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    GradientText(
                      "REASON 3".tr,
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromRGBO(87, 222, 210, 1),
                          Color.fromRGBO(87, 148, 221, 1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      style: AppTextStyles.libreCaslonHeading.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Curious about a property? Simply search and purchase a detailed report that covers every angle of the property.'.tr,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: CustomColors.landingPageSubHeadingColor(
                              context, ref)),
                    ),
                  ],
                ),
                Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      height: 48,
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    8), // Ensure valid shape
                              ),
                            ),
                            onPressed: () {
                              nav.pushNamedScreen(Routes.reports);

                            },
                            iconAlignment: IconAlignment.end,
                            label: Text(
                              'Buy Your Property Report Today'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: CustomColors.landingPageButtonTextcolor(
                                    context, ref),
                              ),
                            ),
                            icon: Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: CustomColors.landingPageButtonTextcolor(
                                  context, ref),
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider()
              ],
            ),
          ],
        ),
      ),
    );
  }
}
