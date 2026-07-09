import 'package:flutter/material.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/activity_time_line_widget.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/add_note_widget.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/custom_calender_widget.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/task_creation_list_view_widget.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/transaction_events_widget.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/nigotiation_header_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/icons.dart';

class TransactionHistoryMobile extends StatelessWidget {
  const TransactionHistoryMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon:
            AppIcons.iosArrowLeft(
              color: Color.fromRGBO(255, 255, 255, 1),
              height: 24.h,
              width: 24.w
            ),),
        title:  Text(
          'History',
          style: TextStyle(
              color: Color.fromRGBO(255, 255, 255, 1),
              fontSize: 18.sp,
              fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          spacing: 20.h,
          children: [
            const NegotiationHeaderWidget(isMobile: true),
            Container(
                decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color.fromRGBO(90, 90, 90, 1)),
                    borderRadius: BorderRadius.circular(6.r)),
                margin:
                     EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                child: const ActivityTimeLineWidget(
                  isMobile: true,
                )),
            Container(
                margin:  EdgeInsets.symmetric(horizontal: 10.w),
                height: 600.h,
                decoration: BoxDecoration(
                    color: const Color.fromRGBO(33, 32, 32, 1),
                    borderRadius: BorderRadius.circular(6.r)),
                child: Column(
                  children: [
                    const Expanded(
                        child: TransActionEventsWidget(
                      isMobile: true,
                    )),
                    Expanded(
                      child: Container(
                        color: const Color.fromRGBO(33, 32, 32, 1),
                        child: CustomCalendarWidget(
                          onDateSelected: (p0) {},
                        ),
                      ),
                    )
                  ],
                )),
            Container(
                height: 400.h,
                margin:  EdgeInsets.symmetric(horizontal: 10.w),
                child:  Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Task Creation',
                          style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700),
                        ),
                        AppIcons.add(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          height: 24.h,
                          width: 24.w
                        ),
                      ],
                    ),
                    Expanded(child: TaskCreationListViewWidget()),
                  ],
                )),
            const Divider(),
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return const AddNoteWidget();
                  },
                ));
              },
              child:  Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        AppIcons.pencil(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          height: 24.h,
                          width: 24.w
                        ),
                        Text(
                          'Add notes',
                          style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    AppIcons.iosArrowRight(
                         color: Color.fromRGBO(255, 255, 255, 1),
                        height: 24.h,
                        width: 24.w
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h,)
          ],
        ),
      ),
    );
  }
}
