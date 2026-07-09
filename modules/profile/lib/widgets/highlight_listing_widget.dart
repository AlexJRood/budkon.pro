import 'package:core/common/chrome/logo_hously.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:portal/screens/add_offer/components/add_offer_components.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:get/get.dart';
class HighlightListingWidget extends ConsumerWidget {
  const HighlightListingWidget({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final controller = TextEditingController();
    return Scaffold(
      backgroundColor: Colors.black,
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
                      height: 550.h,
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
                                  'Daily budget',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                CustomTextField(controller: controller, labelText: 'Entar value', ref: ref),
                                Text(
                                  '*minimum price- 1 \$',
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
                                    Text(
                                      'Price per click',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.copyWith(
                                        color: Colors.white,
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    Container(
                                      height: 48.h,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Color.fromRGBO(255, 255, 255, 0.1),
                                        borderRadius: BorderRadius.circular(6)
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            height: 48.h,
                                            width: 48.h,
                                            decoration: BoxDecoration(
                                              color: Color.fromRGBO(87, 148, 221, 0.2),
                                              borderRadius: BorderRadius.circular(6)
                                            ),
                                            child: Center(
                                              child: AppIcons.decrease(
                                                color: Colors.white,
                                                height: 24.h,
                                                width: 24.h
                                              ),
                                            ),
                                          ),
                                          Text('0.50',
                                          style:Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.copyWith(
                                            color: Colors.white,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                          ) ,),
                                          Container(
                                            height: 48.h,
                                            width: 48.h,
                                            decoration: BoxDecoration(
                                                color: Color.fromRGBO(87, 148, 221, 0.2),
                                                borderRadius: BorderRadius.circular(6)
                                            ),
                                            child: Center(
                                              child: AppIcons.add(
                                                  color: Colors.white,
                                                  height: 24.h,
                                                  width: 24.h
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ViewsCurveChart(),
                                    
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Duration of promotion',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.copyWith(
                                              color: Colors.white,
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                            ),),
                                            Text('5 days',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.copyWith(
                                              color: Colors.white,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w600,
                                            ),),
                                          ],
                                        ),
                                        CustomSliderWidget()
                                      ],
                                    )

                                  ],
                                ),
                                SizedBox(height: 20.h),
                                Column(
                                  spacing: 20.h,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                          Expanded(
                            child: SizedBox(
                              height: 400.h,
                              child: Image.asset('assets/images/group_113.webp',
                              fit: BoxFit.cover,),
                            ),
                          ),
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


class ViewsCurveChart extends StatelessWidget {
  const ViewsCurveChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
      ),
      width: double.infinity,
      height: 153.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
           Text(
            'Get more views',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 53.h,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF6B6B), // red
                        Color(0xFFB58D63), // brown
                        Color(0xFF7FFFD4), // light green
                      ],
                    ),
                    spots: const [
                      FlSpot(0, 1),
                      FlSpot(1, 2),
                      FlSpot(2, 3.5),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _LegendItem(color: Color(0xFFFF6B6B), text: '0.50 \$/click'),
              _LegendItem(color: Color(0xFFB58D63), text: '3 \$/click'),
              _LegendItem(color: Color(0xFF7FFFD4), text: '5 \$/click'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style:  TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}

class CustomSliderWidget extends StatefulWidget {
  const CustomSliderWidget({super.key});

  @override
  State<CustomSliderWidget> createState() => _CustomSliderWidgetState();
}

class _CustomSliderWidgetState extends State<CustomSliderWidget> {
  double _sliderValue = 0.2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: Colors.cyanAccent.shade100,
          inactiveTrackColor: Colors.grey.shade700,
          thumbColor: Colors.cyanAccent.shade100,
          overlayColor: Colors.transparent,
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
        child: Slider(
          value: _sliderValue,
          onChanged: (value) {
            setState(() {
              _sliderValue = value;
            });
          },
        ),
      ),
    );
  }
}

