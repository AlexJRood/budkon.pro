import 'dart:convert';
import 'package:portal/portal_urls.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:core/platform/api_services.dart';

final nearbyadsProvider =FutureProvider.family<List<AdsListViewModel>, String>((ref, offerId) async {
  final response = await ApiServices.get(ref:ref,PortalUrls.nearbyAdvertisements(offerId),hasToken: true);

  if (response != null && response.statusCode == 200) {
    final decodedBody = utf8.decode(response.data);
    final newList = json.decode(decodedBody) as List<dynamic>;

    return newList.map((json) => AdsListViewModel.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load listings');
  }
});
