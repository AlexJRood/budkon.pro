import 'package:flutter/material.dart';
import 'package:crm_fliper/refurbishment/widget/gantt_chart_widget.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/flipper_custom_list_view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RefurbishmentPcScreen extends StatelessWidget {
  const RefurbishmentPcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: EdgeInsets.symmetric(horizontal: 160.0.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 40.w,
        children: [
          FlipperCustomListView(title: '', itemCount: 10, id: 6),
          Expanded(child: GanttChartWidget()),
        ],
      ),
    );
  }
}



