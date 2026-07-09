// import 'package:core/shell/appbar/hously/mobile/appbar_mobile.dart';
// import 'package:core/shell/bottom_bar_mobile/bottom_bar.dart';
// import 'package:core/common/chrome/side_menu_manager.dart';
// import 'package:core/ui/side_menu/slide_rotate_menu.dart';
// import 'package:fav_board/providers/portal_board_provider.dart';
// import 'package:fav_board/widgets/favorite_properties_board_grid_view_widget.dart';
// import 'package:fav_board/widgets/unorganized_properties_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:core/common/install_popup.dart';
// import 'package:core/theme/backgroundgradient.dart';
// import 'package:pie_menu/pie_menu.dart';
// import 'package:core/theme/design.dart';

// class FavMobileScreen extends ConsumerStatefulWidget {
//   const FavMobileScreen({super.key});

//   @override
//   ConsumerState<FavMobileScreen> createState() => _FavMobileScreenState();
// }

// class _FavMobileScreenState extends ConsumerState<FavMobileScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
//       ref.read(portalBoardsProvider.notifier).fetchPortalBoards();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final sideMenuKey = GlobalKey<SideMenuState>();
//     return PieCanvas(
//       theme: const PieTheme(
//         rightClickShowsMenu: true,
//         leftClickShowsMenu: false,
//         buttonTheme: PieButtonTheme(
//           backgroundColor: AppColors.buttonGradient1,
//           iconColor: Colors.white,
//         ),
//         buttonThemeHovered: PieButtonTheme(
//           backgroundColor: Color.fromARGB(96, 58, 58, 58),
//           iconColor: Colors.white,
//         ),
//       ),
//       child: PopupListener(
//         child: SafeArea(
//           child: Scaffold(
//             backgroundColor: const Color.fromRGBO(19, 19, 19, 1),
//             body: SideMenuManager.sideMenuSettings(
//               menuKey: sideMenuKey,
//               child: Container(
//                 decoration: BoxDecoration(
//                     gradient: CustomBackgroundGradients.getMainMenuBackground(
//                         context, ref)),
//                 child: Column(
//                   children: [
//                     AppBarMobile(sideMenuKey: sideMenuKey),
//                     Expanded(
//                       child: SingleChildScrollView(
//                         child: Column(
//                           children: [
//                             FavoritePropertiesBoardGridViewWidget(
//                               isMobile: true,
//                             ),
//                             Container(
//                                 height: 779.h,
//                                 padding: EdgeInsets.symmetric(horizontal: 40),
//                                 decoration: BoxDecoration(
//                                   color: Color.fromRGBO(33, 32, 32, 1),
//                                 ),
//                                 child: UnOrganizedPropertiesWidget(
//                                   isMobile: true,
//                                 ))
//                           ],
//                         ),
//                       ),
//                     ),
//                     BottomBarMobile()
//                   ],
//                 ),
//               ),
//             ),

//           ),
//         ),
//       ),
//     );
//   }
// }
