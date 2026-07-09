// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:network_monitoring/screens/saved_search_new_screens/widgets/network_monitoring_feed_bar_vertical.dart';
// import 'package:network_monitoring/screens/feed_page/widgets/nm_grid_mobile.dart';
// import 'package:core/theme/backgroundgradient.dart';


// class NMFeedMobile extends ConsumerWidget {
//   const NMFeedMobile({super.key});

//   @override
//   Widget build(BuildContext context,WidgetRef ref) {

//     return Stack(
//               children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       gradient: CustomBackgroundGradients.getMainMenuBackground(
//                           context, ref),
//                     ),
//                     child: 
//                         const NMGridViewMobile(),
//                 ),
//                 Positioned(
//                   bottom: 55,
//                   right: 5,
//                   child: NetworkMonitoringFeedBarVerticalMobile(ref: ref),
//                 )
//               ],
//     );
//   }
// }
