
class PredefinedChecklistResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<PredefinedFliperCheckList> results;

  PredefinedChecklistResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PredefinedChecklistResponse.fromJson(Map<String, dynamic> json) {
    return PredefinedChecklistResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => PredefinedFliperCheckList.fromJson(e))
          .toList(),
    );
  }
}

class PredefinedFliperCheckList {
  final int id;
  final String title;
  final String description;
  final dynamic checklist; // Replace with a model class if needed
  final int user;

  PredefinedFliperCheckList({
    required this.id,
    required this.title,
    required this.description,
    this.checklist,
    required this.user,
  });

  factory PredefinedFliperCheckList.fromJson(Map<String, dynamic> json) {
    return PredefinedFliperCheckList(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      checklist: json['checklist'],
      user: json['user'],
    );
  }
}
