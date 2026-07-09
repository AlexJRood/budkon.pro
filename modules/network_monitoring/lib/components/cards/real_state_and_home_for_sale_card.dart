import 'package:flutter/material.dart';
import 'package:network_monitoring/components/open_nm_ad.dart';
import 'package:network_monitoring/pie_menu/network_monitoring.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:intl/intl.dart';


import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/ad_type_utils.dart';
import 'package:core/theme/apptheme.dart';

class RealStateAndHomeForSaleCard extends ConsumerWidget { // ✅ Poprawione
  final dynamic ad;
  final String keyTag;
  final bool isMobile;
  final int? transactionId;
  final int? clientId;

  const RealStateAndHomeForSaleCard({
    super.key,
    required this.ad,
    required this.keyTag,
    this.isMobile = false,
    this.transactionId,
    this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) { // ✅ Teraz poprawne

    return AspectRatio(
      aspectRatio: isMobile ? 1 : 1,
      child: PieMenu(
        theme: PieTheme.of(context).copyWith(
                        overlayColor:
                            (() {
                              final theme = ref.watch(themeColorsProvider);
                              final bool uiIsDark =
                                  theme.textColor.computeLuminance() > 0.5;

                              final base =
                                  uiIsDark ? Colors.black : Colors.white;
                              return base.withValues(alpha: 0.70);
                            })(),
                      ),
        onPressedWithDevice: (kind) {
          if (kind == PointerDeviceKind.mouse || kind == PointerDeviceKind.touch) {
               openAdUrl(context, ref, ad, transactionId, clientId, '${ad.id}');
          }
        },
        actions: buildPieMenuActionsNM(ref, ad, context, null, null),
        child: Hero(
          tag: keyTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isMobile ? 0 : 6),
                    color: const Color.fromRGBO(41, 41, 41, 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(isMobile ? 0 : 6)),
                          child: Image.network(
                            ad.images.first,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Expanded(
                        flex:2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    ad.street != null ? '${'street'.tr},' : '${ad.street}, ',
                                    style: const TextStyle(
                                      color: Color.fromRGBO(200, 200, 200, 1),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ad.city != null ? '${'city'.tr},' : '${ad.city}, ',
                                    style: const TextStyle(
                                      color: Color.fromRGBO(200, 200, 200, 1),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ad.state != null ? '${'State'.tr},' : ad.state,
                                    style: const TextStyle(
                                      color: Color.fromRGBO(200, 200, 200, 1),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  if (ad.squareFootage != null && ad.squareFootage.toString().trim().isNotEmpty) ...[
                                    IconText(icon: Icons.square_foot, text: '${ad.squareFootage} ㎡'),    
                                  ], 

                                  if (AdTypeUtils.showRoomsAndBathrooms((ad.estateType ?? '').toString()) && ad.rooms != null && (ad.rooms ?? 0) > 0) ...[
                                    const Text('  |  ',
                                        style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    IconText(icon: Icons.bed, text: '${ad.rooms} ${'Rooms'.tr}'),
                                  ],

                                  if (AdTypeUtils.showRoomsAndBathrooms((ad.estateType ?? '').toString()) && ad.bathrooms != null && (ad.bathrooms ?? 0) > 0) ...[
                                    const Text('  |  ',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    IconText(icon: Icons.bathtub, text: '${ad.bathrooms} ${'Bath'.tr}'),
                                  ],

                                ],
                              ),
                              const SizedBox(height: 6),
                              const Divider(color: Color.fromRGBO(90, 90, 90, 1)),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'FOR SALE'.tr,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                  '${NumberFormat.decimalPattern('fr').format(ad.price)} ${ad.currency}',
                                    style: const TextStyle(
                                      color: Color.fromRGBO(255, 255, 255, 1),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




class IconText extends StatelessWidget {
  final IconData icon;
  final String text;

  const IconText({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
