import 'package:flutter/material.dart';
import 'package:crm_fliper/flipper_pop_ups/calculation_pop_up/widget/calculator_flip_widget.dart';
import 'package:crm_fliper/flipper_pop_ups/calculation_pop_up/widget/calculator_profit_results_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CalculationPopUpScreen extends StatelessWidget {
  const CalculationPopUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: const Color.fromRGBO(90, 90, 90, 1))),
        child: const SingleChildScrollView(
          child: Row(
            children: [
              CalculatorProfitResultsWidget(),
              Expanded(child: CalculatorFlipWidget())
            ],
          ),
        ),
      ),
    );
  }
}
