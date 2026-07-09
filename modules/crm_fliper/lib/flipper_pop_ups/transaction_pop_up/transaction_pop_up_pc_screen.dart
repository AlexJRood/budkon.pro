import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/icons.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/activity_time_line_widget.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/custom_calender_widget.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/negotiation_history_widget.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/transaction_details.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/transaction_events_widget.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/transaction_task_creation_widget.dart';
import 'package:crm_fliper/refurbishment/provider/refurbishment_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/foundation.dart';


class TransactionPopUpPcScreen extends ConsumerWidget {
  const TransactionPopUpPcScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: const Color.fromRGBO(90, 90, 90, 1)),
        ),
        child: Row(
          spacing: 10.w,
          children: [
            const TransActionDetails(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    spacing: 10.h,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          spacing: 10.r,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            InkWell(
                              onTap: () {},
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6.r),
                                  color: const Color.fromRGBO(33, 32, 32, 1),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10.0.h,
                                    horizontal: 15.w,
                                  ),
                                  child: Row(
                                    spacing: 5.w,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      AppIcons.share(
                                        color: Color.fromRGBO(233, 233, 233, 1),
                                        height: 16.h,
                                        width: 16.w,
                                      ),
                                      Text(
                                        'Share',
                                        style: TextStyle(
                                          color: Color.fromRGBO(
                                            233,
                                            233,
                                            233,
                                            1,
                                          ),
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                ref.read(refurbishmentTaskProvider.notifier).refurbishmentFetchTask(ref)
                                .whenComplete(() {
                                  if (kDebugMode) print(ref.watch(refurbishmentTaskProvider).map((e) => e.taskName,));

                                },);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6.r),
                                  color: const Color.fromRGBO(33, 32, 32, 1),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10.0.h,
                                    horizontal: 15.w,
                                  ),
                                  child: Row(
                                    spacing: 5.w,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      AppIcons.download(
                                        color: Color.fromRGBO(233, 233, 233, 1),
                                        height: 16.h,
                                        width: 16.w,
                                      ),
                                      Text(
                                        'Download',
                                        style: TextStyle(
                                          color: Color.fromRGBO(
                                            233,
                                            233,
                                            233,
                                            1,
                                          ),
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        spacing: 10.w,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              spacing: 20.h,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6.r),
                                    color: const Color.fromRGBO(33, 32, 32, 1),
                                  ),
                                  child: const Row(
                                    children: [
                                      ActivityTimeLineWidget(),
                                      Expanded(
                                        child: NegotiationHistoryWidget(),
                                      ),
                                    ],
                                  ),
                                ),
                                const TransactionTaskCreationWidget(),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              spacing: 20.h,
                              children: [
                                Container(
                                  height: 144.h,
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6.r),
                                    color: const Color.fromRGBO(33, 32, 32, 1),
                                  ),
                                  child: CustomCalendarWidget(
                                    onDateSelected: (p0) {
                                      if (kDebugMode) print(p0);
                                    },
                                  ),
                                ),
                                const TransActionEventsWidget(),
                                Container(
                                  height: 420.h,
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(50, 50, 50, 1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(6.r),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 5.w,
                                    children: [
                                      AppIcons.newChat(
                                        color: Color.fromRGBO(255, 255, 255, 1),
                                        height: 15.h,
                                        width: 15.h,
                                      ),
                                      Text(
                                        'Notes...',
                                        style: TextStyle(
                                          color: Color.fromRGBO(
                                            255,
                                            255,
                                            255,
                                            1,
                                          ),
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
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
            ),
          ],
        ),
      ),
    );
  }
}
