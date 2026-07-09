class FlipperActivityTimeline {
  final int? id;
  final int? transaction; // 🔁 CHANGED from Map<String, dynamic> to int
  final String? action;
  final String? actionDisplay;
  final String? date;

  FlipperActivityTimeline({
    this.id,
    this.transaction,
    this.action,
    this.actionDisplay,
    this.date,
  });

  factory FlipperActivityTimeline.fromJson(Map<String, dynamic> json) {
    return FlipperActivityTimeline(
      id: json['id'],
      transaction: json['transaction'], // ✅ Now safe: it's an int
      action: json['action'],
      actionDisplay: json['action_display'],
      date: json['date'],
    );
  }

  factory FlipperActivityTimeline.fromId(int id) {
    return FlipperActivityTimeline(id: id);
  }
}

class FlipperActivityTimelineResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FlipperActivityTimeline> results;

  FlipperActivityTimelineResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory FlipperActivityTimelineResponse.fromJson(Map<String, dynamic> json) {
    return FlipperActivityTimelineResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List)
          .map((e) => FlipperActivityTimeline.fromJson(e))
          .toList(),
    );
  }
}
