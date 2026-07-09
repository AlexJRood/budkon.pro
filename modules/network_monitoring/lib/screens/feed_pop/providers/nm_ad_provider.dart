import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/network_monitoring_urls.dart';

// lib/providers/ad_provider.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/design.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:network_monitoring/screens/feed_pop/nm_feed_pop.dart';
import 'package:core/platform/api_services.dart';

final adNetworkMonitoringProvider =
FutureProvider.family<MonitoringAdsModel, int>((ref, adId) async {
  final response = await ApiServices.get(ref: ref, NetworkMonitoringUrls.advertiseMonitoring('$adId'));

  if (response != null && response.statusCode == 200) {
    if (response.data is Uint8List) {
      String jsonString = utf8.decode(response.data);
      final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      return MonitoringAdsModel.fromJson(decodedJson);

    } else if (response.data is Map<String, dynamic>) {
      return MonitoringAdsModel.fromJson(response.data);

    } else {
      throw Exception('unexpected_response_format'.tr);
    }
  } else {
    throw Exception('failed_to_load_advertisement'.tr);
    
  }
});

class NMAdFetcher extends ConsumerWidget {
  final int adNetworkPop;
  final String tagNetworkPop;

  const NMAdFetcher({
    required this.adNetworkPop,
    required this.tagNetworkPop,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adAsyncValue = ref.watch(adNetworkMonitoringProvider(adNetworkPop));

    return adAsyncValue.when(
      data: (adNetwork) {
        return NMFeedPop(adNetworkPop: adNetwork, tagNetworkPop: tagNetworkPop);
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.light,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (error, stack){
       return Scaffold(
        body: Center(child: Text('${'Error'.tr}: $error'.tr)),
      );}
    );
  }
}
