// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:network_monitoring/screens/feed_page/nm_feed_mobile.dart';
// import 'package:network_monitoring/screens/feed_page/nm_feed_pc.dart';


// class NMFeedPage extends ConsumerWidget {
//   const NMFeedPage({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return LayoutBuilder(
//       builder: (BuildContext context, BoxConstraints constraints) {
//         if (constraints.maxWidth > 1080) {
//           // Jeśli jest to aplikacja webowa lub aplikacja desktopowa z szerokością większą niż 1420
//           return const NMFeedPc();
//         } else {
//           // W przeciwnym razie (aplikacja mobilna lub aplikacja desktopowa z mniejszą szerokością)
//           return const NMFeedMobile();
//         }
//       },
//     );
//   }
// }
