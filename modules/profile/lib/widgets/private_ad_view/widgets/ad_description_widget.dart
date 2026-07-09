import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:get/get.dart';

class AdDescriptionWidget extends StatelessWidget {
  final ThemeColors theme;
  const AdDescriptionWidget({super.key,required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        // Opis
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.start,
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Text(
                "Description".tr,
                style: AppTextStyles
                    .interBold
                    .copyWith(
                  fontSize: 20.sp,
                  color:
                  theme
                      .textColor,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                'Welcome to this beautifully maintained 3-bedroom, 2-bathroom home, perfectly situated in a quiet, family-friendly neighborhood. '
                    'Offering 2,000 sq. ft. of living space, this property combines modern upgrades with timeless charm, making it an ideal choice for your next home. '
                    'Step inside to find a bright, open-concept living area featuring large windows that flood the space with natural light. '
                    'The spacious kitchen boasts sleek granite countertops, stainless steel appliances, and plenty of storage, making it perfect for cooking and entertaining.',
                style: AppTextStyles
                    .interRegular
                    .copyWith(
                  color:
                  theme
                      .textColor,
                  fontSize: 14,
                ),
                textAlign:
                TextAlign.justify,
                softWrap: true,
              ),
            ],
          ),
        ),
        const Expanded(
          flex: 1,
          child: SizedBox(),
        ),
        // Szczegóły
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.start,
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Text(
                "Property Details".tr,
                style: AppTextStyles
                    .interBold
                    .copyWith(
                  fontSize: 20,
                  color:
                  theme
                      .textColor,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Text(
                    'property_type'.tr,
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Apartment',
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'Street Address'.tr,
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Warszawa, Mokotów',
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'Number'.tr,
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '123B',
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'City'.tr,
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Poland',
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'Area'.tr,
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Poland',
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'Zip Code'.tr,
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '123',
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'Property Size'.tr,
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '200m2',
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'Number of Rooms'
                        .tr,
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '3',
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'Number of Bathrooms'
                        .tr,
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '3',
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'Floor/Level'.tr,
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '3',
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'Type of Building'
                        .tr,
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'New',
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'Building Material'
                        .tr,
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'idk',
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'Condition'.tr,
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Renovated',
                    style: AppTextStyles
                        .interRegular
                        .copyWith(
                      fontSize: 14,
                      color:
                      theme
                          .textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
