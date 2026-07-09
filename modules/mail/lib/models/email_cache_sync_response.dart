import 'mail_models.dart';

class EmailCacheSyncResponse {
  final String serverTime;
  final String scopeKey;
  final int totalInScope;
  final int windowCount;
  final bool hasOlder;
  final int olderAvailableCount;
  final List<int> windowIds;
  final List<EmailMessage> addedOrChanged;
  final List<int> removedIds;
  final bool replaceAll;
  final String? oldestServerAt;
  final String? newestServerAt;

  const EmailCacheSyncResponse({
    required this.serverTime,
    required this.scopeKey,
    required this.totalInScope,
    required this.windowCount,
    required this.hasOlder,
    required this.olderAvailableCount,
    required this.windowIds,
    required this.addedOrChanged,
    required this.removedIds,
    required this.replaceAll,
    required this.oldestServerAt,
    required this.newestServerAt,
  });

  factory EmailCacheSyncResponse.fromJson(Map<String, dynamic> json) {
    List<int> parseIds(dynamic value) {
      if (value is! List) return const [];
      return value
          .map((e) => int.tryParse(e.toString()))
          .whereType<int>()
          .toList();
    }

    List<EmailMessage> parseEmails(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((e) => EmailMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return EmailCacheSyncResponse(
      serverTime: (json["server_time"] ?? "").toString(),
      scopeKey: (json["scope_key"] ?? "").toString(),
      totalInScope: int.tryParse("${json["total_in_scope"]}") ?? 0,
      windowCount: int.tryParse("${json["window_count"]}") ?? 0,
      hasOlder: json["has_older"] == true,
      olderAvailableCount: int.tryParse("${json["older_available_count"]}") ?? 0,
      windowIds: parseIds(json["window_ids"]),
      addedOrChanged: parseEmails(json["added_or_changed"]),
      removedIds: parseIds(json["removed_ids"]),
      replaceAll: json["replace_all"] == true,
      oldestServerAt: json["oldest_server_at"]?.toString(),
      newestServerAt: json["newest_server_at"]?.toString(),
    );
  }
}

class LoadOlderEmailsResponse {
  final List<EmailMessage> results;
  final int count;
  final bool hasMore;

  const LoadOlderEmailsResponse({
    required this.results,
    required this.count,
    required this.hasMore,
  });

  factory LoadOlderEmailsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json["results"];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => EmailMessage.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <EmailMessage>[];

    return LoadOlderEmailsResponse(
      results: items,
      count: int.tryParse("${json["count"]}") ?? items.length,
      hasMore: json["has_more"] == true,
    );
  }
}