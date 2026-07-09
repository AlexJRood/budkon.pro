import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:portal/screens/feed/widgets/about_us/about_us_mobile.dart';
import 'package:portal/screens/feed/widgets/about_us/about_us_pc.dart';

class BasicAboutUsPage extends StatefulWidget {
  const BasicAboutUsPage({super.key});

  @override
  State<BasicAboutUsPage> createState() => _BasicAboutUsPageState();
}

class _BasicAboutUsPageState extends State<BasicAboutUsPage> {
  final sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context) {

    return BarManager(sideMenuKey: sideMenuKey, appModule: AppModule.portal,
    childMobile: AboutPageMobile(),
      childPc: AboutPage(),
    );
  }
}

///void navigateToAboutUs(BuildContext context, WidgetRef ref) {
//   ref.read(navigationService).pushNamedScreen(Routes.aboutusview);
//   ref.read(selectedFeedViewProvider.notifier).state = Routes.aboutusview;
// }

///ElevatedButton(
//   onPressed: () => navigateToAboutUs(context, ref),
//   child: const Text('About Us'),
// )
