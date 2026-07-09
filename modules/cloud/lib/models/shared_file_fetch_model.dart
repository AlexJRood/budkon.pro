
import 'package:cloud/models/folder.dart';
import 'package:cloud/models/shared_folder_fetch_model.dart';

class SharedExplorerResponse {
  final int count;
  final int foldersCount;
  final int filesCount;
  final String? next;
  final String? previous;
  final List<SharedFolder> subfolders;
  final List<SharedFile> files;

  SharedExplorerResponse({
    required this.count,
    required this.foldersCount,
    required this.filesCount,
    required this.next,
    required this.previous,
    required this.subfolders,
    required this.files,
  });

  factory SharedExplorerResponse.fromJson(Map<String, dynamic> json) {
    return SharedExplorerResponse(
      count: json['count'] ?? 0,
      foldersCount: json['folders_count'] ?? 0,
      filesCount: json['files_count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      subfolders: (json['subfolders'] as List<dynamic>?)
          ?.map((e) => SharedFolder.fromJson(e))
          .toList() ??
          [],
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => SharedFile.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class CloudFileShare {
  final String shareId;
  final String? resourceType;
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

  const CloudFileShare({
    required this.shareId,
    required this.resourceType,
    required this.sharedBy,
    required this.user,
    required this.email,
    required this.company,
    required this.team,
    required this.recipientType,
    required this.recipientValue,
    required this.publicToken,
    required this.note,
    required this.canEdit,
    required this.createdAt,
    required this.expiresAt,
  });

  factory CloudFileShare.fromJson(Map<String, dynamic> json) {
    return CloudFileShare(
      shareId: (json['share_id'] ?? '').toString(),
      resourceType: json['resource_type']?.toString(),
      sharedBy: json['shared_by'] is int
          ? json['shared_by'] as int
          : int.tryParse('${json['shared_by']}'),
      user: json['user'] is int
          ? json['user'] as int
          : int.tryParse('${json['user']}'),
      email: json['email']?.toString(),
      company: json['company'] is int
          ? json['company'] as int
          : int.tryParse('${json['company']}'),
      team: json['team'] is int
          ? json['team'] as int
          : int.tryParse('${json['team']}'),
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

  String get recipientLabel {
    switch (recipientType) {
      case 'email':
        return email ?? recipientValue?.toString() ?? 'Email';
      case 'user':
        return 'User #${recipientValue ?? user ?? ''}';
      case 'company':
        return 'Company #${recipientValue ?? company ?? ''}';
      case 'team':
        return 'Team #${recipientValue ?? team ?? ''}';
      default:
        return recipientValue?.toString() ?? 'Unknown recipient';
    }
  }
}

class SharedFile {
  final String id;
  final String? folder;
  final int? user;
  final String fileType;
  final String originalName;
  final String url;
  final String? mimeType;
  final int size;
  final String? checksum;
  final String? description;
  final List<String> tags;
  final bool isUniqueAssignment;
  final bool isPublic;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CloudFileShare? share;
  final String? thumbnailUrl;

  const SharedFile({
    required this.id,
    required this.folder,
    required this.user,
    required this.fileType,
    required this.originalName,
    required this.url,
    required this.mimeType,
    required this.size,
    required this.checksum,
    required this.description,
    required this.tags,
    required this.isUniqueAssignment,
    required this.isPublic,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.share,
    required this.thumbnailUrl,
  });

  factory SharedFile.fromJson(Map<String, dynamic> json) {
    return SharedFile(
      id: (json['id'] ?? '').toString(),
      folder: json['folder']?.toString(),
      user: json['user'] is int
          ? json['user'] as int
          : int.tryParse('${json['user']}'),
      fileType: (json['file_type'] ?? '').toString(),
      originalName: (json['original_name'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      mimeType: json['mime_type']?.toString(),
      size: json['size'] is int
          ? json['size'] as int
          : int.tryParse('${json['size']}') ?? 0,
      checksum: json['checksum']?.toString(),
      description: json['description']?.toString(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      isUniqueAssignment: json['is_unique_assignment'] == true,
      isPublic: json['is_public'] == true,
      isDeleted: json['is_deleted'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      share: json['share'] is Map<String, dynamic>
          ? CloudFileShare.fromJson(json['share'] as Map<String, dynamic>)
          : json['share'] is Map
          ? CloudFileShare.fromJson(
        Map<String, dynamic>.from(json['share'] as Map),
      )
          : null,
      thumbnailUrl: json['thumbnail_url']?.toString(),
    );
  }

  String get name => originalName;

  bool get isImage =>
      fileType.toLowerCase() == 'image' ||
          (mimeType ?? '').toLowerCase().startsWith('image/');

  bool get isVideo =>
      fileType.toLowerCase() == 'video' ||
          (mimeType ?? '').toLowerCase().startsWith('video/');

  bool get isPdf =>
      (mimeType ?? '').toLowerCase().contains('pdf') ||
          url.toLowerCase().endsWith('.pdf');

  bool get isText =>
      (mimeType ?? '').toLowerCase().startsWith('text/');

  bool get hasDescription => (description ?? '').trim().isNotEmpty;
  bool get hasTags => tags.isNotEmpty;
}