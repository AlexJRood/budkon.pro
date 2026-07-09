import 'package:core/common/chrome/logo_hously.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profile/widgets/promotion_package_ui/promotion_package_ui_mobile.dart';
import 'package:profile/widgets/promotion_package_ui/promotion_package_ui_pc.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/design.dart';
import 'dart:ui' as ui;
import 'package:core/theme/icons.dart';

class PromotionPackageUiWidget extends ConsumerWidget {
  const PromotionPackageUiWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.black.withAlpha(217),
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
                        color: AppColors.white,
                        height: 48.h,
                        width: 48.w,
                      ),
                    ),
                    LogoHouslyWidget(),
                  ],
                ),
              ),
              if(isMobile)...[
                Expanded(
                  child: PromotionPackageUiMobile(),
                ),

              ]else...[
                PromotionPackageUiPc(),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
