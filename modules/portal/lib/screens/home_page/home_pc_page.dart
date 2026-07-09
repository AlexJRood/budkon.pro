// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:core/platform/api_services.dart';
// import 'package:showcaseview/showcaseview.dart';
// import 'package:portal/screens/landing_page/landing_page_mobile.dart';
// import 'package:portal/screens/landing_page/landing_page_mobile.dart';

// class HomePage extends ConsumerWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final isUserLoggedIn = ApiServices.isUserLoggedIn();

//     return LayoutBuilder(
//       builder: (BuildContext context, BoxConstraints constraints) {
//         // if (isUserLoggedIn) {
//           if (constraints.maxWidth < 1080) {
//             // Jeśli jest to aplikacja webowa lub aplikacja desktopowa z szerokością większą niż 1420
//         //     return const HomePageMobile();
//         //   } else {
//         //     // W przeciwnym razie (aplikacja mobilna lub aplikacja desktopowa z mniejszą szerokością)
//         //     return const HomePcPage();
//         //   }
//         // } else if (constraints.maxWidth < 1080) {
//           // Jeśli jest to aplikacja webowa lub aplikacja desktopowa z szerokością większą niż 1420
//           return ShowCaseWidget(
//               autoPlay: true,
//               onStart: (index, key) {
//                 log('onStart: $index, $key');
//               },
//               blurValue: 1,
//               autoPlayDelay: const Duration(seconds: 10),
//               builder: (context) => LandingPageMobile(isUserLoggedIn: isUserLoggedIn)
//               );
//         } else {
//           // W przeciwnym razie (aplikacja mobilna lub aplikacja desktopowa z mniejszą szerokością)
//           return ShowCaseWidget(
//               autoPlay: true,
//               onStart: (index, key) {
//                 log('onStart: $index, $key');
//               },
//               blurValue: 1,
//               autoPlayDelay: const Duration(seconds: 10),
//               builder: (context) => LandingPagePc(isUserLoggedIn: isUserLoggedIn));
//         }
//       },
//     );
//   }
// }