// ignore_for_file: unused_result

import 'package:flutter/cupertino.dart';
import 'package:portal/portal_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/profile_page/providers/profile_ad_provider.dart';
import 'package:core/platform/api_services.dart';

final removeAdProvider = Provider((ref) => RemoveAdProvider(ref));

class RemoveAdProvider {
  final Ref ref;

  RemoveAdProvider(this.ref);

  Future<bool> removeAd(int adId) async {
    final url = PortalUrls.advertisementsArchive('$adId');

    final response = await ApiServices.post(
      url,
      hasToken: true,
    );

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 204)) {
      ref.read(yourAdsFilterProvider.notifier).removeAdFromList(adId);
      return true;
    }

    return false;
  }
}
