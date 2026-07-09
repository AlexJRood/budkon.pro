// cloud/providers/providers.dart
import 'dart:convert';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:cloud/models/explorer.dart';
import 'package:cloud/models/folder.dart';
import 'package:cloud/models/query_params.dart';
import 'package:cloud/models/quota.dart';
import 'package:cloud/providers/shared_explorer_provider.dart';
import 'package:cloud/providers/shared_files_provider.dart';
import 'package:cloud/utils/bread_crumbs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:core/platform/api_services.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud/models/cloud_shortcut.dart';

// ------------------------------------------------------------
// Shared helpers
// ------------------------------------------------------------

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

// ------------------------------------------------------------
// State providers
// ------------------------------------------------------------

final selectedFolderPathProvider = StateProvider<List<CloudFolder>>(
  (ref) => [],
);

final cloudSidebarRefreshTriggerProvider = StateProvider<int>((ref) => 0);
final cloudExplorerRefreshTriggerProvider = StateProvider<int>((ref) => 0);
final clientExplorerRefreshTriggerProvider = StateProvider<int>((ref) => 0);

final isAnyDragInProgressProvider = StateProvider<bool>((ref) => false);

final cloudExplorerParamsProvider = StateProvider<FolderQueryParams>(
  (ref) => FolderQueryParams(),
);

final clientExplorerParamsProvider = StateProvider<FolderQueryParams>(
  (ref) => FolderQueryParams(),
);

// ------------------------------------------------------------
// Refresh helpers
// ------------------------------------------------------------

void refreshCloudExplorer(Ref ref) {
  ref.read(cloudExplorerRefreshTriggerProvider.notifier).state++;
  ref.invalidate(cloudExplorerProvider);
}

void refreshClientExplorer(Ref ref) {
  ref.read(clientExplorerRefreshTriggerProvider.notifier).state++;
  ref.invalidate(clientCloudExplorerProvider);
}

void refreshCloudSidebar(Ref ref) {
  ref.read(cloudSidebarRefreshTriggerProvider.notifier).state++;
  ref.invalidate(cloudSidebarProvider);
}

void refreshAllCloudData(dynamic ref) {
  refreshCloudExplorer(ref);
  refreshClientExplorer(ref);
  refreshCloudSidebar(ref);

  ref.invalidate(storageQuotaProvider);

  ref.read(sharedFilesProvider.notifier).refresh();
  ref.read(sharedExplorerProvider.notifier).refreshAll();
}

void refreshAllCloudDataFromContainer(ProviderContainer container) {
  container.read(cloudExplorerRefreshTriggerProvider.notifier).state++;
  container.read(clientExplorerRefreshTriggerProvider.notifier).state++;
  container.read(cloudSidebarRefreshTriggerProvider.notifier).state++;

  container.invalidate(cloudExplorerProvider);
  container.invalidate(clientCloudExplorerProvider);
  container.invalidate(cloudSidebarProvider);
  container.invalidate(storageQuotaProvider);

  container.read(sharedFilesProvider.notifier).refresh();
  container.read(sharedExplorerProvider.notifier).refreshAll();
}
// ------------------------------------------------------------
// Explorer providers
// ------------------------------------------------------------

final cloudExplorerProvider = FutureProvider<CloudExplorerResponse>((ref) async {
  ref.watch(cloudExplorerRefreshTriggerProvider);
  final params = ref.watch(cloudExplorerParamsProvider);
  final query = params.toQuery();

  final data = await _getAndDecodeMap(
    url: 'https://www.superbee.cloud/storage/explorer/',
    ref: ref,
    queryParameters: query,
  );

  return CloudExplorerResponse.fromJson(data);
});

/// Scoped provider driven directly by `clientExplorerParamsProvider`.
/// Use this in client / transaction views if you want automatic refresh
/// after DnD, move, upload, etc.
final clientCloudExplorerProvider =
    FutureProvider<CloudExplorerResponse>((ref) async {
      ref.watch(clientExplorerRefreshTriggerProvider);
      ref.watch(cloudExplorerRefreshTriggerProvider);

      final params = ref.watch(clientExplorerParamsProvider);
      final query = params.toQuery();

      final rawSection = (params.additionalSection ?? '').trim();
      final section = rawSection.isEmpty ? 'assigned' : rawSection;

      final data = await _getAndDecodeMap(
        url: 'https://www.superbee.cloud/storage/explorer/$section/',
        ref: ref,
        queryParameters: query,
      );

      return CloudExplorerResponse.fromJson(data);
    });

/// Family version for places where you explicitly pass params.
/// It also listens to refresh triggers, so all scoped lists can refresh.
final clientFileExplorerProvider =
    FutureProvider.family<CloudExplorerResponse, FolderQueryParams>((
      ref,
      params,
    ) async {
      ref.watch(clientExplorerRefreshTriggerProvider);
      ref.watch(cloudExplorerRefreshTriggerProvider);

      final query = params.toQuery();
      final rawSection = (params.additionalSection ?? '').trim();
      final section = rawSection.isEmpty ? 'assigned' : rawSection;

      final data = await _getAndDecodeMap(
        url: 'https://www.superbee.cloud/storage/explorer/$section/',
        ref: ref,
        queryParameters: query,
      );

      return CloudExplorerResponse.fromJson(data);
    });

final cloudSidebarProvider = FutureProvider<CloudSidebarResponse>((ref) async {
  ref.watch(cloudSidebarRefreshTriggerProvider);

  final data = await _getAndDecodeMap(
    url: 'https://www.superbee.cloud/storage/sidebar/',
    ref: ref,
  );

  return CloudSidebarResponse.fromJson(data);
});

final storageQuotaProvider = FutureProvider<StorageQuota>((ref) async {
  final data = await _getAndDecodeMap(
    url: 'https://www.superbee.cloud/storage/storage-quota/',
    ref: ref,
  );

  return StorageQuota.fromJson(data);
});

/// Isolated family provider used by the cloud-shortcut picker modal.
/// Keyed by folder-ID (null = root). Auto-disposed when the picker closes.
final cloudPickerExplorerProvider =
    FutureProvider.autoDispose.family<CloudExplorerResponse, String?>(
  (ref, folderId) async {
    final params = folderId != null
        ? <String, dynamic>{'parent': folderId}
        : <String, dynamic>{'show_all_files': 'true'};

    final data = await _getAndDecodeMap(
      url: 'https://www.superbee.cloud/storage/explorer/',
      ref: ref,
      queryParameters: params,
    );

    return CloudExplorerResponse.fromJson(data);
  },
);

final rootFolder = CloudFolder(
  id: 'root',
  name: 'Cloud Storage',
  filesCount: 0,
);

// ------------------------------------------------------------
// Breadcrumbs
// ------------------------------------------------------------

final breadcrumbsProvider = Provider<List<CloudFolder>>((ref) {
  final explorerParams = ref.watch(cloudExplorerParamsProvider);
  final sidebarAsync = ref.watch(cloudSidebarProvider);

  return sidebarAsync.maybeWhen(
    data: (sidebar) => buildPathToRoot(sidebar.folders, explorerParams.parent),
    orElse: () => [],
  );
});

final clientBreadcrumbsProvider = Provider<List<CloudFolder>>((ref) {
  final explorerParams = ref.watch(clientExplorerParamsProvider);
  final sidebarAsync = ref.watch(cloudSidebarProvider);

  return sidebarAsync.maybeWhen(
    data: (sidebar) => buildPathToRoot(sidebar.folders, explorerParams.parent),
    orElse: () => [],
  );
});

// ------------------------------------------------------------
// Video / Chewie
// ------------------------------------------------------------

class ChewieVideoState {
  final VideoPlayerController video;
  final ChewieController chewie;

  const ChewieVideoState({required this.video, required this.chewie});
}

class ChewieVideoNotifier extends StateNotifier<AsyncValue<ChewieVideoState>> {
  ChewieVideoNotifier(this.url) : super(const AsyncValue.loading()) {
    _init();
  }

  final String url;
  bool _started = false;

  Future<void> _init() async {
    if (_started) return;
    _started = true;

    try {
      final video = VideoPlayerController.networkUrl(Uri.parse(url));

      await video.initialize();

      final chewie = ChewieController(
        videoPlayerController: video,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white12,
        ),
      );



      state = AsyncValue.data(ChewieVideoState(video: video, chewie: chewie));
    } catch (e, st) {
      debugPrint('--- VIDEO INIT ERROR ---');
      debugPrint('Video URL failed: $url');
      debugPrint('Error: $e');
      debugPrintStack(stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    final current = state;
    if (current is AsyncData<ChewieVideoState>) {
      current.value.chewie.dispose();
      current.value.video.dispose();
    }
    super.dispose();
  }
}

final chewieVideoProvider = StateNotifierProvider.autoDispose
    .family<ChewieVideoNotifier, AsyncValue<ChewieVideoState>, String>((
      ref,
      url,
    ) {
      return ChewieVideoNotifier(url);
    });

class VideoViewerState {
  final VideoPlayerController controller;
  final bool isInitialized;
  final bool isPlaying;

  const VideoViewerState({
    required this.controller,
    required this.isInitialized,
    required this.isPlaying,
  });

  VideoViewerState copyWith({bool? isInitialized, bool? isPlaying}) {
    return VideoViewerState(
      controller: controller,
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

class VideoViewerNotifier extends StateNotifier<AsyncValue<VideoViewerState>> {
  VideoViewerNotifier(this.url) : super(const AsyncValue.loading()) {
    _init();
  }

  final String url;
  bool _initStarted = false;

  Future<void> _init() async {
    if (_initStarted) return;
    _initStarted = true;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();

      state = AsyncValue.data(
        VideoViewerState(
          controller: controller,
          isInitialized: controller.value.isInitialized,
          isPlaying: controller.value.isPlaying,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> togglePlay() async {
    final current = state;
    if (current is! AsyncData<VideoViewerState>) return;

    final controller = current.value.controller;

    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }

      state = AsyncValue.data(
        current.value.copyWith(isPlaying: controller.value.isPlaying),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    final current = state;
    if (current is AsyncData<VideoViewerState>) {
      current.value.controller.dispose();
    }
    super.dispose();
  }
}

final videoViewerProvider = StateNotifierProvider.autoDispose
    .family<VideoViewerNotifier, AsyncValue<VideoViewerState>, String>((
      ref,
      url,
    ) {
      return VideoViewerNotifier(url);
    });

// ------------------------------------------------------------
// File viewer loading
// ------------------------------------------------------------

class FileLoadResult {
  final String? textContent;
  final String? localPdfPath;

  const FileLoadResult({this.textContent, this.localPdfPath});
}

bool isPdf(String? mimeType, String url) {
  final mt = (mimeType ?? '').toLowerCase().trim();
  final u = url.toLowerCase();
  return mt.contains('pdf') || u.endsWith('.pdf');
}

class FileViewerLoadNotifier extends StateNotifier<AsyncValue<FileLoadResult>> {
  FileViewerLoadNotifier(this.args) : super(const AsyncValue.loading());

  final ({String id, String url, String? mimeType}) args;
  bool _started = false;

  Future<void> load() async {
    if (_started) return;
    _started = true;

    state = const AsyncValue.loading();

    try {
      if (args.mimeType?.startsWith('text/') == true) {
        final response = await http
            .get(Uri.parse(args.url))
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final txt = utf8.decode(response.bodyBytes);
          state = AsyncValue.data(FileLoadResult(textContent: txt));
          return;
        }

        state = const AsyncValue.data(
          FileLoadResult(textContent: 'Nie udało się pobrać pliku'),
        );
        return;
      }

      final isPdfFile = isPdf(args.mimeType, args.url);

      if (!kIsWeb && isPdfFile) {
        final response = await http
            .get(Uri.parse(args.url))
            .timeout(const Duration(seconds: 25));

        if (response.statusCode != 200) {
          throw Exception('PDF download failed: HTTP ${response.statusCode}');
        }

        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/cloud_pdf_${args.id}.pdf';
        final file = File(filePath);

        if (await file.exists()) {
          final len = await file.length();
          if (len > 0) {
            state = AsyncValue.data(FileLoadResult(localPdfPath: file.path));
            return;
          }
        }

        await file.writeAsBytes(response.bodyBytes, flush: true);
        state = AsyncValue.data(FileLoadResult(localPdfPath: file.path));
        return;
      }

      state = const AsyncValue.data(FileLoadResult());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final fileViewerLoadProvider = StateNotifierProvider.autoDispose.family<
  FileViewerLoadNotifier,
  AsyncValue<FileLoadResult>,
  ({String id, String url, String? mimeType})
>((ref, args) => FileViewerLoadNotifier(args));

final isDownloadingProvider = StateProvider<bool>((ref) => false);


enum CloudSidebarTab {
  sharedFiles,
  images,
  videos,
  documents,
  others,
  emma,
  allFiles,
  trash,
}

final cloudSidebarSelectedTabProvider =
StateProvider<CloudSidebarTab?>((ref) => null);



// ------------------------------------------------------------
// Cloud shortcuts
// ------------------------------------------------------------

final cloudShortcutsRefreshTriggerProvider = StateProvider<int>((ref) => 0);
final cloudRecentlyOpenedRefreshTriggerProvider = StateProvider<int>((ref) => 0);

void refreshCloudRecentlyOpened(Object ref) {
  if (ref is WidgetRef) {
    ref.read(cloudRecentlyOpenedRefreshTriggerProvider.notifier).state++;
    ref.invalidate(cloudRecentlyOpenedProvider);
    return;
  }
  if (ref is Ref<Object?>) {
    ref.read(cloudRecentlyOpenedRefreshTriggerProvider.notifier).state++;
    ref.invalidate(cloudRecentlyOpenedProvider);
    return;
  }
  throw ArgumentError(
    'refreshCloudRecentlyOpened expected WidgetRef or Ref, got ${ref.runtimeType}',
  );
}

void refreshCloudShortcuts(Object ref) {
  if (ref is WidgetRef) {
    ref.read(cloudShortcutsRefreshTriggerProvider.notifier).state++;
    ref.invalidate(cloudShortcutsProvider);
    return;
  }

  if (ref is Ref<Object?>) {
    ref.read(cloudShortcutsRefreshTriggerProvider.notifier).state++;
    ref.invalidate(cloudShortcutsProvider);
    return;
  }

  throw ArgumentError(
    'refreshCloudShortcuts expected WidgetRef or Ref, got ${ref.runtimeType}',
  );
}

final cloudShortcutsApiProvider = Provider<CloudShortcutsApi>((ref) {
  return CloudShortcutsApi(ref);
});

final cloudRecentlyOpenedProvider =
    FutureProvider.autoDispose<List<CloudShortcut>>((ref) async {
  ref.watch(cloudRecentlyOpenedRefreshTriggerProvider);
  return ref.read(cloudShortcutsApiProvider).listRecentlyOpened(limit: 12);
});

final cloudShortcutsProvider =
    FutureProvider.autoDispose<List<CloudShortcut>>((ref) async {
  ref.watch(cloudShortcutsRefreshTriggerProvider);
  return ref.read(cloudShortcutsApiProvider).list();
});

final cloudShortcutsByDashboardProvider =
    FutureProvider.autoDispose.family<List<CloudShortcut>, String>(
  (ref, dashboardKey) async {
    ref.watch(cloudShortcutsRefreshTriggerProvider);

    return ref.read(cloudShortcutsApiProvider).list(
          dashboardKey: dashboardKey,
        );
  },
);

final cloudShortcutProvider =
    FutureProvider.autoDispose.family<CloudShortcut, String>(
  (ref, shortcutId) async {
    ref.watch(cloudShortcutsRefreshTriggerProvider);
    return ref.read(cloudShortcutsApiProvider).resolve(shortcutId);
  },
);

class CloudShortcutsApi {
  final Ref ref;

  const CloudShortcutsApi(this.ref);

  static const String _baseUrl = 'https://www.superbee.cloud/storage/shortcuts/';

  Map<String, dynamic> _decodeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);

    if (raw is List<int>) {
      final decoded = utf8.decode(raw);
      final jsonValue = json.decode(decoded);
      if (jsonValue is Map) return Map<String, dynamic>.from(jsonValue);
    }

    if (raw is String) {
      final jsonValue = json.decode(raw);
      if (jsonValue is Map) return Map<String, dynamic>.from(jsonValue);
    }

    throw Exception('Unsupported response format: ${raw.runtimeType}');
  }

  List<dynamic> _extractResults(dynamic raw) {
    final map = _decodeMap(raw);

    if (map['results'] is List) {
      return map['results'] as List;
    }

    if (map['data'] is List) {
      return map['data'] as List;
    }

    return const [];
  }

  Future<List<CloudShortcut>> list({
    String? dashboardKey,
  }) async {
    final response = await ApiServices.get(
      _baseUrl,
      hasToken: true,
      ref: ref,
      queryParameters: {
        if (dashboardKey != null && dashboardKey.trim().isNotEmpty)
          'dashboard_key': dashboardKey.trim(),
      },
    );

    if (response == null || response.statusCode != 200) {
      throw Exception('Failed to load cloud shortcuts');
    }

    final rows = _extractResults(response.data);

    return rows
        .whereType<Map>()
        .map((e) => CloudShortcut.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CloudShortcut> pin(PinCloudShortcutRequest request) async {
    final response = await ApiServices.post(
      '${_baseUrl}pin/',
      hasToken: true,
      ref: ref,
      data: request.toJson(),
    );

    final code = response?.statusCode ?? 0;
    if (response == null || code < 200 || code >= 300) {
      throw Exception('Failed to pin cloud shortcut: ${response?.data}');
    }

    final shortcut = CloudShortcut.fromJson(_decodeMap(response.data));
    refreshCloudShortcuts(ref);
    return shortcut;
  }

  Future<CloudShortcut> resolve(String shortcutId) async {
    final response = await ApiServices.get(
      '$_baseUrl$shortcutId/resolve/',
      hasToken: true,
      ref: ref,
    );

    if (response == null || response.statusCode != 200) {
      throw Exception('Failed to resolve cloud shortcut');
    }

    return CloudShortcut.fromJson(_decodeMap(response.data));
  }

  Future<CloudShortcutOpenTarget?> open(String shortcutId) async {
    final response = await ApiServices.post(
      '$_baseUrl$shortcutId/open/',
      hasToken: true,
      ref: ref,
    );

    final code = response?.statusCode ?? 0;
    if (response == null || code < 200 || code >= 300) {
      throw Exception('Failed to open cloud shortcut: ${response?.data}');
    }

    final data = _decodeMap(response.data);
    final targetRaw = data['open_target'];

    if (targetRaw is Map) {
      return CloudShortcutOpenTarget.fromJson(
        Map<String, dynamic>.from(targetRaw),
      );
    }

    final shortcutRaw = data['shortcut'];
    if (shortcutRaw is Map) {
      return CloudShortcut.fromJson(
        Map<String, dynamic>.from(shortcutRaw),
      ).openTarget;
    }

    return null;
  }

  Future<void> unpin(String shortcutId) async {
    final response = await ApiServices.delete(
      '$_baseUrl$shortcutId/',
      hasToken: true,
    );

    final code = response?.statusCode ?? 0;
    if (response == null || code < 200 || code >= 300) {
      throw Exception('Failed to unpin cloud shortcut');
    }

    refreshCloudShortcuts(ref);
  }

  Future<List<CloudShortcut>> listRecentlyOpened({int limit = 12}) async {
    final response = await ApiServices.get(
      '${_baseUrl}recently-opened/',
      hasToken: true,
      ref: ref,
      queryParameters: {'limit': limit},
    );

    if (response == null || response.statusCode != 200) {
      throw Exception('Failed to load recently opened shortcuts');
    }

    final rows = _extractResults(response.data);
    return rows
        .whereType<Map>()
        .map((e) => CloudShortcut.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}











// ------------------------------------------------------------
// Cloud file -> Hously docs preview
// ------------------------------------------------------------

typedef CloudFileDocumentPreviewArgs = ({
  String fileId,
  String sourceUrl,
  String filename,
  String? mimeType,
});

class CloudFileDocumentPreviewResult {
  final String? documentId;
  final String? title;
  final Map<String, dynamic> deltaMap;
  final Map<String, dynamic>? styleMap;
  final Map<String, dynamic> raw;

  const CloudFileDocumentPreviewResult({
    required this.documentId,
    required this.title,
    required this.deltaMap,
    required this.styleMap,
    required this.raw,
  });

  List<dynamic> get ops {
    final rawOps = deltaMap['ops'];
    if (rawOps is List) return rawOps;

    return const [
      {'insert': '\n'},
    ];
  }

  String get cacheKey {
    final deltaHash = jsonEncode(deltaMap).hashCode;
    return '${documentId ?? 'preview'}_$deltaHash';
  }
}

dynamic _cloudDocsPreviewPayload(dynamic response) {
  if (response == null) return null;

  try {
    return response.data;
  } catch (_) {
    return response;
  }
}

dynamic _cloudDocsDecodeAny(dynamic value) {
  if (value == null) return null;

  if (value is List<int>) {
    final decoded = utf8.decode(value);
    return json.decode(decoded);
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    try {
      return json.decode(trimmed);
    } catch (_) {
      return trimmed;
    }
  }

  return value;
}

Map<String, dynamic> _cloudDocsAsMap(dynamic value) {
  final decoded = _cloudDocsDecodeAny(value);

  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);

  throw Exception('Invalid cloud document preview response: $decoded');
}

String? _cloudDocsExtractDocumentId(Map<String, dynamic> data) {
  final direct = data['document_id'] ??
      data['documentId'] ??
      data['doc_id'] ??
      data['docId'] ??
      data['id'];

  if (direct != null && direct.toString().trim().isNotEmpty) {
    return direct.toString().trim();
  }

  final document = data['document'];

  if (document is Map) {
    final documentMap = Map<String, dynamic>.from(document);

    final nested = documentMap['id'] ??
        documentMap['document_id'] ??
        documentMap['documentId'] ??
        documentMap['doc_id'] ??
        documentMap['docId'];

    if (nested != null && nested.toString().trim().isNotEmpty) {
      return nested.toString().trim();
    }
  }

  if (document is String && document.trim().isNotEmpty) {
    return document.trim();
  }

  return null;
}

String? _cloudDocsExtractTitle(Map<String, dynamic> data) {
  final direct = data['title'] ?? data['name'] ?? data['filename'];

  if (direct != null && direct.toString().trim().isNotEmpty) {
    return direct.toString().trim();
  }

  final document = data['document'];

  if (document is Map) {
    final documentMap = Map<String, dynamic>.from(document);
    final nested = documentMap['title'] ?? documentMap['name'];

    if (nested != null && nested.toString().trim().isNotEmpty) {
      return nested.toString().trim();
    }
  }

  return null;
}

dynamic _cloudDocsFirstDeltaCandidate(Map<String, dynamic> data) {
  final direct = data['delta'] ??
      data['current_delta'] ??
      data['currentDelta'] ??
      data['document_delta'] ??
      data['documentDelta'];

  if (direct != null) return direct;

  final document = data['document'];

  if (document is Map) {
    final documentMap = Map<String, dynamic>.from(document);

    return documentMap['current_delta'] ??
        documentMap['currentDelta'] ??
        documentMap['delta'] ??
        documentMap['document_delta'] ??
        documentMap['documentDelta'];
  }

  return null;
}

dynamic _cloudDocsFirstStyleCandidate(Map<String, dynamic> data) {
  final direct = data['style'] ??
      data['current_style'] ??
      data['currentStyle'] ??
      data['style_json'] ??
      data['styleJson'];

  if (direct != null) return direct;

  final document = data['document'];

  if (document is Map) {
    final documentMap = Map<String, dynamic>.from(document);

    return documentMap['current_style'] ??
        documentMap['currentStyle'] ??
        documentMap['style'] ??
        documentMap['style_json'] ??
        documentMap['styleJson'];
  }

  return null;
}

Map<String, dynamic> _cloudDocsNormalizeDeltaMap(dynamic raw) {
  final decoded = _cloudDocsDecodeAny(raw);

  if (decoded is Map<String, dynamic>) {
    final ops = decoded['ops'];
    if (ops is List) return {'ops': ops};
  }

  if (decoded is Map) {
    final map = Map<String, dynamic>.from(decoded);
    final ops = map['ops'];
    if (ops is List) return {'ops': ops};
  }

  if (decoded is List) {
    return {'ops': decoded};
  }

  if (decoded is String) {
    final text = decoded.endsWith('\n') ? decoded : '$decoded\n';

    return {
      'ops': [
        {'insert': text},
      ],
    };
  }

  return {
    'ops': [
      {'insert': '\n'},
    ],
  };
}

Map<String, dynamic>? _cloudDocsNormalizeStyleMap(dynamic raw) {
  final decoded = _cloudDocsDecodeAny(raw);

  if (decoded == null) return null;
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);

  return null;
}

final cloudFileDocumentPreviewProvider = FutureProvider.autoDispose.family<
    CloudFileDocumentPreviewResult,
    CloudFileDocumentPreviewArgs>((ref, args) async {
  const endpoint = 'https://www.superbee.cloud/docs/import/cloud-file/preview/';

  final response = await ApiServices.post(
    endpoint,
    data: {
      'file_id': args.fileId,
      'source_url': args.sourceUrl,
      'filename': args.filename,
      'mime_type': args.mimeType,
    },
    hasToken: true,
    ref: ref,
  );

  final code = response?.statusCode ?? 0;

  if (response == null || code < 200 || code >= 300) {
    throw Exception('Cloud document preview failed: ${response?.data}');
  }

  final data = _cloudDocsAsMap(_cloudDocsPreviewPayload(response));
  final deltaMap = _cloudDocsNormalizeDeltaMap(
    _cloudDocsFirstDeltaCandidate(data),
  );

  final ops = deltaMap['ops'];
  if (ops is! List) {
    throw Exception('Backend did not return delta.ops. Data: $data');
  }

  return CloudFileDocumentPreviewResult(
    documentId: _cloudDocsExtractDocumentId(data),
    title: _cloudDocsExtractTitle(data),
    deltaMap: deltaMap,
    styleMap: _cloudDocsNormalizeStyleMap(
      _cloudDocsFirstStyleCandidate(data),
    ),
    raw: data,
  );
});



