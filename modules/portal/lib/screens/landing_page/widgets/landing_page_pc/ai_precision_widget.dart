import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/common/gradiant_text_widget.dart';
import 'package:emma/runner.dart';

class AiPrecisionWidget extends ConsumerWidget {
  final double paddingDynamic;
  final bool isTablet;
  const AiPrecisionWidget({
    super.key,
    required this.paddingDynamic,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context, ref) {
    final dynamicVerticalPadding = paddingDynamic / 3;
    final theme = ref.watch(themeColorsProvider);
    final nav = ref.read(navigationService);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: dynamicVerticalPadding),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingDynamic),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Section 1: AI Precision
              isTablet
                  ? Column(
                    children: [
                      Image.asset(
                        'assets/images/group_113.webp',
                        width: 500,
                        cacheWidth: 350,
                      ),

                      _aiPrecisionHeading(theme),
                      const SizedBox(height: 10),
                      _aiPrecisionDivider(theme),
                      const SizedBox(height: 10),
                      _aiPrecisionDescriptionRow(theme),
                      const SizedBox(height: 20),
                      _aiPrecisionAction(context, theme),
                      const SizedBox(height: 20),
                      Divider(color: theme.textColor),
                    ],
                  )
                  : Row(
                    children: [
                      Image.asset(
                        'assets/images/group_113.webp',
                        width: 500,
                        cacheWidth: 350,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _aiPrecisionHeading(theme),
                            const SizedBox(height: 10),
                            _aiPrecisionDivider(theme),
                            const SizedBox(height: 5),
                            _aiPrecisionDescriptionRow(theme),
                            const SizedBox(height: 25),
                            _aiPrecisionAction(context, theme),
                            const SizedBox(height: 10),
                            Divider(color: theme.textColor),
                          ],
                        ),
                      ),
                    ],
                  ),

              // // Section 2: Network Monitoring
              // isTablet
              //     ? Column(
              //       children: [
              //         Image.asset(
              //           'assets/images/landingpage_ai_section.webp',
              //           width: 500,
              //           cacheWidth: 350,
              //         ),

              //         _networkMonitoringHeading(theme),
              //         const SizedBox(height: 10),
              //         _networkMonitoringDivider(theme),
              //         const SizedBox(height: 10),
              //         _networkMonitoringDescriptionRow(theme),
              //         const SizedBox(height: 20),
              //         _networkMonitoringAction(nav, theme),
              //         const SizedBox(height: 20),

              //         Divider(color: theme.textColor),
              //       ],
              //     )
              //     : Row(
              //       children: [
              //         Expanded(
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               _networkMonitoringHeading(theme),
              //               const SizedBox(height: 10),
              //               _networkMonitoringDivider(theme),
              //               const SizedBox(height: 5),
              //               _networkMonitoringDescriptionRow(theme),
              //               const SizedBox(height: 25),
              //               _networkMonitoringAction(nav, theme),
              //               const SizedBox(height: 10),
              //               Divider(color: theme.textColor),
              //             ],
              //           ),
              //         ),
              //         Image.asset(
              //           'assets/images/landingpage_ai_section.webp',
              //           width: 424,
              //           height: 281,
              //           cacheWidth: 250,
              //         ),
              //       ],
              //     ),

              // Section 3: Detailed Reports
              isTablet
                  ? Column(
                    children: [
                      Image.asset(
                        'assets/images/landingpage_report_section.webp',
                        width: 500,
                        cacheWidth: 350,
                      ),
                      const SizedBox(height: 20),
                      _detailedReportsHeading(theme),
                      const SizedBox(height: 10),
                      _detailedReportsDivider(theme),
                      const SizedBox(height: 10),
                      _detailedReportsDescriptionRow(theme),
                      const SizedBox(height: 20),
                      _detailedReportsAction(nav, theme),
                      const SizedBox(height: 5),
                      Divider(color: theme.textColor),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailedReportsHeading(theme),
                            const SizedBox(height: 10),
                            _detailedReportsDivider(theme),
                            const SizedBox(height: 5),
                            _detailedReportsDescriptionRow(theme),
                            const SizedBox(height: 25),
                            _detailedReportsAction(nav, theme),
                            const SizedBox(height: 5),
                            Divider(color: theme.textColor),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/images/landingpage_report_section.webp',
                        width: 424,
                        height: 281,
                        cacheWidth: 250,
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // AI Precision Helpers
  Widget _aiPrecisionHeading(theme) => Row(
    mainAxisAlignment:
        isTablet ? MainAxisAlignment.center : MainAxisAlignment.start,
    children: [
      GradientText(
        "AI".tr,
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(87, 222, 210, 1),
            Color.fromRGBO(87, 148, 221, 1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        style: AppTextStyles.libreCaslonHeading.copyWith(
          fontSize: isTablet ? 24 : 36,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        'Precision'.tr,
        style: AppTextStyles.libreCaslonHeading.copyWith(
          color: theme.textColor,
          fontSize: isTablet ? 24 : 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _aiPrecisionDivider(theme) => Center(
    child:
        isTablet
            ? SizedBox(
              width: 120,
              child: Divider(thickness: 2, color: theme.textColor),
            )
            : Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 120,
                child: Divider(thickness: 2, color: theme.textColor),
              ),
            ),
  );

  Widget _aiPrecisionDescriptionRow(theme) => Row(
    mainAxisAlignment:
        isTablet ? MainAxisAlignment.center : MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          'ai_analysis_description'.tr,
          textAlign: isTablet ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isTablet ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: theme.textColor,
          ),
        ),
      ),
    ],
  );

  Widget _aiPrecisionAction(context, theme) => Align(
    alignment: isTablet ? Alignment.center : Alignment.bottomRight,
    child: ElevatedButton(
      style: elevatedButtonStyleRounded10,
      onPressed:
          () => Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => const ChatAiPage(),
              transitionsBuilder:
                  (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
            ),
          ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Try the AI Experience Now'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.textColor,
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.arrow_forward, size: 14, color: theme.textColor),
        ],
      ),
    ),
  );

  // Network Monitoring Helpers
  Widget _networkMonitoringHeading(theme) => Row(
    mainAxisAlignment:
        isTablet ? MainAxisAlignment.center : MainAxisAlignment.start,
    children: [
      Text(
        'Network'.tr,
        style: AppTextStyles.libreCaslonHeading.copyWith(
          color: theme.textColor,
          fontSize: isTablet ? 24 : 36,
          fontWeight: FontWeight.bold,
        ),
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
          fontSize: isTablet ? 24 : 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _networkMonitoringDivider(theme) => Center(
    child:
        isTablet
            ? SizedBox(
              width: 120,
              child: Divider(thickness: 2, color: theme.textColor),
            )
            : Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 120,
                child: Divider(thickness: 2, color: theme.textColor),
              ),
            ),
  );

  Widget _networkMonitoringDescriptionRow(theme) => Row(
    mainAxisAlignment:
        isTablet ? MainAxisAlignment.center : MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          'We continuously monitor thousands of listings to ensure the properties you see are accurate, up-to-date, and ready to go. Our network monitoring ensures you never miss a property!'
              .tr,
          textAlign: isTablet ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isTablet ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: theme.textColor,
          ),
        ),
      ),
    ],
  );

  Widget _networkMonitoringAction(nav, theme) => Align(
    alignment: isTablet ? Alignment.center : Alignment.bottomRight,
    child: ElevatedButton(
      style: elevatedButtonStyleRounded10,
      onPressed: () => nav.pushNamedScreen(Routes.homeNetworkMonitoring),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Explore Our Monitoring Advantage'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.textColor,
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.arrow_forward, size: 14, color: theme.textColor),
        ],
      ),
    ),
  );

  // Detailed Reports Helpers
  Widget _detailedReportsHeading(theme) => Row(
    mainAxisAlignment:
        isTablet ? MainAxisAlignment.center : MainAxisAlignment.start,
    children: [
      Text(
        'Detailed'.tr,
        style: AppTextStyles.libreCaslonHeading.copyWith(
          color: theme.textColor,
          fontSize: isTablet ? 24 : 36,
          fontWeight: FontWeight.bold,
        ),
      ),
      GradientText(
        "Reports".tr,
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(87, 222, 210, 1),
            Color.fromRGBO(87, 148, 221, 1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        style: AppTextStyles.libreCaslonHeading.copyWith(
          fontSize: isTablet ? 24 : 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _detailedReportsDivider(theme) => Center(
    child:
        isTablet
            ? SizedBox(
              width: 120,
              child: Divider(thickness: 2, color: theme.textColor),
            )
            : Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 120,
                child: Divider(thickness: 2, color: theme.textColor),
              ),
            ),
  );

  Widget _detailedReportsDescriptionRow(theme) => Row(
    mainAxisAlignment:
        isTablet ? MainAxisAlignment.center : MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          'Curious about a property? Simply search and purchase a detailed report that covers every angle of the property.'
              .tr,
          textAlign: isTablet ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isTablet ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: theme.textColor,
          ),
        ),
      ),
    ],
  );

  Widget _detailedReportsAction(nav, theme) => Align(
    alignment: isTablet ? Alignment.center : Alignment.bottomRight,
    child: ElevatedButton(
      style: elevatedButtonStyleRounded10,
      onPressed: () => nav.pushNamedScreen(Routes.reports),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Buy Your Property Report Today'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.textColor,
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.arrow_forward, size: 14, color: theme.textColor),
        ],
      ),
    ),
  );
}
