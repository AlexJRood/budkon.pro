// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:core/theme/backgroundgradient.dart';
// import 'package:core/theme/design.dart';
// import 'package:core/shell/keyboard_shortcuts.dart';
// import 'package:core/platform/api_services.dart';
// import 'package:portal/screens/landing_page/widgets/landing_page_pc/featured_news_widget.dart';
// import 'package:portal/screens/landing_page/widgets/landing_page_pc/footer_widget.dart';
// import 'package:portal/screens/home_page/widgets/home_page/best_in.dart';
// import 'package:portal/screens/home_page/widgets/home_page/hot_carousel.dart';
// import 'package:core/common/chrome/side_menu_manager.dart';
// import 'package:core/shell/portal/sidebar.dart';
// import 'package:portal/bars/top_app_bar_portal.dart';
// import 'package:pie_menu/pie_menu.dart';

// import 'package:core/ui/side_menu/slide_rotate_menu.dart';

// class HomePcPage extends ConsumerStatefulWidget {
//   const HomePcPage({super.key});

//   @override
//   ConsumerState<HomePcPage> createState() => _HomePcPageState();
// }

// class _HomePcPageState extends ConsumerState<HomePcPage>   with AutomaticKeepAliveClientMixin {
//   final sideMenuKey = GlobalKey<SideMenuState>();
//   late FocusNode _focusNode;
//   @override
//   void initState() {
//     super.initState();
//     _focusNode = FocusNode();
//      WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         _focusNode.requestFocus();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _focusNode.dispose();
//     super.dispose();
//   }

//    @override
//   bool get wantKeepAlive => true;


//   @override
//   Widget build(BuildContext context) {
//      super.build(context);
//     final isUserLoggedIn = ApiServices.isUserLoggedIn();

//     double screenWidth = MediaQuery.of(context).size.width;
//     const double maxWidth = 1920;
//     const double minWidth = 350;
//     const double maxDynamicPadding = 40;
//     const double minDynamicPadding = 5;

//     double dynamicPadding =
//         (screenWidth - minWidth) /
//             (maxWidth - minWidth) *
//             (maxDynamicPadding - minDynamicPadding) +
//         minDynamicPadding;
//     dynamicPadding = dynamicPadding.clamp(minDynamicPadding, maxDynamicPadding);
//     ScrollController scrollController = ScrollController();
//     return KeyboardListener(
//       focusNode: _focusNode,
//       onKeyEvent: (KeyEvent event) {
//         // Check if the pressed key matches the stored pop key
//         KeyBoardShortcuts().filterpop(event, ref, context);
//         KeyBoardShortcuts().sortpopup(event, ref, context);
//         KeyBoardShortcuts().handleKeyNavigation(event, ref, context);
//         KeyBoardShortcuts().handleKeyEvent(event, scrollController, 200, 50);
//       },
//       child: PieCanvas(
//         theme: const PieTheme(
//           rightClickShowsMenu: true,
//           leftClickShowsMenu: false,
//           buttonTheme: PieButtonTheme(
//             backgroundColor: AppColors.buttonGradient1,
//             iconColor: Colors.white,
//           ),
//           buttonThemeHovered: PieButtonTheme(
//             backgroundColor: Color.fromARGB(96, 58, 58, 58),
//             iconColor: Colors.white,
//           ),
//         ),
//         child: Scaffold(
//           body: SideMenuManager.sideMenuSettings(
//             menuKey: sideMenuKey,
//             child: Stack(
//               children: [
//                 Row(
//                   children: [
//                     SidebarPortal(sideMenuKey: sideMenuKey),
//                     Expanded(
//                       child: Container(
//                         height: double.infinity,
//                         decoration: BoxDecoration(
//                           gradient:
//                               CustomBackgroundGradients.getMainMenuBackground(
//                                 context,
//                                 ref,
//                               ),
//                         ),
//                         child: SingleChildScrollView(
//                           controller: scrollController,
//                           child: Column(
//                             children: [
//                               Padding(
//                                 padding: EdgeInsets.only(
//                                   left: dynamicPadding,
//                                   right: dynamicPadding,
//                                 ),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     const SizedBox(height: 65.0),
//                                     const SizedBox(height: 5.0),
//                                     // const HelpBar(),
//                                     const SizedBox(height: 25.0),
//                                     // if (isUserLoggedIn) ...[
//                                     //   // Użycie operatora spread do opcjonalnego włączenia widżetu
//                                     //   const RecentlyViewedAds(),
//                                     //   const SizedBox(height: 50),
//                                     // ],
//                                     FeaturedNewsWidget(paddingDynamic: 0),
//                                     const SizedBox(height: 50),
//                                     const HotCarousel(),
//                                     const SizedBox(height: 100.0),
//                                     const SizedBox(height: 100.0),
//                                     // const ArticlesModule(),
//                                     // const SizedBox(height: 100.0),
//                                     const BestIn(),
//                                     // const SizedBox(
//                                     //   height: 25,
//                                     // ),
//                                     // const BestIn2(),
//                                     const SizedBox(height: 100.0),
//                                     // const WhyUs(),
//                                     // const SizedBox(height: 100.0),
//                                   ],
//                                 ),
//                               ),
//                               FooterWidget(paddingDynamic: dynamicPadding),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Positioned(top: 0, right: 0, child: TopAppBarPortal()),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
