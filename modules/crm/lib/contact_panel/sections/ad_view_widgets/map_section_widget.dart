import 'package:crm/data/add_field/edit_sell_offer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:portal/screens/feed/components/map/map_ad.dart';

class MapSection extends ConsumerWidget {
  const MapSection({
    super.key,
    required this.adId,
    required this.latitude,
    required this.longitude,
  });

  final Object adId;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasValidLocation = latitude != null && longitude != null;

    if (!hasValidLocation) {
      return Container(
        height: 180,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child:  Text(
          'Location is not available'.tr,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return SizedBox(
      height: 400,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MapAd(
          latitude: latitude!,
          longitude: longitude!,
          onMapActivated: () {
            final activated = ref.read(adMapActivatedProvider(adId));
            if (!activated) {
              ref.read(adMapActivatedProvider(adId).notifier).state = true;
            }
          },
        ),
      ),
    );
  }
}