
// mail/models/mail_scheduled_models.dart

class ScheduledEmail {
  final int id;
  final int emailAccount;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String subject;
  final String body;
  final String htmlBody;
  final String sendAt;
  final bool isSent;
  final String? sentAt;
  final String? lastError;
  final int? createdBy;

  ScheduledEmail({
    required this.id,
    required this.emailAccount,
    required this.to,
    required this.cc,
    required this.bcc,
    required this.subject,
    required this.body,
    required this.htmlBody,
    required this.sendAt,
    required this.isSent,
    required this.sentAt,
    required this.lastError,
    required this.createdBy,
  });

  factory ScheduledEmail.fromJson(Map<String, dynamic> json) {
    List<String> _listStr(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    return ScheduledEmail(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      emailAccount: (json['email_account'] is int)
          ? json['email_account'] as int
          : int.tryParse('${json['email_account']}') ?? 0,
      to: _listStr(json['to']),
      cc: _listStr(json['cc']),
      bcc: _listStr(json['bcc']),
      subject: (json['subject'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      htmlBody: (json['html_body'] ?? '').toString(),
      sendAt: (json['send_at'] ?? '').toString(),
      isSent: json['is_sent'] == true,
      sentAt: json['sent_at']?.toString(),
      lastError: json['last_error']?.toString(),
      createdBy: (json['created_by'] is int)
          ? json['created_by'] as int
          : int.tryParse('${json['created_by']}'),
    );
  }
}

class PaginatedScheduledEmailResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<ScheduledEmail> results;

  PaginatedScheduledEmailResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedScheduledEmailResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = (json['results'] as List?) ?? const [];
    return PaginatedScheduledEmailResponse(
      count: (json['count'] is int) ? json['count'] as int : int.tryParse('${json['count']}') ?? 0,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: rawResults
          .whereType<Map>()
          .map((e) => ScheduledEmail.fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
          .toList(),
    );
  }
}
