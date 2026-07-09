import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/go_pro_cards.dart';
import '../components/go_pro_components.dart';

class GoProMobile extends ConsumerWidget {
  const GoProMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const RealEstateGoalsWidget(isMobile: true),
          const Tabview(isMobile: true),
          SizedBox(height: TopAppBarSize.withTopAppBar(context)),
        ],
      ),
    );
  }
}
