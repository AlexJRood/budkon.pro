class RenovationSchedulesResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FlierRenovationSchedule> results;

  RenovationSchedulesResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory RenovationSchedulesResponse.fromJson(Map<String, dynamic> json) {
    return RenovationSchedulesResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => FlierRenovationSchedule.fromJson(e))
          .toList(),
    );
  }
}

class FlierRenovationSchedule {
  final int id;
  final String? task;
  final String? deadline;
  final String? responsiblePerson;
  final String? budget;
  final String? actualCost;
  final int? transaction;

  FlierRenovationSchedule({
    required this.id,
    this.task,
    this.deadline,
    this.responsiblePerson,
    this.budget,
    this.actualCost,
    this.transaction,
  });

  factory FlierRenovationSchedule.fromJson(Map<String, dynamic> json) {
    return FlierRenovationSchedule(
      id: json['id'],
      task: json['task'],
      deadline: json['deadline'],
      responsiblePerson: json['responsible_person'],
      budget: json['budget'],
      actualCost: json['actual_cost'],
      transaction: json['transaction'],
    );
  }
}
