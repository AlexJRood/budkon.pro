import 'board_progress_model.dart';
import 'user_model.dart';

final boardDetailsModelDefault = BoardDetailsModel(
  timestamp: DateTime.now().toIso8601String(),
  updatedAt: DateTime.now().toIso8601String(),
  version: 1,
  name: '',
  id: 0,
  projectProgresses: [projectProgressDefault],
  user: userDefault,
);

class BoardDetailsModel {
  final int? id;
  final User? user;
  final List<ProjectProgresses>? projectProgresses;
  final String? name;
  final String? timestamp;
  final String? updatedAt;
  final int? version;

  const BoardDetailsModel({
    this.id,
    this.user,
    this.projectProgresses,
    this.name,
    this.timestamp,
    this.updatedAt,
    this.version,
  });

  factory BoardDetailsModel.fromJson(Map json) {
    final map = Map<String, dynamic>.from(json);

    final rawProgresses = map['project_progesses'];
    final parsedProgresses = rawProgresses is List
        ? rawProgresses
            .whereType<Map>()
            .map((v) => ProjectProgresses.fromJson(Map<String, dynamic>.from(v)))
            .toList()
        : <ProjectProgresses>[];

    return BoardDetailsModel(
      id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}'),
      user: map['user'] is Map
          ? User.fromJson(Map<String, dynamic>.from(map['user']))
          : null,
      projectProgresses: parsedProgresses,
      name: map['name']?.toString(),
      timestamp: map['timestamp']?.toString(),
      updatedAt: map['updated_at']?.toString(),
      version: map['version'] is int
          ? map['version'] as int
          : int.tryParse('${map['version']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'project_progesses': projectProgresses?.map((v) => v.toJson()).toList(),
      'name': name,
      'timestamp': timestamp,
      'updated_at': updatedAt,
      'version': version,
    };
  }
}