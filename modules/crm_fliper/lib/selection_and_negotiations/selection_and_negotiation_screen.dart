import 'package:flutter/material.dart';
import 'package:crm_fliper/selection_and_negotiations/selection_and_negotiation_mobile_screen.dart';
import 'package:crm_fliper/selection_and_negotiations/selection_and_negotiation_pc_screen.dart';

class SelectionAndNegotiationScreen extends StatelessWidget {
  const SelectionAndNegotiationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 1080) {
          return const SelectionAndNegotiationPcScreen();
        } else {
          return const SelectionAndNegotiationMobileScreen();
        }
      },
    );
  }
}
