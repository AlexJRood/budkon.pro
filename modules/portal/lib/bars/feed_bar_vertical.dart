import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/screens/filters/filters_page.dart';
import 'package:portal/screens/pop_pages/pages/sort_pop_mobile_page.dart';
import 'package:portal/screens/pop_pages/pages/view_settings_page.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'dart:ui' as ui;
import 'package:core/theme/icons.dart';




final verticalBottomBarVisibilityProvider = StateProvider<bool>((ref) => true);

class FeedBarVerticalMobile extends ConsumerWidget {
  final WidgetRef ref;

  const FeedBarVerticalMobile({
    super.key,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool _excludeFavorites = false;
    bool _excludeHide = false;
    bool _excludeDisplayed = false;

    final tag = UniqueKey().toString();
    final theme = ref.read(themeColorsProvider);
    final isUserLoggedIn = ApiServices.isUserLoggedIn();
 
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 45,
          height:45,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
                  color: theme.textFieldColor.withAlpha(60),

              ),
              child: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: BuildNavigationOption(
                  tag:  'asdasdasd$tag',
                icon: AppIcons.search(color: theme.textColor),
                label: 'Filters'.tr,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                    builder: (context) {
                      final bottomInset = MediaQuery.of(context).viewInsets.bottom;

                      return AnimatedPadding(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.only(bottom: bottomInset),
                        child: DraggableScrollableSheet(
                          initialChildSize: 0.85,
                          minChildSize: 0.4,
                          maxChildSize: 0.95,
                          expand: false,
                          builder: (ctx, scrollController) => FiltersPage(
                            tag: tag,
                            isNeedToNavigate: true,
                            scrollController: scrollController,
                          ),
                        ),
                      );
                    },
                  ),
          
                heroValue: '3',
              ),
            ),
        ),
      ),
        const SizedBox(height: 2),
        Container(
        width: 45,
        height:45,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
                  color: theme.textFieldColor.withAlpha(80),
                  ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: BuildNavigationOption(
                  tag:  'asdasdsasdsadasd$tag',
                  icon: AppIcons.sort(color: theme.textColor),
                  label: 'Sort'.tr,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    isDismissible: true,
                    enableDrag: true,
                    builder: (context, ) {                                              
                       return DraggableScrollableSheet(                        
                        initialChildSize: 0.6,
                        minChildSize: 0.4,
                        maxChildSize: 0.85,
                        expand: false,
                        builder: (ctx, scrollController) => 
                               SortPopMobilePage(
                                      theme: theme,
                                      isUserLoggedIn: isUserLoggedIn,
                                      scrollController: scrollController,   
                                      isMobile: true,
                        ),
                      );
                    },
                  ),

                  heroValue: '4',
                ),
              ),
            ),
          ),
          
        const SizedBox(height: 2),
        // Container(
        // width: 45,
        // height:45,
        // decoration: BoxDecoration(
        //     borderRadius: BorderRadius.circular(6.0),
        //           color: theme.textFieldColor.withAlpha(60),),
        //     child: ClipRRect(
        //       borderRadius: BorderRadius.circular(6.0),
        //       child: BackdropFilter(
        //         filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        //         child: BuildNavigationOption(
        //           tag:  'asda1241sdasd$tag',
        //           heroValue: "sortPopFeedBarVertical",
        //           icon: AppIcons.gridView(color: theme.textColor),
        //           label: 'View'.tr,
        //           onTap: () => showModalBottomSheet(
        //             context: context,
        //             backgroundColor: Colors.transparent,
        //             isScrollControlled: true,
        //             shape: const RoundedRectangleBorder(
        //               borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
        //             ),
        //             builder: (context) {
        //                     return const MobilePopAppBarPage();
        //                     },
        //                   ),
        //         ),
        //       ),
        //     ),
        //   ),
          
               
      ],
    );
  }
}

class BuildNavigationOption extends ConsumerWidget {
  const BuildNavigationOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.heroValue,
    required this.tag,
  });
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final String heroValue;
  final String tag;

  @override
  Widget build(BuildContext context, ref) {

    return ElevatedButton(
      onPressed: onTap,
      style: elevatedButtonStyleRounded10,
      child:  Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                icon,
        ],
      ),
    );
  }
}
