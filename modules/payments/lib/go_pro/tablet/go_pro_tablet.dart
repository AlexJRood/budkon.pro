import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/go_pro_cards.dart';
import '../components/go_pro_components.dart';

class GoProTablet extends ConsumerWidget {
  const GoProTablet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          Row(children: [Expanded(child: RealEstateGoalsWidget(isMobile: false))]),
          Tabview(isMobile: false, isTablet: true),
        ],
      ),
    );
  }
}
