import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core/theme/design.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';

class OfferTypeWidget extends StatelessWidget {
  final double dynamicBoxHeightGroupSmall;
  final bool isTablet;

  const OfferTypeWidget({
    required this.dynamicBoxHeightGroupSmall,
    this.isTablet = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: isTablet ? 0 : dynamicBoxHeightGroupSmall,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isTablet) ...[const SizedBox(height: 20)],
        Material(
          color: Colors.transparent,
          child: Text(
            'Offer type'.tr,
            style: (isTablet
                    ? AppTextStyles.interSemiBold
                    : AppTextStyles.interSemiBold16)
                .copyWith(color: Theme.of(context).iconTheme.color),
          ),
        ),
        isTablet
            ? Column(
              children: [
                SizedBox(height: 10),
                NetworkMonitoringFilterButton(
                  text: 'For sale'.tr,
                  filterValue: 'sell',
                  filterKey: 'offer_type',
                  isTablet: isTablet,
                  width: double.infinity,
                ),
                SizedBox(height: 10),
                NetworkMonitoringFilterButton(
                  text: 'For rent'.tr,
                  filterValue: 'rent',
                  filterKey: 'offer_type',
                  isTablet: isTablet,
                  width: double.infinity,
                ),
              ],
            )
            : Row(
              spacing: 8,
              children: [
                Expanded(
                  child: NetworkMonitoringFilterButton(
                    text: 'offer_type_sell'.tr,
                    filterValue: 'sell',
                    filterKey: 'offer_type',
                    isTablet: isTablet,
                  ),
                ),
                Expanded(
                  child: NetworkMonitoringFilterButton(
                    text: 'offer_type_rent'.tr,
                    filterValue: 'rent',
                    filterKey: 'offer_type',
                    isTablet: isTablet,
                  ),
                ),
              ],
            ),
      ],
    );
  }
}
