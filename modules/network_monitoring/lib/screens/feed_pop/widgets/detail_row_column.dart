import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/home_page/widgets/home_page/nearby_ads.dart';

class PropertyDetailsColumn extends ConsumerWidget {
  final MonitoringAdsModel adNetworkPop; // lepiej jawny typ niż dynamic

  const PropertyDetailsColumn({super.key, required this.adNetworkPop});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final canShowNearby = (adNetworkPop.lon ?? 0.0) != 0.0 &&
                          (adNetworkPop.lat ?? 0.0) != 0.0;
    final theme = ref.watch(themeColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Offer Data Section
        Text("offer_data".tr, style: AppTextStyles.interBold.copyWith(fontSize: 20,
        color: theme.textColor)),
        const SizedBox(height: 20),
        _buildDetailRow('page_id'.tr, adNetworkPop.siteId,theme),
        _buildDetailRow('ownership_form'.tr, adNetworkPop.ownershipForm,theme),
        _buildDetailRow('available_from'.tr, adNetworkPop.availableFrom,theme),
        _buildDetailRow('land_and_mortgage_register'.tr, adNetworkPop.landAndMortgageRegister,theme),
        _buildDetailRow('created_at'.tr, adNetworkPop.createdAt,theme),

        const SizedBox(height: 50),

        // Additional Info Section
        Text("additional_info".tr, style: AppTextStyles.interBold.copyWith(fontSize: 20,
        color: theme.textColor)),
        const SizedBox(height: 20),
        _buildDetailRow('windows'.tr, adNetworkPop.windows, theme),
        _buildDetailRow('attic_type'.tr, adNetworkPop.atticType, theme),
        _buildDetailRow('building_material'.tr, adNetworkPop.buildingMaterial, theme),
        _buildDetailRow('security'.tr, adNetworkPop.security, theme),
        _buildDetailRow('fencing'.tr, adNetworkPop.fencing, theme),
        _buildDetailRow('access_road'.tr, adNetworkPop.accessRoad, theme),
        _buildDetailRow('plot_type'.tr, adNetworkPop.plotType, theme),
        _buildDetailRow('dimensions'.tr, adNetworkPop.dimensions, theme),
        _buildDetailRow('premises_location'.tr, adNetworkPop.premisesLocation, theme),
        _buildDetailRow('purpose'.tr, adNetworkPop.purpose, theme),
        _buildDetailRow('location_info'.tr, adNetworkPop.locationInfo, theme),
        _buildDetailRow('roof'.tr, adNetworkPop.roof, theme),
        _buildDetailRow('recreational_house'.tr, adNetworkPop.recreationalHouse, theme),
        _buildDetailRow('roof_covering'.tr, adNetworkPop.roofCovering, theme),
        _buildDetailRow('construction'.tr, adNetworkPop.construction, theme),
        _buildDetailRow('height'.tr, adNetworkPop.height?.toString(), theme),
        _buildDetailRow('office_rooms'.tr, adNetworkPop.officeRooms?.toString(), theme),
        _buildDetailRow('social_facilities'.tr, adNetworkPop.socialFacilities, theme),
        _buildDetailRow('parking'.tr, adNetworkPop.parking, theme),
        _buildDetailRow('ramp'.tr, adNetworkPop.ramp, theme),
        _buildDetailRow('floor_material'.tr, adNetworkPop.floorMaterial, theme),
        _buildDetailRow('lighting'.tr, adNetworkPop.lighting, theme),

        const SizedBox(height: 50),

        // Boolean Fields Section
        if (_hasAnyTrueValue(adNetworkPop)) ...[
          Text("property_features".tr, style: AppTextStyles.interBold.copyWith(fontSize: 20,color: theme.textColor)),
          const SizedBox(height: 20),
           if (adNetworkPop.elevator == true) _buildDetailRow('elevator'.tr, 'yes'.tr, theme),
          if ((adNetworkPop.media ?? '').isNotEmpty) _buildDetailRow('media'.tr, adNetworkPop.media, theme),
          if (adNetworkPop.electricity == true) _buildDetailRow('electricity'.tr, 'yes'.tr, theme),
          if (adNetworkPop.water == true) _buildDetailRow('water'.tr, 'yes'.tr, theme),
          if (adNetworkPop.gas == true) _buildDetailRow('gas'.tr, 'yes'.tr, theme),
          if (adNetworkPop.phone == true) _buildDetailRow('phone'.tr, 'yes'.tr, theme),
          if (adNetworkPop.internet == true) _buildDetailRow('internet'.tr, 'yes'.tr, theme),
          if (adNetworkPop.sewerage == true) _buildDetailRow('sewerage'.tr, 'yes'.tr, theme),
          if (adNetworkPop.equipment == true) _buildDetailRow('equipment'.tr, 'yes'.tr, theme),
          if (adNetworkPop.garden == true) _buildDetailRow('garden'.tr, 'yes'.tr, theme),
          if (adNetworkPop.garage == true) _buildDetailRow('garage'.tr, 'yes'.tr, theme),
          if (adNetworkPop.basement == true) _buildDetailRow('basement'.tr, 'yes'.tr, theme),
          if (adNetworkPop.attic == true) _buildDetailRow('attic'.tr, 'yes'.tr, theme),
          if (adNetworkPop.terraces == true) _buildDetailRow('terraces'.tr, 'yes'.tr, theme),
          if (adNetworkPop.sepreteKitchen == true) _buildDetailRow('separate_kitchen'.tr, 'yes'.tr, theme),
          if ((adNetworkPop.balcony ?? '').isNotEmpty && adNetworkPop.balcony != 'false')
            _buildDetailRow('balcony'.tr, adNetworkPop.balcony, theme),
          if ((adNetworkPop.parkingSpace ?? '').isNotEmpty && adNetworkPop.parkingSpace != 'false')
            _buildDetailRow('parking_space'.tr, adNetworkPop.parkingSpace, theme),
          const SizedBox(height: 50),
        ],

        // Address Data Section
        Text("address".tr, style: AppTextStyles.interBold.copyWith(fontSize: 20,color: theme.textColor)),
        const SizedBox(height: 20),
        _buildDetailRow('street'.tr, adNetworkPop.street, theme),
        _buildDetailRow('city'.tr, adNetworkPop.city, theme),
        _buildDetailRow('country'.tr, adNetworkPop.country, theme),
        _buildDetailRow('state_voivodeship'.tr, adNetworkPop.state, theme),
        _buildDetailRow('district'.tr, adNetworkPop.district, theme),
        _buildDetailRow('province'.tr, adNetworkPop.province, theme),
        _buildDetailRow('commune'.tr, adNetworkPop.commune, theme),
        _buildDetailRow('housing_estate'.tr, adNetworkPop.housingEstate, theme),
        _buildDetailRow('zipcode'.tr, adNetworkPop.zipcode, theme),
        _buildDetailRow('neighborhood'.tr, adNetworkPop.neighborhood, theme),

        const SizedBox(height: 50),

        // Offerer Section
        Text("offerer".tr, style: AppTextStyles.interBold.copyWith(fontSize: 20,color: theme.textColor)),
        const SizedBox(height: 20),
        _buildDetailRow('advertiser_name'.tr, adNetworkPop.advertiserName, theme),
        _buildDetailRow('advertiser_type'.tr, adNetworkPop.advertiserType, theme),
        _buildDetailRow('remote_service'.tr, adNetworkPop.remoteService, theme),

        const SizedBox(height: 50),

        // Offerer Phone Section
        Text("bidders_telephone_number".tr, style: AppTextStyles.interBold.copyWith(fontSize: 20,color: theme.textColor)),
        const SizedBox(height: 20),
        _buildDetailRow('phone_number'.tr, adNetworkPop.advertiserPhone,theme),

        const SizedBox(height: 50),

        // Listing Counter Section
        Text("view_counter".tr, style: AppTextStyles.interBold.copyWith(fontSize: 20,color: theme.textColor)),
        const SizedBox(height: 20),
        _buildDetailRow('number_of_views'.tr, adNetworkPop.viewCount.toString(),theme),

        const SizedBox(height: 100.0),

        if (canShowNearby) NearbyAds(offerId: adNetworkPop.id.toString()),

        const SizedBox(height: 75),
      ],
    );
  }

  /// Rysuje wiersz; przyjmuje String? i pokazuje '-' gdy brak danych.
  Widget _buildDetailRow(String label, String? value,ThemeColors theme) {
    final display = (value == null || value.toString().trim().isEmpty) ? '-' : value!;
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.interRegular.copyWith(fontSize: 14,color: theme.textColor)),
            const Spacer(),
            Flexible(
              child: Text(
                display,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.interRegular.copyWith(fontSize: 14,color: theme.textColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Divider(color: AppColors.dark, thickness: 1),
        const SizedBox(height: 5),
      ],
    );
  }

  bool _hasAnyTrueValue(MonitoringAdsModel m) {
    final present = <String>[];

    bool addIfTrue(bool? v, String key) {
      if (v == true) {
        present.add(key);
        return true;
      }
      return false;
    }

    addIfTrue(m.elevator, 'elevator');
    if ((m.media ?? '').isNotEmpty) present.add('media');
    addIfTrue(m.electricity, 'electricity');
    addIfTrue(m.water, 'water');
    addIfTrue(m.gas, 'gas');
    addIfTrue(m.phone, 'phone');
    addIfTrue(m.internet, 'internet');
    addIfTrue(m.sewerage, 'sewerage');
    addIfTrue(m.equipment, 'equipment');
    addIfTrue(m.garden, 'garden');
    addIfTrue(m.garage, 'garage');
    addIfTrue(m.basement, 'basement');
    addIfTrue(m.attic, 'attic');
    addIfTrue(m.terraces, 'terraces');
    addIfTrue(m.sepreteKitchen, 'seprete_kitchen');

    if ((m.balcony ?? '').isNotEmpty && m.balcony != 'false') present.add('balcony');
    if ((m.parkingSpace ?? '').isNotEmpty && m.parkingSpace != 'false') present.add('parkingSpace');

    final any = present.isNotEmpty;
    log(any
        ? "✅ hasAnyTrueValue: TRUE - Active fields: ${present.join(', ')}"
        : "❌ hasAnyTrueValue: FALSE - No active fields.");
    return any;
  }

  double _parseDouble(String? v) {
    if (v == null) return 0.0;
    final s = v.replaceAll(',', '.').trim();
    return double.tryParse(s) ?? 0.0;
  }
}
