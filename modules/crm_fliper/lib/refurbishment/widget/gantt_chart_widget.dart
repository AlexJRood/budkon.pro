import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/common/models/gantt_task_model.dart';
import 'package:crm_fliper/refurbishment/provider/refurbishment_provider.dart';
import 'package:crm_fliper/refurbishment/widget/gantt_display_chart_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';

class GanttChartWidget extends ConsumerStatefulWidget {
  const GanttChartWidget({super.key});

  @override
  ConsumerState<GanttChartWidget> createState() => _GanttChartWidgetState();
}

class _GanttChartWidgetState extends ConsumerState<GanttChartWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refurbishmentTaskProvider.notifier).refurbishmentFetchTask(ref);
      ref.read(refurbishmentProgressProvider.notifier).refurbishmentFetchProgress(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(refurbishmentTaskProvider);
    final dates = ref.watch(refurbishmentProgressProvider);

    // Ensure we iterate only up to the minimum length of both lists.
    final int count = tasks.length < dates.length ? tasks.length : dates.length;

    // Combine the tasks and dates (including plannedEndDate) into a single list.
    final combined = List.generate(count, (i) {
      return {
        'taskName': tasks[i].taskName,
        'plannedStartDate': dates[i].plannedStartDate,
        'plannedEndDate': dates[i].plannedEndDate,
      };
    });

    // Sort by plannedStartDate (ascending).
    combined.sort((a, b) {
      final dateA = DateTime.parse(a['plannedStartDate']!);
      final dateB = DateTime.parse(b['plannedStartDate']!);
      return dateA.compareTo(dateB);
    });

    // Use the earliest plannedStartDate as baseline.
    DateTime? earliest;
    if (combined.isNotEmpty) {
      earliest = DateTime.parse(combined.first['plannedStartDate']!);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Parker Rd. Allentown".tr,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(255, 255, 255, 1),
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  "Warszawa, Mokotów, Poland",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Color.fromRGBO(200, 200, 200, 1),
                  ),
                ),
              ],
            ),
          ),
          // ListView.builder displays one GanttDisplayChartWidget per task.
          ListView.builder(
            itemCount: combined.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final item = combined[index];
              final taskName = item['taskName'] as String;
              final plannedStartStr = item['plannedStartDate'] as String;
              final plannedEndStr = item['plannedEndDate'] as String;

              final startDate = DateTime.parse(plannedStartStr);
              final endDate = DateTime.parse(plannedEndStr);

              double startOffset = 0.0;
              double endOffset = 0.0;
              if (earliest != null) {
                startOffset = startDate.difference(earliest).inDays.toDouble();
                endOffset = endDate.difference(earliest).inDays.toDouble();
              }

              return GanttDisplayChartWidget(
                tasks: [
                  GanttTask(taskName, startOffset, endOffset),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
