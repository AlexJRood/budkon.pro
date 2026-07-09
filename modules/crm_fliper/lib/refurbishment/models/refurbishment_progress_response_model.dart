import 'package:crm_fliper/refurbishment/models/refurbishment_progress_model.dart';

class RefurbishmentProgressResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<RefurbishmentProgress> results;

  RefurbishmentProgressResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory RefurbishmentProgressResponse.fromJson(Map<String, dynamic> json) {
    return RefurbishmentProgressResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List)
          .map((item) => RefurbishmentProgress.fromJson(item))
          .toList(),
    );
  }
}
