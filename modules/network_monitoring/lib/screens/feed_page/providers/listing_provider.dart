import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/url.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:core/platform/api_services.dart';

final listingsProvider = FutureProvider<List<AdsListViewModel>>((ref) async {
  final response = await ApiServices.get(ref: ref,URLs.apiAdvertisements);

  if (response != null && response.statusCode == 200) {
    final decodedBody = utf8.decode(response.data);
    final listingsJson = json.decode(decodedBody) as Map<dynamic, dynamic>;
    final newList = listingsJson['results'] as List<dynamic>;

    return newList.map((json) => AdsListViewModel.fromJson(json)).toList();
  } else {
    throw Exception('failed_to_load_listings'.tr);
  }
});
