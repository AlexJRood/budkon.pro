

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/design.dart';
import 'package:get/get_utils/get_utils.dart';


class AppBarLandingPageWidget extends ConsumerWidget {
  const AppBarLandingPageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {


      return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 0),
              child:  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 20,
                      children: [
                        Text(
                          'BUY'.tr,
                      style: AppTextStyles.interSemiBold14Light50,
                        ),
                        Text(
                          'RENT'.tr,
                      style: AppTextStyles.interSemiBold14Light50,
                        ),
                        Text(
                          'SELL'.tr,
                      style: AppTextStyles.interSemiBold14Light50,
                        ),
                        Text(
                          'INVEST'.tr,
                      style: AppTextStyles.interSemiBold14Light50,
                        ),
                        Text(
                          'BUILD'.tr,
                      style: AppTextStyles.interSemiBold14Light50,
                        ),
                      ],
                    ),
                    Text(
                      'HOUSLY',
                      style: AppTextStyles.houslyAiLogo30,
                    )
                  ],
                ),
                );
      

  }
}
