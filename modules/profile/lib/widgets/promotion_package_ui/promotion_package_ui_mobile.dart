import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/design.dart';

class PromotionPackageUiMobile extends StatelessWidget {
  const PromotionPackageUiMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 0.5,
      color: Colors.transparent,
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          spacing: 10.h,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promotion packages',
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

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 20.w,
              children: [
                Container(
                  height: 387.w,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(33, 32, 32, 1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.white),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(
                          color: AppColors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'for one month',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.5),
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 30.h),
                      Text(
                        'Advertising without promotion services',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.5),
                          fontSize: 13.sp,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '\$0',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(
                          color: AppColors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 400.w,
                  color: Colors.transparent,
                  alignment: Alignment.topCenter,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 387.w,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(33, 32, 32, 1),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.white),
                          ),
                          padding: EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plus',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.white,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'for 7 days',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.white.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 13.sp,
                                ),
                              ),
                              SizedBox(height: 30.h),
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: true,
                                        onChanged: (value) {},
                                        fillColor:
                                            WidgetStateProperty.resolveWith<
                                              Color
                                            >((Set<WidgetState> states) {
                                              if (states.contains(
                                                WidgetState.disabled,
                                              )) {
                                                return Color.fromRGBO(
                                                  255,
                                                  255,
                                                  255,
                                                  0.1,
                                                ).withAlpha(82);
                                              }
                                              return Color.fromRGBO(
                                                255,
                                                255,
                                                255,
                                                0.1,
                                              );
                                            }),
                                      ),
                                      Text(
                                        'Twice as many views at the top with Booster',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.copyWith(
                                          color: AppColors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: true,
                                        onChanged: (value) {},
                                        fillColor:
                                            WidgetStateProperty.resolveWith<
                                              Color
                                            >((Set<WidgetState> states) {
                                              if (states.contains(
                                                WidgetState.disabled,
                                              )) {
                                                return Color.fromRGBO(
                                                  255,
                                                  255,
                                                  255,
                                                  0.1,
                                                ).withAlpha(82);
                                              }
                                              return Color.fromRGBO(
                                                255,
                                                255,
                                                255,
                                                0.1,
                                              );
                                            }),
                                      ),
                                      Text(
                                        '1 repost per day during peak category traffic',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.copyWith(
                                          color: AppColors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: true,
                                        onChanged: (value) {},
                                        fillColor:
                                            WidgetStateProperty.resolveWith<
                                              Color
                                            >((Set<WidgetState> states) {
                                              if (states.contains(
                                                WidgetState.disabled,
                                              )) {
                                                return Color.fromRGBO(
                                                  255,
                                                  255,
                                                  255,
                                                  0.1,
                                                ).withAlpha(82);
                                              }
                                              return Color.fromRGBO(
                                                255,
                                                255,
                                                255,
                                                0.1,
                                              );
                                            }),
                                      ),
                                      Text(
                                        'A tag on your ad',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.copyWith(
                                          color: AppColors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Spacer(),
                              Row(
                                children: [
                                  Text(
                                    '\$14.00',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      color: const Color.fromRGBO(
                                        145,
                                        145,
                                        145,
                                        1,
                                      ),
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.lineThrough,
                                      decorationThickness: 2,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ), // space between prices
                                  Text(
                                    '\$11.00',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        child: Container(
                          height: 19.h,
                          width: 156.w,
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Center(
                            child: Text(
                              'Most popular',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 387.w,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(33, 32, 32, 1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.white),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turbo',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(
                          color: AppColors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'for 7 days',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.5),
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 30.h),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: true,
                                onChanged: (value) {},
                                fillColor: WidgetStateProperty.resolveWith<
                                  Color
                                >((Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return Color.fromRGBO(
                                      255,
                                      255,
                                      255,
                                      0.1,
                                    ).withAlpha(82);
                                  }
                                  return Color.fromRGBO(255, 255, 255, 0.1);
                                }),
                              ),
                              Text(
                                '5 times more views at the top with Booster',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.white.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: true,
                                onChanged: (value) {},
                                fillColor: WidgetStateProperty.resolveWith<
                                  Color
                                >((Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return Color.fromRGBO(
                                      255,
                                      255,
                                      255,
                                      0.1,
                                    ).withAlpha(82);
                                  }
                                  return Color.fromRGBO(255, 255, 255, 0.1);
                                }),
                              ),
                              Text(
                                '3 reposts per day during peak category traffic',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.white.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: true,
                                onChanged: (value) {},
                                fillColor: WidgetStateProperty.resolveWith<
                                  Color
                                >((Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return Color.fromRGBO(
                                      255,
                                      255,
                                      255,
                                      0.1,
                                    ).withAlpha(82);
                                  }
                                  return Color.fromRGBO(255, 255, 255, 0.1);
                                }),
                              ),
                              Text(
                                'Highlighted in the list with animation',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.white.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Spacer(),
                      Row(
                        children: [
                          Text(
                            '\$20.00',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: const Color.fromRGBO(145, 145, 145, 1),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.lineThrough,
                              decorationThickness: 2,
                            ),
                          ),
                          const SizedBox(width: 8), // space between prices
                          Text(
                            '\$15.00',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Text(
                  'Automatic package renewal',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                ),
                Switch(value: false, onChanged: (value) {}),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(value: false, onChanged: (value) {}),
                Expanded(
                  child: Text(
                    'I have read and understood the rules for posting ads on the HOUSLY.AI website',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ],
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
                    'Selected',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
}
