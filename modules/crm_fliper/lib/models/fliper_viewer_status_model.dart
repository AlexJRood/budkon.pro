class ViewerStatusResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperViewerStatus> results;

  ViewerStatusResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory ViewerStatusResponse.fromJson(Map<String, dynamic> json) {
    return ViewerStatusResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List)
          .map((e) => FliperViewerStatus.fromJson(e))
          .toList(),
    );
  }
}

class FliperViewerStatus {
  final int id;
  final String statusName;
  final int statusIndex;
  final dynamic transactionIndex;
  final bool isView;
  final bool isNegotiations;
  final bool isFinalization;
  final int user;

  FliperViewerStatus({
    required this.id,
    required this.statusName,
    required this.statusIndex,
    this.transactionIndex,
    required this.isView,
    required this.isNegotiations,
    required this.isFinalization,
    required this.user,
  });

  factory FliperViewerStatus.fromJson(Map<String, dynamic> json) {
    return FliperViewerStatus(
      id: json['id'],
      statusName: json['status_name'],
      statusIndex: json['status_index'],
      transactionIndex: json['transaction_index'],
      isView: json['is_view'] ?? false,
      isNegotiations: json['is_negotiations'] ?? false,
      isFinalization: json['is_finalization'] ?? false,
      user: json['user'],
    );
  }
}
