class QuickFlipCostsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperQuickFlipCost> results;

  QuickFlipCostsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory QuickFlipCostsResponse.fromJson(Map<String, dynamic> json) {
    return QuickFlipCostsResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => FliperQuickFlipCost.fromJson(e))
          .toList(),
    );
  }
}

class FliperQuickFlipCost {
  final int id;
  final String? painting;
  final String? cleaning;
  final String? clearing;
  final String? listingPreparation;
  final String? photoSession;
  final String? homestaging;
  final dynamic other; // Replace with model if needed
  final String summary;
  final String dateCreate;
  final String dateUpdate;
  final int? transaction;
  final int? renovation;
  final int user;

  FliperQuickFlipCost({
    required this.id,
    this.painting,
    this.cleaning,
    this.clearing,
    this.listingPreparation,
    this.photoSession,
    this.homestaging,
    this.other,
    required this.summary,
    required this.dateCreate,
    required this.dateUpdate,
    this.transaction,
    this.renovation,
    required this.user,
  });

  factory FliperQuickFlipCost.fromJson(Map<String, dynamic> json) {
    return FliperQuickFlipCost(
      id: json['id'],
      painting: json['painting'],
      cleaning: json['cleaning'],
      clearing: json['clearing'],
      listingPreparation: json['listing_preparation'],
      photoSession: json['photo_session'],
      homestaging: json['homestaging'],
      other: json['other'],
      summary: json['summary'] ?? '0',
      dateCreate: json['date_create'] ?? '',
      dateUpdate: json['date_update'] ?? '',
      transaction: json['transaction'],
      renovation: json['renovation'],
      user: json['user'],
    );
  }
}
