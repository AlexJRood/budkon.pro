import 'package:flutter/material.dart';
import 'package:crm_fliper/finance/finance2/finance_2_mobile_screen.dart';
import 'package:crm_fliper/finance/finance2/finance_2_pc_screen.dart';

class Finance2Screen extends StatelessWidget {
  const Finance2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 1080) {
          return const Finance2PcScreen();
        } else {
          return const Finance2MobileScreen();
        }
      },
    );
  }
}
