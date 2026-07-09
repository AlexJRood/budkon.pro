// lib/providers/ad_provider.dart

import 'dart:convert';
import 'package:crm/crm_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/url.dart';
import 'package:crm/draft_ads_listview_model.dart';
import 'package:core/platform/api_services.dart';

final draftAdProvider =
FutureProvider.family<DraftAdsListViewModel, int>((ref, adId) async {
  final response = await ApiServices.get(
    CrmUrls.draftAdvertisement(adId.toString()),
    ref: ref,
    hasToken: true,
  );

  if (response == null) {
    throw Exception('Draft API returned null');
  }

  if (response.statusCode != 200) {
    throw Exception('Draft API failed: ${response.statusCode}');
  }

  final jsonMap = jsonDecode(
    utf8.decode(response.data as List<int>),
  ) as Map<String, dynamic>;

  return DraftAdsListViewModel.fromJson(jsonMap);
});



//   // bool _isLoad = false; // Initialize the boolean flag to false
//   // bool get isLoad =>_isLoad;
//   Future<List<AdsListViewModel>> fetchAdvertisements(int pageKey, int pageSize,dynamic ref) async {
//     try {
//       final response = await ApiServices.get(
//         ref:ref,
//         '${URLs.apiAdvertisements}?page=$pageKey&pageSize=$pageSize',
//         hasToken: true,
//         queryParameters: {
//           ...filters,
//           if (searchQuery.isNotEmpty) 'search': searchQuery,
//           if (excludeQuery.isNotEmpty) 'exclude': excludeQuery,
//           if (sortOrder.isNotEmpty) 'sort': sortOrder,
//           'currency': selectedCurrency,
//         },
//       );

//       if (response != null && response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.data);
//         final listingsJson = json.decode(decodedBody) as Map<dynamic, dynamic>;
//         final newList = listingsJson['results'] as List<dynamic>;

//         return newList.map((item) {
//           return AdsListViewModel.fromJson(item as Map<String, dynamic>);
//         }).toList();
//       }
//     } catch (e) {
//       throw Exception('Failed to fetch advertisements');
//     }
//     return [];
//   }
// }