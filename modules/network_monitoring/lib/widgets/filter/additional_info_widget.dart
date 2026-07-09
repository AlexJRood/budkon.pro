import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core/platform/values.dart';
import 'package:core/theme/design.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';

class AdditionalInfoWidget extends StatelessWidget {
  final double dynamicBoxHeightGroup; //
  final double dynamicSpace; //
  const AdditionalInfoWidget({
    required this.dynamicBoxHeightGroup,
    required this.dynamicSpace,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: Text('additional_info'.tr,
                  style: AppTextStyles.interSemiBold16
                      .copyWith(color: Theme.of(context).iconTheme.color)),
            ),
          ],
        ),
        SizedBox(height: dynamicBoxHeightGroup),
        GridView.builder(
          addAutomaticKeepAlives: false,
          addSemanticIndexes: false,
          cacheExtent: 160,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            childAspectRatio: 4,
          ),
          itemCount: additionalFilters.length,
          itemBuilder: (context, index) {
            final filter = additionalFilters[index];
            return NetworkMonitoringAdditionalInfoFilterButton(
              text: filter['text']!,
              filterKey: filter['filterKey']!,
            );
          },
        )
      ],
    );
  }

  // Pamiętaj, aby zdefiniować metody `NetworkMonitoringAdditionalInfoFilterButton` lub zaimportować je, jeśli są w oddzielnym pliku.
}
