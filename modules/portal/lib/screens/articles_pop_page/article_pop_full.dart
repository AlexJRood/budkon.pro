import 'dart:ui' as ui;
import 'package:core/common/chrome/back_button.dart';
import 'package:core/common/chrome/logo_hously.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/secure_storage.dart';

import 'package:get/get_utils/get_utils.dart';

void copyToClipboard(BuildContext context, String listingUrl) {
  Clipboard.setData(ClipboardData(text: listingUrl)).then((_) {
    final snackBar = Customsnackbar().showSnackBar("Success".tr,
        'link_copied_to_clipboard'.tr, "success", () {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });       
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  });
}

class ArticlePopFull extends ConsumerWidget {
  final dynamic articlePop;
  final String tagArticlePop;

  ArticlePopFull({
    super.key,
    required this.articlePop,
    required this.tagArticlePop,
  });

  final secureStorage = SecureStorage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final theme = ref.read(themeColorsProvider);
    final userAsyncValue = ref.watch(userProvider);

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double mainImageHeight = screenHeight * 0.85;
    double mainImageWidth = mainImageHeight * 0.75;

    const double maxWidth = 1920;
    const double minWidth = 480;
    const double maxPadding = 100;
    const double minPadding = 20;

    double dynamicPadding = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxPadding - minPadding) +
        minPadding;
    dynamicPadding = dynamicPadding.clamp(minPadding, maxPadding);

    return userAsyncValue.when(
      data: (user) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  color: theme.adPopBackground.withAlpha((255 * 0.35).toInt()),
                  width: double.infinity,
                  height: double.infinity,
                child: 
              GestureDetector(
                onTap: () => ref.read(navigationService).beamPop(),
             child: 
              
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: mainImageWidth,
                              child: Hero(
                              tag: tagArticlePop,
                              child: GestureDetector(
                                onTap: () {},
                                child: Image.network(
                                  articlePop.thumbnailUrl,
                                  width: mainImageWidth,
                                  height: screenHeight,
                                  fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child:  SingleChildScrollView(
                                  child: Row(
                                    children: [
                                     SizedBox(width: dynamicPadding),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 150),
                                            Material(
                                              color: Colors.transparent,
                                              child: Text(articlePop.title,
                                                  style: AppTextStyles.interBold
                                                      .copyWith(fontSize: 30, color: theme.textColor)),
                                            ),
                                            const SizedBox(height: 75),
                                            Material(
                                              color: Colors.transparent,
                                              child: Text(articlePop.body,
                                                  style: AppTextStyles.interMedium14.copyWith(color: theme.textColor)
                                                  ),
                                            ),
                                            const SizedBox(height: 150),
                                          ],
                                        ),
                                      ),
                                     SizedBox(width: dynamicPadding*2),
                                    ],
                                  ),
                              ),
                            ),
                          ],
                        ),
              ),
                  ),
                ),
              Positioned(
                top: 0,
                left: 0,
                child: BackButtonHously()
              ),
              Positioned(
                top: 0,
                right: 0,
                child: LogoHouslyWidget(),
              ),
            ],
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('${'Error'.tr}: $error'.tr),
    );
  }
}
