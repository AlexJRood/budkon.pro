import 'package:docs/models/document_temp.dart';

class Documents {
  final String id;
  final String templateId;
  final String templateName;
  final String? ownerId;
  final String? ownerUsername;
  final String? companyId;
  final String? companyName;
  final String? teamId;
  final String? teamName;
  final String title;
  final Map<String, dynamic> currentDelta;
  final Map<String, dynamic> currentStyle;
  final int revision;
  final String? lastEditedById;
  final String? lastEditedByUsername;
  final String status;
  final bool isFinalized;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Documents({
    required this.id,
    required this.templateId,
    required this.templateName,
    this.ownerId,
    this.ownerUsername,
    this.companyId,
    this.companyName,
    this.teamId,
    this.teamName,
    required this.title,
    required this.currentDelta,
    required this.currentStyle,
    required this.revision,
    this.lastEditedById,
    this.lastEditedByUsername,
    required this.status,
    required this.isFinalized,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEditingTemplate => id == templateId;

  factory Documents.fromJson(Map<String, dynamic> json) {
    return Documents(
      id: json['id']?.toString() ?? '',
      templateId: json['template']?.toString() ?? '',
      templateName: json['template_name']?.toString() ?? '',
      ownerId: json['owner']?.toString(),
      ownerUsername: json['owner_username']?.toString(),
      companyId: json['company']?.toString(),
      companyName: json['company_name']?.toString(),
      teamId: json['team']?.toString(),
      teamName: json['team_name']?.toString(),
      title: json['title']?.toString() ?? 'Untitled Document',
      currentDelta: _normalizeDelta(json['current_delta']),
      currentStyle: _normalizeMap(json['current_style']),
      revision: _toInt(json['revision']),
      lastEditedById: json['last_edited_by']?.toString(),
      lastEditedByUsername: json['last_edited_by_username']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      isFinalized: json['is_finalized'] == true,
      createdAt: _parseDate(json['date_created'] ?? json['created_at']) ??
          DateTime.now(),
      updatedAt: _parseDate(json['date_updated'] ?? json['updated_at']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'template': templateId,
      'title': title,
      'current_delta': currentDelta,
      'current_style': currentStyle,
      'status': status,
      'is_finalized': isFinalized,
    };
  }

  Documents copyWith({
    String? id,
    String? templateId,
    String? templateName,
    String? ownerId,
    String? ownerUsername,
    String? companyId,
    String? companyName,
    String? teamId,
    String? teamName,
    String? title,
    Map<String, dynamic>? currentDelta,
    Map<String, dynamic>? currentStyle,
    int? revision,
    String? lastEditedById,
    String? lastEditedByUsername,
    String? status,
    bool? isFinalized,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Documents(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      ownerId: ownerId ?? this.ownerId,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      title: title ?? this.title,
      currentDelta: currentDelta ?? this.currentDelta,
      currentStyle: currentStyle ?? this.currentStyle,
      revision: revision ?? this.revision,
      lastEditedById: lastEditedById ?? this.lastEditedById,
      lastEditedByUsername:
          lastEditedByUsername ?? this.lastEditedByUsername,
      status: status ?? this.status,
      isFinalized: isFinalized ?? this.isFinalized,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DocumentVersion {
  final String id;
  final String documentId;
  final String title;
  final Map<String, dynamic> delta;
  final Map<String, dynamic> style;
  final int version;
  final String? authorId;
  final String? authorUsername;
  final String comment;
  final DateTime createdAt;

  const DocumentVersion({
    required this.id,
    required this.documentId,
    required this.title,
    required this.delta,
    required this.style,
    required this.version,
    this.authorId,
    this.authorUsername,
    required this.comment,
    required this.createdAt,
  });

  factory DocumentVersion.fromJson(Map<String, dynamic> json) {
    return DocumentVersion(
      id: json['id']?.toString() ?? '',
      documentId: json['document']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      delta: _normalizeDelta(json['delta_json']),
      style: _normalizeMap(json['style_json']),
      version: _toInt(json['version']),
      authorId: json['author']?.toString(),
      authorUsername: json['author_username']?.toString(),
      comment: json['comment']?.toString() ?? '',
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }
}

class DocumentCommentReply {
  final String id;
  final String commentId;
  final String? userId;
  final String? userUsername;
  final String content;
  final DateTime createdAt;

  const DocumentCommentReply({
    required this.id,
    required this.commentId,
    this.userId,
    this.userUsername,
    required this.content,
    required this.createdAt,
  });

  factory DocumentCommentReply.fromJson(Map<String, dynamic> json) {
    return DocumentCommentReply(
      id: json['id']?.toString() ?? '',
      commentId: json['comment']?.toString() ?? '',
      userId: json['user']?.toString(),
      userUsername: json['user_username']?.toString(),
      content: json['content']?.toString() ?? '',
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }
}

class DocumentComment {
  final String id;
  final String documentId;
  final String? userId;
  final String? userUsername;
  final String content;
  final Map<String, dynamic> position;
  final bool isResolved;
  final String? resolvedById;
  final String? resolvedByUsername;
  final DateTime? resolvedAt;
  final List<DocumentCommentReply> replies;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentComment({
    required this.id,
    required this.documentId,
    this.userId,
    this.userUsername,
    required this.content,
    required this.position,
    required this.isResolved,
    this.resolvedById,
    this.resolvedByUsername,
    this.resolvedAt,
    required this.replies,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentComment.fromJson(Map<String, dynamic> json) {
    final repliesRaw = json['replies'];

    return DocumentComment(
      id: json['id']?.toString() ?? '',
      documentId: json['document']?.toString() ?? '',
      userId: json['user']?.toString(),
      userUsername: json['user_username']?.toString(),
      content: json['content']?.toString() ?? json['text']?.toString() ?? '',
      position: _normalizeMap(json['position']),
      isResolved: json['is_resolved'] == true,
      resolvedById: json['resolved_by']?.toString(),
      resolvedByUsername: json['resolved_by_username']?.toString(),
      resolvedAt: _parseDate(json['resolved_at']),
      replies: repliesRaw is List
          ? repliesRaw
              .whereType<Map>()
              .map((item) => DocumentCommentReply.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'document': documentId,
      'content': content,
      'position': position,
    };
  }
}

class GeneratedDocument {
  final String id;
  final String documentId;
  final String? fileId;
  final String fileUrl;
  final String originalName;
  final String format;
  final String status;
  final Map<String, dynamic> metaData;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GeneratedDocument({
    required this.id,
    required this.documentId,
    this.fileId,
    required this.fileUrl,
    required this.originalName,
    required this.format,
    required this.status,
    required this.metaData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GeneratedDocument.fromJson(Map<String, dynamic> json) {
    return GeneratedDocument(
      id: json['id']?.toString() ?? '',
      documentId: json['document']?.toString() ?? '',
      fileId: json['pdf_file']?.toString(),
      fileUrl: json['file_url']?.toString() ??
          json['public_url']?.toString() ??
          json['document_file']?.toString() ??
          '',
      originalName: json['original_name']?.toString() ?? '',
      format: json['format']?.toString() ?? 'pdf',
      status: json['status']?.toString() ?? 'draft',
      metaData: _normalizeMap(json['meta_data']),
      createdAt: _parseDate(json['date_created'] ?? json['created_at']) ??
          DateTime.now(),
      updatedAt: _parseDate(json['date_updated'] ?? json['updated_at']) ??
          DateTime.now(),
    );
  }
}




class DocumentFillSession {
  final String id;
  final String templateId;
  final String templateName;
  final String? documentId;
  final String? documentTitle;
  final String? createdById;
  final String? createdByUsername;

  final String recipientEmail;
  final String recipientName;
  final String message;
  final String publicToken;

  final Map<String, dynamic> values;
  final String status;

  final Map<String, dynamic> templateDeltaJson;
  final Map<String, dynamic> templateStyleJson;
  final List<DocumentTemplateField> templateFields;

  final DateTime? expiresAt;
  final DateTime? openedAt;
  final DateTime? submittedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentFillSession({
    required this.id,
    required this.templateId,
    required this.templateName,
    this.documentId,
    this.documentTitle,
    this.createdById,
    this.createdByUsername,
    required this.recipientEmail,
    required this.recipientName,
    required this.message,
    required this.publicToken,
    required this.values,
    required this.status,
    required this.templateDeltaJson,
    required this.templateStyleJson,
    required this.templateFields,
    this.expiresAt,
    this.openedAt,
    this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentFillSession.fromJson(Map<String, dynamic> json) {
    final rawTemplate = json['template'];
    final templateMap = rawTemplate is Map
        ? Map<String, dynamic>.from(rawTemplate)
        : json['template_data'] is Map
            ? Map<String, dynamic>.from(json['template_data'])
            : json['template_detail'] is Map
                ? Map<String, dynamic>.from(json['template_detail'])
                : <String, dynamic>{};

    final fieldsRaw = json['template_fields'] ??
        json['form_fields'] ??
        templateMap['form_fields'] ??
        templateMap['fields'];

    return DocumentFillSession(
      id: json['id']?.toString() ?? '',
      templateId: rawTemplate is Map
          ? rawTemplate['id']?.toString() ?? ''
          : json['template']?.toString() ?? '',
      templateName: json['template_name']?.toString() ??
          templateMap['name']?.toString() ??
          '',
      documentId: json['document']?.toString(),
      documentTitle: json['document_title']?.toString(),
      createdById: json['created_by']?.toString(),
      createdByUsername: json['created_by_username']?.toString(),
      recipientEmail: json['recipient_email']?.toString() ?? '',
      recipientName: json['recipient_name']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      publicToken: json['public_token']?.toString() ?? '',
      values: _normalizeMap(json['values']),
      status: json['status']?.toString() ?? 'draft',
      templateDeltaJson: _normalizeDelta(
        json['template_delta_json'] ??
            json['template_delta'] ??
            json['delta_json'] ??
            templateMap['delta_json'],
      ),
      templateStyleJson: _normalizeMap(
        json['template_style_json'] ??
            json['template_style'] ??
            json['style_json'] ??
            templateMap['style_json'],
      ),
      templateFields: fieldsRaw is List
          ? fieldsRaw
              .whereType<Map>()
              .map(
                (item) => DocumentTemplateField.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
      expiresAt: _parseDate(json['expires_at']),
      openedAt: _parseDate(json['opened_at']),
      submittedAt: _parseDate(json['submitted_at']),
      createdAt: _parseDate(json['date_created'] ?? json['created_at']) ??
          DateTime.now(),
      updatedAt: _parseDate(json['date_updated'] ?? json['updated_at']) ??
          DateTime.now(),
    );
  }

  bool get isSubmitted => status == 'submitted' || submittedAt != null;

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const PaginatedResponse({
    required this.count,
    required this.results,
    this.next,
    this.previous,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    final rawResults = json['results'];

    return PaginatedResponse(
      count: _toInt(json['count']),
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: rawResults is List
          ? rawResults.map((item) => fromJsonT(item)).toList()
          : <T>[],
    );
  }
}

Map<String, dynamic> _normalizeDelta(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is List) return {'ops': value};

  return {
    'ops': [
      {'insert': '\n'},
    ],
  };
}

Map<String, dynamic> _normalizeMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}