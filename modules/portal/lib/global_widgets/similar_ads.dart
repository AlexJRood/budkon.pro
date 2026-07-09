// import 'dart:math';
//
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:get/get.dart';
// import 'package:hously_flutter/const/route_constant.dart';
// import 'package:core/theme/design.dart'; // Załóżmy, że jest dostępny
// import 'package:hously_flutter/state_managers/data/home_page/listing_provider.dart';
// import 'package:core/platform/navigation_service.dart';
// import 'package:portal/pie_menu/feed.dart';
// import 'package:intl/intl.dart';
// import 'package:pie_menu/pie_menu.dart';
//
// class RecomendedForYou extends ConsumerWidget {
//   const RecomendedForYou({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final listingsAsyncValue = ref.watch(listingsProvider); // Używamy providera
//
//     double screenWidth = MediaQuery.of(context).size.width;
//     double itemWidth = screenWidth / 1500 * 400;
//     itemWidth = max(250.0, min(itemWidth, 500.0));
//     double itemHeight = itemWidth * (222 / 400);
//
//     double minBaseTextSize = 10;
//     double maxBaseTextSize = 14;
//     double baseTextSize = minBaseTextSize +
//         (itemWidth - 200) / (400 - 200) * (maxBaseTextSize - minBaseTextSize);
//     baseTextSize = max(minBaseTextSize, min(baseTextSize, maxBaseTextSize));
//     NumberFormat customFormat = NumberFormat.decimalPattern('fr');
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(left: 8.0),
//           child: Text(
//             'Wybrane dla Ciebie'.tr,
//             style: AppTextStyles.interSemiBold
//                 .copyWith(fontSize: baseTextSize + 8),
//           ),
//         ),
//         const SizedBox(height: 20.0),
//         listingsAsyncValue.when(
//           data: (listings) => SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: listings.map((recomended) {
//                 final tag =
//                     'recommended${recomended.id}'; // Unikalny tag dla każdego elementu
//                 String formattedPrice = customFormat.format(recomended.price);
//                 // Wybieramy pierwszy obraz z listy jako główne zdjęcie, zakładamy, że lista nie jest pusta
//                 final mainImageUrl =
//                     recomended.images.isNotEmpty ? recomended.images[0] : '';
//                 return PieMenu(
//                   onPressedWithDevice: (kind) {
//                     if (kind == PointerDeviceKind.mouse ||
//                         kind == PointerDeviceKind.touch) {
//                       handleDisplayedAction(ref, recomended.id, context);
//                       ref.read(navigationService).pushNamedScreen(
//                         '${Routes.feedview}/${recomended.id}',
//                         data: {'tag': tag, 'ad': recomended},
//                       );
//                     }
//                   },
//                   actions: buildPieMenuActions(ref, recomended, context),
//                   child: Hero(
//                     tag: tag,
//                     child: Container(
//                       width: itemWidth,
//                       height: itemHeight,
//                       margin: const EdgeInsets.only(right: 10.0),
//                       decoration: BoxDecoration(
//                         image: DecorationImage(
//                           image: NetworkImage(
//                               mainImageUrl), // Używamy głównego obrazu
//                           fit: BoxFit.cover,
//                         ),
//                         borderRadius: BorderRadius.circular(10.0),
//                       ),
//                       child: Stack(
//                         children: [
//                           Positioned(
//                             left: 2.0,
//                             bottom: 2.0,
//                             child: Container(
//                               padding: const EdgeInsets.only(
//                                   top: 5, bottom: 5, right: 8, left: 8),
//                               decoration: BoxDecoration(
//                                 color: Colors.black.withAlpha((255 * 0.25).toInt()),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '$formattedPrice ${recomended.currency}',
//                                     style: AppTextStyles.interBold.copyWith(
//                                       fontSize: baseTextSize + 2,
//                                     ),
//                                   ),
//                                   Text(
//                                     '${recomended.city}, ${recomended.street}',
//                                     style: AppTextStyles.interSemiBold.copyWith(
//                                       fontSize: baseTextSize,
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
//                 );
//               }).toList(),
//             ),
//           ),
//           loading: () => const Center(child: CircularProgressIndicator()),
//           error: (error, stack) => Center(
//               child: Text(
//             'Wystąpił błąd: $error'.tr,
//             style: AppTextStyles.interRegular.copyWith(fontSize: 16),
//           )),
//         ),
//       ],
//     );
//   }
// }
