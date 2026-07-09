class RefurbishmentProgress {
  final int id;
  final int task;
  final String plannedStartDate;
  final String plannedEndDate;
  final String? actualStartDate;
  final String? actualEndDate;
  final String status;

  RefurbishmentProgress({
    required this.id,
    required this.task,
    required this.plannedStartDate,
    required this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    required this.status,
  });

  factory RefurbishmentProgress.fromJson(Map<String, dynamic> json) {
    return RefurbishmentProgress(
      id: json['id'] as int,
      task: json['task'] as int,
      plannedStartDate: json['planned_start_date'] as String,
      plannedEndDate: json['planned_end_date'] as String,
      actualStartDate: json['actual_start_date'] as String?,
      actualEndDate: json['actual_end_date'] as String?,
      status: json['status'] as String,
    );
  }
}
