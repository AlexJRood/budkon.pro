import 'package:flutter/material.dart';
import 'package:network_monitoring/screens/fav/nm_fav_mobile_page.dart';
import 'package:network_monitoring/screens/fav/nm_fav_pc_page.dart';

class NMFavPage extends StatelessWidget {
  const NMFavPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 1080) {
          return const NMFavPcPage(); // Widok dla mniejszych ekranów
        } else {
          return const NMFavMobilePage(); // Widok dla większych ekranów
        }
      },
    );
  }
}
