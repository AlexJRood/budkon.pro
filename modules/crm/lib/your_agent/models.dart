import 'dart:convert';

class AgentPortalAccessModel {
  final int id;
  final String uuid;
  final int transactionId;
  final String? clientName;
  final int? userId;
  final String? invitedEmail;
  final String? invitedPhone;
  final bool isEnabled;
  final bool canEditListing;
  final bool canViewDocuments;
  final bool canViewPresentations;
  final bool isReadOnly;
  final String? visibleUntil;
  final String? minVisibleUntil;
  final String? inviteUrl;
  final bool isBound;
  final int pendingSuggestionsCount;

  const AgentPortalAccessModel({
    required this.id,
    required this.uuid,
    required this.transactionId,
    this.clientName,
    this.userId,
    this.invitedEmail,
    this.invitedPhone,
    required this.isEnabled,
    required this.canEditListing,
    required this.canViewDocuments,
    required this.canViewPresentations,
    required this.isReadOnly,
    this.visibleUntil,
    this.minVisibleUntil,
    this.inviteUrl,
    required this.isBound,
    required this.pendingSuggestionsCount,
  });

  factory AgentPortalAccessModel.fromJson(Map<String, dynamic> json) {
    return AgentPortalAccessModel(
      id: _asInt(json['id']) ?? 0,
      uuid: _asString(json['uuid']) ?? '',
      transactionId: _asInt(json['transaction_id']) ?? 0,
      clientName: _asString(json['client_name']),
      userId: _asInt(json['user']),
      invitedEmail: _asString(json['invited_email']),
      invitedPhone: _asString(json['invited_phone']),
      isEnabled: _asBool(json['is_enabled']),
      canEditListing: _asBool(json['can_edit_listing']),
      canViewDocuments: _asBool(json['can_view_documents']),
      canViewPresentations: _asBool(json['can_view_presentations']),
      isReadOnly: _asBool(json['is_read_only']),
      visibleUntil: _asString(json['visible_until']),
      minVisibleUntil: _asString(json['min_visible_until']),
      inviteUrl: _asString(json['invite_url']),
      isBound: _asBool(json['is_bound']),
      pendingSuggestionsCount: _asInt(json['pending_suggestions_count']) ?? 0,
    );
  }
}

class AgentPortalManageResponse {
  final bool exists;
  final AgentPortalAccessModel? portal;

  final int transactionId;
  final int? clientContactId;
  final String? clientName;

  final String? defaultInvitedEmail;
  final String? defaultInvitedPhone;
  final bool defaultIsEnabled;
  final bool defaultCanEditListing;
  final bool defaultCanViewDocuments;
  final bool defaultCanViewPresentations;
  final bool defaultIsReadOnly;

  const AgentPortalManageResponse({
    required this.exists,
    required this.portal,
    required this.transactionId,
    this.clientContactId,
    this.clientName,
    this.defaultInvitedEmail,
    this.defaultInvitedPhone,
    required this.defaultIsEnabled,
    required this.defaultCanEditListing,
    required this.defaultCanViewDocuments,
    required this.defaultCanViewPresentations,
    required this.defaultIsReadOnly,
  });

  bool get hasPortal => exists && portal != null;

  String? get invitedEmail => portal?.invitedEmail ?? defaultInvitedEmail;
  String? get invitedPhone => portal?.invitedPhone ?? defaultInvitedPhone;
  bool get isEnabled => portal?.isEnabled ?? defaultIsEnabled;
  bool get canEditListing => portal?.canEditListing ?? defaultCanEditListing;
  bool get canViewDocuments =>
      portal?.canViewDocuments ?? defaultCanViewDocuments;
  bool get canViewPresentations =>
      portal?.canViewPresentations ?? defaultCanViewPresentations;
  bool get isReadOnly => portal?.isReadOnly ?? defaultIsReadOnly;
  String? get visibleUntil => portal?.visibleUntil;
  String? get minVisibleUntil => portal?.minVisibleUntil;
  String? get inviteUrl => portal?.inviteUrl;
  String? get portalUuid => portal?.uuid;
  bool get isBound => portal?.isBound ?? false;
  int get pendingSuggestionsCount => portal?.pendingSuggestionsCount ?? 0;

  factory AgentPortalManageResponse.fromJson(Map<String, dynamic> json) {
    final exists = _asBool(json['exists']);

    if (exists) {
      final portalMap =
          (json['portal'] as Map?)?.cast<String, dynamic>() ?? const {};
      final portal = AgentPortalAccessModel.fromJson(portalMap);

      return AgentPortalManageResponse(
        exists: true,
        portal: portal,
        transactionId: portal.transactionId,
        clientContactId: null,
        clientName: portal.clientName,
        defaultInvitedEmail: null,
        defaultInvitedPhone: null,
        defaultIsEnabled: portal.isEnabled,
        defaultCanEditListing: portal.canEditListing,
        defaultCanViewDocuments: portal.canViewDocuments,
        defaultCanViewPresentations: portal.canViewPresentations,
        defaultIsReadOnly: portal.isReadOnly,
      );
    }

    final defaults =
        (json['defaults'] as Map?)?.cast<String, dynamic>() ?? const {};

    return AgentPortalManageResponse(
      exists: false,
      portal: null,
      transactionId: _asInt(json['transaction_id']) ?? 0,
      clientContactId: _asInt(json['client_contact_id']),
      clientName: _asString(json['client_name']),
      defaultInvitedEmail: _asString(defaults['invited_email']),
      defaultInvitedPhone: _asString(defaults['invited_phone']),
      defaultIsEnabled: _asBool(defaults['is_enabled'], fallback: true),
      defaultCanEditListing:
          _asBool(defaults['can_edit_listing'], fallback: true),
      defaultCanViewDocuments:
          _asBool(defaults['can_view_documents'], fallback: true),
      defaultCanViewPresentations:
          _asBool(defaults['can_view_presentations'], fallback: true),
      defaultIsReadOnly: _asBool(defaults['is_read_only']),
    );
  }
}

class AgentPortalSuggestionDiffItem {
  final String field;
  final String label;
  final dynamic oldValue;
  final dynamic newValue;

  const AgentPortalSuggestionDiffItem({
    required this.field,
    required this.label,
    required this.oldValue,
    required this.newValue,
  });

  factory AgentPortalSuggestionDiffItem.fromJson(Map<String, dynamic> json) {
    return AgentPortalSuggestionDiffItem(
      field: _asString(json['field']) ?? '',
      label: _asString(json['label']) ??
          _prettyFieldLabel(_asString(json['field']) ?? ''),
      oldValue: json['old'],
      newValue: json['new'],
    );
  }

  factory AgentPortalSuggestionDiffItem.fromRawDiffEntry(
    String field,
    dynamic rawValue,
  ) {
    dynamic oldValue;
    dynamic newValue;

    if (rawValue is Map) {
      oldValue = rawValue['old'];
      newValue = rawValue['new'];
    } else {
      oldValue = null;
      newValue = rawValue;
    }

    return AgentPortalSuggestionDiffItem(
      field: field,
      label: _prettyFieldLabel(field),
      oldValue: _normalizeDiffValue(oldValue),
      newValue: _normalizeDiffValue(newValue),
    );
  }
}

class AgentPortalSuggestionModel {
  final int id;
  final String status;
  final String? reviewNote;
  final String? clientName;
  final String? transactionName;
  final String? createdByName;
  final String? createdAt;
  final List<AgentPortalSuggestionDiffItem> diffItems;

  const AgentPortalSuggestionModel({
    required this.id,
    required this.status,
    this.reviewNote,
    this.clientName,
    this.transactionName,
    this.createdByName,
    this.createdAt,
    required this.diffItems,
  });

  factory AgentPortalSuggestionModel.fromJson(Map<String, dynamic> json) {
    final rawDiffItems = (json['diff_items'] as List?) ?? const [];
    final rawDiff = json['diff'];

    List<AgentPortalSuggestionDiffItem> parsedDiffItems = [];

    if (rawDiffItems.isNotEmpty) {
      parsedDiffItems = rawDiffItems
          .map((e) {
            if (e is Map<String, dynamic>) {
              return AgentPortalSuggestionDiffItem.fromJson(e);
            }
            if (e is Map) {
              return AgentPortalSuggestionDiffItem.fromJson(
                Map<String, dynamic>.from(e),
              );
            }
            return null;
          })
          .whereType<AgentPortalSuggestionDiffItem>()
          .toList();
    } else if (rawDiff is Map) {
      parsedDiffItems = rawDiff.entries
          .map(
            (entry) => AgentPortalSuggestionDiffItem.fromRawDiffEntry(
              entry.key.toString(),
              entry.value,
            ),
          )
          .toList();
    }

    return AgentPortalSuggestionModel(
      id: _asInt(json['id']) ?? 0,
      status: _asString(json['status']) ?? 'pending',
      reviewNote: _asString(json['review_note']),
      clientName: _asString(json['client_name']),
      transactionName: _asString(json['transaction_name']),
      createdByName: _asString(json['created_by_name']),
      createdAt: _asString(json['created_at']),
      diffItems: parsedDiffItems,
    );
  }
}

class ClientPortalInviteStatusResponse {
  final String status;
  final String? reason;
  final Map<String, dynamic> portal;
  final Map<String, dynamic> transaction;
  final Map<String, dynamic>? agent;

  const ClientPortalInviteStatusResponse({
    required this.status,
    this.reason,
    required this.portal,
    required this.transaction,
    this.agent,
  });

  factory ClientPortalInviteStatusResponse.fromJson(Map<String, dynamic> json) {
    return ClientPortalInviteStatusResponse(
      status: _asString(json['status']) ?? 'unknown',
      reason: _asString(json['reason']),
      portal: (json['portal'] as Map?)?.cast<String, dynamic>() ?? const {},
      transaction:
          (json['transaction'] as Map?)?.cast<String, dynamic>() ?? const {},
      agent: json['agent'] is Map
          ? (json['agent'] as Map).cast<String, dynamic>()
          : null,
    );
  }

  bool get isValid => status == 'valid';
  bool get isAlreadyBound => status == 'already_bound';
  bool get isBound => status == 'bound';
  bool get isDisabled => status == 'disabled';
  bool get isExpired => status == 'expired';
  bool get isInviteExpired => status == 'invite_expired';
  bool get isNotFound => status == 'not_found';
  bool get isBoundToOtherUser => status == 'bound_to_other_user';

  String? get portalUuid => _asString(portal['uuid']);

  int get transactionId =>
      _asInt(transaction['id']) ?? _asInt(portal['transaction_id']) ?? 0;

  String get transactionTitle {
    return _asString(transaction['name']) ??
        _asString(transaction['transaction_name']) ??
        'Sprawa #$transactionId';
  }

  String? get transactionStatus => _asString(transaction['status']);

  bool get isSeller => _asBool(transaction['is_seller']);
  bool get isBuyer => _asBool(transaction['is_buyer']);

  String? get invitedEmail => _asString(portal['invited_email']);
  String? get invitedPhone => _asString(portal['invited_phone']);

  bool get canEditListing => _asBool(portal['can_edit_listing']);
  bool get canViewDocuments => _asBool(portal['can_view_documents']);
  bool get canViewPresentations => _asBool(portal['can_view_presentations']);
  bool get isReadOnly => _asBool(portal['is_read_only']);

  String? get visibleUntil => _asString(portal['visible_until']);

  String? get amountLabel {
    final amount = transaction['amount'];
    final currency = _asString(transaction['currency']);

    if (amount == null && (currency == null || currency.isEmpty)) {
      return null;
    }

    if (amount == null) {
      return currency;
    }

    return '$amount ${currency ?? ''}'.trim();
  }

  String? get agentName {
    if (agent == null) return null;
    return _asString(agent!['full_name']) ??
        _asString(agent!['name']) ??
        _asString(agent!['username']);
  }

  String? get agentEmail {
    if (agent == null) return null;
    return _asString(agent!['email']);
  }

  String? get agentPhone {
    if (agent == null) return null;
    return _asString(agent!['phone']);
  }
}

class ClientPortalCaseDetail {
  final Map<String, dynamic> portal;
  final Map<String, dynamic> transaction;
  final Map<String, dynamic>? listing;
  final List<dynamic> documents;

  ClientPortalCaseDetail({
    required this.portal,
    required this.transaction,
    required this.listing,
    required this.documents,
  });

  bool get isSeller {
    final val = transaction['is_seller'];
    if (val is bool) return val;
    if (val is int) return val == 1;
    return false;
  }

  int get transactionId => transaction['id'] as int;

  bool get canViewDocuments {
    final v = portal['can_view_documents'];
    if (v is bool) return v;
    if (v is int) return v == 1;
    return false;
  }

  bool get canViewPresentations {
    final v = portal['can_view_presentations'];
    if (v is bool) return v;
    if (v is int) return v == 1;
    return false;
  }

  bool get canEditListing {
    final v = portal['can_edit_listing'];
    if (v is bool) return v;
    if (v is int) return v == 1;
    return false;
  }

  factory ClientPortalCaseDetail.fromJson(Map<String, dynamic> json) {
    return ClientPortalCaseDetail(
      portal: (json['portal'] as Map?)?.cast<String, dynamic>() ?? const {},
      transaction:
          (json['transaction'] as Map?)?.cast<String, dynamic>() ?? const {},
      listing: json['listing'] == null
          ? null
          : (json['listing'] as Map).cast<String, dynamic>(),
      documents: (json['documents'] as List?) ?? const [],
    );
  }
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  if (value is String) {
    final v = value.toLowerCase().trim();
    return v == '1' || v == 'true' || v == 'yes';
  }
  return fallback;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

dynamic _normalizeDiffValue(dynamic value) {
  if (value == null) return null;
  if (value is String || value is num || value is bool) return value;
  try {
    return jsonEncode(value);
  } catch (_) {
    return value.toString();
  }
}

String _prettyFieldLabel(String field) {
  const labels = {
    'title': 'Tytuł',
    'description': 'Opis',
    'price': 'Cena',
    'currency': 'Waluta',
    'estate_type': 'Typ nieruchomości',
    'building_type': 'Typ budynku',
    'building_material': 'Materiał budynku',
    'market_type': 'Rynek',
    'offer_type': 'Typ oferty',
    'rooms': 'Liczba pokoi',
    'bathrooms': 'Liczba łazienek',
    'square_footage': 'Powierzchnia',
    'lot_size': 'Powierzchnia działki',
    'year_built': 'Rok budowy',
    'floor': 'Piętro',
    'street': 'Ulica',
    'city': 'Miasto',
    'state': 'Województwo / region',
    'country': 'Kraj',
    'zipcode': 'Kod pocztowy',
    'sewerage': 'Kanalizacja',
    'equipment': 'Wyposażenie',
    'is_renewable': 'Odnawialne',
    'isPremium2': 'Premium',
  };

  if (labels.containsKey(field)) return labels[field]!;
  if (field.isEmpty) return 'Pole';
  return field.replaceAll('_', ' ');
}





class AgentPortalEventModel {
  final int id;
  final String eventType;
  final String? eventTypeLabel;
  final String? createdAt;
  final int? userId;
  final String? userName;
  final Map<String, dynamic> metadata;

  const AgentPortalEventModel({
    required this.id,
    required this.eventType,
    this.eventTypeLabel,
    this.createdAt,
    this.userId,
    this.userName,
    required this.metadata,
  });

  factory AgentPortalEventModel.fromJson(Map<String, dynamic> json) {
    return AgentPortalEventModel(
      id: _asInt(json['id']) ?? 0,
      eventType: _asString(json['event_type']) ?? '',
      eventTypeLabel: _asString(json['event_type_label']),
      createdAt: _asString(json['created_at']),
      userId: _asInt(json['user']),
      userName: _asString(json['user_name']),
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

class AgentPortalStatusModel {
  final int id;
  final String uuid;
  final int transactionId;
  final String? clientName;
  final bool isEnabled;
  final String? visibleUntil;

  final String? inviteClickedAt;
  final int inviteClickCount;

  final String? boundAt;
  final String? firstSeenAt;
  final String? lastSeenAt;
  final int visitCount;
  final String? lastActivityAt;

  final bool hasSeenListing;
  final bool hasSeenDocuments;
  final bool hasSeenPresentations;

  final bool isBound;
  final bool isInviteClicked;
  final bool isSeenByClient;
  final bool canClientAccessNow;

  final List<AgentPortalEventModel> recentEvents;

  const AgentPortalStatusModel({
    required this.id,
    required this.uuid,
    required this.transactionId,
    this.clientName,
    required this.isEnabled,
    this.visibleUntil,
    this.inviteClickedAt,
    required this.inviteClickCount,
    this.boundAt,
    this.firstSeenAt,
    this.lastSeenAt,
    required this.visitCount,
    this.lastActivityAt,
    required this.hasSeenListing,
    required this.hasSeenDocuments,
    required this.hasSeenPresentations,
    required this.isBound,
    required this.isInviteClicked,
    required this.isSeenByClient,
    required this.canClientAccessNow,
    required this.recentEvents,
  });

  factory AgentPortalStatusModel.fromJson(Map<String, dynamic> json) {
    final rawEvents = (json['recent_events'] as List?) ?? const [];

    return AgentPortalStatusModel(
      id: _asInt(json['id']) ?? 0,
      uuid: _asString(json['uuid']) ?? '',
      transactionId: _asInt(json['transaction_id']) ?? 0,
      clientName: _asString(json['client_name']),
      isEnabled: _asBool(json['is_enabled']),
      visibleUntil: _asString(json['visible_until']),
      inviteClickedAt: _asString(json['invite_clicked_at']),
      inviteClickCount: _asInt(json['invite_click_count']) ?? 0,
      boundAt: _asString(json['bound_at']),
      firstSeenAt: _asString(json['first_seen_at']),
      lastSeenAt: _asString(json['last_seen_at']),
      visitCount: _asInt(json['visit_count']) ?? 0,
      lastActivityAt: _asString(json['last_activity_at']),
      hasSeenListing: _asBool(json['has_seen_listing']),
      hasSeenDocuments: _asBool(json['has_seen_documents']),
      hasSeenPresentations: _asBool(json['has_seen_presentations']),
      isBound: _asBool(json['is_bound']),
      isInviteClicked: _asBool(json['is_invite_clicked']),
      isSeenByClient: _asBool(json['is_seen_by_client']),
      canClientAccessNow: _asBool(json['can_client_access_now']),
      recentEvents: rawEvents
          .whereType<Map>()
          .map((e) => AgentPortalEventModel.fromJson(
                e.cast<String, dynamic>(),
              ))
          .toList(),
    );
  }
}