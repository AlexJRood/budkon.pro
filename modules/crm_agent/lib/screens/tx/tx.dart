
import 'package:crm_agent/screens/tx/tx_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrasanctionPage extends ConsumerWidget {
  const TrasanctionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const TxPc();
    // return  LayoutBuilder(
        // builder: (BuildContext context, BoxConstraints constraints) {
          // if (constraints.maxWidth > 1080) {
            // return const TxPc();
          // } else {
          //   return DraggableFinanceCrmMobile();
          // }
        // },
    // );
  }
}
