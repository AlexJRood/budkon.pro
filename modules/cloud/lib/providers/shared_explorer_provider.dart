import 'dart:convert';
import 'package:cloud/models/explorer.dart';
import 'package:cloud/models/shared_file_fetch_model.dart';
import 'package:cloud/models/shared_folder_fetch_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

enum SharedExplorerTab {
  sharedToMe,
  iShared,
}

class SharedExplorerBucket {
  final bool isLoading;
  final bool initialized;
  final String? error;
  final SharedExplorerResponse? explorer;
  final List<SharedExplorerResponse> history;
  final List<String> path;
  final SharedFolder? currentFolder;

  const SharedExplorerBucket({
    required this.isLoading,
    required this.initialized,
    required this.error,
    required this.explorer,
    this.history = const [],
    this.path = const [],
    this.currentFolder,
  });

  factory SharedExplorerBucket.initial() {
    return const SharedExplorerBucket(
      isLoading: false,
      initialized: false,
      error: null,
      explorer: null,
    );
  }

  SharedExplorerBucket copyWith({
    bool? isLoading,
    bool? initialized,
    String? error,
    SharedExplorerResponse? explorer,
    List<SharedExplorerResponse>? history,
    List<String>? path,
    SharedFolder? currentFolder,
    bool clearError = false,
  }) {
    return SharedExplorerBucket(
      isLoading: isLoading ?? this.isLoading,
      initialized: initialized ?? this.initialized,
      error: clearError ? null : (error ?? this.error),
      explorer: explorer ?? this.explorer,
      history: history ?? this.history,
      path: path ?? this.path,
      currentFolder: currentFolder ?? this.currentFolder,
    );
  }

  int get totalCount =>
      (explorer?.files.length ?? 0).toInt() +
          (explorer?.subfolders.length ?? 0).toInt();
}

class SharedExplorerState {
  final SharedExplorerTab selectedTab;
  final SharedExplorerBucket sharedToMe;
  final SharedExplorerBucket iShared;

  const SharedExplorerState({
    required this.selectedTab,
    required this.sharedToMe,
    required this.iShared,
  });

  factory SharedExplorerState.initial() {
    return SharedExplorerState(
      selectedTab: SharedExplorerTab.sharedToMe,
      sharedToMe: SharedExplorerBucket.initial(),
      iShared: SharedExplorerBucket.initial(),
    );
  }

  SharedExplorerState copyWith({
    SharedExplorerTab? selectedTab,
    SharedExplorerBucket? sharedToMe,
    SharedExplorerBucket? iShared,
  }) {
    return SharedExplorerState(
      selectedTab: selectedTab ?? this.selectedTab,
      sharedToMe: sharedToMe ?? this.sharedToMe,
      iShared: iShared ?? this.iShared,
    );
  }

  SharedExplorerBucket bucketFor(SharedExplorerTab tab) {
    switch (tab) {
      case SharedExplorerTab.sharedToMe:
        return sharedToMe;
      case SharedExplorerTab.iShared:
        return iShared;
    }
  }
}

class SharedExplorerNotifier extends StateNotifier<SharedExplorerState> {
  SharedExplorerNotifier(this.ref) : super(SharedExplorerState.initial());

  final Ref ref;
  Map<String, dynamic> _decodeResponseMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);

    if (raw is List<int>) {
      final decoded = utf8.decode(raw);
      return json.decode(decoded) as Map<String, dynamic>;
    }

    if (raw is String) {
      return json.decode(raw) as Map<String, dynamic>;
    }

    throw Exception('Unsupported response format: ${raw.runtimeType}');
  }

  Future<Map<String, dynamic>> _getAndDecodeMap({
    required String url,
    required Ref ref,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await ApiServices.get(
      url,
      queryParameters: queryParameters,
      hasToken: true,
      ref: ref,
    );

    if (response == null || response.statusCode != 200) {
      throw Exception('Failed request: $url');
    }

    return _decodeResponseMap(response.data);
  }
  Future<void> preload({bool forceRefresh = false}) async {
    await fetchTab(
      SharedExplorerTab.sharedToMe,
      forceRefresh: forceRefresh,
    );

    await fetchTab(
      SharedExplorerTab.iShared,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> selectTab(SharedExplorerTab tab) async {
    state = state.copyWith(selectedTab: tab);

    final bucket = state.bucketFor(tab);
    if (!bucket.initialized && !bucket.isLoading) {
      await fetchTab(tab);
    }
  }

  Future<void> openSharedFolder(SharedFolder folder) async {
    final tab = state.selectedTab;
    final bucket = state.bucketFor(tab);

    _setBucket(tab, bucket.copyWith(isLoading: true, clearError: true));

    try {
      SharedExplorerResponse? explorer = folder.contents;

      if (explorer == null) {
        final data = await _getAndDecodeMap(
          url: tab == SharedExplorerTab.iShared
              ? 'https://www.superbee.cloud/storage/explorer/'
              : 'https://www.superbee.cloud/storage/explorer/share/',
          ref: ref,
          queryParameters: tab == SharedExplorerTab.iShared
              ? {'parent': folder.id}
              : {
            'shared_to_me': true,
            'parent': folder.id,
          },
        );

        explorer = SharedExplorerResponse.fromJson(data);
      }

      _setBucket(
        tab,
        bucket.copyWith(
          isLoading: false,
          explorer: explorer,
          initialized: true,
          currentFolder: folder.share != null ? folder : bucket.currentFolder,
          history: [
            if (bucket.explorer != null) bucket.explorer!,
            ...bucket.history,
          ],
          path: [...bucket.path, folder.name],
          clearError: true,
        ),
      );
    } catch (e) {
      _setBucket(
        tab,
        bucket.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  void goBackSharedFolder() {
    final tab = state.selectedTab;
    final bucket = state.bucketFor(tab);

    if (bucket.history.isEmpty) return;

    final previous = bucket.history.first;
    final remainingHistory = bucket.history.skip(1).toList();

    final newPath = [...bucket.path];
    if (newPath.isNotEmpty) {
      newPath.removeLast();
    }

    _setBucket(
      tab,
      bucket.copyWith(
        explorer: previous,
        history: remainingHistory,
        path: newPath,
        currentFolder: null,
      ),
    );
  }
  Future<void> refreshCurrent() async {
    await fetchTab(state.selectedTab, forceRefresh: true);
  }

  Future<void> refreshAll() async {
    await fetchTab(SharedExplorerTab.sharedToMe, forceRefresh: true);
    await fetchTab(SharedExplorerTab.iShared, forceRefresh: true);
  }

  Future<void> fetchTab(
      SharedExplorerTab tab, {
        bool forceRefresh = false,
      }) async {
    final bucket = state.bucketFor(tab);

    if (bucket.isLoading) return;
    if (bucket.initialized && !forceRefresh) return;

    _setBucket(
      tab,
      bucket.copyWith(
        isLoading: true,
        initialized: true,
        clearError: true,
      ),
    );

    try {
      final query = <String, dynamic>{
        if (tab == SharedExplorerTab.sharedToMe) 'shared_to_me': true,
        if (tab == SharedExplorerTab.iShared) 'i_shared': true,
      };

      final data = await _getAndDecodeMap(
        url: 'https://www.superbee.cloud/storage/explorer/share/',
        ref: ref,
        queryParameters: query,
      );

      final explorer = SharedExplorerResponse.fromJson(data);

      _setBucket(
        tab,
        state.bucketFor(tab).copyWith(
          isLoading: false,
          initialized: true,
          explorer: explorer,
          clearError: true,
        ),
      );
    } catch (e) {
      _setBucket(
        tab,
        state.bucketFor(tab).copyWith(
          isLoading: false,
          initialized: true,
          error: e.toString(),
        ),
      );
    }
  }

  void _setBucket(SharedExplorerTab tab, SharedExplorerBucket bucket) {
    switch (tab) {
      case SharedExplorerTab.sharedToMe:
        state = state.copyWith(sharedToMe: bucket);
        break;
      case SharedExplorerTab.iShared:
        state = state.copyWith(iShared: bucket);
        break;
    }
  }
}

final sharedExplorerProvider =
StateNotifierProvider<SharedExplorerNotifier, SharedExplorerState>((ref) {
  return SharedExplorerNotifier(ref);
});