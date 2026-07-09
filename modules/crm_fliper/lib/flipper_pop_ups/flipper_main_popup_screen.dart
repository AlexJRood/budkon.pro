import 'package:flutter/material.dart';
import 'package:crm_fliper/flipper_pop_ups/flipper_main_mobile_pop_up.dart';
import 'package:crm_fliper/flipper_pop_ups/flipper_main_pc_pop_up.dart';

class FlipperMainPopupScreen extends StatelessWidget {
  const FlipperMainPopupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 1080) {
          return const FlipperMainPcPopUp();
        } else {
          return const FlipperMainMobilePopUp();
        }
      },
    );
  }
}
