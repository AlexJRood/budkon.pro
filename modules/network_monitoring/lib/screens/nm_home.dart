// screens/network_home_page/nm_home.dart
// Main screen + Riverpod tab state. Uses BarManager layout.

import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:network_monitoring/screens/network_home_page/widgets/monitoring_custom_map.dart';
import 'package:network_monitoring/screens/network_home_page/widgets/monitoring_custom_text_field.dart';
import 'package:network_monitoring/screens/network_home_page/widgets/network_home_filter_pop_widget.dart';
import 'package:network_monitoring/screens/network_home_page/widgets/network_monitoring_header_widget.dart';
import 'package:network_monitoring/screens/network_home_page/widgets/real_state_and_home_for_sale_grid_view.dart';
import 'package:network_monitoring/screens/network_home_page/widgets/recently_trending_widget.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';

class SelectedTabNotifier extends StateNotifier<bool> {
  SelectedTabNotifier() : super(true);
  void toggleTab(bool isRecentlyViewed) => state = isRecentlyViewed;
}

final monitoringSelectedTabProvider =
    StateNotifierProvider<SelectedTabNotifier, bool>(
  (ref) => SelectedTabNotifier(),
);

class MonitoringHomeScreen extends ConsumerWidget {
  const MonitoringHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);

    return BarManager(
      appModule: AppModule.networkMonitoring,
      sideMenuKey: sideMenuKey,
      enableScrool: true,

      // ---------- DESKTOP / LARGE ----------
      childrenPc: [
        const NetworkMonitoringHeaderWidget(),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            // Using spacing (if supported by your setup) to keep layout clean
            spacing: 60,
            children: [
              Column(
                spacing: 12,
                children: [
                  // Filter launcher (disabled TextField -> opens filter pop)
                  ElevatedButton(
                    style: elevatedButtonStyleRounded10withoutPadding,
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (_, __, ___) =>
                              const NetworkHomeFilterPopWidget(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                        ),
                      );
                    },
                    child: const MonitoringCustomTextField(enabled: false),
                  ),
                ],
              ),
              const RecentlyTrendingWidget(isMobile: false),
            ],
          ),
        ),
        const MonitoringCustomMap(),
        const RealStateAndHomeForSaleGridView(isMobile: false),
      ],

      // ---------- MOBILE ----------
      childrenMobile: [
        SizedBox(height: TopAppBarSize.resolve(context)),
        const NetworkMonitoringHeaderWidget(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 30,
            children: [
              ElevatedButton(
                    style: elevatedButtonStyleRounded10withoutPadding,
                    onPressed: () {
                       showModalBottomSheet(
                       context: context,
                       isScrollControlled: true, 
                       backgroundColor: Colors.transparent, 
                       shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                         builder: (context) {
                           return DraggableScrollableSheet(
                             initialChildSize: 0.85,
                             minChildSize: 0.4,
                             maxChildSize: 0.95,
                             expand: false,
                             builder: (context, scrollController) => NetworkHomeFilterPopWidget(
                               isMobile: true,
                               scrollController: scrollController,
                             ),
                           );
                         },
               );
             },
                    child: const MonitoringCustomTextField(enabled: false),
                  ),
              
              // TODO: finish flow
              // Row(
              //   spacing: 12,
              //   children: [
              //     const Expanded(child: MonitoringCustomTextField()),
              //     Container(
              //       height: 48,
              //       width: 48,
              //       decoration: BoxDecoration(
              //         color: Colors.transparent,
              //         borderRadius: BorderRadius.circular(6),
              //         border: Border.all(
              //           color: theme.themeColor.withAlpha((255 * 0.7).toInt()),
              //         ),
              //       ),
              //       child: Center(
              //         child: AppIcons.folder(
              //           color: theme.themeColor
              //               .withAlpha((255 * 0.7).toInt()),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              const RecentlyTrendingWidget(isMobile: true),
            ],
          ),
        ),
        const MonitoringCustomMap(isMobile: true),
        const RealStateAndHomeForSaleGridView(isMobile: true),
        SizedBox(height: TopAppBarSize.withTopAppBar(context)),
      ],
    );
  }
}
