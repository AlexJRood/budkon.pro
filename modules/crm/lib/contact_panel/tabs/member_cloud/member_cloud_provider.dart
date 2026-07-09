import 'dart:async';
import 'dart:convert';

import 'package:cloud/models/explorer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

enum MemberCloudScope {
  all,
  sharedTo,
  sharedBy,
  owned,
}

extension MemberCloudScopeX on MemberCloudScope {
  String get apiValue {
    switch (this) {
      case MemberCloudScope.all:
        return 'all';
      case MemberCloudScope.sharedTo:
        return 'shared_to';
      case MemberCloudScope.sharedBy:
        return 'shared_by';
      case MemberCloudScope.owned:
        return 'owned';
    }
  }

  String get translationKey {
    switch (this) {
      case MemberCloudScope.all:
        return 'member_cloud_all';
      case MemberCloudScope.sharedTo:
        return 'member_cloud_shared_to';
      case MemberCloudScope.sharedBy:
        return 'member_cloud_shared_by';
      case MemberCloudScope.owned:
        return 'member_cloud_owned';
    }
  }
}

class MemberCloudBreadcrumb {
  final String id;
  final String name;

  const MemberCloudBreadcrumb({
    required this.id,
    required this.name,
  });

  factory MemberCloudBreadcrumb.fromJson(Map<String, dynamic> json) {
    return MemberCloudBreadcrumb(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class MemberCloudState {
  final AsyncValue<CloudExplorerResponse> explorer;
  final MemberCloudScope scope;
  final String? parent;
  final String search;
  final String? fileType;
  final List<MemberCloudBreadcrumb> breadcrumbs;
  final int count;
  final int foldersCount;
  final int filesCount;
  final int documentsCount;
  final bool truncated;

  const MemberCloudState({
    required this.explorer,
    this.scope = MemberCloudScope.all,
    this.parent,
    this.search = '',
    this.fileType,
    this.breadcrumbs = const [],
    this.count = 0,
    this.foldersCount = 0,
    this.filesCount = 0,
    this.documentsCount = 0,
    this.truncated = false,
  });

  factory MemberCloudState.initial() {
    return const MemberCloudState(
      explorer: AsyncValue.loading(),
    );
  }

  MemberCloudState copyWith({
    AsyncValue<CloudExplorerResponse>? explorer,
    MemberCloudScope? scope,
    String? parent,
    bool clearParent = false,
    String? search,
    String? fileType,
    bool clearFileType = false,
    List<MemberCloudBreadcrumb>? breadcrumbs,
    int? count,
    int? foldersCount,
    int? filesCount,
    int? documentsCount,
    bool? truncated,
  }) {
    return MemberCloudState(
      explorer: explorer ?? this.explorer,
      scope: scope ?? this.scope,
      parent: clearParent ? null : (parent ?? this.parent),
      search: search ?? this.search,
      fileType: clearFileType ? null : (fileType ?? this.fileType),
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      count: count ?? this.count,
      foldersCount: foldersCount ?? this.foldersCount,
      filesCount: filesCount ?? this.filesCount,
      documentsCount: documentsCount ?? this.documentsCount,
      truncated: truncated ?? this.truncated,
    );
  }
}

final memberCloudProvider = StateNotifierProvider.autoDispose.family<
    MemberCloudNotifier, MemberCloudState, int>((ref, memberId) {
  return MemberCloudNotifier(ref, memberId);
});

class MemberCloudNotifier extends StateNotifier<MemberCloudState> {
  MemberCloudNotifier(this.ref, this.memberId)
      : super(MemberCloudState.initial()) {
    Future.microtask(fetch);
  }

  static const String _baseUrl =
      'https://www.superbee.cloud/storage/explorer/member';

  final Ref ref;
  final int memberId;
  Timer? _searchDebounce;
  int _requestVersion = 0;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _decodeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List<int>) {
      return json.decode(utf8.decode(raw)) as Map<String, dynamic>;
    }
    if (raw is String) {
      return json.decode(raw) as Map<String, dynamic>;
    }
    throw Exception('Unsupported response format: ${raw.runtimeType}');
  }



Future<void> fetch({
  bool preserveData = true,
}) async {
  final requestVersion = ++_requestVersion;
  final previousExplorer = state.explorer;

  state = state.copyWith(
    explorer: preserveData && previousExplorer.hasValue
        ? const AsyncValue<CloudExplorerResponse>.loading()
            .copyWithPrevious(previousExplorer)
        : const AsyncValue<CloudExplorerResponse>.loading(),
  );

  try {
    final response = await ApiServices.get(
      '$_baseUrl/$memberId/',
      hasToken: true,
      ref: ref,
      queryParameters: {
        'scope': state.scope.apiValue,
        if (state.parent != null && state.parent!.isNotEmpty)
          'parent': state.parent,
        if (state.search.trim().isNotEmpty)
          'search': state.search.trim(),
        if (state.fileType != null && state.fileType!.isNotEmpty)
          'file_type': state.fileType,
        'limit': 500,
      },
    );

    if (requestVersion != _requestVersion) return;

    if (response == null || response.statusCode != 200) {
      throw Exception(
        'Member Cloud request failed '
        '(${response?.statusCode ?? 'no response'}).',
      );
    }

    final map = _decodeMap(response.data);
    final explorer = CloudExplorerResponse.fromJson(map);

    final rawBreadcrumbs = map['breadcrumbs'];

    final breadcrumbs = rawBreadcrumbs is List
        ? rawBreadcrumbs
            .whereType<Map>()
            .map(
              (item) => MemberCloudBreadcrumb.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <MemberCloudBreadcrumb>[];

    state = state.copyWith(
      explorer: AsyncValue.data(explorer),
      breadcrumbs: breadcrumbs,
      count: _asInt(map['count']),
      foldersCount: _asInt(map['folders_count']),
      filesCount: _asInt(map['files_count']),
      documentsCount: _asInt(map['documents_count']),
      truncated: map['truncated'] == true,
    );
  } catch (error, stackTrace) {
    if (requestVersion != _requestVersion) return;

    state = state.copyWith(
      explorer: AsyncValue.error(error, stackTrace),
    );
  }
}
  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }

  Future<void> selectScope(MemberCloudScope scope) async {
    if (scope == state.scope) return;

    state = state.copyWith(
      scope: scope,
      clearParent: true,
      breadcrumbs: const [],
    );
    await fetch();
  }

  Future<void> openFolder(String? folderId) async {
    state = state.copyWith(
      parent: folderId,
      clearParent: folderId == null || folderId.isEmpty,
    );
    await fetch();
  }

  Future<void> goRoot() => openFolder(null);

  Future<void> goToBreadcrumb(MemberCloudBreadcrumb breadcrumb) {
    return openFolder(breadcrumb.id);
  }

  void setSearch(String value) {
    state = state.copyWith(
      search: value,
      clearParent: true,
      breadcrumbs: const [],
    );

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      fetch(preserveData: false);
    });
  }

  Future<void> setFileType(String? value) async {
    state = state.copyWith(
      fileType: value,
      clearFileType: value == null || value.isEmpty,
      clearParent: true,
      breadcrumbs: const [],
    );
    await fetch();
  }

  Future<void> refresh() => fetch();
}
