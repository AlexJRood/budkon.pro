class TaskModel {
  final int id;
  final String name;
  final String description;
  final bool isCompleted;
  final String priority;
  final DateTime timestamp;
  final int creator;
  final dynamic progress;
  final int assignedToUser;
  final String status;

  const TaskModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isCompleted,
    required this.priority,
    required this.timestamp,
    required this.creator,
    this.progress,
    required this.assignedToUser,
    this.status = 'Todo',
  });

  factory TaskModel.fromJson(Map<String, dynamic> data) => TaskModel(
        id: data['id'] ?? 0,
        name: data['name'].toString(),
        description: data['description'].toString(),
        isCompleted: data['is_completed'] ?? false,
        priority: data['priority'].toString(),
        timestamp: DateTime.parse(data['timestamp']),
        creator: data['creator'] ?? 0,
        progress: data['progress'] ?? 0,
        assignedToUser: data['assigned_to_user'] ?? 0,
        status: data['status'] ?? 'In Progress',
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_completed': isCompleted,
      'priority': priority,
      'timestamp': timestamp.toIso8601String(),
      'creator': creator,
      'progress': progress,
      'assigned_to_user': assignedToUser,
      'status': status,
    };
  }

  TaskModel copyWith({
    int? id,
    String? name,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? timestamp,
    int? creator,
    dynamic progress,
    int? assignedToUser,
    String? status,
  }) {
    return TaskModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      creator: creator ?? this.creator,
      progress: progress ?? this.progress,
      assignedToUser: assignedToUser ?? this.assignedToUser,
      status: status ?? this.status,
    );
  }
}

class StoryModel {
  const StoryModel({
    required this.title,
    required this.children,
  });

  factory StoryModel.fromJson(Map<String, dynamic> data) => StoryModel(
        title: data['title'] as String,
        children: data['children'] as List<TaskModel>,
      );

  StoryModel copyWith({
    String? title,
    List<TaskModel>? children,
  }) {
    return StoryModel(
      title: title ?? this.title,
      children: children ?? this.children,
    );
  }

  final String title;
  final List<TaskModel> children;
}