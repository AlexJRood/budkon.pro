import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:articles/components/all_articles_widget.dart';

class ArticlesPage extends ConsumerWidget {
  const ArticlesPage({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref){
    final sideMenuKey = GlobalKey<SideMenuState>();


    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.back,
      childMobile: AllArticlesWidget(isMobile: true),
      childTablet: AllArticlesWidget(isTablet: true),
      childPc: AllArticlesWidget(),
      
    );


  }
}