import 'package:core/shell/manager/bar_manager.dart';
import 'package:fav_board/providers/network_board_provider.dart';
import 'package:fav_board/providers/portal_board_provider.dart';
import 'package:fav_board/widgets/favorite_properties_board_grid_view_widget.dart';
import 'package:fav_board/widgets/unorganized_properties_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';

class FavScreen extends ConsumerStatefulWidget {
  final AppModule appModule;
  const FavScreen({super.key, this.appModule = AppModule.portal});

  @override
  ConsumerState<FavScreen> createState() => _FavScreenState();
}

class _FavScreenState extends ConsumerState<FavScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.read(portalBoardsProvider.notifier).fetchPortalBoards();
      ref.read(networkBoardsProvider.notifier).fetchNetworkFavBoards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: widget.appModule,
      enableScrool: true,
      
      childrenPc:[
              FavoritePropertiesBoardGridViewWidget(),
              UnOrganizedPropertiesWidget(),
            ],

      childrenMobile: [
        // SizedBox(
        //   height: TopAppBarSize.resolve(context),
        // ),
         FavoritePropertiesBoardGridViewWidget(isMobile: true,),
         UnOrganizedPropertiesWidget(isMobile: true,),
      //   SizedBox(
      // height: BottomBarSize.resolve(context),
      //   ),
      ]
    );
  }
}
