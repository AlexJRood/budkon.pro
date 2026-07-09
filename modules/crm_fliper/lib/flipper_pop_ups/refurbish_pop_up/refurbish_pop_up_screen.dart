import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:core/platform/values.dart';
import 'package:core/common/models/gantt_task_model.dart';
import 'package:crm_fliper/finance/finance2/widget/finance_2_property_card.dart';
import 'package:crm_fliper/refurbishment/widget/gantt_display_chart_widget.dart';
import 'package:core/common/gradiant_text_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RefurbishPopUpScreen extends StatelessWidget {
  const RefurbishPopUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: const Color.fromRGBO(90, 90, 90, 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
              padding: EdgeInsets.all(28.0),
              child: SizedBox(
                width: 300.w,
                child: Finance2PropertyCard(isMobile: false),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 20.h,
                    children: [
                      SizedBox(
                        height: 93.h,
                        child: ListView.builder(
                          addAutomaticKeepAlives: false,
                          cacheExtent: 300.0,
                          itemCount: refurbishmentListData.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final listData = refurbishmentListData[index];

                            return Row(
                              spacing: 30.w,
                              children: [
                                DottedBorder(
                                  color: const Color.fromRGBO(200, 200, 200, 1),
                                  dashPattern: const [4, 2],
                                  borderType: BorderType.RRect,
                                  radius:  Radius.circular(6.r),
                                  padding: EdgeInsets.zero,
                                  child: Container(
                                    width: 285.w,
                                    height: 93.h,
                                    decoration:  BoxDecoration(
                                      color: Color.fromRGBO(33, 32, 32, 1),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(6.r)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            listData['title']!,
                                            style:  TextStyle(
                                              color: Color.fromRGBO(
                                                  200, 200, 200, 1),
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                          Text(
                                            listData['amount']!,
                                            style:  TextStyle(
                                              color: Color.fromRGBO(
                                                  255, 255, 255, 1),
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                listData['subtext']!,
                                                style:  TextStyle(
                                                  color: Color.fromRGBO(
                                                      200, 200, 200, 1),
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                              Text(
                                                listData['value']!,
                                                style:  TextStyle(
                                                  color: Color.fromRGBO(
                                                      200, 200, 200, 1),
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox()
                              ],
                            );
                          },
                        ),
                      ),
                       Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Parker Rd. Allentown',
                                style: TextStyle(
                                    color: Color.fromRGBO(255, 255, 255, 1),
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '~\$165.000',
                                style: TextStyle(
                                    color: Color.fromRGBO(255, 255, 255, 1),
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Warszawa, Mokotów, Poland',
                                style: TextStyle(
                                  color: Color.fromRGBO(200, 200, 200, 1),
                                  fontSize: 12.sp,
                                ),
                              ),
                              GradientText(
                                ' Profit Potential:  \$50.000 ',
                                gradient: LinearGradient(colors: [
                                  Color.fromRGBO(87, 222, 210, 1),
                                  Color.fromRGBO(87, 148, 221, 1),
                                ]),
                                style: TextStyle(
                                  color: Color.fromRGBO(200, 200, 200, 1),
                                  fontSize: 12.sp,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                      GanttDisplayChartWidget(
                        tasks: [
                          GanttTask("Planning", 0, 1),
                          GanttTask("Demolition", 1, 3),
                          GanttTask("Electrical/Plumbing", 1.2, 4),
                          GanttTask("Framing/Drywall", 4.3, 8),
                          GanttTask("Paint", 5, 9),
                          GanttTask("Cabinets Fixtures", 4, 5),
                          GanttTask("Doors/Surrounds", 6, 8),
                          GanttTask("Cleaning", 4.5, 10),
                          GanttTask("Flooring", 3, 10),
                          GanttTask("Trim/Finish Work", 9, 10),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
