


// =====================
// 1) MODELS
// =====================

class AssocCampaignStatus {
  static const draft = 'draft';
  static const scheduled = 'scheduled';
  static const sending = 'sending';
  static const sent = 'sent';
  static const cancelled = 'cancelled';
  static const failed = 'failed';
}

class RecipientPreview {
  final String memberId;
  final String memberName;
  final String status; // planned/sent/failed/skipped
  final String? error;
  final DateTime? sentAt;

  RecipientPreview({
    required this.memberId,
    required this.memberName,
    required this.status,
    this.error,
    this.sentAt,
  });

  factory RecipientPreview.fromJson(Map<String, dynamic> j) {
    return RecipientPreview(
      memberId: j['member_id']?.toString() ?? '',
      memberName: j['member_name']?.toString() ?? '',
      status: j['status']?.toString() ?? 'planned',
      error: j['error']?.toString(),
      sentAt: j['sent_at'] != null ? DateTime.tryParse(j['sent_at'].toString()) : null,
    );
  }
}

class AssociationNotificationCampaign {
  final String id;
  final int associationId;
  final String title;
  final String text;
  final String status;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int totalRecipients;
  final int sentSuccess;
  final int sentFailed;
  final String? lastError;

  // detail-only
  final String? image;
  final List<dynamic> actions; // keep raw, UI shows as JSON view
  final List<String> memberStatuses;
  final List<dynamic> roleIds;
  final List<String> includeMemberIds;
  final List<String> excludeMemberIds;
  final bool? respectConsent;
  final bool? includeInactiveDevices;
  final List<RecipientPreview> preview;

  AssociationNotificationCampaign({
    required this.id,
    required this.associationId,
    required this.title,
    required this.text,
    required this.status,
    this.scheduledAt,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    required this.totalRecipients,
    required this.sentSuccess,
    required this.sentFailed,
    this.lastError,
    this.image,
    this.actions = const [],
    this.memberStatuses = const [],
    this.roleIds = const [],
    this.includeMemberIds = const [],
    this.excludeMemberIds = const [],
    this.respectConsent,
    this.includeInactiveDevices,
    this.preview = const [],
  });

  factory AssociationNotificationCampaign.fromListJson(Map<String, dynamic> j) {
    return AssociationNotificationCampaign(
      id: j['id'].toString(),
      associationId: j['association_id'] is int
          ? j['association_id'] as int
          : int.tryParse(j['association_id'].toString()) ?? 0,
      title: j['title']?.toString() ?? '',
      text: j['text']?.toString() ?? '',
      status: j['status']?.toString() ?? AssocCampaignStatus.draft,
      scheduledAt: _parseDate(j['scheduled_at']),
      createdAt: _parseDate(j['created_at']) ?? DateTime.now(),
      startedAt: _parseDate(j['started_at']),
      finishedAt: _parseDate(j['finished_at']),
      totalRecipients: j['total_recipients'] as int? ?? 0,
      sentSuccess: j['sent_success'] as int? ?? 0,
      sentFailed: j['sent_failed'] as int? ?? 0,
      lastError: j['last_error']?.toString(),
    );
  }

  factory AssociationNotificationCampaign.fromDetailJson(Map<String, dynamic> j) {
    return AssociationNotificationCampaign(
      id: j['id'].toString(),
      associationId: j['association_id'] is int
          ? j['association_id'] as int
          : int.tryParse(j['association_id'].toString()) ?? 0,
      title: j['title']?.toString() ?? '',
      text: j['text']?.toString() ?? '',
      status: j['status']?.toString() ?? AssocCampaignStatus.draft,
      scheduledAt: _parseDate(j['scheduled_at']),
      createdAt: _parseDate(j['created_at']) ?? DateTime.now(),
      startedAt: _parseDate(j['started_at']),
      finishedAt: _parseDate(j['finished_at']),
      totalRecipients: j['total_recipients'] as int? ?? 0,
      sentSuccess: j['sent_success'] as int? ?? 0,
      sentFailed: j['sent_failed'] as int? ?? 0,
      lastError: j['last_error']?.toString(),
      image: j['image']?.toString(),
      actions: (j['actions'] as List?) ?? const [],
      memberStatuses: ((j['member_statuses'] as List?) ?? []).map((e) => e.toString()).toList(),
      roleIds: (j['role_ids'] as List?) ?? const [],
      includeMemberIds: ((j['include_member_ids'] as List?) ?? []).map((e) => e.toString()).toList(),
      excludeMemberIds: ((j['exclude_member_ids'] as List?) ?? []).map((e) => e.toString()).toList(),
      respectConsent: j['respect_consent'] as bool?,
      includeInactiveDevices: j['include_inactive_devices'] as bool?,
      preview: ((j['recipients_preview'] as List?) ?? [])
          .map((e) => RecipientPreview.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}
