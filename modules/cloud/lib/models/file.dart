class CloudFile {
  final String id;
  final String name;
  final int size;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> sharedWith;
  final String? folderId;
  final String? folderName;
  final String? mimeType;
  final String? fileType;
  final String url;
  final String? publicUrl;
  final String? checksum;
  final String? description;
  final List<String>? tags;
  final bool? isUniqueAssignment;
  final bool? isPublic;
  final bool? isDeleted;
  final String? thumbnailUrl;

  CloudFile({
    required this.id,
    required this.name,
    required this.size,
    required this.createdAt,
    required this.updatedAt,
    required this.sharedWith,
    this.folderId,
    this.folderName,
    this.mimeType,
    this.fileType,
    required this.url,
    this.publicUrl,
    this.checksum,
    this.description,
    this.tags,
    this.isUniqueAssignment,
    this.isPublic,
    this.isDeleted,
    this.thumbnailUrl,
  });

  factory CloudFile.fromJson(Map<String, dynamic> json) => CloudFile(
    id: json['id'].toString(),
    name: json['original_name'] ?? '',
    size: json['size'] ?? 0,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    sharedWith:
        (json['shares'] is List)
            ? (json['shares'] as List)
                .map<String>((u) => u['user_display']?.toString() ?? '')
                .toList()
            : <String>[],
    folderId: json['folder']?.toString(),
    folderName: json['folder_name']?.toString(),
    mimeType: json['mime_type']?.toString(),
    fileType: json['file_type']?.toString(),
    url: json['url'].toString(),
    checksum: json['checksum']?.toString(),
    description: json['description']?.toString(),
    tags:
        (json['tags'] is List)
            ? (json['tags'] as List).map<String>((t) => t.toString()).toList()
            : null,
    isUniqueAssignment: json['is_unique_assignment'] ?? false,
    isPublic: json['is_public'] ?? false,
    isDeleted: json['is_deleted'] ?? false,
    thumbnailUrl: json['thumbnail_url']?.toString(),
    publicUrl: json['public_url']?.toString(),
  );

  String get sizeString {
    if (size < 1024) return "$size B";
    if (size < 1024 * 1024) return "${(size / 1024).toStringAsFixed(1)} KB";
    return "${(size / 1024 / 1024).toStringAsFixed(1)} MB";
  }

  String get extension => name.contains('.') ? name.split('.').last : '';

  Map<String, dynamic> toJson() => {
    'id': id,
    'original_name': name,
    'size': size,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'shares': sharedWith.map((u) => {'user_display': u}).toList(),
    'folder': folderId,
    'folder_name': folderName,
    'mime_type': mimeType,
    'file_type': fileType,
    'url': url,
    'checksum': checksum,
    'description': description,
    'tags': tags,
    'is_unique_assignment': isUniqueAssignment,
    'is_public': isPublic,
    'is_deleted': isDeleted,
    'thumbnail_url': thumbnailUrl,
    'public_url': publicUrl,
  };
}
