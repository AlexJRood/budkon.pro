// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:core/theme/backgroundgradient.dart';
// import 'package:core/theme/design.dart';
// import 'package:core/common/install_popup.dart';
// import 'package:core/platform/api_services.dart';
// import 'package:portal/screens/home_page/widgets/home_page/articles_module.dart';
// import 'package:portal/screens/home_page/widgets/home_page/best_in.dart';
// import 'package:portal/screens/home_page/widgets/home_page/best_in2.dart';
// import 'package:portal/screens/home_page/widgets/home_page/help_bar.dart';
// import 'package:portal/screens/home_page/widgets/home_page/hot_carousel.dart';
// import 'package:portal/screens/home_page/widgets/home_page/recomended_for_you.dart';
// import 'package:portal/screens/home_page/widgets/home_page/why_us.dart';
// import 'package:core/common/chrome/side_menu_manager.dart';
// import 'package:portal/bars/bottom_bar.dart';
// import 'package:core/common/chrome/appbar_mobile.dart';
// import 'package:pie_menu/pie_menu.dart';

// import 'package:core/ui/side_menu/slide_rotate_menu.dart';

// class HomePageMobile extends ConsumerStatefulWidget {
//   const HomePageMobile({super.key});

//   @override
//   ConsumerState<HomePageMobile> createState() => _HomePageMobileState();
// }

// class _HomePageMobileState extends ConsumerState<HomePageMobile> {
//   double dynamicPadding = 0.0;
//   final sideMenuKey = GlobalKey<SideMenuState>();

//   @override
//   Widget build(BuildContext context) {
//     final isUserLoggedIn = ApiServices.isUserLoggedIn();
//     double screenWidth = MediaQuery.of(context).size.width;

//     // Constants
//     const double maxWidth = 1920;
//     const double minWidth = 350;
//     const double maxDynamicPadding = 40;
//     const double minDynamicPadding = 3;

//     // Calculate dynamic padding based on screen width
//     dynamicPadding = (screenWidth - minWidth) /
//             (maxWidth - minWidth) *
//             (maxDynamicPadding - minDynamicPadding) +
//         minDynamicPadding;

//     // Clamp the value within min and max bounds
//     dynamicPadding = dynamicPadding.clamp(minDynamicPadding, maxDynamicPadding);
//     return PieCanvas(
//       theme: const PieTheme(
//         rightClickShowsMenu: true,
//         leftClickShowsMenu: false,
//         buttonTheme: PieButtonTheme(
//           backgroundColor: AppColors.themeColor,
//           iconColor: Colors.white,
//         ),
//         buttonThemeHovered: PieButtonTheme(
//           backgroundColor: Color.fromARGB(96, 58, 58, 58),
//           iconColor: Colors.white,
//         ),
//       ),
//       child: PopupListener(
//         child: SafeArea(
//           top: false,
//           bottom: false,
//           child: Scaffold(
//             body: SideMenuManager.sideMenuSettings(
//               menuKey: sideMenuKey,
//               child: Stack(
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                         gradient: CustomBackgroundGradients.getMainMenuBackground(
//                             context, ref)),
//                     child: Column(
//                       children: [
//                         Expanded(
//                           child: SingleChildScrollView(
//                             padding:
//                                 EdgeInsets.symmetric(horizontal: dynamicPadding),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const SizedBox(height: 60,),
//                                 const SizedBox(height: 10.0),
//                                 const HelpBar(),
//                                 const SizedBox(height: 25.0),
//                                 // if (isUserLoggedIn) ...[
//                                 //   const RecentlyViewedAds(),
//                                 //   const SizedBox(height: 25),
//                                 // ],
//                                 const HotCarousel(),
//                                 const SizedBox(height: 50.0),
//                                 const RecomendedForYou(),
//                                 const SizedBox(height: 50.0),
//                                 const ArticlesModule(),
//                                 const SizedBox(height: 50.0),
//                                 const BestIn(),
//                                 const SizedBox(height: 15),
//                                 const BestIn2(),
//                                 const SizedBox(height: 50.0),
//                                 const WhyUs(),
//                                 const SizedBox(height: 50.0),
//                                 const SizedBox(height: 55,)
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Positioned(
//                     bottom: 0,
//                     right: 0,
//                     child: 
//                   BottomBarMobile(),),
                      
//                   Positioned(
//                     top: 0,
//                     right: 0,
//                     child: AppBarMobile(sideMenuKey: sideMenuKey,),),
          
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }