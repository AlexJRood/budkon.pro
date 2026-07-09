import 'package:crm/draft_ads_listview_model.dart';

class PaginatedDraftResponse {
  final List<DraftAdsListViewModel> results;
  final int count;

  PaginatedDraftResponse({required this.results, required this.count});

  factory PaginatedDraftResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedDraftResponse(
      results: (json['results'] as List)
          .map((e) => DraftAdsListViewModel.fromJson(e))
          .toList(),
      count: json['count'],
    );
  }
}
