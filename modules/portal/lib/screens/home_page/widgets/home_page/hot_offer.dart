// import 'dart:math';
//
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:get/get.dart';
// import 'package:hously_flutter/const/route_constant.dart';
// import 'package:core/theme/design.dart';
// import 'package:hously_flutter/state_managers/data/home_page/listing_provider.dart';
// import 'package:core/platform/navigation_service.dart';
// import 'package:hously_flutter/theme/apptheme.dart';
// import 'package:portal/pie_menu/feed.dart';import 'package:intl/intl.dart';
// import 'package:pie_menu/pie_menu.dart';
//
// class HotOffers extends ConsumerWidget {
//   const HotOffers({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final listingsAsyncValue = ref.watch(listingsProvider);
//     final themecolors = ref.watch(themeColorsProvider);
//
//     final textColor = themecolors.themeTextColor;
//     double screenWidth = MediaQuery.of(context).size.width;
//     double itemWidth = screenWidth / 1920 * 240;
//     itemWidth = max(150.0, min(itemWidth, 300.0));
//     double minBaseTextSize = 14;
//     double maxBaseTextSize = 18;
//     double baseTextSize = minBaseTextSize +
//         (itemWidth - 150) / (240 - 150) * (maxBaseTextSize - minBaseTextSize);
//     baseTextSize = max(minBaseTextSize, min(baseTextSize, maxBaseTextSize));
//     NumberFormat customFormat = NumberFormat.decimalPattern('fr');
//
//     //  final currentthememode = ref.watch(themeProvider);
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Gorące oferty'.tr,
//             style: AppTextStyles.interSemiBold18.copyWith(color: textColor)),
//         const SizedBox(height: 10.0),
//         listingsAsyncValue.when(
//           data: (listings) {
//             if (listings.isNotEmpty) {
//               final hotAd = listings.first;
//               final tag = 'hotOffer${hotAd.id}';
//               String formattedPrice = customFormat.format(hotAd.price);
//               String mainImageUrl = hotAd.images.isNotEmpty
//                   ? hotAd.images[0]
//                   : 'default_image_url';
//
//               return PieMenu(
//                 onPressedWithDevice: (kind) {
//                   if (kind == PointerDeviceKind.mouse ||
//                       kind == PointerDeviceKind.touch) {
//                     handleDisplayedAction(ref, hotAd.id, context);
//                     ref.read(navigationService).pushNamedScreen(
//                       '${Routes.feedview}/${hotAd.id}',
//                       data: {'tag': tag, 'ad': hotAd},
//                     );
//                   }
//                 },
//                 actions: buildPieMenuActions(ref, hotAd, context),
//                 child: Hero(
//                   tag: tag,
//                   child: Container(
//                     width: 1000,
//                     height: 450,
//                     decoration: BoxDecoration(
//                       image: DecorationImage(
//                         image: NetworkImage(mainImageUrl)
//                           ..resolve(createImageConfiguration(context))
//                               .addListener(
//                             ImageStreamListener(
//                               // ignore: avoid_print
//                               (image, synchronousCall) =>
//                                   print('Obraz został załadowany.'),
//                               onError: (exception, stackTrace) {},
//                             ),
//                           ),
//                         fit: BoxFit.cover,
//                       ),
//                     ), // Używamy głównego obrazu
//                     child: Stack(
//                       children: [
//                         Positioned(
//                           left: 2,
//                           bottom: 2,
//                           child: Container(
//                             padding: const EdgeInsets.only(
//                                 top: 5, bottom: 5, right: 8, left: 8),
//                             decoration: BoxDecoration(
//                               color: Colors.black.withAlpha((255 * 0.25).toInt()),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   '$formattedPrice ${hotAd.currency}',
//                                   style: AppTextStyles.interBold.copyWith(
//                                       fontSize: baseTextSize + 2,
//                                       color: textColor),
//                                 ),
//                                 Text(
//                                   hotAd.title,
//                                   style: AppTextStyles.interSemiBold.copyWith(
//                                       fontSize: baseTextSize, color: textColor),
//                                 ),
//                                 Text(
//                                   '${hotAd.city}, ${hotAd.street}',
//                                   style: AppTextStyles.interRegular.copyWith(
//                                       fontSize: baseTextSize - 2,
//                                       color: textColor),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             } else {
//               return const Center(child: Text('Brak gorących ofert'));
//             }
//           },
//           loading: () => const Center(child: CircularProgressIndicator()),
//           error: (error, stack) => Center(
//               child: Text(
//             'Wystąpił błąd: $error'.tr,
//             style: AppTextStyles.interRegular
//                 .copyWith(fontSize: 16, color: textColor),
//           )),
//         )
//       ],
//     );
//   }
//
//   ImageConfiguration createImageConfiguration(BuildContext context) {
//     return ImageConfiguration(
//       bundle: DefaultAssetBundle.of(context),
//       devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
//       locale: Localizations.localeOf(context),
//       textDirection: Directionality.of(context),
//       size: MediaQuery.of(context).size,
//       platform: Theme.of(context).platform,
//     );
//   }
// }
