import 'package:flutter/material.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/transaction_details.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TransactionPopUpMobileScreen extends StatelessWidget {
  const TransactionPopUpMobileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          spacing: 20.h,
          children: [
            TransActionDetails(
              isMobile: true,
            ),
          ],
        ),
      ),
    );
  }
}
