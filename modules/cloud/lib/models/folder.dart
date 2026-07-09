class CloudFolder {
  final String id;
  final String name;
  final String? parent;
  final int? filesCount;

  // Dodane z backendu:
  final int? user;
  final int? company;
  final int? team;
  final bool? isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CloudFolder({
    required this.id,
    required this.name,
    required this.filesCount,
    this.parent,
    this.user,
    this.company,
    this.team,
    this.isPublic,
    this.createdAt,
    this.updatedAt,
  });

  factory CloudFolder.fromJson(Map<String, dynamic> json) => CloudFolder(
    id: json['id'].toString(),
    name: json['name'] ?? '',
    parent: json['parent']?.toString(),
    filesCount: json['files_count'] ?? 0,
    user: json['user'] as int?,
    company: json['company'] as int?,
    team: json['team'] as int?,
    isPublic: json['is_public'] as bool?,
    createdAt:
        json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
    updatedAt:
        json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'])
            : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'parent': parent,
    'files_count': filesCount,
    'user': user,
    'company': company,
    'team': team,
    'is_public': isPublic,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
