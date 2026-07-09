class SaleClientsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperSaleClient> results;

  SaleClientsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory SaleClientsResponse.fromJson(Map<String, dynamic> json) {
    return SaleClientsResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => FliperSaleClient.fromJson(e))
          .toList(),
    );
  }
}

class FliperSaleClient {
  final int id;
  final int? user;
  final String fullName;
  final String email;
  final String? phoneNumber;

  FliperSaleClient({
    required this.id,
    this.user,
    required this.fullName,
    required this.email,
    this.phoneNumber,
  });

  factory FliperSaleClient.fromJson(Map<String, dynamic> json) {
    return FliperSaleClient(
      id: json['id'],
      user: json['user'],
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
    );
  }
}
