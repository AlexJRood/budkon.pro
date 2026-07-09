import 'explorer.dart';

class FileShare {
  final String id;
  final String file;
  final int? user;
  final int? sharedBy;
  final String? email;
  final int? company;
  final int? team;
  final String? publicToken;
  final String? note;
  final bool canEdit;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const FileShare({
    required this.id,
    required this.file,
    required this.user,
    required this.sharedBy,
    required this.email,
    required this.company,
    required this.team,
    required this.publicToken,
    required this.note,
    required this.canEdit,
    required this.createdAt,
    required this.expiresAt,
  });

  factory FileShare.fromJson(Map<String, dynamic> json) {
    return FileShare(
      id: (json['id'] ?? '').toString(),
      file: (json['file'] ?? '').toString(),
      user:
          json['user'] is int
              ? json['user'] as int
              : int.tryParse('${json['user']}'),
      sharedBy:
          json['shared_by'] is int
              ? json['shared_by'] as int
              : int.tryParse('${json['shared_by']}'),
      email: json['email']?.toString(),
      company:
          json['company'] is int
              ? json['company'] as int
              : int.tryParse('${json['company']}'),
      team:
          json['team'] is int
              ? json['team'] as int
              : int.tryParse('${json['team']}'),
      publicToken: json['public_token']?.toString(),
      note: json['note']?.toString(),
      canEdit: json['can_edit'] == true,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      expiresAt:
          json['expires_at'] != null
              ? DateTime.tryParse(json['expires_at'].toString())
              : null,
    );
  }

  String get recipientType {
    if (user != null) return 'user';
    if (company != null) return 'company';
    if (team != null) return 'team';
    if (email != null && email!.isNotEmpty) return 'email';
    return 'unknown';
  }

  String get recipientLabel {
    if (user != null) return 'User #$user';
    if (company != null) return 'Company #$company';
    if (team != null) return 'Team #$team';
    if (email != null && email!.isNotEmpty) return email!;
    return 'Unknown recipient';
  }
}

class FileShareListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FileShare> results;

  const FileShareListResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory FileShareListResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final resultsList = rawResults is List ? rawResults : const [];

    return FileShareListResponse(
      count:
          json['count'] is int
              ? json['count'] as int
              : int.tryParse('${json['count']}') ?? 0,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results:
          resultsList
              .whereType<Map>()
              .map((e) => FileShare.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
    );
  }
}

class SharedFilesState {
  final bool isLoading;
  final List<FileShare> items;
  final String? error;
  final int count;
  final String? next;
  final String? previous;
  final bool initialized;

  const SharedFilesState({
    required this.isLoading,
    required this.items,
    required this.error,
    required this.count,
    required this.next,
    required this.previous,
    required this.initialized,
  });

  factory SharedFilesState.initial() {
    return const SharedFilesState(
      isLoading: false,
      items: [],
      error: null,
      count: 0,
      next: null,
      previous: null,
      initialized: false,
    );
  }

  SharedFilesState copyWith({
    bool? isLoading,
    List<FileShare>? items,
    String? error,
    int? count,
    String? next,
    String? previous,
    bool? initialized,
    bool clearError = false,
  }) {
    return SharedFilesState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      initialized: initialized ?? this.initialized,
    );
  }
}

enum ShareTargetType { user, company, team, email }

class ShareTargetOption {
  final String id;
  final String label;

  const ShareTargetOption({required this.id, required this.label});
}

class ShareTargetState {
  final bool isLoading;
  final List<ShareTargetOption> items;
  final String? error;
  final bool initialized;

  const ShareTargetState({
    required this.isLoading,
    required this.items,
    required this.error,
    required this.initialized,
  });

  factory ShareTargetState.initial() {
    return const ShareTargetState(
      isLoading: false,
      items: [],
      error: null,
      initialized: false,
    );
  }

  ShareTargetState copyWith({
    bool? isLoading,
    List<ShareTargetOption>? items,
    String? error,
    bool? initialized,
    bool clearError = false,
  }) {
    return ShareTargetState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
      initialized: initialized ?? this.initialized,
    );
  }
}


enum SharedExplorerMode {
  sharedToMe,
  iShared,
}

class SharedExplorerState {
  final bool isLoading;
  final bool initialized;
  final String? error;
  final SharedExplorerMode mode;
  final CloudExplorerResponse? explorer;

  const SharedExplorerState({
    required this.isLoading,
    required this.initialized,
    required this.error,
    required this.mode,
    required this.explorer,
  });

  factory SharedExplorerState.initial() {
    return const SharedExplorerState(
      isLoading: false,
      initialized: false,
      error: null,
      mode: SharedExplorerMode.sharedToMe,
      explorer: null,
    );
  }

  SharedExplorerState copyWith({
    bool? isLoading,
    bool? initialized,
    String? error,
    SharedExplorerMode? mode,
    CloudExplorerResponse? explorer,
    bool clearError = false,
  }) {
    return SharedExplorerState(
      isLoading: isLoading ?? this.isLoading,
      initialized: initialized ?? this.initialized,
      error: clearError ? null : (error ?? this.error),
      mode: mode ?? this.mode,
      explorer: explorer ?? this.explorer,
    );
  }
}