import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class ArticlesModule extends ConsumerWidget {
  const ArticlesModule({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final currentThemeMode = ref.watch(themeProvider);
    final themecolors = ref.watch(themeColorsProvider);

    final textColor = themecolors.themeTextColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text('Articles'.tr,
            style: AppTextStyles.interSemiBold18.copyWith(color: textColor)),
        const SizedBox(
          height: 25,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // pierwsza koluna

              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 500,
                      width: 360,
                      color: currentThemeMode == ThemeMode.system
                          ? AppColors.dark50
                          : currentThemeMode == ThemeMode.light
                              ? AppColors.light50
                              : AppColors.dark75),
                  const SizedBox(height: 20),
                  Text("article.title".tr,
                      style: AppTextStyles.interRegular14
                          .copyWith(color: textColor)),
                  const SizedBox(height: 15),
                  Text('short_description_article'.tr,
                      style: AppTextStyles.interLight.copyWith(color: textColor)),
                  const SizedBox(height: 10),
                ],
              ),
              const SizedBox(
                width: 40,
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 700,
                      width: 500,
                      color: currentThemeMode == ThemeMode.system
                          ? AppColors.dark50
                          : currentThemeMode == ThemeMode.light
                              ? AppColors.light50
                              : AppColors.dark75),
                  const SizedBox(height: 20),
                  Text("article.title".tr,
                      style: AppTextStyles.interRegular14
                          .copyWith(color: textColor)),
                  const SizedBox(height: 15),
                  Text('short_description_article'.tr,
                      style: AppTextStyles.interLight.copyWith(color: textColor)),
                  const SizedBox(height: 10),
                ],
              ),

              const SizedBox(
                width: 40,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 500,
                      width: 360,
                      color: currentThemeMode == ThemeMode.system
                          ? AppColors.dark50
                          : currentThemeMode == ThemeMode.light
                              ? AppColors.light50
                              : AppColors.dark75),
                  const SizedBox(height: 20),
                  Text("article.title".tr,
                      style: AppTextStyles.interRegular14
                          .copyWith(color: textColor)),
                  const SizedBox(height: 15),
                  Text('short_description_article'.tr,
                      style: AppTextStyles.interLight.copyWith(color: textColor)),
                  const SizedBox(height: 10),
                ],
              ),

            ],
          ),
        ),
      ],
    );
  }
}
