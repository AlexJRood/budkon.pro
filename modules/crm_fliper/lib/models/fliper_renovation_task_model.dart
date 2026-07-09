class RenovationTaskResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperRenovationTask> results;

  RenovationTaskResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory RenovationTaskResponse.fromJson(Map<String, dynamic> json) {
    return RenovationTaskResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => FliperRenovationTask.fromJson(e))
          .toList(),
    );
  }
}

class FliperRenovationTask {
  final int id;
  final int transaction;
  final String taskName;
  final String taskNameDisplay;
  final List<Budget> budget;
  final String? actualCost;

  FliperRenovationTask({
    required this.id,
    required this.transaction,
    required this.taskName,
    required this.taskNameDisplay,
    required this.budget,
    this.actualCost,
  });

  factory FliperRenovationTask.fromJson(Map<String, dynamic> json) {
    return FliperRenovationTask(
      id: json['id'],
      transaction: json['transaction'],
      taskName: json['task_name'],
      taskNameDisplay: json['task_name_display'] ?? '',
      budget: (json['budget'] as List<dynamic>?)
          ?.map((e) => Budget.fromJson(e))
          .toList() ??
          [],
      actualCost: json['actual_cost'],
    );
  }
}

class Budget {
  final String title;
  final String amount;

  Budget({required this.title, required this.amount});

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(title: json['title'] ?? '', amount: json['amount'] ?? '0');
  }
}
