class NegotiationHistoryResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperNegotiationHistory> results;

  NegotiationHistoryResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory NegotiationHistoryResponse.fromJson(Map<String, dynamic> json) {
    return NegotiationHistoryResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => FliperNegotiationHistory.fromJson(e))
          .toList(),
    );
  }
}

class FliperNegotiationHistory {
  final int id;
  final String initialPrice;
  final String? sellerOffer;
  final String? viewerOffer;
  final String? renegotiationPrice;
  final bool accepted;
  final String date;
  final int transaction;

  FliperNegotiationHistory({
    required this.id,
    required this.initialPrice,
    this.sellerOffer,
    this.viewerOffer,
    this.renegotiationPrice,
    required this.accepted,
    required this.date,
    required this.transaction,
  });

  factory FliperNegotiationHistory.fromJson(Map<String, dynamic> json) {
    return FliperNegotiationHistory(
      id: json['id'],
      initialPrice: json['initial_price'] ?? '',
      sellerOffer: json['seller_offer'],
      viewerOffer: json['viewer_offer'],
      renegotiationPrice: json['renegotiation_price'],
      accepted: json['accepted'] ?? false,
      date: json['date'] ?? '',
      transaction: json['transaction'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'initial_price': initialPrice,
      'seller_offer': sellerOffer,
      'viewer_offer': viewerOffer,
      'renegotiation_price': renegotiationPrice,
      'accepted': accepted,
      'date': date,
      'transaction': transaction,
    };
  }
}
