// import 'package:core/shell/manager/bar_manager.dart';
// import 'package:fav_board/providers/network_board_provider.dart';
// import 'package:fav_board/providers/portal_board_provider.dart';
// import 'package:fav_board/widgets/favorite_properties_board_grid_view_widget.dart';
// import 'package:fav_board/widgets/unorganized_properties_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:core/theme/backgroundgradient.dart';
// import 'package:core/theme/design.dart';
// import 'package:core/common/chrome/side_menu_manager.dart';
// import 'package:core/shell/sidebar/sidebar.dart';
// import 'package:pie_menu/pie_menu.dart';
// import 'package:core/ui/side_menu/slide_rotate_menu.dart';

// class FavPcScreen extends ConsumerStatefulWidget {
//   const FavPcScreen({super.key});

//   @override
//   ConsumerState<FavPcScreen> createState() => _FavPcScreenState();
// }

// class _FavPcScreenState extends ConsumerState<FavPcScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
//       ref.read(portalBoardsProvider.notifier).fetchPortalBoards();
//       ref.read(networkBoardsProvider.notifier).fetchNetworkFavBoards();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final sideMenuKey = GlobalKey<SideMenuState>();
//     return BarManager(
//       sideMenuKey: sideMenuKey,
//       appModule: AppModule.portal,
//       enableScrool: true,

//       childrenPc:[
//               FavoritePropertiesBoardGridViewWidget(),
//               UnOrganizedPropertiesWidget(),
//             ],

//       childrenMobile: [
//          FavoritePropertiesBoardGridViewWidget(isMobile: true,),
//          UnOrganizedPropertiesWidget()
//       ]
//     );
//   }
// }
