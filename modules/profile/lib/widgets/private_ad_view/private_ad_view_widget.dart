import 'package:core/common/chrome/logo_hously.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:portal/screens/feed/components/map/map_ad.dart';
import 'package:profile/widgets/private_ad_view/widgets/ad_description_widget.dart';
import 'package:profile/widgets/private_ad_view/widgets/ad_view_icons_widget.dart';
import 'package:profile/widgets/private_ad_view/widgets/display_ad_images_widget.dart';
import 'package:profile/widgets/private_ad_view/widgets/financial_information_and_additional_features_widget.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

class PrivateAdViewWidget extends ConsumerWidget {
  final bool isExpired;
  const PrivateAdViewWidget({super.key, this.isExpired = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    double screenWidth = MediaQuery.of(context).size.width;
    double mainImageWidth = screenWidth * 0.625;
    double mainImageHeight = mainImageWidth * (650 / 1200);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.white.withAlpha(217),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          GestureDetector(onTap: () => ref.read(navigationService).beamPop()),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                child: Container(
                  width: MediaQuery.of(context).size.width / 1.5,
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    child: Row(
                      spacing: 90.w,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            spacing: 10.h,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DisplayAdImagesWidget(
                                        mainImageHeight: mainImageHeight,
                                        mainImageWidth: mainImageWidth,
                                        isExpired: isExpired,
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: mainImageWidth,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Cena, cena za m²
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Parker Rd. Allentown',
                                                  style: AppTextStyles.interBold
                                                      .copyWith(
                                                        fontSize: 26,
                                                        color: theme.textColor,
                                                      ),
                                                ),
                                                Text(
                                                  'Warszawa, Mokotów, Poland',
                                                  style: AppTextStyles
                                                      .interRegular
                                                      .copyWith(
                                                        fontSize: 16,
                                                        color: theme.textColor,
                                                      ),
                                                ),
                                                Text(
                                                  '\$165,000',
                                                  style: AppTextStyles.interBold
                                                      .copyWith(
                                                        fontSize: 26,
                                                        color: theme.textColor,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 50),
                                            AdDescriptionWidget(theme: theme),
                                            //Mapa
                                            const SizedBox(height: 70),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    height: 400,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(20.0), // Zaokrąglone rogi
                                                      // Dodaj inne dekoracje, jak tło, jeśli potrzebujesz
                                                    ),
                                                    child: MapAd(
                                                      latitude:
                                                          37.7749, // Example: San Francisco
                                                      longitude: -122.4194,
                                                      onMapActivated: () {
                                                        debugPrint(
                                                          'Map activated',
                                                        ); // Dummy action for now
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 50),

                                            FinancialInformationAndAdditionalFeaturesWidget(
                                              theme: theme,
                                            ),

                                            const SizedBox(height: 25),

                                            // PropertyDetailsColumn(
                                            //   adNetworkPop: widget.adNetworkPop,
                                            // ),
                                            const SizedBox(height: 75),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(child: AdViewIconsWidget(theme: theme)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
