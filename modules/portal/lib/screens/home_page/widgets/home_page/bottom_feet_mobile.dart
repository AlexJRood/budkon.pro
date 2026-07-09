import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

import 'package:get/get_utils/get_utils.dart';

class BottomFeetMobile extends ConsumerWidget {
  const BottomFeetMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentthememode = ref.watch(themeProvider);

    final isDefaultDarkSystem = ref.watch(isDefaultDarkSystemProvider);
    final themecolors = ref.watch(themeColorsProvider);
    final textFieldColor = themecolors.textFieldColor;
    return Container(
      height: 650,
      width: double.infinity,
      color: currentthememode == ThemeMode.system
          ? AppColors.dark50
          : currentthememode == ThemeMode.light
              ? AppColors.light50
              : AppColors.dark50,
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Column(
                    children: [
                      Text('how_it_works'.tr,
                          style: AppTextStyles.interMedium14
                              .copyWith(fontSize: 18, color: textFieldColor)),
                      const SizedBox(height: 20),
                      Text('check_offer'.tr,
                          style: AppTextStyles.interLight
                              .copyWith(color: textFieldColor)),
                      const SizedBox(
                        height: 20,
                      ),
                      Text('what_can_you_gain'.tr,
                          style: AppTextStyles.interLight
                              .copyWith(color: textFieldColor)),
                      const SizedBox(height: 20),
                      Text('professional_registration_hously_pro'.tr,
                          style: AppTextStyles.interLight
                              .copyWith(color: textFieldColor)),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        'support_for_beginners_with_hously'.tr,
                        style: AppTextStyles.interLight
                            .copyWith(color: textFieldColor),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      Text('check_offer'.tr,
                          style: AppTextStyles.interLight
                              .copyWith(color: textFieldColor)),
                      const SizedBox(
                        height: 20,
                      ),
                      Text('what_can_you_gain'.tr,
                          style: AppTextStyles.interLight
                              .copyWith(color: textFieldColor)),
                      const SizedBox(
                        height: 75,
                      ),
                      Text('for_professionals'.tr,
                          style: AppTextStyles.interMedium14
                              .copyWith(fontSize: 18, color: textFieldColor)),
                      const SizedBox(height: 20),
                      Text('check_offer'.tr,
                          style: AppTextStyles.interLight
                              .copyWith(color: textFieldColor)),
                      const SizedBox(
                        height: 20,
                      ),
                      Text('what_can_you_gain'.tr,
                          style: AppTextStyles.interLight
                              .copyWith(color: textFieldColor)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text('about_us_hously_ai'.tr,
                          style: AppTextStyles.interMedium14
                              .copyWith(fontSize: 18, color: textFieldColor)),
                      const SizedBox(height: 20),
                      Text('contact'.tr,
                          style: AppTextStyles.interLight
                              .copyWith(color: textFieldColor)),
                      const SizedBox(
                        height: 20,
                      ),
                      Text('what_can_you_gain'.tr,
                          style: AppTextStyles.interLight
                              .copyWith(color: textFieldColor)),
                      const SizedBox(height: 20),
                      Text('check_offer'.tr,
                          style: AppTextStyles.interLight
                              .copyWith(color: textFieldColor)),
                      const SizedBox(
                        height: 20,
                      ),
                      Text('what_can_you_gain'.tr,
                          style: AppTextStyles.interLight
                              .copyWith(color: textFieldColor)),
                      const SizedBox(
                        height: 75,
                      ),
                      Text('for_investors'.tr,
                          style: AppTextStyles.interMedium14
                              .copyWith(fontSize: 18, color: textFieldColor)),
                      const SizedBox(height: 20),
                      Text('check_offer'.tr,
                          style: AppTextStyles.interLight
                              .copyWith(color: textFieldColor)),
                      const SizedBox(
                        height: 20,
                      ),
                      Text('what_can_you_gain'.tr,
                          style: AppTextStyles.interLight
                              .copyWith(color: textFieldColor)),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Row(
              children: [
                const Spacer(),
                IconButton(
                    onPressed: () {},
                    icon: AppIcons.faceBookLogo(color: isDefaultDarkSystem
                            ? Theme.of(context).iconTheme.color
                            : Theme.of(context).primaryColor)),
                const SizedBox(
                  width: 20,
                ),
                IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.face,
                        color: isDefaultDarkSystem
                            ? Theme.of(context).iconTheme.color
                            : Theme.of(context).primaryColor)),
                const SizedBox(
                  width: 20,
                ),
                IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.one_x_mobiledata,
                        color: isDefaultDarkSystem
                            ? Theme.of(context).iconTheme.color
                            : Theme.of(context).primaryColor)),
                const SizedBox(
                  width: 20,
                ),
                IconButton(
                    onPressed: () {},
                    icon: AppIcons.search(color: isDefaultDarkSystem
                            ? Theme.of(context).iconTheme.color
                            : Theme.of(context).primaryColor)),
                const SizedBox(
                  width: 20,
                ),
                IconButton(
                    onPressed: () {},
                    icon: AppIcons.faceBookLogo(color: isDefaultDarkSystem
                            ? Theme.of(context).iconTheme.color
                            : Theme.of(context).primaryColor)),
                const SizedBox(
                  width: 20,
                ),
                const Spacer(),
              ],
            )
          ],
        ),
      ),
    );
  }
}
