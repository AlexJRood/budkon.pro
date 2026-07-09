// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:get/get.dart';
// import 'package:hously_flutter/const/backgroundgradient.dart';
// import 'package:hously_flutter/const/route_constant.dart';
// import 'package:core/theme/design.dart';
// import 'package:portal/models/ad_list_view_model.dart';
// import 'package:portal/state_managers/filter_provider.dart'; // Upewnij się, że ścieżka jest poprawna
// import 'package:core/platform/navigation_service.dart';
// import 'package:portal/pie_menu/feed.dart';
// import 'package:hously_flutter/widgets/appbar/hously/pc/appbar.dart';
// import 'package:hously_flutter/widgets/side_menu/side_menu_manager.dart';
// import 'package:hously_flutter/widgets/sidebar/sidebar.dart';
// import 'package:intl/intl.dart';
// import 'package:pie_menu/pie_menu.dart';
//
import 'package:hously_flutter/widgets/side_menu/slide_rotate_menu.dart';
//
// class DoubleViewPCPage extends ConsumerWidget {
//   const DoubleViewPCPage({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final ScrollController scrollController = ScrollController();
//     double screenWidth = MediaQuery.of(context).size.width;
//
//     const double maxWidth = 1920;
//     const double minWidth = 480;
//     // Ustawienie maksymalnego i minimalnego rozmiaru czcionki
//     const double maxDynamicPadding = 40;
//     const double minDynamicPadding = 10;
//     // Obliczenie odpowiedniego rozmiaru czcionki
//     double dynamicPadding = (screenWidth - minWidth) /
//             (maxWidth - minWidth) *
//             (maxDynamicPadding - minDynamicPadding) +
//         minDynamicPadding;
//     // Ograniczenie rozmiaru czcionki do zdefiniowanych minimum i maksimum
//     dynamicPadding = dynamicPadding.clamp(minDynamicPadding, maxDynamicPadding);
//     double dynamicSizedBoxWidth = screenWidth / 8 <= 20 ? 20 : screenWidth / 8;
//     // Oblicz proporcję szerokości
//     final sideMenuKey = GlobalKey<SideMenuState>();
//
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
//       child: Scaffold(
//         body: SideMenuManager.sideMenuSettings(
//           menuKey: sideMenuKey,
//           child: Stack(
//             children: [
//               Container(
//                 decoration: BoxDecoration(
//                     gradient: CustomBackgroundGradients.getMainMenuBackground(
//                         context, ref)),
//                 child: Row(
//                   children: [
//                     Sidebar(
//                       sideMenuKey: sideMenuKey,
//                     ),
//                     Expanded(
//                       child: Container(
//                         decoration: BoxDecoration(
//                             gradient:
//                                 CustomBackgroundGradients.getMainMenuBackground(
//                                     context, ref)),
//                         child: Column(
//                           children: [
//                             const TopAppBar(),
//                             Expanded(
//                               child: ref.watch(filterProvider).when(
//                                     data: (filteredAdvertisements) =>
//                                         SingleChildScrollView(
//                                       controller: scrollController,
//                                       child: Padding(
//                                         padding: EdgeInsets.symmetric(
//                                             horizontal: dynamicSizedBoxWidth),
//                                         child: BuildAdvertisementsList(
//                                           filteredAdvertisements:
//                                               filteredAdvertisements,
//                                           scrollController: scrollController,
//                                         ),
//                                       ),
//                                     ),
//                                     loading: () => const Center(
//                                         child: CircularProgressIndicator()),
//                                     error: (error, stack) => Center(
//                                         child:
//                                             Text('Wystąpił błąd: $error'.tr)),
//                                   ),
//                             ),
//                           ],
//                         ),
//                       ),
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
//
// class BuildAdvertisementsList extends ConsumerWidget {
//   const BuildAdvertisementsList({
//     super.key,
//     required this.filteredAdvertisements,
//     required this.scrollController,
//   });
//
//   final List<AdsListViewModel> filteredAdvertisements;
//   final ScrollController scrollController;
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return GridView.builder(
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2, // Liczba kolumn
//           childAspectRatio: 16 / 9, // Proporcje wymiarów dzieci
//           crossAxisSpacing: 10, // Odstęp między kolumnami
//           mainAxisSpacing: 10, // Odstęp między rzędami
//         ),
//         itemCount: filteredAdvertisements.length,
//         itemBuilder: (BuildContext context, int index) {
//           final fullSizeAd = filteredAdvertisements[index];
//           final tag = 'fullSize${fullSizeAd.id}';
//           final mainImageUrl = fullSizeAd.images.isNotEmpty
//               ? fullSizeAd.images[0]
//               : 'default_image_url';
//
//           return GestureDetector(
//             onTap: () {},
//             onSecondaryTapDown: (details) {},
//             onVerticalDragUpdate: (details) {
//               scrollController
//                   .jumpTo(scrollController.offset - details.delta.dy);
//             },
//             child: AspectRatio(
//               aspectRatio: 16 / 9,
//               child: PieMenu(
//                 onPressedWithDevice: (kind) {
//                   if (kind == PointerDeviceKind.mouse ||
//                       kind == PointerDeviceKind.touch) {
//                     handleDisplayedAction(ref, fullSizeAd.id, context);
//                     ref.read(navigationService).pushNamedScreen(
//                       '/${Routes.feedview}/${fullSizeAd.id}',
//                       data: {'tag': tag, 'ad': fullSizeAd},
//                     );
//                   }
//                 },
//                 actions: buildPieMenuActions(ref, fullSizeAd, context),
//                 child: Padding(
//                   padding: const EdgeInsets.only(bottom: 8.0),
//                   child: Hero(
//                     tag: tag,
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(10),
//                       child: Stack(
//                         children: [
//                           AspectRatio(
//                             aspectRatio: 16 / 9,
//                             child: FittedBox(
//                               fit: BoxFit.cover,
//                               child: Image.network(
//                                 mainImageUrl,
//                                 errorBuilder: (context, error, stackTrace) =>
//                                     Container(
//                                   color: Colors.grey,
//                                   alignment: Alignment.center,
//                                   child: Text('Brak obrazu'.tr,
//                                       style:
//                                           const TextStyle(color: Colors.white)),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Positioned(
//                             left: 2,
//                             bottom: 2,
//                             child: Container(
//                               padding: const EdgeInsets.only(
//                                   top: 5, bottom: 5, right: 8, left: 8),
//                               decoration: BoxDecoration(
//                                 color: Colors.black.withAlpha((255 * 0.4).toInt()),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '${NumberFormat.decimalPattern().format(fullSizeAd.price)} ${fullSizeAd.currency}',
//                                     style: AppTextStyles.interBold.copyWith(
//                                       fontSize: 18,
//                                       shadows: [
//                                         Shadow(
//                                           offset: const Offset(5.0, 5.0),
//                                           blurRadius: 10.0,
//                                           color: Colors.black.withAlpha((255 * 1).toInt()),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   Text(
//                                     fullSizeAd.title,
//                                     style: AppTextStyles.interSemiBold.copyWith(
//                                       fontSize: 14,
//                                       shadows: [
//                                         Shadow(
//                                           offset: const Offset(5.0, 5.0),
//                                           blurRadius: 10.0,
//                                           color: Colors.black.withAlpha((255 * 1).toInt()),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   Text(
//                                     '${fullSizeAd.city}, ${fullSizeAd.street}',
//                                     style: AppTextStyles.interRegular.copyWith(
//                                       fontSize: 12,
//                                       shadows: [
//                                         Shadow(
//                                           offset: const Offset(5.0, 5.0),
//                                           blurRadius: 10.0,
//                                           color: Colors.black.withAlpha((255 * 1).toInt()),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         });
//   }
// }
