import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/feed/components/view/slected_view_provider.dart';
import 'package:portal/screens/feed/components/map/map_visuals.dart';
import 'package:portal/screens/pop_pages/pages/sort_pop_page.dart';
import 'package:portal/screens/pop_pages/pages/view_settings_page.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/shell/components/searchbar.dart' as custom_search_bar;

class TopAppBarMap extends ConsumerWidget {
  const TopAppBarMap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey coToMaRobicTopAppBarMap = GlobalKey();
    final GlobalKey sortButtonTopAppBarMap = GlobalKey();
    final screenWidth = MediaQuery.of(context).size.width;
    final widthRatio = screenWidth / 1920.0;
    final dynamicSizedBoxWidth = 100.0 * widthRatio - 50;
    final mapOverlayPalette = ref.watch(mapOverlayPaletteProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: () {
              final RenderBox? buttonRenderBox =
                  coToMaRobicTopAppBarMap.currentContext?.findRenderObject()
                      as RenderBox?;
              if (buttonRenderBox == null) return;
              final Offset buttonPosition =
                  buttonRenderBox.localToGlobal(Offset.zero);
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, __, ___) =>
                      ViewSettingsPage(buttonPosition: buttonPosition),
                  transitionsBuilder: (_, anim, __, child) {
                    return FadeTransition(opacity: anim, child: child);
                  },
                ),
              );
            },
            child: Hero(
              tag: 'CoToMaRobic-${UniqueKey().toString()}',
              child: Container(
                key: coToMaRobicTopAppBarMap,
                height: 30,
                width: 30,
                color: Colors.transparent,
                  child: AppIcons.global(
                    color: mapOverlayPalette.buttonColor,
                    height: 25.0,
                    width: 25,
                  ),
              ),
            ),
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: custom_search_bar.SearchBar(),
          ),
        ),
        SizedBox(
          height: 60,
          width: 60,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: () {
              final RenderBox? buttonRenderBox =
                  sortButtonTopAppBarMap.currentContext?.findRenderObject()
                      as RenderBox?;
              if (buttonRenderBox == null) return;
              final Offset buttonPosition =
                  buttonRenderBox.localToGlobal(Offset.zero);
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, __, ___) =>
                      SortPopPage(buttonPosition: buttonPosition),
                  transitionsBuilder: (_, anim, __, child) {
                    return FadeTransition(opacity: anim, child: child);
                  },
                ),
              );
            },
            child: Hero(
              tag: 'SortBarButton-${UniqueKey().toString()}',
              child: Container(
                key: sortButtonTopAppBarMap,
                height: 35,
                width: 35,
                color: Colors.transparent,
              
                  child: AppIcons.sort(
                    color: mapOverlayPalette.buttonColor,
                    height: 30.0,
                    width: 30,
                  ),
                ),
            ),
          ),
        ),
        const SizedBox(width: 15),

        const MapFeedToggleSelector(
          currentView: FeedMapViewMode.map,
          feedRoute: '/feed',
          mapRoute: '/mapview',
        ),

        const SizedBox(width: 15),
        const CardTypeSelector(),

        SizedBox(width: dynamicSizedBoxWidth),
      ],
    );
  }
}