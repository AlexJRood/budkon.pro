import 'dart:convert';

class EmailTag {
  final int id;
  final String name;
  final String slug;
  final String color;
  final int order;
  final bool isSystem;

  const EmailTag({
    required this.id,
    required this.name,
    required this.slug,
    required this.color,
    required this.order,
    required this.isSystem,
  });

  factory EmailTag.fromJson(Map<String, dynamic> json) {
    return EmailTag(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      color: (json['color'] ?? '#7C3AED').toString(),
      order: int.tryParse('${json['order']}') ?? 0,
      isSystem: json['is_system'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'color': color,
        'order': order,
        'is_system': isSystem,
      };
}

class EmailTab {
  final int id;
  final String name;
  final String slug;
  final String color;
  final String icon;
  final int order;
  final bool isSystem;
  final String systemKey;
  final bool isVisible;
  final bool excludeFromEmmaProcessing;
  final bool autoAssignEnabled;

  const EmailTab({
    required this.id,
    required this.name,
    required this.slug,
    required this.color,
    required this.icon,
    required this.order,
    required this.isSystem,
    required this.systemKey,
    required this.isVisible,
    required this.excludeFromEmmaProcessing,
    required this.autoAssignEnabled,
  });

  factory EmailTab.fromJson(Map<String, dynamic> json) {
    return EmailTab(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      color: (json['color'] ?? '#2563EB').toString(),
      icon: (json['icon'] ?? '').toString(),
      order: int.tryParse('${json['order']}') ?? 0,
      isSystem: json['is_system'] == true,
      systemKey: (json['system_key'] ?? '').toString(),
      isVisible: json['is_visible'] != false,
      excludeFromEmmaProcessing:
          json['exclude_from_emma_processing'] == true,
      autoAssignEnabled: json['auto_assign_enabled'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'color': color,
        'icon': icon,
        'order': order,
        'is_system': isSystem,
        'system_key': systemKey,
        'is_visible': isVisible,
        'exclude_from_emma_processing': excludeFromEmmaProcessing,
        'auto_assign_enabled': autoAssignEnabled,
      };
}


class EmailMessage {
  final int id;
  final String? messageId;
  final String subject;
  final String body;
  final String htmlBody;
  final String sender;
  final List<String> recipients;
  final List<String> cc;
  final List<String> bcc;
  final String? receivedAt;
  final String? sentAt;
  final String? timelineAtIso;
  final bool isRead;
  final bool isOutgoing;
  final String? inReplyTo;
  final String email;
  final String? createdAt;
  final String? updatedAt;
  final int? leadId;
  final int? pipelineStageId;
  final String senderDisplayName;
  final String? avatarUrl;

  final int? currentTabId;
  final String currentTabName;
  final String currentTabSlug;
  final String currentTabColor;

  final List<EmailTag> tags;

  final bool isEmma;
  final bool isEmmaDirectSend;
  final String? emmaLastSeenAt;
  final String? emmaLastUsedAt;

  final String spamStatus;
  final double? spamScore;
  final String spamReason;
  final String spamUserOverride;
  final bool effectiveIsSpam;
  final bool shouldSkipEmmaProcessing;

  final String listUnsubscribeHeader;
  final String? unsubscribeUrl;
  final String? unsubscribeMailto;
  final String unsubscribeStatus;
  final String? unsubscribedAt;

  const EmailMessage({
    required this.id,
    required this.messageId,
    required this.subject,
    required this.body,
    required this.htmlBody,
    required this.sender,
    required this.recipients,
    required this.cc,
    required this.bcc,
    required this.receivedAt,
    required this.sentAt,
    required this.timelineAtIso,
    required this.isRead,
    required this.isOutgoing,
    required this.inReplyTo,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.leadId,
    required this.pipelineStageId,
    required this.senderDisplayName,
    required this.avatarUrl,
    required this.currentTabId,
    required this.currentTabName,
    required this.currentTabSlug,
    required this.currentTabColor,
    required this.tags,
    required this.isEmma,
    required this.isEmmaDirectSend,
    required this.emmaLastSeenAt,
    required this.emmaLastUsedAt,
    required this.spamStatus,
    required this.spamScore,
    required this.spamReason,
    required this.spamUserOverride,
    required this.effectiveIsSpam,
    required this.shouldSkipEmmaProcessing,
    required this.listUnsubscribeHeader,
    required this.unsubscribeUrl,
    required this.unsubscribeMailto,
    required this.unsubscribeStatus,
    required this.unsubscribedAt,
  });

  bool get hasHtmlBody => htmlBody.trim().isNotEmpty;

  String get bestBody {
    final html = htmlBody.trim();
    if (html.isNotEmpty) return html;
    return body;
  }

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return const [];

      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }

      if (value is String) {
        final s = value.trim();
        if (s.isEmpty) return const [];

        if (s.startsWith('[') && s.endsWith(']')) {
          try {
            final decoded = jsonDecode(s);
            if (decoded is List) {
              return decoded.map((e) => e.toString()).toList();
            }
          } catch (_) {}
        }

        return s
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      return const [];
    }

    List<EmailTag> parseTags(dynamic value) {
      if (value is! List) return const [];

      return value
          .whereType<Map>()
          .map(
            (e) => EmailTag.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          )
          .toList();
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return EmailMessage(
      id: int.tryParse('${json['id']}') ?? 0,
      messageId: json['message_id']?.toString(),
      subject: (json['subject'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      htmlBody: (
        json['html_body'] ??
        json['htmlBody'] ??
        json['body_html'] ??
        ''
      ).toString(),
      sender: (json['sender'] ?? '').toString(),
      recipients: parseStringList(json['recipients']),
      cc: parseStringList(json['cc']),
      bcc: parseStringList(json['bcc']),
      receivedAt: json['received_at']?.toString(),
      sentAt: json['sent_at']?.toString(),
      timelineAtIso: json['timeline_at']?.toString(),
      isRead: json['is_read'] == true,
      isOutgoing: json['is_outgoing'] == true,
      inReplyTo: json['in_reply_to']?.toString(),
      email: (json['email'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      leadId: int.tryParse('${json['lead']}'),
      pipelineStageId: int.tryParse('${json['pipeline_stage']}'),
      senderDisplayName: (json['sender_display_name'] ?? '').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      currentTabId: int.tryParse('${json['current_tab']}'),
      currentTabName: (json['current_tab_name'] ?? '').toString(),
      currentTabSlug: (json['current_tab_slug'] ?? '').toString(),
      currentTabColor: (json['current_tab_color'] ?? '#2563EB').toString(),
      tags: parseTags(json['tags']),
      isEmma: json['is_emma'] == true,
      isEmmaDirectSend: json['is_emma_direct_send'] == true,
      emmaLastSeenAt: json['emma_last_seen_at']?.toString(),
      emmaLastUsedAt: json['emma_last_used_at']?.toString(),
      spamStatus: (json['spam_status'] ?? 'unknown').toString(),
      spamScore: parseDouble(json['spam_score']),
      spamReason: (json['spam_reason'] ?? '').toString(),
      spamUserOverride: (json['spam_user_override'] ?? 'none').toString(),
      effectiveIsSpam: json['effective_is_spam'] == true,
      shouldSkipEmmaProcessing: json['should_skip_emma_processing'] == true,
      listUnsubscribeHeader:
          (json['list_unsubscribe_header'] ?? '').toString(),
      unsubscribeUrl: json['unsubscribe_url']?.toString(),
      unsubscribeMailto: json['unsubscribe_mailto']?.toString(),
      unsubscribeStatus:
          (json['unsubscribe_status'] ?? 'unknown').toString(),
      unsubscribedAt: json['unsubscribed_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson({bool includeBody = true}) => {
        'id': id,
        'message_id': messageId,
        'subject': subject,
        if (includeBody) 'body': body,
        if (includeBody) 'html_body': htmlBody,
        'sender': sender,
        'recipients': recipients,
        'cc': cc,
        'bcc': bcc,
        'received_at': receivedAt,
        'sent_at': sentAt,
        'timeline_at': timelineAtIso,
        'is_read': isRead,
        'is_outgoing': isOutgoing,
        'in_reply_to': inReplyTo,
        'email': email,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'lead': leadId,
        'pipeline_stage': pipelineStageId,
        'sender_display_name': senderDisplayName,
        'avatar_url': avatarUrl,
        'current_tab': currentTabId,
        'current_tab_name': currentTabName,
        'current_tab_slug': currentTabSlug,
        'current_tab_color': currentTabColor,
        'tags': tags.map((e) => e.toJson()).toList(),
        'is_emma': isEmma,
        'is_emma_direct_send': isEmmaDirectSend,
        'emma_last_seen_at': emmaLastSeenAt,
        'emma_last_used_at': emmaLastUsedAt,
        'spam_status': spamStatus,
        'spam_score': spamScore,
        'spam_reason': spamReason,
        'spam_user_override': spamUserOverride,
        'effective_is_spam': effectiveIsSpam,
        'should_skip_emma_processing': shouldSkipEmmaProcessing,
        'list_unsubscribe_header': listUnsubscribeHeader,
        'unsubscribe_url': unsubscribeUrl,
        'unsubscribe_mailto': unsubscribeMailto,
        'unsubscribe_status': unsubscribeStatus,
        'unsubscribed_at': unsubscribedAt,
      };

  EmailMessage copyWith({
    bool? isRead,
    String? body,
    String? htmlBody,
    String? emmaLastSeenAt,
    String? emmaLastUsedAt,
    int? currentTabId,
    String? currentTabName,
    String? currentTabSlug,
    String? currentTabColor,
    List<EmailTag>? tags,
    String? unsubscribeStatus,
    String? unsubscribedAt,
  }) {
    return EmailMessage(
      id: id,
      messageId: messageId,
      subject: subject,
      body: body ?? this.body,
      htmlBody: htmlBody ?? this.htmlBody,
      sender: sender,
      recipients: recipients,
      cc: cc,
      bcc: bcc,
      receivedAt: receivedAt,
      sentAt: sentAt,
      timelineAtIso: timelineAtIso,
      isRead: isRead ?? this.isRead,
      isOutgoing: isOutgoing,
      inReplyTo: inReplyTo,
      email: email,
      createdAt: createdAt,
      updatedAt: updatedAt,
      leadId: leadId,
      pipelineStageId: pipelineStageId,
      senderDisplayName: senderDisplayName,
      avatarUrl: avatarUrl,
      currentTabId: currentTabId ?? this.currentTabId,
      currentTabName: currentTabName ?? this.currentTabName,
      currentTabSlug: currentTabSlug ?? this.currentTabSlug,
      currentTabColor: currentTabColor ?? this.currentTabColor,
      tags: tags ?? this.tags,
      isEmma: isEmma,
      isEmmaDirectSend: isEmmaDirectSend,
      emmaLastSeenAt: emmaLastSeenAt ?? this.emmaLastSeenAt,
      emmaLastUsedAt: emmaLastUsedAt ?? this.emmaLastUsedAt,
      spamStatus: spamStatus,
      spamScore: spamScore,
      spamReason: spamReason,
      spamUserOverride: spamUserOverride,
      effectiveIsSpam: effectiveIsSpam,
      shouldSkipEmmaProcessing: shouldSkipEmmaProcessing,
      listUnsubscribeHeader: listUnsubscribeHeader,
      unsubscribeUrl: unsubscribeUrl,
      unsubscribeMailto: unsubscribeMailto,
      unsubscribeStatus: unsubscribeStatus ?? this.unsubscribeStatus,
      unsubscribedAt: unsubscribedAt ?? this.unsubscribedAt,
    );
  }
}

class PaginatedEmailResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<EmailMessage> results;

  const PaginatedEmailResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedEmailResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final results = rawResults is List
        ? rawResults
            .whereType<Map>()
            .map((e) => EmailMessage.fromJson(
                  e.map((k, v) => MapEntry(k.toString(), v)),
                ))
            .toList()
        : <EmailMessage>[];

    return PaginatedEmailResponse(
      count: int.tryParse('${json['count']}') ?? results.length,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: results,
    );
  }
}