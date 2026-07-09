class MailboxQuery {
  final String storageNamespace;
  final int? emailAccountId;
  final String mailType;
  final String search;
  final int? leadId;
  final String? email;
  final String ordering;
  final int maxLocal;

  final int? currentTabId;
  final List<int> tagIds;

  const MailboxQuery({
    required this.storageNamespace,
    required this.emailAccountId,
    required this.mailType,
    required this.search,
    required this.leadId,
    required this.email,
    required this.ordering,
    required this.maxLocal,
    required this.currentTabId,
    required this.tagIds,
  });

  String get normalizedSearch => search.trim().toLowerCase();

  String get scopeKey {
    final normalizedEmail = (email ?? '').trim().toLowerCase();
    final sortedTags = [...tagIds]..sort();

    return [
      'account:${emailAccountId ?? "all"}',
      'type:$mailType',
      'search:$normalizedSearch',
      'lead:${leadId ?? "null"}',
      'email:${normalizedEmail.isEmpty ? "null" : normalizedEmail}',
      'ordering:$ordering',
      'max:$maxLocal',
      'tab:${currentTabId ?? "null"}',
      'tags:${sortedTags.isEmpty ? "none" : sortedTags.join(",")}',
    ].join('|');
  }

  MailboxQuery copyWith({
    String? storageNamespace,
    int? emailAccountId,
    String? mailType,
    String? search,
    int? leadId,
    String? email,
    String? ordering,
    int? maxLocal,
    int? currentTabId,
    List<int>? tagIds,
  }) {
    return MailboxQuery(
      storageNamespace: storageNamespace ?? this.storageNamespace,
      emailAccountId: emailAccountId ?? this.emailAccountId,
      mailType: mailType ?? this.mailType,
      search: search ?? this.search,
      leadId: leadId ?? this.leadId,
      email: email ?? this.email,
      ordering: ordering ?? this.ordering,
      maxLocal: maxLocal ?? this.maxLocal,
      currentTabId: currentTabId ?? this.currentTabId,
      tagIds: tagIds ?? this.tagIds,
    );
  }

  Map<String, dynamic> toBackendJson() {
    final sortedTags = [...tagIds]..sort();

    return {
      'email_account_id': emailAccountId,
      'mail_type': mailType,
      'search': search,
      'lead_id': leadId,
      'email': email,
      'ordering': ordering,
      'max_local': maxLocal,
      'current_tab_id': currentTabId,
      'tag_ids': sortedTags,
    };
  }
}