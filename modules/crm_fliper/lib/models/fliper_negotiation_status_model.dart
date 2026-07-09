
class NegotiationStatusesResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperNegotiationStatus> results;

  NegotiationStatusesResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory NegotiationStatusesResponse.fromJson(Map<String, dynamic> json) {
    return NegotiationStatusesResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => FliperNegotiationStatus.fromJson(e))
          .toList(),
    );
  }
}

class FliperNegotiationStatus {
  final int id;
  final String statusName;
  final int statusIndex;
  final dynamic transactionIndex; // Replace with actual model if needed
  final bool isCalculations;
  final bool isNegotiations;
  final bool isFinalization;
  final int user;

  FliperNegotiationStatus({
    required this.id,
    required this.statusName,
    required this.statusIndex,
    this.transactionIndex,
    required this.isCalculations,
    required this.isNegotiations,
    required this.isFinalization,
    required this.user,
  });

  factory FliperNegotiationStatus.fromJson(Map<String, dynamic> json) {
    return FliperNegotiationStatus(
      id: json['id'],
      statusName: json['status_name'] ?? '',
      statusIndex: json['status_index'] ?? 0,
      transactionIndex: json['transaction_index'], // map if needed
      isCalculations: json['is_calculations'] ?? false,
      isNegotiations: json['is_negotiations'] ?? false,
      isFinalization: json['is_finalization'] ?? false,
      user: json['user'],
    );
  }
}
