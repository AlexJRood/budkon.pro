import 'package:crm_fliper/refurbishment/models/refurbishment_task_model.dart';

class RefurbishmentTasksResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<RefurbishmentTask> results;

  RefurbishmentTasksResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory RefurbishmentTasksResponse.fromJson(Map<String, dynamic> json) {
    return RefurbishmentTasksResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List)
          .map((item) => RefurbishmentTask.fromJson(item))
          .toList(),
    );
  }
}
