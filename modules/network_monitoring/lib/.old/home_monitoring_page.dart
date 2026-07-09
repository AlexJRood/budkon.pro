import 'package:flutter/material.dart';
import 'package:hously_flutter/screens/network_monitoring/.old/home_monitoring_mobile_page.dart';
import 'package:hously_flutter/screens/network_monitoring/.old/home_monitoring_pc_page.dart';

class HomeMonitoringPage extends StatelessWidget {
  const HomeMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 1080) {
          // Jeśli jest to aplikacja webowa lub aplikacja desktopowa z szerokością większą niż 1420
          return const HomeMonitoringPcPage();
        } else {
          // W przeciwnym razie (aplikacja mobilna lub aplikacja desktopowa z mniejszą szerokością)
          return const HomeMonitoringMobilePage();
        }
      },
    );
  }
}
