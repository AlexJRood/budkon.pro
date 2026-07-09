class RefurbishmentTask {
  final int id;
  final int transaction;
  final String taskName;
  final String taskNameDisplay;
  final String budget;
  final String? actualCost;

  RefurbishmentTask({
    required this.id,
    required this.transaction,
    required this.taskName,
    required this.taskNameDisplay,
    required this.budget,
    this.actualCost,
  });

  factory RefurbishmentTask.fromJson(Map<String, dynamic> json) {
    return RefurbishmentTask(
      id: json['id'] as int,
      transaction: json['transaction'] as int,
      taskName: json['task_name'] as String,
      taskNameDisplay: json['task_name_display'] as String,
      budget: json['budget'] as String,
      actualCost: json['actual_cost']?.toString(),
    );
  }
}
