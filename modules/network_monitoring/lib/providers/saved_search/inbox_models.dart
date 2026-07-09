import 'dart:convert';




class SavedSearchScopeItemModel {
  final int id;
  final String label;

  const SavedSearchScopeItemModel({
    required this.id,
    required this.label,
  });

  factory SavedSearchScopeItemModel.fromJson(Map<String, dynamic> json) {
    return SavedSearchScopeItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      label: (json['label'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
      };
}

class SavedSearchWithCountersModel {
  final int id;
  final String? title;
  final String? description;
  final String? tags;
  final String? searchQuery;
  final Map<String, dynamic> filters;

  final int? lastCount;
  final String? lastChecked;
  final String? createdAt;
  final String? updatedAt;
  final String? avatar;
  final String? lastNotificationAt;

  final bool enableNotifications;
  final bool enableEmailNotification;

  final String? lastViewedAt;
  final String? lastSeenAdCreatedAt;

  final int newUniqueCount;
  final int totalUniqueCount;
  final String? lastMatchAt;

  final List<SavedSearchScopeItemModel> clients;
  final List<SavedSearchScopeItemModel> transactions;
  final int? defaultTransactionId;
  final bool canAutoAttachTransaction;

  const SavedSearchWithCountersModel({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.searchQuery,
    required this.filters,
    required this.lastCount,
    required this.lastChecked,
    required this.createdAt,
    required this.updatedAt,
    required this.avatar,
    required this.lastNotificationAt,
    required this.enableNotifications,
    required this.enableEmailNotification,
    required this.lastViewedAt,
    required this.lastSeenAdCreatedAt,
    required this.newUniqueCount,
    required this.totalUniqueCount,
    required this.lastMatchAt,
    required this.clients,
    required this.transactions,
    required this.defaultTransactionId,
    required this.canAutoAttachTransaction,
  });

  factory SavedSearchWithCountersModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedFilters = <String, dynamic>{};
    final rawFilters = json['filters'];

    if (rawFilters is Map<String, dynamic>) {
      parsedFilters = rawFilters;
    } else if (rawFilters is Map) {
      parsedFilters = rawFilters.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    } else if (rawFilters is String && rawFilters.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawFilters);
        if (decoded is Map<String, dynamic>) {
          parsedFilters = decoded;
        } else if (decoded is Map) {
          parsedFilters = decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {}
    }

    List<SavedSearchScopeItemModel> parseScopeList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (e) => SavedSearchScopeItemModel.fromJson(
              e.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
    }

    return SavedSearchWithCountersModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      tags: json['tags']?.toString(),
      searchQuery: json['search_query']?.toString(),
      filters: parsedFilters,
      lastCount: (json['last_count'] as num?)?.toInt(),
      lastChecked: json['last_checked']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      avatar: json['avatar']?.toString(),
      lastNotificationAt: json['last_notification_at']?.toString(),
      enableNotifications: json['enable_notifications'] == true,
      enableEmailNotification: json['enable_email_notification'] == true,
      lastViewedAt: json['last_viewed_at']?.toString(),
      lastSeenAdCreatedAt: json['last_seen_ad_created_at']?.toString(),
      newUniqueCount: (json['new_unique_count'] as num?)?.toInt() ?? 0,
      totalUniqueCount: (json['total_unique_count'] as num?)?.toInt() ?? 0,
      lastMatchAt: json['last_match_at']?.toString(),
      clients: parseScopeList(json['clients']),
      transactions: parseScopeList(json['transactions']),
      defaultTransactionId: (json['default_transaction_id'] as num?)?.toInt(),
      canAutoAttachTransaction: json['can_auto_attach_transaction'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'tags': tags,
        'search_query': searchQuery,
        'filters': filters,
        'last_count': lastCount,
        'last_checked': lastChecked,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'avatar': avatar,
        'last_notification_at': lastNotificationAt,
        'enable_notifications': enableNotifications,
        'enable_email_notification': enableEmailNotification,
        'last_viewed_at': lastViewedAt,
        'last_seen_ad_created_at': lastSeenAdCreatedAt,
        'new_unique_count': newUniqueCount,
        'total_unique_count': totalUniqueCount,
        'last_match_at': lastMatchAt,
        'clients': clients.map((e) => e.toJson()).toList(),
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'default_transaction_id': defaultTransactionId,
        'can_auto_attach_transaction': canAutoAttachTransaction,
      };
}

class SavedSearchInboxMatchedSearchModel {
  final int id;
  final String title;
  final List<SavedSearchScopeItemModel> clients;
  final List<SavedSearchScopeItemModel> transactions;
  final bool isNew;
  final int newMatchesCount;
  final int totalMatchesCount;

  const SavedSearchInboxMatchedSearchModel({
    required this.id,
    required this.title,
    required this.clients,
    required this.transactions,
    required this.isNew,
    required this.newMatchesCount,
    required this.totalMatchesCount,
  });

  factory SavedSearchInboxMatchedSearchModel.fromJson(
    Map<String, dynamic> json,
  ) {
    List<SavedSearchScopeItemModel> parseScopeList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (e) => SavedSearchScopeItemModel.fromJson(
              e.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
    }

    return SavedSearchInboxMatchedSearchModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      clients: parseScopeList(json['clients']),
      transactions: parseScopeList(json['transactions']),
      isNew: json['is_new'] == true,
      newMatchesCount: (json['new_matches_count'] as num?)?.toInt() ?? 0,
      totalMatchesCount: (json['total_matches_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SavedSearchInboxItemModel {
  final int representativeAdId;
  final String dedupeKey;
  final Map<String, dynamic>? ad;
  final String? newestAdCreatedAt;
  final int matchedSavedSearchCount;
  final int newMatchesCount;
  final int totalMatchesCount;
  final List<SavedSearchInboxMatchedSearchModel> matchedSavedSearches;
  final List<int> matchedSavedSearchIds;
  final int? defaultTransactionId;
  final int? defaultClientId;
  final int matchedTransactionsCount;
  final int matchedClientsCount;

  const SavedSearchInboxItemModel({
    required this.representativeAdId,
    required this.dedupeKey,
    required this.ad,
    required this.newestAdCreatedAt,
    required this.matchedSavedSearchCount,
    required this.newMatchesCount,
    required this.totalMatchesCount,
    required this.matchedSavedSearches,
    required this.matchedSavedSearchIds,
    required this.defaultTransactionId,
    required this.defaultClientId,
    required this.matchedTransactionsCount,
    required this.matchedClientsCount,
  });

  factory SavedSearchInboxItemModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedAd;
    final rawAd = json['ad'];
    if (rawAd is Map<String, dynamic>) {
      parsedAd = rawAd;
    } else if (rawAd is Map) {
      parsedAd = rawAd.map((key, value) => MapEntry(key.toString(), value));
    }

    final rawMatched = json['matched_saved_searches'];
    final matched = rawMatched is List
        ? rawMatched
            .whereType<Map>()
            .map(
              (e) => SavedSearchInboxMatchedSearchModel.fromJson(
                e.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList()
        : <SavedSearchInboxMatchedSearchModel>[];

    final rawIds = json['matched_saved_search_ids'];
    final matchedIds = rawIds is List
        ? rawIds.map((e) => (e as num).toInt()).toList()
        : <int>[];

    return SavedSearchInboxItemModel(
      representativeAdId: (json['representative_ad_id'] as num?)?.toInt() ?? 0,
      dedupeKey: (json['dedupe_key'] ?? '').toString(),
      ad: parsedAd,
      newestAdCreatedAt: json['newest_ad_created_at']?.toString(),
      matchedSavedSearchCount:
          (json['matched_saved_search_count'] as num?)?.toInt() ?? 0,
      newMatchesCount: (json['new_matches_count'] as num?)?.toInt() ?? 0,
      totalMatchesCount: (json['total_matches_count'] as num?)?.toInt() ?? 0,
      matchedSavedSearches: matched,
      matchedSavedSearchIds: matchedIds,
      defaultTransactionId: (json['default_transaction_id'] as num?)?.toInt(),
      defaultClientId: (json['default_client_id'] as num?)?.toInt(),
      matchedTransactionsCount:
          (json['matched_transactions_count'] as num?)?.toInt() ?? 0,
      matchedClientsCount: (json['matched_clients_count'] as num?)?.toInt() ?? 0,
    );
  }

  String get title => (ad?['title'] ?? 'Offer').toString();

  String? get city => ad?['city']?.toString();

  String? get district {
    final d = ad?['district'];
    if (d == null) return null;
    final s = d.toString().trim();
    return s.isEmpty ? null : s;
  }

  String? get currency => ad?['currency']?.toString();

  num? get price {
    final raw = ad?['price'];
    if (raw is num) return raw;
    return num.tryParse(raw?.toString() ?? '');
  }

  String? get offerType => ad?['offer_type']?.toString();

  String? get estateType => ad?['estate_type']?.toString();

  dynamic get images => ad?['images'];
}

class SavedSearchInboxPageModel {
  final int count;
  final String? next;
  final String? previous;
  final List<SavedSearchInboxItemModel> results;
  final Map<String, dynamic> meta;

  const SavedSearchInboxPageModel({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
    required this.meta,
  });

  factory SavedSearchInboxPageModel.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final results = rawResults is List
        ? rawResults
            .whereType<Map>()
            .map(
              (e) => SavedSearchInboxItemModel.fromJson(
                e.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList()
        : <SavedSearchInboxItemModel>[];

    final rawMeta = json['meta'];
    final meta = rawMeta is Map<String, dynamic>
        ? rawMeta
        : rawMeta is Map
            ? rawMeta.map((key, value) => MapEntry(key.toString(), value))
            : <String, dynamic>{};

    return SavedSearchInboxPageModel(
      count: (json['count'] as num?)?.toInt() ?? 0,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: results,
      meta: meta,
    );
  }

  factory SavedSearchInboxPageModel.empty() {
    return const SavedSearchInboxPageModel(
      count: 0,
      next: null,
      previous: null,
      results: [],
      meta: <String, dynamic>{},
    );
  }
}


class SavedSearchesWithCountersPageModel {
  final int count;
  final String? next;
  final String? previous;
  final List<SavedSearchWithCountersModel> results;
  final Map<String, dynamic> meta;

  const SavedSearchesWithCountersPageModel({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
    required this.meta,
  });

  factory SavedSearchesWithCountersPageModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawResults = json['results'];
    final results = rawResults is List
        ? rawResults
            .whereType<Map>()
            .map(
              (e) => SavedSearchWithCountersModel.fromJson(
                e.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList()
        : <SavedSearchWithCountersModel>[];

    final rawMeta = json['meta'];
    final meta = rawMeta is Map<String, dynamic>
        ? rawMeta
        : rawMeta is Map
            ? rawMeta.map((key, value) => MapEntry(key.toString(), value))
            : <String, dynamic>{};

    return SavedSearchesWithCountersPageModel(
      count: (json['count'] as num?)?.toInt() ?? results.length,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: results,
      meta: meta,
    );
  }

  factory SavedSearchesWithCountersPageModel.empty() {
    return const SavedSearchesWithCountersPageModel(
      count: 0,
      next: null,
      previous: null,
      results: [],
      meta: <String, dynamic>{},
    );
  }
}