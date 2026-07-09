import 'package:flutter/material.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/task_creation_list_view_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/icons.dart';

class TransactionTaskCreationWidget extends StatelessWidget {
  const TransactionTaskCreationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420.h,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        color: const Color.fromRGBO(33, 32, 32, 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'Task Creation',
                style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                height: 32.h,
                width: 96.w,
                decoration: BoxDecoration(
                    color: const Color.fromRGBO(79, 79, 79, 1),
                    borderRadius: BorderRadius.circular(6.r)),
                child:  Center(
                  child: Row(
                    spacing: 5.w,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppIcons.add(
                        color: Color.fromRGBO(233, 233, 233, 1),
                        height: 15.h,
                        width: 15.h
                      ),
                      Text(
                        'Add task',
                        style: TextStyle(
                            color: Color.fromRGBO(233, 233, 233, 1),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
          const Expanded(
            child: TaskCreationListViewWidget(),
          )
        ],
      ),
    );
  }
}
