import 'package:flutter/material.dart';
import 'package:crm_fliper/finance/finance_mobile_screen.dart';
import 'package:crm_fliper/finance/finance_pc_screen.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 1080) {
          return const FinancePcScreen();
        } else {
          return const FinanceMobileScreen();
        }
      },
    );
  }
}
