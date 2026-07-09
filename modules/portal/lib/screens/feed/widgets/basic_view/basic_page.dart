import 'package:flutter/material.dart';
import 'package:portal/screens/feed/widgets/basic_view/ads_view_pc.dart';
import 'package:portal/screens/feed/widgets/basic_view/grid_mobile_page.dart';

class BasicPage extends StatelessWidget {
  const BasicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 560) {

          return const GridMobilePage();
        } else {
          return const AdsViewPage();
        }
      },
    );
  }
}
