import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:get/get.dart';
class FinancialInformationAndAdditionalFeaturesWidget extends StatelessWidget {
  final ThemeColors theme;
  const FinancialInformationAndAdditionalFeaturesWidget({super.key,required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Container(
            height: 225,
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(6),
              color: theme.themeColor,
            ),
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Financial Information',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        18.sp,
                        color:
                        Colors
                            .white,
                      ),
                    ),
                    Row(
                      spacing: 10.w,
                      children: [
                        AppIcons.pencil(
                          height: 16.h,
                          width: 16.w,
                          color: Colors
                              .white
                              .withValues(
                            alpha:
                            0.5,
                          ),
                        ),
                        Text(
                          'Edit',
                          style: AppTextStyles.interRegular.copyWith(
                            fontSize:
                            18.sp,
                            color: Colors
                                .white
                                .withValues(
                              alpha:
                              0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Initial Price',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                    Text(
                      '\$165,000',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Commission',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                    Text(
                      '\$20,000',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Preferd Payment Methods',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                    Text(
                      'Credit',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Status',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color:
                        Color.fromRGBO(
                          87,
                          148,
                          221,
                          0.1,
                        ),
                        borderRadius:
                        BorderRadius.all(
                          Radius.circular(6),
                        ),
                      ),
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal:
                        15,
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          color:
                          Color.fromRGBO(
                            161,
                            236,
                            230,
                            1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Tony Stark',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color:
                        Colors
                            .white,
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color:
                        Color.fromRGBO(
                          87,
                          148,
                          221,
                          0.1,
                        ),
                        borderRadius:
                        BorderRadius.all(
                          Radius.circular(6),
                        ),
                      ),
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal:
                        15,
                      ),
                      child: Row(
                        spacing: 10.w,
                        children: [
                          AppIcons.call(
                            height:
                            16.h,
                            width: 16.w,
                            color: Colors
                                .white
                                .withValues(
                              alpha:
                              0.5,
                            ),
                          ),
                          const Text(
                            'Pending',
                            style: TextStyle(
                              color:
                              Color.fromRGBO(
                                161,
                                236,
                                230,
                                1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Expanded(
          flex: 1,
          child: SizedBox(),
        ),
        // Szczegóły
        Expanded(
          flex: 4,
          child: Container(
            height: 225,
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(6),
              color: theme.themeColor
                  .withValues(
                alpha: 0.5,
              ),
            ),
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
              children: [
                Text(
                  'Additional Features'.tr,
                  style: AppTextStyles
                      .interRegular
                      .copyWith(
                    fontSize: 18.sp,
                    color:
                    Colors
                        .white,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Balcony',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                    Text(
                      '2',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Pool',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                    Text(
                      'Yes',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Elevator',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                    Text(
                      'No',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Suna',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                    Text(
                      'No',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Suna',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                    Text(
                      '2',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Parking'.tr,
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                    Text(
                      'No',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Air Conditioning'.tr,
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                    Text(
                      'No',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      'Basement',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                    Text(
                      'Yes',
                      style: AppTextStyles
                          .interRegular
                          .copyWith(
                        fontSize:
                        13.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
