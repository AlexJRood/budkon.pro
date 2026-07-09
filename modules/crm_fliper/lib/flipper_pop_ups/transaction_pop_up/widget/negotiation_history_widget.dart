import 'package:flutter/material.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/negotiation_history_list_view_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NegotiationHistoryWidget extends StatelessWidget {
  const NegotiationHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 521.h,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Color.fromRGBO(50, 50, 50, 1),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 57.h,
            width: MediaQuery.of(context).size.width,
            decoration:
                const BoxDecoration(color: Color.fromRGBO(50, 50, 50, 1)),
            child:  Align(
              alignment:Alignment.centerLeft,
              child: Text(
                '   Negotiation history',
                style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Expanded(
            child: NegotiationHistoryListViewWidget(),
          )
        ],
      ),
    );
  }
}
