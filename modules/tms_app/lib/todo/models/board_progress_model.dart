import 'tasks_model.dart';

final projectProgressDefault = ProjectProgresses(
  id: 0,
  name: '',
  timestamp: DateTime.now().toIso8601String(),
  updatedAt: DateTime.now().toIso8601String(),
  version: 1,
  project: 1,
  tasks: const [],
);

class ProjectProgresses {
  final int? id;
  final List<Tasks>? tasks;
  final String? name;
  final String? timestamp;
  final String? updatedAt;
  final int? version;
  final int? project;

  const ProjectProgresses({
    this.id,
    this.tasks,
    this.name,
    this.timestamp,
    this.updatedAt,
    this.version,
    this.project,
  });

  factory ProjectProgresses.fromJson(Map json) {
    final map = Map<String, dynamic>.from(json);

    final rawTasks = map['tasks'];
    final parsedTasks = rawTasks is List
        ? rawTasks
            .whereType<Map>()
            .map((v) => Tasks.fromJson(Map<String, dynamic>.from(v)))
            .toList()
        : <Tasks>[];

    return ProjectProgresses(
      id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}'),
      tasks: parsedTasks,
      name: map['name']?.toString(),
      timestamp: map['timestamp']?.toString(),
      updatedAt: map['updated_at']?.toString(),
      version: map['version'] is int
          ? map['version'] as int
          : int.tryParse('${map['version']}'),
      project: map['project'] is int
          ? map['project'] as int
          : int.tryParse('${map['project']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tasks': tasks?.map((v) => v.toJson()).toList(),
      'name': name,
      'timestamp': timestamp,
      'updated_at': updatedAt,
      'version': version,
      'project': project,
    };
  }

  ProjectProgresses copyWith({
    int? id,
    List<Tasks>? tasks,
    String? name,
    String? timestamp,
    String? updatedAt,
    int? version,
    int? project,
  }) {
    return ProjectProgresses(
      id: id ?? this.id,
      tasks: tasks ?? this.tasks,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      project: project ?? this.project,
    );
  }
}