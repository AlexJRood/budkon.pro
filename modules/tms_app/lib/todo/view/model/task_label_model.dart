// tms_app/todo/view/model/task_label_model.dart

class TaskLabelsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<TaskLabel> results;

  TaskLabelsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory TaskLabelsResponse.fromJson(Map<String, dynamic> json) {
    return TaskLabelsResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results:
      (json['results'] as List<dynamic>)
          .map((e) => TaskLabel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }
}

class TaskLabel {
  final int id;
  final String color;
  final String name;

  TaskLabel({required this.id, required this.color, required this.name});

  factory TaskLabel.fromJson(Map<String, dynamic> json) {
    return TaskLabel(
      id: json['id'] as int,
      color: json['color'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'color': color, 'name': name};
  }
}
