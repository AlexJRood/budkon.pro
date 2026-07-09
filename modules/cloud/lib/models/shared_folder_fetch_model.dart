import 'package:cloud/models/shared_file_fetch_model.dart';

class SharedFolder {
  final String id;
  final String name;
  final String? parent;
  final int? user;
  final int? company;
  final int? team;
  final bool isPublic;
  final int filesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SharedFolderShare? share;
  final SharedExplorerResponse? contents;

  const SharedFolder({
    required this.id,
    required this.name,
    this.parent,
    this.user,
    this.company,
    this.team,
    required this.isPublic,
    required this.filesCount,
    this.createdAt,
    this.updatedAt,
    this.share,
    this.contents,
  });

  factory SharedFolder.fromJson(Map<String, dynamic> json) {
    return SharedFolder(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      parent: json['parent']?.toString(),
      user: json['user'] is int ? json['user'] as int : int.tryParse('${json['user']}'),
      company: json['company'] is int ? json['company'] as int : int.tryParse('${json['company']}'),
      team: json['team'] is int ? json['team'] as int : int.tryParse('${json['team']}'),
      isPublic: json['is_public'] == true,
      filesCount: json['files_count'] is int
          ? json['files_count'] as int
          : int.tryParse('${json['files_count']}') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      share: json['share'] is Map
          ? SharedFolderShare.fromJson(Map<String, dynamic>.from(json['share'] as Map))
          : null,
      contents: json['contents'] is Map
          ? SharedExplorerResponse.fromJson(
        Map<String, dynamic>.from(json['contents'] as Map),
      )
          : null,
    );
  }
}

class SharedFolderShare {
  final String shareId;
  final String resourceType;
  final int? sharedBy;
  final int? user;
  final String? email;
  final int? company;
  final int? team;
  final String? recipientType;
  final dynamic recipientValue;
  final String? publicToken;
  final String? note;
  final bool canEdit;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const SharedFolderShare({
    required this.shareId,
    required this.resourceType,
    this.sharedBy,
    this.user,
    this.email,
    this.company,
    this.team,
    this.recipientType,
    this.recipientValue,
    this.publicToken,
    this.note,
    required this.canEdit,
    this.createdAt,
    this.expiresAt,
  });

  factory SharedFolderShare.fromJson(Map<String, dynamic> json) {
    return SharedFolderShare(
      shareId: json['share_id']?.toString() ?? '',
      resourceType: json['resource_type']?.toString() ?? '',
      sharedBy: json['shared_by'] is int
          ? json['shared_by'] as int
          : int.tryParse('${json['shared_by']}'),
      user: json['user'] is int ? json['user'] as int : int.tryParse('${json['user']}'),
      email: json['email']?.toString(),
      company: json['company'] is int
          ? json['company'] as int
          : int.tryParse('${json['company']}'),
      team: json['team'] is int ? json['team'] as int : int.tryParse('${json['team']}'),
      recipientType: json['recipient_type']?.toString(),
      recipientValue: json['recipient_value'],
      publicToken: json['public_token']?.toString(),
      note: json['note']?.toString(),
      canEdit: json['can_edit'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
    );
  }
}