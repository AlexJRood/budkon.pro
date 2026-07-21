
// import 'package:flutter/material.dart';

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:budkon_flutter/const/backgroundgradient.dart';
// import 'package:budkon_flutter/screens/go_pro/pc/components/const.dart';
// import 'package:budkon_flutter/screens/go_pro/pc/components/pro_cards.dart';
// import 'package:budkon_flutter/widgets/appbar/hously/pc/appbar_logo.dart';
// import 'package:budkon_flutter/widgets/side_menu/side_menu_manager.dart';
// import 'package:budkon_flutter/widgets/sidebar/sidebar.dart';

// import 'package:budkon_flutter/widgets/side_menu/slide_rotate_menu.dart';

// class GoProPc extends ConsumerWidget {
//   const GoProPc({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final sideMenuKey = GlobalKey<SideMenuState>();

//     return Scaffold(
//       body: SideMenuManager.sideMenuSettings(
//         menuKey: sideMenuKey,
//         child: Container(
//           decoration: BoxDecoration(
//               gradient: CustomBackgroundGradients.getMainMenuBackground(
//                   context, ref)),
//           child: Row(
//             children: [
//                Sidebar(
//                  sideMenuKey: sideMenuKey,
//                ),
//               Expanded(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const TopAppBarLogoOnly(),
//                     RealEstateGoalsWidget(),
//                     Expanded(
//                       child: Tabview(),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class Tabview extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 4, // Number of tabs/categories
//       child: Column(
//         children: [
//           TabBar(
//             dividerColor: Colors.transparent,
//             unselectedLabelColor: Colors.white,
//             labelColor: Colors.white,
//             indicator: const BoxDecoration(
//               color: Color(0xFF1d1d1f),
//             ),
//             isScrollable: true,
//             tabs: [
//               Container(
//                 width: 100,
//                 alignment: Alignment.center,
//                 child: Tab(
//                   text: "Agent".tr,
//                   height: 40,
//                 ),
//               ),
//               Container(
//                 width: 100,
//                 alignment: Alignment.center,
//                 child: Tab(
//                   text: "Investor".tr,
//                   height: 40,
//                 ),
//               ),
//               Container(
//                 width: 100,
//                 alignment: Alignment.center,
//                 child: Tab(
//                   text: "Individual".tr,
//                   height: 40,
//                 ),
//               ),
//               Container(
//                 width: 100,
//                 alignment: Alignment.center,
//                 child: Tab(
//                   text: "Landlord".tr,
//                   height: 40,
//                 ),
//               ),
//             ],
//           ),
//           Expanded(
//             child: TabBarView(
//               children: [
//                 SubscriptionPlans(category: "Agent".tr),
//                 SubscriptionPlans(category: "Investor".tr),
//                 SubscriptionPlans(category: "Individual".tr),
//                 SubscriptionPlans(category: "Landlord".tr),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class SubscriptionPlans extends StatelessWidget {
//   final String category;

//   const SubscriptionPlans({required this.category});

//   @override
//   Widget build(BuildContext context) {
//     final filteredPlans = subscriptionPackages
//         .where((plan) => plan.userCategory == category)
//         .toList();

//     return ListView.builder(
//       padding: EdgeInsets.all(16),
//       itemCount: filteredPlans.length,
//       itemBuilder: (context, index) {
//         final plan = filteredPlans[index];
//         return PremiumCard(onPressed: ,
//           mainContainerHeight: 450,
//           innerContainerHeight: 400,
//           title: 'Premium',
//           originalPrice: '\$99.00',
//           discountedPrice: '\$89.00',
//           pricingDescription: '/month per user',
//           features: [
//             'Track views, clicks, and leads'.tr,
//             'Priority visibility with a "Gold".tr badge',
//             'Advanced analytics and insights'.tr,
//           ],
//         );
//       },
//     );
//   }
// }
