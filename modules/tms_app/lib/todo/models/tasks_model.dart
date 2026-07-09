import 'user_model.dart';

const tasksDefault = Tasks();

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

class Tasks {
  final int? id;
  final int? progressId;
  final Progress? progress;
  final String? name;
  final String? description;
  final bool? isCompleted;
  final String? priority;
  final int? ordering;
  final MetaFields? metaFields;
  final String? timestamp;
  final String? updatedAt;
  final String? deadline;
  final int? commentsCount;
  final String? dateStart;
  final String? dateEnd;
  final int? assignedTo;
  final int? clientId;
  final int? transactionObjectId;
  final String? transactionContentType;
  final List<int>? members;
  final List<int>? labels;
  final List<TaskChecklist>? tmsTaskChecklist;
  final int? projectId;
  final Project? project;
  final int? assignedToUser;
  final List<String>? tags;
  final List<TaskFile>? files;
  final int? version;

  const Tasks({
    this.id,
    this.progressId,
    this.progress,
    this.name,
    this.description,
    this.isCompleted,
    this.priority,
    this.ordering,
    this.metaFields,
    this.timestamp,
    this.updatedAt,
    this.deadline,
    this.tmsTaskChecklist,
    this.commentsCount,
    this.dateStart,
    this.dateEnd,
    this.assignedTo,
    this.clientId,
    this.transactionObjectId,
    this.transactionContentType,
    this.members,
    this.labels,
    this.projectId,
    this.project,
    this.assignedToUser,
    this.tags,
    this.files,
    this.version,
  });

  factory Tasks.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);

    final projectJson = map['project'];
    final progressJson = map['progress'];

    return Tasks(
      id: _asInt(map['id']),
      progressId: progressJson is Map
          ? _asInt(Map<String, dynamic>.from(progressJson)['id'])
          : _asInt(progressJson),
      progress: progressJson is Map
          ? Progress.fromJson(Map<String, dynamic>.from(progressJson))
          : null,
      tmsTaskChecklist: (map['tms_task_checklist'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => TaskChecklist.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      name: map['name']?.toString(),
      description: map['description']?.toString(),
      isCompleted: map['is_completed'] is bool
          ? map['is_completed'] as bool
          : map['is_completed'] == null
              ? null
              : '${map['is_completed']}'.toLowerCase() == 'true',
      priority: map['priority']?.toString(),
      ordering: _asInt(map['ordering']),
      metaFields: map['meta_fields'] != null
          ? MetaFields.fromJson(Map<String, dynamic>.from(map['meta_fields']))
          : null,
      timestamp: map['timestamp']?.toString(),
      updatedAt: map['updated_at']?.toString(),
      deadline: map['deadline']?.toString(),
      commentsCount: _asInt(map['comments_count']),
      dateStart: map['date_start']?.toString(),
      dateEnd: map['date_end']?.toString(),
      assignedTo: _asInt(map['assigned_to']),
      clientId: _asInt(map['client']),
      transactionObjectId: _asInt(map['transaction_object_id']),
      transactionContentType: map['transaction_content_type']?.toString(),
      members: map['members'] != null ? List<int>.from(map['members']) : [],
      labels: map['label'] != null ? List<int>.from(map['label']) : [],
      projectId: projectJson is Map
          ? _asInt(Map<String, dynamic>.from(projectJson)['id'])
          : _asInt(projectJson),
      project: projectJson is Map
          ? Project.fromJson(Map<String, dynamic>.from(projectJson))
          : null,
      assignedToUser: _asInt(map['assigned_to_user']),
      tags: map['tags'] != null ? List<String>.from(map['tags']) : [],
      files: map['files'] != null
          ? List<TaskFile>.from(
              (map['files'] as List)
                  .whereType<Map>()
                  .map((fileJson) =>
                      TaskFile.fromJson(Map<String, dynamic>.from(fileJson))),
            )
          : [],
      version: _asInt(map['version']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'progress': progress?.toJson() ?? progressId,
      'name': name,
      'description': description,
      'is_completed': isCompleted,
      'priority': priority,
      'ordering': ordering,
      'meta_fields': metaFields?.toJson(),
      'timestamp': timestamp,
      'updated_at': updatedAt,
      'deadline': deadline,
      'tms_task_checklist': tmsTaskChecklist?.map((e) => e.toJson()).toList(),
      'comments_count': commentsCount,
      'date_start': dateStart,
      'date_end': dateEnd,
      'assigned_to': assignedTo,
      'client': clientId,
      'transaction_object_id': transactionObjectId,
      'transaction_content_type': transactionContentType,
      'members': members,
      'label': labels,
      'project': project?.toJson() ?? projectId,
      'projectId': projectId,
      'assigned_to_user': assignedToUser,
      'tags': tags,
      'files': files?.map((file) => file.toJson()).toList(),
      'version': version,
    };
  }

  Tasks copyWith({
    int? id,
    int? progressId,
    Progress? progress,
    String? name,
    String? description,
    bool? isCompleted,
    String? priority,
    int? ordering,
    MetaFields? metaFields,
    String? timestamp,
    String? updatedAt,
    String? deadline,
    int? projectId,
    Project? project,
    int? assignedTo,
    int? assignedToUser,
    List<String>? tags,
    List<TaskFile>? files,
    List<int>? members,
    List<int>? labels,
    String? dateStart,
    String? dateEnd,
    int? clientId,
    int? transactionObjectId,
    String? transactionContentType,
    List<TaskChecklist>? tmsTaskChecklist,
    int? commentsCount,
    int? version,
  }) {
    return Tasks(
      id: id ?? this.id,
      progressId: progressId ?? this.progressId,
      progress: progress ?? this.progress,
      name: name ?? this.name,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      ordering: ordering ?? this.ordering,
      metaFields: metaFields ?? this.metaFields,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      deadline: deadline ?? this.deadline,
      tmsTaskChecklist: tmsTaskChecklist ?? this.tmsTaskChecklist,
      commentsCount: commentsCount ?? this.commentsCount,
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      assignedTo: assignedTo ?? this.assignedTo,
      clientId: clientId ?? this.clientId,
      transactionObjectId: transactionObjectId ?? this.transactionObjectId,
      transactionContentType:
          transactionContentType ?? this.transactionContentType,
      version: version ?? this.version,
      members: members ?? this.members,
      labels: labels ?? this.labels,
      projectId: projectId ?? this.projectId,
      project: project ?? this.project,
      assignedToUser: assignedToUser ?? this.assignedToUser,
      tags: tags ?? this.tags,
      files: files ?? this.files,
    );
  }
}

class MetaFields {
  final String? someField;
  final bool emmaPending;

  const MetaFields({this.someField, this.emmaPending = false});

  factory MetaFields.fromJson(Map<String, dynamic> json) {
    return MetaFields(
      someField: json['some-field']?.toString(),
      emmaPending: json['emma_pending'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'some-field': someField,
      'emma_pending': emmaPending,
    };
  }
}

class TaskFile {
  final int? id;
  final String? task;
  final String? filename;
  final String? file;
  final String? timestamp;

  const TaskFile({
    this.id,
    this.task,
    this.filename,
    this.file,
    this.timestamp,
  });

  factory TaskFile.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId = rawId is int ? rawId : int.tryParse('$rawId');
    final fn = (json['filename'] ?? json['name'])?.toString();

    return TaskFile(
      id: parsedId,
      task: json['task']?.toString(),
      filename: fn,
      file: json['file']?.toString(),
      timestamp: json['timestamp']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'task': task,
        'filename': filename,
        'file': file,
        'timestamp': timestamp,
      };

  TaskFile copyWith({
    int? id,
    String? task,
    String? filename,
    String? file,
    String? timestamp,
  }) {
    return TaskFile(
      id: id ?? this.id,
      task: task ?? this.task,
      filename: filename ?? this.filename,
      file: file ?? this.file,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  String get displayName {
    final n = filename?.trim();
    if (n != null && n.isNotEmpty) return n;

    final f = file?.trim();
    if (f != null && f.isNotEmpty) {
      try {
        final segs = Uri.parse(f).pathSegments;
        if (segs.isNotEmpty) return segs.last;
      } catch (_) {}
    }
    return 'attachment';
  }

  @override
  String toString() =>
      'TaskFile(id: $id, task: $task, filename: $filename, file: $file, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          task == other.task &&
          filename == other.filename &&
          file == other.file &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(id, task, filename, file, timestamp);
}

class Project {
  final int? id;
  final User? user;
  final String? avatar;
  final String? name;
  final String? description;
  final String? timestamp;
  final String? updatedAt;
  final int? version;
  final List<dynamic>? addedUsers;

  const Project({
    this.id,
    this.user,
    this.avatar,
    this.name,
    this.description,
    this.timestamp,
    this.updatedAt,
    this.version,
    this.addedUsers,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: _asInt(json['id']),
      user: json['user'] != null && json['user'] is Map
          ? User.fromJson(Map<String, dynamic>.from(json['user']))
          : null,
      avatar: json['avatar']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      timestamp: json['timestamp']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      version: _asInt(json['version']),
      addedUsers:
          json['added_users'] != null ? List<dynamic>.from(json['added_users']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'avatar': avatar,
      'name': name,
      'description': description,
      'timestamp': timestamp,
      'updated_at': updatedAt,
      'version': version,
      'added_users': addedUsers,
    };
  }
}

class Progress {
  final int? id;
  final int? projectId;
  final String? name;
  final String? timestamp;
  final String? updatedAt;
  final int? version;

  const Progress({
    this.id,
    this.projectId,
    this.name,
    this.timestamp,
    this.updatedAt,
    this.version,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      id: _asInt(json['id']),
      projectId: _asInt(json['project']),
      name: json['name']?.toString(),
      timestamp: json['timestamp']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      version: _asInt(json['version']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project': projectId,
      'name': name,
      'timestamp': timestamp,
      'updated_at': updatedAt,
      'version': version,
    };
  }

  Progress copyWith({
    int? id,
    int? projectId,
    String? name,
    String? timestamp,
    String? updatedAt,
    int? version,
  }) {
    return Progress(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}

class ChecklistItem {
  final String name;
  final bool completed;
  final int? checkedBy;
  final DateTime? checkedAt;

  const ChecklistItem({
    required this.name,
    required this.completed,
    this.checkedBy,
    this.checkedAt,
  });

  ChecklistItem copyWith({
    String? name,
    bool? completed,
    int? checkedBy,
    DateTime? checkedAt,
    bool clearCheckedBy = false,
    bool clearCheckedAt = false,
  }) {
    return ChecklistItem(
      name: name ?? this.name,
      completed: completed ?? this.completed,
      checkedBy: clearCheckedBy ? null : (checkedBy ?? this.checkedBy),
      checkedAt: clearCheckedAt ? null : (checkedAt ?? this.checkedAt),
    );
  }

  factory ChecklistItem.fromJson(dynamic json) {
    if (json is! Map) {
      return const ChecklistItem(name: 'Invalid Item', completed: false);
    }

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final trimmed = v.trim();
        if (trimmed.isEmpty) return null;
        return int.tryParse(trimmed);
      }
      return null;
    }

    DateTime? toDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return ChecklistItem(
      name: (json['name'] ?? json['title'] ?? '').toString(),
      completed: (json['completed'] ?? false) == true,
      checkedBy: toInt(json['checked_by'] ?? json['checkedBy']),
      checkedAt: toDate(json['checked_at'] ?? json['checkedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'completed': completed,
      if (checkedBy != null) 'checked_by': checkedBy,
      if (checkedAt != null) 'checked_at': checkedAt!.toIso8601String(),
    };
  }
}

class TaskChecklist {
  final int id;
  final int task;
  final String title;
  final String description;
  final List<ChecklistItem> checklist;
  final int? createdBy;

  TaskChecklist({
    required this.id,
    required this.task,
    required this.title,
    required this.description,
    required this.checklist,
    this.createdBy,
  });

  TaskChecklist copyWith({
    int? id,
    int? task,
    String? title,
    String? description,
    List<ChecklistItem>? checklist,
    int? createdBy,
  }) {
    return TaskChecklist(
      id: id ?? this.id,
      task: task ?? this.task,
      title: title ?? this.title,
      description: description ?? this.description,
      checklist: checklist ?? this.checklist,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory TaskChecklist.fromJson(Map<String, dynamic> json) {
    final rawList = (json['checklist'] as List?) ?? const [];
    return TaskChecklist(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      task: int.tryParse(json['task']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      checklist: rawList.map((e) => ChecklistItem.fromJson(e)).toList(),
      createdBy: json['created_by'] == null
          ? null
          : int.tryParse(json['created_by'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'task': task,
        'title': title,
        'description': description,
        'checklist': checklist.map((e) => e.toJson()).toList(),
        if (createdBy != null) 'created_by': createdBy,
      };
}