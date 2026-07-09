import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/go_pro_cards.dart';
import '../components/go_pro_components.dart';

class GoProPc extends ConsumerWidget {
  const GoProPc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          Row(children: [Expanded(child: RealEstateGoalsWidget())]),
          Tabview(isMobile: false),
        ],
      ),
    );
  }
}
