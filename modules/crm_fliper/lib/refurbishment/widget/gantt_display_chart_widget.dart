import 'package:flutter/material.dart';
import 'package:core/common/models/gantt_task_model.dart';
import 'package:crm_fliper/refurbishment/widget/gantt_bar_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GanttDisplayChartWidget extends StatelessWidget {
  final List<GanttTask> tasks;
  const GanttDisplayChartWidget({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GanttHeader(),
          GanttTaskRows(tasks: tasks),
        ],
      ),
    );
  }
}

class GanttHeader extends StatelessWidget {
  const GanttHeader({super.key});

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return "$day/$month/$year";
  }

  @override
  Widget build(BuildContext context) {
    final baseDate = DateTime(2025, 1, 1);
    return Container(
      color: const Color.fromRGBO(33, 32, 32, 1),
      padding:  EdgeInsets.symmetric(vertical: 8.h),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
           SizedBox(width: 150.w),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              10,
              (index) {
                final currentDate = baseDate.add(Duration(days: index));
                return Container(
                  width: 100.w,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey[800]!),
                      left: BorderSide(color: Colors.grey[800]!),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      formatDate(currentDate),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12.sp),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GanttTaskRows extends StatelessWidget {
  final List<GanttTask> tasks;
  const GanttTaskRows({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(tasks.length, (index) {
        final task = tasks[index];
        return Container(
          height: 40.h,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: index.isEven
                ? Colors.transparent
                : const Color.fromRGBO(33, 32, 32, 1),
            border: Border(
              bottom: BorderSide(color: Colors.grey[700]!),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 150.w,
                height: 42.h,
                padding: const EdgeInsets.only(left: 8.0, top: 10, bottom: 10),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey[700]!),
                  ),
                ),
                child: Text(
                  task.name,
                  style:  TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
              ),
              GanttBarWidget(start: task.start, end: task.end),
            ],
          ),
        );
      }),
    );
  }
}
