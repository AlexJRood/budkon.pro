import 'package:flutter/material.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/activity_timeline_check_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ActivityTimeLineWidget extends StatelessWidget {
  final bool isMobile;
  const ActivityTimeLineWidget({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Activity timeline',
            style: TextStyle(
                color: Color.fromRGBO(255, 255, 255, 1),
                fontWeight: FontWeight.bold,
                fontSize: 18.sp),
          ),
           SizedBox(
            height: 10.h,
          ),
          ActivityTimelineCheckWidget(
              isMobile: isMobile, title: 'Flipper offer', date: '01-02-2025'),
          ActivityTimelineCheckWidget(
              isMobile: isMobile,
              title: 'Player Counteroffer',
              date: '10-02-2025'),
          ActivityTimelineCheckWidget(
              isMobile: isMobile, title: 'Renegotiation', date: '12-02-2025'),
          ActivityTimelineCheckWidget(
              isMobile: isMobile, title: 'Player Response', date: '17-02-2025'),
          ActivityTimelineCheckWidget(
              isMobile: isMobile, title: 'Deal Approved', date: '01-02-2025'),
        ],
      ),
    );
  }
}
