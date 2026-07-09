class RenovationProgressResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperRenovationProgress> results;

  RenovationProgressResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory RenovationProgressResponse.fromJson(Map<String, dynamic> json) {
    return RenovationProgressResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => FliperRenovationProgress.fromJson(e))
          .toList(),
    );
  }
}

class FliperRenovationProgress {
  final int id;
  final int task;
  final String? plannedStartDate;
  final String? plannedEndDate;
  final String? actualStartDate;
  final String? actualEndDate;
  final String status;

  FliperRenovationProgress({
    required this.id,
    required this.task,
    this.plannedStartDate,
    this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    required this.status,
  });

  factory FliperRenovationProgress.fromJson(Map<String, dynamic> json) {
    return FliperRenovationProgress(
      id: json['id'],
      task: json['task'],
      plannedStartDate: json['planned_start_date'],
      plannedEndDate: json['planned_end_date'],
      actualStartDate: json['actual_start_date'],
      actualEndDate: json['actual_end_date'],
      status: json['status'] ?? '',
    );
  }
}
