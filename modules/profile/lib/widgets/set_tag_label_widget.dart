import 'package:core/common/chrome/logo_hously.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:get/get.dart';
final selectedDurationProvider = StateProvider<String>((ref) => '3 days');

class SetTagLabelWidget extends ConsumerWidget {
  const SetTagLabelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Container(
                width: MediaQuery.of(context).size.width / 1.5,
                color: Colors.transparent,
                child: Column(
                  spacing: 10.h,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set tag/label',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Boost your ad to reach more buyers faster and sell your property with ease!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 50.h),

                    SizedBox(
                      height: 450.h,
                      child: Row(
                        spacing: 140.w,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose tag',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Tag will help your listing to make it stand out and provide quick info at a glance.',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                Column(
                                  spacing: 10.h,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          height: 27.h,
                                          width: 83.w,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            color: Color.fromRGBO(
                                              161,
                                              236,
                                              230,
                                              1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Label name',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.copyWith(
                                                color: Colors.black,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Radio<bool>(
                                            value: false,
                                            groupValue: false,
                                            onChanged: (bool? value) {},
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(color: Colors.grey),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          height: 27.h,
                                          width: 83.w,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            color: Color.fromRGBO(
                                              161,
                                              236,
                                              230,
                                              1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Label name',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.copyWith(
                                                color: Colors.black,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Radio<bool>(
                                            value: false,
                                            groupValue: false,
                                            onChanged: (bool? value) {},
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(color: Colors.grey),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          height: 27.h,
                                          width: 83.w,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            color: Color.fromRGBO(
                                              161,
                                              236,
                                              230,
                                              1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Label name',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.copyWith(
                                                color: Colors.black,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Radio<bool>(
                                            value: false,
                                            groupValue: false,
                                            onChanged: (bool? value) {},
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(color: Colors.grey),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                Column(
                                  spacing: 20.h,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DurationSelector(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Price',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.copyWith(
                                            color: Colors.white,
                                            fontSize: 24.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '6 \$',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.copyWith(
                                            color: Colors.white,
                                            fontSize: 24.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Expanded(
                          //   child: SizedBox(
                          //     height: 350.h,
                          //     child: AdCardWidget(),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    SizedBox(height: 50.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        height: 48.h,
                        width: 290.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Color.fromRGBO(87, 148, 221, 0.2),
                        ),
                        child: Center(
                          child: Text(
                            'Continue'.tr,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
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
    );
  }
}

class DurationSelector extends ConsumerWidget {
  const DurationSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDurationProvider);
    final notifier = ref.read(selectedDurationProvider.notifier);
    final options = ['1 day', '3 days', '7 days'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10.h,
      children: [
        Text(
          'Set time',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          height: 40.h,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                options.map((option) {
                  final isSelected = selected == option;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        notifier.state = option;
                        debugPrint('Selected: $option');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Colors.cyanAccent.shade100
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Center(
                          child: Text(
                            option,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
