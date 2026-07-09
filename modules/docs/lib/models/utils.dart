class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  PaginatedResponse({
    required this.count,
    required this.results,
    this.next,
    this.previous,
  });

  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic json) fromJsonT,
  ) {
    return PaginatedResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List)
          .map((item) => fromJsonT(item))
          .toList(),
    );
  }
}
