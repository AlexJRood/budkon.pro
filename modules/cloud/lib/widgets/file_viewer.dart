import 'dart:async';
import 'dart:convert';

import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:core/common/chrome/back_button.dart';
import 'package:cloud/models/file.dart';
import 'package:dio/dio.dart';
import 'package:cloud/platforms/view_registry_stub.dart'
    if (dart.library.html) 'package:cloud/platforms/view_registry_web.dart';
import 'package:cloud/providers/providers.dart';
import 'package:cloud/widgets/chewie_video_player_widget.dart';
import 'package:cloud/widgets/error_box_widget.dart';
import 'package:cloud/widgets/native_pdf_viewer_widget.dart';
import 'package:docs/provider/document_page_setup_provider.dart';
import 'package:docs/widgets/paged_quill_document_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api/api_buttons.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';

class FileViewerDialog extends ConsumerStatefulWidget {
  final CloudFile file;
  final bool isMobile;

  const FileViewerDialog({
    super.key,
    required this.file,
    this.isMobile = false,
  });

  @override
  ConsumerState<FileViewerDialog> createState() => _FileViewerDialogState();
}

class _DocsPreviewData {
  final String cacheKey;
  final List<dynamic> ops;
  final String? documentId;
  final Map<String, dynamic> raw;

  const _DocsPreviewData({
    required this.cacheKey,
    required this.ops,
    required this.raw,
    this.documentId,
  });
}

class _FileViewerDialogState extends ConsumerState<FileViewerDialog> {
  static const String _docsCloudPreviewEndpoint =
      'https://www.superbee.cloud/docs/import/cloud-file/preview/';

  static const Duration _resolvePreviewTimeout = Duration(seconds: 25);
  static const Duration _docsPreviewTimeout = Duration(seconds: 45);
  static const Duration _openInEditorTimeout = Duration(seconds: 55);

  late final String _pdfViewId;
  late final String _videoViewId;
  late final String _tag;

  final Set<String> _startedLoadKeys = <String>{};
  final Set<String> _docsPreviewLoadingKeys = <String>{};

  final Map<String, _DocsPreviewData> _docsPreviewCache =
      <String, _DocsPreviewData>{};

  final Map<String, Object> _docsPreviewErrors = <String, Object>{};

  final ScrollController _docsPreviewScrollController = ScrollController();

  final FocusNode _docsPreviewFocusNode = FocusNode(
    debugLabel: 'cloud_docs_preview_focus',
  );

  String _previewUrl = '';
  bool _resolvingPreviewUrl = true;
  String? _resolvePreviewError;
  String? _storageError;
  bool _requiresAuthHeader = false;
  bool _isSecured = false;

  QuillController? _docsPreviewController;
  String? _docsPreviewControllerKey;

  bool _openingInEditor = false;

  @override
  void initState() {
    super.initState();

    _tag = UniqueKey().toString();

    _pdfViewId =
        'pdf_viewer_${widget.file.id}_${DateTime.now().millisecondsSinceEpoch}';

    _videoViewId =
        'video_viewer_${widget.file.id}_${DateTime.now().millisecondsSinceEpoch}';

    _previewUrl = widget.file.url;

    _debugLog('initState', {
      'fileId': widget.file.id,
      'name': widget.file.name,
      'mimeType': widget.file.mimeType,
      'url': widget.file.url,
      'isMobile': widget.isMobile,
      'isWeb': kIsWeb,
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resolvePreviewUrl();
    });
  }

  @override
  void dispose() {
    _debugLog('dispose', {
      'fileId': widget.file.id,
      'controllerKey': _docsPreviewControllerKey,
    });

    _docsPreviewController?.dispose();
    _docsPreviewScrollController.dispose();
    _docsPreviewFocusNode.dispose();

    super.dispose();
  }

  void _debugLog(String event, [Object? payload]) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();

    if (payload == null) {
      debugPrint('[FileViewerDialog][$timestamp][$event]');
      return;
    }

    debugPrint(
      '[FileViewerDialog][$timestamp][$event] ${_safeJson(payload)}',
    );
  }

  String _safeJson(Object? payload) {
    try {
      return jsonEncode(_jsonSafe(payload));
    } catch (_) {
      return payload.toString();
    }
  }

  dynamic _jsonSafe(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      return _short(value);
    }

    if (value is num || value is bool) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key.toString(),
          _jsonSafe(item),
        ),
      );
    }

    if (value is Iterable) {
      return value.map(_jsonSafe).toList();
    }

    return _short(value.toString());
  }

  String _short(String value, {int max = 220}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}... [len=${value.length}]';
  }

  Future<void> _backgroundCheckUrl(String url) async {
    try {
      final dio = Dio();
      final headResp = await dio.head<dynamic>(
        url,
        options: Options(
          validateStatus: (_) => true,
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );

      final statusCode = headResp.statusCode ?? 0;
      final contentType =
          (headResp.headers.value(Headers.contentTypeHeader) ?? '').toLowerCase();

      if (statusCode >= 200 && statusCode < 300 && !contentType.contains('xml')) {
        return;
      }

      final getResp = await dio.get<String>(
        url,
        options: Options(
          validateStatus: (_) => true,
          receiveTimeout: const Duration(seconds: 6),
          responseType: ResponseType.plain,
        ),
      );

      final body = (getResp.data ?? '').toString();
      if (body.contains('NoSuchKey') ||
          body.contains('The specified key does not exist') ||
          body.contains('<Error>')) {
        if (!mounted) return;
        setState(() {
          _storageError = body.length > 512 ? body.substring(0, 512) : body;
        });
      }
    } catch (_) {
      // Background check — ignore failures
    }
  }

  Widget _buildStorageErrorBody({required ThemeColors theme}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 36,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'file_unavailable_title'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'file_unavailable_desc'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textColor.withAlpha(155),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: Text('Retry'.tr),
                    onPressed: () {
                      setState(() => _storageError = null);
                      _resolvePreviewUrl();
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.feedback_outlined, size: 17),
                    label: Text('report_problem'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor,
                      foregroundColor: theme.themeColorText,
                    ),
                    onPressed: () => _copyErrorReport(theme),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyErrorReport(ThemeColors theme) {
    final details = [
      '=== Hously File Error Report ===',
      'File: ${widget.file.name}',
      'File ID: ${widget.file.id}',
      'MIME type: ${widget.file.mimeType ?? 'unknown'}',
      'Storage error: ${_storageError ?? _resolvePreviewError ?? 'unknown'}',
      'Time: ${DateTime.now().toIso8601String()}',
    ].join('\n');

    Clipboard.setData(ClipboardData(text: details));
    _showSnackBar(
      message: 'error_report_copied'.tr,
      backgroundColor: Colors.green,
    );
  }

  Future<void> _resolvePreviewUrl() async {
    if (!mounted) return;

    setState(() {
      _resolvingPreviewUrl = true;
      _resolvePreviewError = null;
      _storageError = null;
    });

    final startedAt = DateTime.now();

    try {
      final endpoint =
          'https://www.superbee.cloud/storage/files/${widget.file.id}/resolve-download-url/';

      _debugLog('resolvePreviewUrl.start', {
        'endpoint': endpoint,
        'fileId': widget.file.id,
        'fileName': widget.file.name,
      });

      final data = await ApiServices.getJson(
        endpoint,
        hasToken: true,
        ref: ref,
      ).timeout(
        _resolvePreviewTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Przekroczono czas pobierania URL podglądu.',
          );
        },
      );

      _debugLog('resolvePreviewUrl.response', {
        'elapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
        'keys': data is Map ? data.keys.toList() : null,
        'data': data,
      });

      final resolvedUrl = (data['url'] ??
              data['preview_url'] ??
              data['download_url'] ??
              '')
          .toString()
          .trim();

      if (resolvedUrl.isEmpty) {
        throw Exception('Backend did not return preview URL. Data: $data');
      }

      if (!mounted) return;

      setState(() {
        _previewUrl = resolvedUrl;
        _requiresAuthHeader = data['requires_auth_header'] == true;
        _isSecured = data['is_secured'] == true;
        _resolvingPreviewUrl = false;
      });

      unawaited(_backgroundCheckUrl(resolvedUrl));

      _debugLog('resolvePreviewUrl.done', {
        'previewUrl': _previewUrl,
        'requiresAuthHeader': _requiresAuthHeader,
        'isSecured': _isSecured,
      });
    } catch (e) {
      _debugLog('resolvePreviewUrl.error', {
        'error': e.toString(),
      });

      if (!mounted) return;

      setState(() {
        _previewUrl = widget.file.url;
        _resolvePreviewError = e.toString();
        _resolvingPreviewUrl = false;
      });
    }
  }

  bool _isPdfFile(String? mimeType, String url) {
    return isPdf(mimeType, url);
  }

  bool _isImageFile(String? mimeType, String url) {
    final cleanUrl = url.split('?').first.toLowerCase();
    final mime = (mimeType ?? '').toLowerCase();

    return mime.startsWith('image/') ||
        cleanUrl.endsWith('.png') ||
        cleanUrl.endsWith('.jpg') ||
        cleanUrl.endsWith('.jpeg') ||
        cleanUrl.endsWith('.webp') ||
        cleanUrl.endsWith('.gif') ||
        cleanUrl.endsWith('.bmp') ||
        cleanUrl.endsWith('.svg');
  }

  bool _isVideoFile(String? mimeType, String url) {
    final cleanUrl = url.split('?').first.toLowerCase();
    final mime = (mimeType ?? '').toLowerCase();

    return mime.startsWith('video/') ||
        cleanUrl.endsWith('.mp4') ||
        cleanUrl.endsWith('.webm') ||
        cleanUrl.endsWith('.mov') ||
        cleanUrl.endsWith('.avi') ||
        cleanUrl.endsWith('.mkv');
  }

  bool _hasExt({
    required CloudFile file,
    required String url,
    required String ext,
  }) {
    final cleanUrl = url.split('?').first.toLowerCase();
    final cleanName = file.name.toLowerCase();

    return cleanUrl.endsWith('.$ext') || cleanName.endsWith('.$ext');
  }

  bool _isPlainTextDocument({
    required CloudFile file,
    required String url,
  }) {
    final mime = (file.mimeType ?? '').toLowerCase().trim();
    final cleanUrl = url.split('?').first.toLowerCase();
    final cleanName = file.name.toLowerCase();

    bool hasExt(String ext) {
      return cleanUrl.endsWith('.$ext') || cleanName.endsWith('.$ext');
    }

    // IMPORTANT:
    // Do NOT use mime.contains('xml') here.
    // DOCX/XLSX/PPTX MIME contains "openxmlformats", so it would be
    // incorrectly treated as plain text.
    if (mime.startsWith('text/')) return true;

    const plainMimeTypes = {
      'application/json',
      'application/xml',
      'application/xhtml+xml',
      'application/csv',
      'text/csv',
      'text/plain',
      'text/markdown',
      'text/html',
      'text/xml',
    };

    if (plainMimeTypes.contains(mime)) return true;

    return hasExt('txt') ||
        hasExt('md') ||
        hasExt('markdown') ||
        hasExt('json') ||
        hasExt('xml') ||
        hasExt('csv') ||
        hasExt('html') ||
        hasExt('htm');
  }

  bool _isPreviewableDocument({
    required CloudFile file,
    required String url,
  }) {
    final mime = (file.mimeType ?? '').toLowerCase();

    if (_isPdfFile(file.mimeType, url)) return false;
    if (_isImageFile(file.mimeType, url)) return false;
    if (_isVideoFile(file.mimeType, url)) return false;

    if (_isPlainTextDocument(file: file, url: url)) return true;

    if (mime.contains('wordprocessingml')) return true;
    if (mime.contains('msword')) return true;
    if (mime.contains('opendocument.text')) return true;
    if (mime.contains('rtf')) return true;
    if (mime.contains('html')) return true;

    if (mime.contains('spreadsheetml')) return true;
    if (mime.contains('excel')) return true;

    if (mime.contains('presentationml')) return true;
    if (mime.contains('powerpoint')) return true;
    if (mime.contains('presentation')) return true;

    return _hasExt(file: file, url: url, ext: 'doc') ||
        _hasExt(file: file, url: url, ext: 'docx') ||
        _hasExt(file: file, url: url, ext: 'odt') ||
        _hasExt(file: file, url: url, ext: 'rtf') ||
        _hasExt(file: file, url: url, ext: 'html') ||
        _hasExt(file: file, url: url, ext: 'htm') ||
        _hasExt(file: file, url: url, ext: 'xls') ||
        _hasExt(file: file, url: url, ext: 'xlsx') ||
        _hasExt(file: file, url: url, ext: 'ods') ||
        _hasExt(file: file, url: url, ext: 'ppt') ||
        _hasExt(file: file, url: url, ext: 'pptx') ||
        _hasExt(file: file, url: url, ext: 'odp');
  }

  bool _needsFileLoader({
    required String? mimeType,
    required String url,
  }) {
    final isPdfFile = _isPdfFile(mimeType, url);
    final mime = (mimeType ?? '').toLowerCase();

    return mime.startsWith('text/') || (!kIsWeb && isPdfFile);
  }

  void _ensureLoadStarted({
    required bool needsLoad,
    required ({String id, String url, String? mimeType}) args,
  }) {
    if (!needsLoad) return;

    final key = '${args.id}|${args.url}|${args.mimeType ?? ''}';

    if (_startedLoadKeys.contains(key)) {
      _debugLog('fileLoader.skipAlreadyStarted', {
        'key': key,
      });
      return;
    }

    _startedLoadKeys.add(key);

    _debugLog('fileLoader.schedule', {
      'key': key,
      'args': {
        'id': args.id,
        'url': args.url,
        'mimeType': args.mimeType,
      },
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _debugLog('fileLoader.load', {
        'key': key,
      });

      ref.read(fileViewerLoadProvider(args).notifier).load();
    });
  }

  String _docsPreviewCacheKey(String previewUrl) {
    return [
      'docs-preview',
      widget.file.id,
      previewUrl,
      widget.file.name,
      widget.file.mimeType ?? '',
    ].join('|');
  }

  bool _looksLikeHtml(String value) {
    final normalized = value.trimLeft().toLowerCase();

    return normalized.startsWith('<!doctype html') ||
        normalized.startsWith('<html') ||
        normalized.contains('<body') ||
        normalized.contains('<title>');
  }

  String _extractHtmlTitle(String html) {
    final titleMatch = RegExp(
      r'<title>(.*?)</title>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);

    final title = titleMatch?.group(1)?.trim();

    if (title != null && title.isNotEmpty) {
      return title.replaceAll(RegExp(r'\s+'), ' ');
    }

    return 'HTML response';
  }

  dynamic _extractRawData(dynamic raw) {
    if (raw == null) return null;

    if (raw is Map || raw is List || raw is String) {
      return raw;
    }

    try {
      return raw.data;
    } catch (_) {
      return raw;
    }
  }

  Map<String, dynamic> _decodeResponseMap(dynamic raw) {
    final data = _extractRawData(raw);

    if (data == null) return <String, dynamic>{};

    if (data is Map<String, dynamic>) return data;

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String) {
      final trimmed = data.trim();

      if (trimmed.isEmpty) {
        return <String, dynamic>{};
      }

      if (_looksLikeHtml(trimmed)) {
        return <String, dynamic>{
          '_raw': trimmed,
          '_html_title': _extractHtmlTitle(trimmed),
        };
      }

      try {
        final decoded = jsonDecode(trimmed);

        if (decoded is Map<String, dynamic>) return decoded;

        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }

        return <String, dynamic>{
          '_raw': trimmed,
          '_decoded': decoded,
        };
      } catch (_) {
        return <String, dynamic>{
          '_raw': trimmed,
        };
      }
    }

    return <String, dynamic>{
      '_raw': data.toString(),
    };
  }

  String? _extractDocumentId(dynamic raw) {
    final data = _decodeResponseMap(raw);

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

    final createdDocument = data['created_document'];

    if (createdDocument is Map) {
      final createdMap = Map<String, dynamic>.from(createdDocument);
      final nested = createdMap['id'] ??
          createdMap['document_id'] ??
          createdMap['documentId'] ??
          createdMap['doc_id'] ??
          createdMap['docId'];

      if (nested != null && nested.toString().trim().isNotEmpty) {
        return nested.toString().trim();
      }
    }

    final dataNested = data['data'];

    if (dataNested is Map) {
      return _extractDocumentId(Map<String, dynamic>.from(dataNested));
    }

    return null;
  }

  List<dynamic> _normalizePreviewOps(dynamic rawOps) {
    if (rawOps is List) {
      final ops = rawOps.map((op) {
        if (op is Map<String, dynamic>) return op;
        if (op is Map) return Map<String, dynamic>.from(op);

        return <String, dynamic>{
          'insert': op.toString(),
        };
      }).toList();

      if (ops.isEmpty) {
        return [
          {'insert': '\n'},
        ];
      }

      final last = ops.last;
      final lastInsert = last['insert'];

      if (lastInsert is String && lastInsert.endsWith('\n')) {
        return ops;
      }

      return [
        ...ops,
        {'insert': '\n'},
      ];
    }

    if (rawOps is Map) {
      final ops = rawOps['ops'];
      if (ops is List) return _normalizePreviewOps(ops);
    }

    if (rawOps is String) {
      final text = rawOps.endsWith('\n') ? rawOps : '$rawOps\n';

      return [
        {'insert': text},
      ];
    }

    return [
      {'insert': '\n'},
    ];
  }

  List<dynamic>? _tryExtractOpsCandidate(dynamic candidate) {
    if (candidate == null) return null;

    if (candidate is List) {
      return _normalizePreviewOps(candidate);
    }

    if (candidate is Map) {
      final map = Map<String, dynamic>.from(candidate);

      if (map['ops'] is List) {
        return _normalizePreviewOps(map['ops']);
      }

      if (map['delta'] is Map || map['delta'] is List) {
        return _tryExtractOpsCandidate(map['delta']);
      }

      if (map['current_delta'] is Map || map['current_delta'] is List) {
        return _tryExtractOpsCandidate(map['current_delta']);
      }

      if (map['currentDelta'] is Map || map['currentDelta'] is List) {
        return _tryExtractOpsCandidate(map['currentDelta']);
      }

      if (map['delta_json'] is Map || map['delta_json'] is List) {
        return _tryExtractOpsCandidate(map['delta_json']);
      }

      if (map['deltaJson'] is Map || map['deltaJson'] is List) {
        return _tryExtractOpsCandidate(map['deltaJson']);
      }
    }

    if (candidate is String && candidate.trim().isNotEmpty) {
      if (_looksLikeHtml(candidate)) return null;
      return _normalizePreviewOps(candidate);
    }

    return null;
  }

  List<dynamic> _extractPreviewOpsFromResponse(dynamic raw) {
    final data = _decodeResponseMap(raw);

    final rawHtml = data['_raw'];
    if (rawHtml is String && _looksLikeHtml(rawHtml)) {
      final title = data['_html_title']?.toString() ?? _extractHtmlTitle(rawHtml);

      throw Exception(
        'Backend zwrócił HTML zamiast JSON: $title. '
        'Sprawdź endpoint $_docsCloudPreviewEndpoint.',
      );
    }

    final candidates = <dynamic>[
      data['delta'],
      data['delta_json'],
      data['deltaJson'],
      data['current_delta'],
      data['currentDelta'],
      data['ops'],
      data['preview'],
      data['result'],
      data['content'],
      data['text'],
      data['plain_text'],
      data['plainText'],
      data['html'],
    ];

    final document = data['document'];
    if (document is Map) {
      final documentMap = Map<String, dynamic>.from(document);
      candidates.addAll([
        documentMap['current_delta'],
        documentMap['currentDelta'],
        documentMap['delta'],
        documentMap['delta_json'],
        documentMap['deltaJson'],
        documentMap['ops'],
        documentMap['text'],
        documentMap['content'],
      ]);
    }

    final nestedData = data['data'];
    if (nestedData is Map) {
      final nestedMap = Map<String, dynamic>.from(nestedData);
      candidates.addAll([
        nestedMap['delta'],
        nestedMap['delta_json'],
        nestedMap['deltaJson'],
        nestedMap['current_delta'],
        nestedMap['currentDelta'],
        nestedMap['ops'],
        nestedMap['preview'],
        nestedMap['result'],
        nestedMap['content'],
        nestedMap['text'],
        nestedMap['plain_text'],
        nestedMap['plainText'],
      ]);
    }

    for (final candidate in candidates) {
      final ops = _tryExtractOpsCandidate(candidate);

      if (ops != null && ops.isNotEmpty) {
        return ops;
      }
    }

    throw Exception(
      'Backend nie zwrócił poprawnego delta.ops dla podglądu dokumentu. '
      'Odpowiedź: ${_short(jsonEncode(data), max: 1500)}',
    );
  }

  Future<dynamic> _postDocsCloudPreview({
    required Map<String, dynamic> data,
    required Duration timeout,
  }) async {
    final startedAt = DateTime.now();

    _debugLog('postDocsCloudPreview.start', {
      'endpoint': _docsCloudPreviewEndpoint,
      'timeoutSeconds': timeout.inSeconds,
      'data': data,
    });

    try {
      final response = await ApiServices.post(
        _docsCloudPreviewEndpoint,
        data: data,
        hasToken: true,
        ref: ref,
      ).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Przekroczono czas odpowiedzi endpointu dokumentów '
            '($_docsCloudPreviewEndpoint).',
          );
        },
      );

      
final decoded = _decodeResponseMap(response);

_debugLog('postDocsCloudPreview.done', {
  'elapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
  'responseType': response.runtimeType.toString(),
  'keys': decoded.keys.toList(),
  'detail': decoded['detail'],
  'error': decoded['error'],
  'supported': decoded['supported'],
  'format': decoded['format'],
  'opsLength': decoded['ops'] is List ? (decoded['ops'] as List).length : null,
  'documentId': _extractDocumentId(response),
});

final detail = decoded['detail']?.toString().trim();
final error = decoded['error']?.toString().trim();

final hasBackendError =
    (error != null && error.isNotEmpty) ||
    ((detail != null && detail.isNotEmpty) &&
        decoded['document_id'] == null &&
        decoded['documentId'] == null &&
        decoded['ops'] == null);

if (hasBackendError) {
  throw Exception(
    [
      if (detail != null && detail.isNotEmpty) detail,
      if (error != null && error.isNotEmpty) error,
    ].join(' | '),
  );
}

return response;
    } catch (e) {
      _debugLog('postDocsCloudPreview.error', {
        'elapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
        'error': e.toString(),
      });

      rethrow;
    }
  }

  Future<void> _loadDocsPreviewManually({
    required String previewUrl,
  }) async {
    final cacheKey = _docsPreviewCacheKey(previewUrl);

    if (_docsPreviewCache.containsKey(cacheKey)) {
      _debugLog('loadDocsPreviewManually.skipCached', {
        'cacheKey': cacheKey,
      });
      return;
    }

    if (_docsPreviewLoadingKeys.contains(cacheKey)) {
      _debugLog('loadDocsPreviewManually.skipAlreadyLoading', {
        'cacheKey': cacheKey,
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _docsPreviewLoadingKeys.add(cacheKey);
      _docsPreviewErrors.remove(cacheKey);
    });

    _debugLog('loadDocsPreviewManually.start', {
      'cacheKey': cacheKey,
      'fileId': widget.file.id,
      'fileName': widget.file.name,
      'mimeType': widget.file.mimeType,
      'previewUrl': previewUrl,
    });

    try {
      final raw = await _postDocsCloudPreview(
        timeout: _docsPreviewTimeout,
        data: {
          'file_id': widget.file.id,
          'source_url': previewUrl,
          'filename': widget.file.name,
          'mime_type': widget.file.mimeType,
          'create_document': false,
          'open_in_editor': false,
        },
      );

      final decoded = _decodeResponseMap(raw);
      final ops = _extractPreviewOpsFromResponse(raw);
      final documentId = _extractDocumentId(raw);

      final preview = _DocsPreviewData(
        cacheKey: cacheKey,
        ops: ops,
        documentId: documentId,
        raw: decoded,
      );

      _debugLog('loadDocsPreviewManually.success', {
        'cacheKey': cacheKey,
        'opsLength': ops.length,
        'documentId': documentId,
        'format': decoded['format'],
        'supported': decoded['supported'],
      });

      if (!mounted) return;

      setState(() {
        _docsPreviewCache[cacheKey] = preview;
      });
    } catch (e) {
      _debugLog('loadDocsPreviewManually.error', {
        'cacheKey': cacheKey,
        'error': e.toString(),
      });

      if (!mounted) return;

      setState(() {
        _docsPreviewErrors[cacheKey] = e;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _docsPreviewLoadingKeys.remove(cacheKey);
      });
    }
  }

  QuillController _controllerForDocsPreview(
    _DocsPreviewData preview,
  ) {
    if (_docsPreviewController != null &&
        _docsPreviewControllerKey == preview.cacheKey) {
      _debugLog('controllerForDocsPreview.reuse', {
        'cacheKey': preview.cacheKey,
      });

      return _docsPreviewController!;
    }

    final ops = _normalizePreviewOps(preview.ops);
    final delta = Delta.fromJson(ops);

    final controller = QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );

    _debugLog('controllerForDocsPreview.create', {
      'cacheKey': preview.cacheKey,
      'opsLength': ops.length,
      'documentLength': controller.document.length,
      'plainTextLength': controller.document.toPlainText().length,
    });

    final oldController = _docsPreviewController;

    _docsPreviewController = controller;
    _docsPreviewControllerKey = preview.cacheKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController?.dispose();
    });

    return controller;
  }

  QuillController _controllerForPlainTextPreview({
    required String text,
    required String cacheKey,
  }) {
    if (_docsPreviewController != null &&
        _docsPreviewControllerKey == cacheKey) {
      _debugLog('controllerForPlainTextPreview.reuse', {
        'cacheKey': cacheKey,
      });

      return _docsPreviewController!;
    }

    final normalizedText = text.endsWith('\n') ? text : '$text\n';

    final delta = Delta()
      ..insert(
        normalizedText.isEmpty ? '\n' : normalizedText,
      );

    final controller = QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );

    _debugLog('controllerForPlainTextPreview.create', {
      'cacheKey': cacheKey,
      'textLength': text.length,
      'documentLength': controller.document.length,
    });

    final oldController = _docsPreviewController;

    _docsPreviewController = controller;
    _docsPreviewControllerKey = cacheKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController?.dispose();
    });

    return controller;
  }

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
  }

Future<String?> _createDocumentFromCloudFile({
  required String previewUrl,
}) async {
  final raw = await _postDocsCloudPreview(
    timeout: _openInEditorTimeout,
    data: {
      'file_id': widget.file.id,
      'source_url': previewUrl,
      'filename': widget.file.name,
      'mime_type': widget.file.mimeType,
      'create_document': true,
      'open_in_editor': true,
    },
  );

  final decoded = _decodeResponseMap(raw);
  final documentId = _extractDocumentId(raw);

  _debugLog('createDocumentFromCloudFile.result', {
    'documentId': documentId,
    'keys': decoded.keys.toList(),
    'detail': decoded['detail'],
    'error': decoded['error'],
  });

  if (documentId == null || documentId.trim().isEmpty) {
    throw Exception(
      'Backend nie zwrócił document_id. Odpowiedź: '
      '${_short(jsonEncode(decoded), max: 1500)}',
    );
  }

  return documentId.trim();
}

  Future<void> _openOrCreateInDocsEditor({
    required String previewUrl,
    String? existingDocumentId,
  }) async {
    if (_openingInEditor) return;

    var documentId = existingDocumentId?.trim();

    setState(() {
      _openingInEditor = true;
    });

    _debugLog('openOrCreateInDocsEditor.start', {
      'existingDocumentId': existingDocumentId,
      'previewUrl': previewUrl,
    });

    try {
      if (documentId == null || documentId.isEmpty) {
        documentId = await _createDocumentFromCloudFile(
          previewUrl: previewUrl,
        );
      }

      if (documentId == null || documentId.trim().isEmpty) {
        _showSnackBar(
          message:
              'Backend nie zwrócił ID dokumentu. Nie mogę otworzyć edytora.',
          backgroundColor: Colors.orange,
        );
        return;
      }

      _debugLog('openOrCreateInDocsEditor.navigate', {
        'documentId': documentId,
      });

      if (!mounted) return;
      final cleanDocumentId = documentId.trim();

      Navigator.of(context).pop();

      final docsEditorPath =
          '${Routes.docs}?documentId=${Uri.encodeComponent(cleanDocumentId)}';

      _debugLog('openOrCreateInDocsEditor.pushRoute', {
        'route': docsEditorPath,
        'documentId': cleanDocumentId,
      });

      ref.read(navigationService).pushNamedScreen(
        docsEditorPath,
        data: {
          'documentId': cleanDocumentId,
          'document_id': cleanDocumentId,
          'id': cleanDocumentId,
          'mode': 'edit',
        },
      );
    } catch (e) {
      _debugLog('openOrCreateInDocsEditor.error', {
        'error': e.toString(),
      });

      _showSnackBar(
        message: 'Nie udało się otworzyć dokumentu w edytorze: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _openingInEditor = false;
      });
    }
  }

  Widget _securedWebWarning(String url) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withAlpha(125)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              Text(
                'This file is secured'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Secured files require authenticated backend download. Browser preview cannot attach Authorization header directly.'
                    .tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textColor.withAlpha(205),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: Text('Download'.tr),
                onPressed: () {
                  openInNewTab(url);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortPreviewError(Object error) {
    if (error is TimeoutException) {
      return error.message ??
          'Przekroczono czas ładowania podglądu dokumentu.';
    }

    final raw = error.toString();

    if (raw.contains('<!DOCTYPE html') || raw.contains('<html')) {
      final titleMatch = RegExp(
        r'<title>(.*?)</title>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(raw);

      final title = titleMatch?.group(1)?.trim();

      if (title != null && title.isNotEmpty) {
        return 'Backend zwrócił stronę HTML zamiast JSON: $title';
      }

      return 'Backend zwrócił HTML zamiast JSON. Najczęściej oznacza to 404, 403 albo błąd endpointu.';
    }

    if (raw.length > 1200) {
      return '${raw.substring(0, 1200)}...';
    }

    return raw;
  }

  Widget _buildDocsPreviewError({
    required ThemeColors theme,
    required String previewUrl,
    required Object error,
  }) {
    final message = _shortPreviewError(error);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                color: Colors.orange.withAlpha(230),
                size: 46,
              ),
              const SizedBox(height: 14),
              Text(
                'Nie udało się przygotować podglądu dokumentu'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: SelectableText(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(170),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text('Spróbuj ponownie'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor,
                      foregroundColor: theme.themeColorText,
                    ),
                    onPressed: () {
                      final cacheKey = _docsPreviewCacheKey(previewUrl);

                      _debugLog('docsPreview.retry', {
                        'cacheKey': cacheKey,
                      });

                      setState(() {
                        _docsPreviewCache.remove(cacheKey);
                        _docsPreviewErrors.remove(cacheKey);
                        _docsPreviewLoadingKeys.remove(cacheKey);
                      });

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _loadDocsPreviewManually(previewUrl: previewUrl);
                      });
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: Text('Download'.tr),
                    onPressed: () {
                      openInNewTab(previewUrl);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagedPreview({
    required ThemeColors theme,
    required QuillController controller,
    required String previewUrl,
    String? documentId,
  }) {
    final pageSetup = ref.watch(documentPageSetupProvider);

    _debugLog('buildPagedPreview', {
      'documentId': documentId,
      'documentLength': controller.document.length,
      'plainTextLength': controller.document.toPlainText().length,
      'pageWidthPx': pageSetup.widthPx,
      'pageHeightPx': pageSetup.heightPx,
    });

    return Container(
      color: theme.adPopBackground.withAlpha(widget.isMobile ? 0 : 70),
      child: PagedQuillDocumentEditor(
        masterController: controller,
        outerScrollController: _docsPreviewScrollController,
        pageSetup: pageSetup,
        resolvedTheme: theme,
        whitePaperMode: true,
        placeholder: '',
        focusNode: _docsPreviewFocusNode,
        readOnly: true,
        enableZoom: true,
      ),
    );
  }

  Widget _buildPlainTextPagedPreview({
    required ThemeColors theme,
    required String previewUrl,
    required String text,
  }) {
    final controller = _controllerForPlainTextPreview(
      text: text,
      cacheKey: 'plain-text|${widget.file.id}|$previewUrl|${text.length}',
    );

    return _buildPagedPreview(
      theme: theme,
      controller: controller,
      previewUrl: previewUrl,
      documentId: null,
    );
  }

  Widget _buildHouslyDocumentPreview({
    required ThemeColors theme,
    required String previewUrl,
  }) {
    final cacheKey = _docsPreviewCacheKey(previewUrl);
    final cachedPreview = _docsPreviewCache[cacheKey];
    final error = _docsPreviewErrors[cacheKey];
    final isLoading = _docsPreviewLoadingKeys.contains(cacheKey);

    _debugLog('buildHouslyDocumentPreview', {
      'cacheKey': cacheKey,
      'hasCachedPreview': cachedPreview != null,
      'hasError': error != null,
      'isLoading': isLoading,
      'previewUrl': previewUrl,
    });

    if (cachedPreview != null) {
      try {
        final controller = _controllerForDocsPreview(cachedPreview);

        return _buildPagedPreview(
          theme: theme,
          controller: controller,
          previewUrl: previewUrl,
          documentId: cachedPreview.documentId,
        );
      } catch (e) {
        _debugLog('buildHouslyDocumentPreview.controllerError', {
          'error': e.toString(),
        });

        return _buildDocsPreviewError(
          theme: theme,
          previewUrl: previewUrl,
          error: e,
        );
      }
    }

    if (error != null) {
      return _buildDocsPreviewError(
        theme: theme,
        previewUrl: previewUrl,
        error: error,
      );
    }

    if (!isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadDocsPreviewManually(previewUrl: previewUrl);
      });
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLottie.loading(size: 320),
          const SizedBox(height: 10),
          Text(
            'Przygotowuję podgląd dokumentu...'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(175),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jeśli plik jest duży, może to chwilę potrwać.'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(125),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedFile({
    required ThemeColors theme,
    required CloudFile file,
    required String previewUrl,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insert_drive_file,
            size: 70,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            '${'Unsupported file type'.tr} (${file.mimeType ?? 'unknown'.tr})',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: Text('Download'.tr),
            onPressed: () {
              openInNewTab(previewUrl);
            },
          ),
        ],
      ),
    );
  }





  Widget _buildPdfBody({
    required String previewUrl,
    required FileLoadResult result,
  }) {
    _debugLog('buildPdfBody', {
      'previewUrl': previewUrl,
      'isWeb': kIsWeb,
      'requiresAuthHeader': _requiresAuthHeader,
      'isSecured': _isSecured,
      'localPdfPath': result.localPdfPath,
    });

    if (_requiresAuthHeader && _isSecured && kIsWeb) {
      return _securedWebWarning(previewUrl);
    }

    if (kIsWeb) {
      registerPdfViewer(_pdfViewId, previewUrl);

      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(12),
          border: Border(
            top: BorderSide(color: Colors.white.withAlpha(18)),
          ),
        ),
        child: HtmlElementView(
          key: ValueKey(_pdfViewId),
          viewType: _pdfViewId,
        ),
      );
    }

    if (result.localPdfPath == null || result.localPdfPath!.trim().isEmpty) {
      return Center(child: AppLottie.loading());
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(12),
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(18)),
        ),
      ),
      child: NativePdfViewer(
        key: ValueKey('native_pdf_${widget.file.id}_${result.localPdfPath}'),
        filePath: result.localPdfPath!,
      ),
    );
  }

  void _openFullScreenImage({
    required String previewUrl,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: _FullScreenImagePreview(
            imageUrl: previewUrl,
          ),
        ),
      ),
    );
  }

  Widget _buildImageBody({
    required String previewUrl,
  }) {
    if (_requiresAuthHeader && _isSecured && kIsWeb) {
      return _securedWebWarning(previewUrl);
    }

    return GestureDetector(
      onTap: () => _openFullScreenImage(previewUrl: previewUrl),
      child: InteractiveViewer(
        child: Image.network(
        previewUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          final theme = ref.read(themeColorsProvider);
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.dashboardBoarder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 32,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'image_load_failed'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'image_load_failed_desc'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(150),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: Text('open_in_browser'.tr),
                          onPressed: () => openInNewTab(previewUrl),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.feedback_outlined, size: 16),
                          label: Text('report_problem'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.themeColor,
                            foregroundColor: theme.themeColorText,
                          ),
                          onPressed: () {
                            final report = [
                              '=== Hously Image Error Report ===',
                              'File: ${widget.file.name}',
                              'File ID: ${widget.file.id}',
                              'Error: $error',
                              'URL: $previewUrl',
                              'Time: ${DateTime.now().toIso8601String()}',
                            ].join('\n');
                            Clipboard.setData(ClipboardData(text: report));
                            _showSnackBar(
                              message: 'error_report_copied'.tr,
                              backgroundColor: Colors.green,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildVideoBody({
    required String previewUrl,
  }) {
    if (_requiresAuthHeader && _isSecured && kIsWeb) {
      return _securedWebWarning(previewUrl);
    }

    if (kIsWeb) {
      registerVideoViewer(_videoViewId, previewUrl);

      return Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          height: 340,
          child: HtmlElementView(viewType: _videoViewId),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ChewieVideoPlayer(url: previewUrl),
    );
  }

  Widget _buildFileBody({
    required ThemeColors theme,
    required CloudFile file,
    required String previewUrl,
    required bool isPdfFile,
    required FileLoadResult result,
  }) {
    final isImage = _isImageFile(file.mimeType, previewUrl);
    final isVideo = _isVideoFile(file.mimeType, previewUrl);
    final isPlainText = _isPlainTextDocument(file: file, url: previewUrl);
    final isPreviewable = _isPreviewableDocument(file: file, url: previewUrl);

    _debugLog('buildFileBody', {
      'fileId': file.id,
      'fileName': file.name,
      'mimeType': file.mimeType,
      'previewUrl': previewUrl,
      'isPdfFile': isPdfFile,
      'isImage': isImage,
      'isVideo': isVideo,
      'isPlainText': isPlainText,
      'isPreviewableDocument': isPreviewable,
      'requiresAuthHeader': _requiresAuthHeader,
      'isSecured': _isSecured,
      'hasTextContent': result.textContent != null,
      'textLength': result.textContent?.length,
      'localPdfPath': result.localPdfPath,
    });



    if (_storageError != null) {
      return _buildStorageErrorBody(theme: theme);
    }

    if (isPdfFile) {
      return _buildPdfBody(
        previewUrl: previewUrl,
        result: result,
      );
    }

    if (isImage) {
      return _buildImageBody(previewUrl: previewUrl);
    }

    if (isVideo) {
      return _buildVideoBody(previewUrl: previewUrl);
    }

    // Office / rich document formats go through backend converter.
    // This must happen before any fallback loader path.
    if (!isPlainText && isPreviewable) {
      return _buildHouslyDocumentPreview(
        theme: theme,
        previewUrl: previewUrl,
      );
    }

    if (isPlainText && !(_requiresAuthHeader && _isSecured && kIsWeb)) {
      final text = result.textContent;

      if (text == null) {
        return Center(child: AppLottie.loading(size: 300));
      }

      return _buildPlainTextPagedPreview(
        theme: theme,
        previewUrl: previewUrl,
        text: text,
      );
    }

    if (isPreviewable) {
      return _buildHouslyDocumentPreview(
        theme: theme,
        previewUrl: previewUrl,
      );
    }

    if (_requiresAuthHeader && _isSecured && kIsWeb) {
      return _securedWebWarning(previewUrl);
    }

    return _buildUnsupportedFile(
      theme: theme,
      file: file,
      previewUrl: previewUrl,
    );
  }

  String _fileKindLabel({
    required CloudFile file,
    required String previewUrl,
  }) {
    if (_isPdfFile(file.mimeType, previewUrl)) return 'PDF';
    if (_isImageFile(file.mimeType, previewUrl)) return 'Image'.tr;
    if (_isVideoFile(file.mimeType, previewUrl)) return 'Video'.tr;
    if (_isPlainTextDocument(file: file, url: previewUrl)) {
      return 'Text document'.tr;
    }
    if (_isPreviewableDocument(file: file, url: previewUrl)) {
      return 'Document'.tr;
    }

    return 'File'.tr;
  }

  bool _canOpenInDocsEditor({
    required CloudFile file,
    required String previewUrl,
  }) {
    if (_isPdfFile(file.mimeType, previewUrl)) return false;
    if (_isImageFile(file.mimeType, previewUrl)) return false;
    if (_isVideoFile(file.mimeType, previewUrl)) return false;

    return _isPlainTextDocument(file: file, url: previewUrl) ||
        _isPreviewableDocument(file: file, url: previewUrl);
  }

  String? _cachedDocumentIdForPreviewUrl(String previewUrl) {
    final cacheKey = _docsPreviewCacheKey(previewUrl);
    final cachedPreview = _docsPreviewCache[cacheKey];

    final documentId = cachedPreview?.documentId?.trim();
    if (documentId == null || documentId.isEmpty) return null;

    return documentId;
  }

  Future<void> _copyPreviewUrl(String previewUrl) async {
    try {
      await Clipboard.setData(ClipboardData(text: previewUrl));

      _showSnackBar(
        message: 'Link copied to clipboard'.tr,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      _showSnackBar(
        message: 'Nie udało się skopiować linku: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Widget _buildTopBarChip({
    required ThemeColors theme,
    required String text,
    IconData? icon,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: widget.isMobile
            ? Colors.white.withAlpha(26)
            : theme.dashboardContainer.withAlpha(175),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: widget.isMobile
              ? Colors.white.withAlpha(35)
              : theme.dashboardBoarder.withAlpha(140),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: widget.isMobile
                  ? theme.themeTextColor.withAlpha(220)
                  : theme.textColor.withAlpha(180),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.isMobile
                  ? theme.themeTextColor.withAlpha(225)
                  : theme.textColor.withAlpha(180),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarIconButton({
    required ThemeColors theme,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool danger = false,
  }) {
    final foreground = danger
        ? Colors.redAccent
        : (widget.isMobile ? theme.themeTextColor : theme.textColor);

    final background = danger
        ? Colors.redAccent.withAlpha(22)
        : (widget.isMobile
            ? Colors.white.withAlpha(22)
            : theme.dashboardContainer.withAlpha(165));

    return Tooltip(
      message: tooltip.tr,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              size: 19,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenEditorTopButton({
    required ThemeColors theme,
    required CloudFile file,
    required String previewUrl,
  }) {
    final existingDocumentId = _cachedDocumentIdForPreviewUrl(previewUrl);
    final label = existingDocumentId == null
        ? 'Otwórz w edytorze'.tr
        : 'Przejdź do edytora'.tr;

    return Tooltip(
      message: label,
      child: ElevatedButton.icon(
        icon: _openingInEditor
            ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.themeColorText,
                ),
              )
            : const Icon(Icons.edit_document, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.themeColor,
          foregroundColor: theme.themeColorText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _openingInEditor
            ? null
            : () => _openOrCreateInDocsEditor(
                  previewUrl: previewUrl,
                  existingDocumentId: existingDocumentId,
                ),
      ),
    );
  }

  Widget _buildFileTopBar({
    required ThemeColors theme,
    required CloudFile file,
    required String previewUrl,
    required bool isPdfFile,
    required bool isPlainTextFile,
    required bool isDocsPreviewFile,
  }) {
    final kindLabel = _fileKindLabel(
      file: file,
      previewUrl: previewUrl,
    );

    final chips = <Widget>[
      _buildTopBarChip(
        theme: theme,
        text: kindLabel,
        icon: Icons.insert_drive_file_outlined,
      ),
      if (file.mimeType != null && file.mimeType!.trim().isNotEmpty)
        _buildTopBarChip(
          theme: theme,
          text: file.mimeType!.trim(),
          icon: Icons.code_rounded,
        ),
      if (file.sizeString.isNotEmpty)
        _buildTopBarChip(
          theme: theme,
          text: file.sizeString,
          icon: Icons.data_usage_rounded,
        ),
      if (file.checksum != null && file.checksum!.length >= 8)
        _buildTopBarChip(
          theme: theme,
          text: '${'checksum'.tr}: ${file.checksum!.substring(0, 8)}',
          icon: Icons.tag_rounded,
        ),
      if (_requiresAuthHeader || _isSecured)
        _buildTopBarChip(
          theme: theme,
          text: 'Secured'.tr,
          icon: Icons.lock_outline_rounded,
        ),
      if (_resolvePreviewError != null)
        _buildTopBarChip(
          theme: theme,
          text: 'URL fallback'.tr,
          icon: Icons.warning_amber_rounded,
        ),
    ];

    return Material(
      color: widget.isMobile ? theme.themeColor : theme.adPopBackground,
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: widget.isMobile
                  ? Colors.white.withAlpha(28)
                  : theme.dashboardBoarder.withAlpha(130),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isMobile)
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 5,
                  width: 96,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(120),
                    color: theme.themeTextColor.withAlpha(185),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
               
                Expanded(
                  child: Row(
                    children: [
                      
                      BackButtonHously(isNamedRoute: false,),
                      const SizedBox(width: 12),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: widget.isMobile
                              ? Colors.white.withAlpha(24)
                              : theme.themeColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.isMobile
                                ? Colors.white.withAlpha(35)
                                : theme.themeColor.withAlpha(65),
                          ),
                        ),
                        child: Icon(
                          isPdfFile
                              ? Icons.picture_as_pdf_rounded
                              : (isPlainTextFile || isDocsPreviewFile)
                                  ? Icons.description_rounded
                                  : Icons.insert_drive_file_rounded,
                          color: widget.isMobile
                              ? theme.themeTextColor
                              : theme.themeColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),


                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: widget.isMobile ? 14 : 16,
                                fontWeight: FontWeight.w900,
                                color: widget.isMobile
                                    ? theme.themeTextColor
                                    : theme.textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: chips
                                    .map(
                                      (chip) => Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: chip,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  ),
              ],
            ),
            if (file.description != null && file.description!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    file.description!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.isMobile
                          ? theme.themeTextColor.withAlpha(210)
                          : theme.textColor.withAlpha(155),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Desktop-only floating action bar, rendered bottom-right via
  /// [PopPageLauncher.verticalButtonsPc] — same pattern used elsewhere
  /// through BarManager's `verticalButtonsPc` (e.g. calendar, todo boards).
  Widget _buildFloatingActionButtons({
    required ThemeColors theme,
    required CloudFile file,
    required String previewUrl,
  }) {
    final canOpenEditor = _canOpenInDocsEditor(
      file: file,
      previewUrl: previewUrl,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        if (canOpenEditor)
          _buildOpenEditorTopButton(
            theme: theme,
            file: file,
            previewUrl: previewUrl,
          ),
        _buildTopBarIconButton(
          theme: theme,
          icon: Icons.refresh_rounded,
          tooltip: 'Odśwież link podglądu',
          onPressed: _resolvePreviewUrl,
        ),
        _buildTopBarIconButton(
          theme: theme,
          icon: Icons.download_rounded,
          tooltip: 'Download',
          onPressed: () => openInNewTab(previewUrl),
        ),
        _buildTopBarIconButton(
          theme: theme,
          icon: Icons.open_in_new_rounded,
          tooltip: 'Open in new tab',
          onPressed: () => openInNewTab(previewUrl),
        ),
        _buildTopBarIconButton(
          theme: theme,
          icon: Icons.link_rounded,
          tooltip: 'Copy link',
          onPressed: () => _copyPreviewUrl(previewUrl),
        ),
        _buildDeleteButton(theme: theme, file: file),
        _buildTopBarIconButton(
          theme: theme,
          icon: Icons.close_rounded,
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Widget _buildFileFooter({
    required ThemeColors theme,
    required CloudFile file,
  }) {
    return const SizedBox.shrink();
  }

  Widget _buildDeleteButton({
    required ThemeColors theme,
    required CloudFile file,
  }) {
    return Tooltip(
      message: 'Delete'.tr,
      child: SizedBox(
        width: 48,
        height: 48,
        child: ApiButton(
          endpoint: 'https://www.superbee.cloud/storage/files/${file.id}/',
          hasToken: true,
          method: ApiMethod.delete,
          icon: AppIcons.delete(color: Colors.redAccent),
          onSuccess: (_) {
            Navigator.of(context).pop();
            ref.invalidate(cloudExplorerProvider);
          },
        ),
      ),
    );
  }

  Widget _buildResolveUrlError({
    required ThemeColors theme,
  }) {
    return ErrorBox(
      title: 'Failed to resolve preview URL'.tr,
      message: _resolvePreviewError ?? 'Unknown error',
      url: widget.file.url,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final file = widget.file;

    if (_resolvingPreviewUrl) {
      _debugLog('build.resolvingPreviewUrl');
      return Center(child: AppLottie.loading());
    }

    if (_resolvePreviewError != null && _previewUrl.trim().isEmpty) {
      _debugLog('build.resolvePreviewError', {
        'error': _resolvePreviewError,
      });

      return _buildResolveUrlError(theme: theme);
    }

    final previewUrl = _previewUrl.trim().isNotEmpty ? _previewUrl : file.url;
    final isPdfFile = _isPdfFile(file.mimeType, previewUrl);

    final isPlainTextFile = _isPlainTextDocument(
      file: file,
      url: previewUrl,
    );

    final isDocsPreviewFile = _isPreviewableDocument(
      file: file,
      url: previewUrl,
    );

    final shouldUseDocsConverter = isDocsPreviewFile && !isPlainTextFile;

    final loadArgs = (
      id: file.id,
      url: previewUrl,
      mimeType: file.mimeType,
    );

    final needsPlainTextLoad =
        isPlainTextFile && !(_requiresAuthHeader && _isSecured && kIsWeb);

    final needsPdfLocalLoad = isPdfFile && !kIsWeb;

    final needsLoad = needsPdfLocalLoad ||
        needsPlainTextLoad ||
        (!isDocsPreviewFile &&
            _needsFileLoader(
              mimeType: file.mimeType,
              url: previewUrl,
            ));

    _debugLog('build.fileDecision', {
      'fileId': file.id,
      'fileName': file.name,
      'mimeType': file.mimeType,
      'previewUrl': previewUrl,
      'isPdfFile': isPdfFile,
      'isPlainTextFile': isPlainTextFile,
      'isDocsPreviewFile': isDocsPreviewFile,
      'shouldUseDocsConverter': shouldUseDocsConverter,
      'needsPlainTextLoad': needsPlainTextLoad,
      'needsLoad': needsLoad,
      'requiresAuthHeader': _requiresAuthHeader,
      'isSecured': _isSecured,
    });

    _ensureLoadStarted(
      needsLoad: needsLoad,
      args: loadArgs,
    );

    final loadAsync = needsLoad
        ? ref.watch(fileViewerLoadProvider(loadArgs))
        : AsyncValue<FileLoadResult>.data(FileLoadResult());

    final stateKey = loadAsync is AsyncLoading
        ? 'loading'.tr
        : (loadAsync is AsyncError ? 'error'.tr : 'data');

    final bodyContent = loadAsync.when(
      loading: () {
        _debugLog('fileLoadAsync.loading');
        return Center(child: AppLottie.loading());
      },
      error: (err, st) {
        _debugLog('fileLoadAsync.error', {
          'error': err.toString(),
        });

        if (isPlainTextFile) {
          return _buildHouslyDocumentPreview(
            theme: theme,
            previewUrl: previewUrl,
          );
        }

        return ErrorBox(
          title: 'Failed to open file'.tr,
          message: err.toString(),
          url: previewUrl,
        );
      },
      data: (result) {
        _debugLog('fileLoadAsync.data', {
          'hasTextContent': result.textContent != null,
          'textLength': result.textContent?.length,
          'localPdfPath': result.localPdfPath,
        });

        return _buildFileBody(
          theme: theme,
          file: file,
          previewUrl: previewUrl,
          isPdfFile: isPdfFile,
          result: result,
        );
      },
    );

    final fileDataContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFileTopBar(
          theme: theme,
          file: file,
          previewUrl: previewUrl,
          isPdfFile: isPdfFile,
          isPlainTextFile: isPlainTextFile,
          isDocsPreviewFile: isDocsPreviewFile,
        ),
        Expanded(
          child: ClipRect(
            child: bodyContent,
          ),
        ),
      ],
    );

    if (widget.isMobile) {
      _debugLog('build.mobile');

      return Container(
        decoration: BoxDecoration(color: theme.dashboardContainer),
        child: Stack(
          children: [
            fileDataContent,
            Positioned(
              bottom: 10,
              right: 10,
              child: _buildFloatingActionButtons(
                theme: theme,
                file: file,
                previewUrl: previewUrl,
              ),
            ),
          ],
        ),
      );
    }

    final dialogWidth = MediaQuery.sizeOf(context).width;
        // (MediaQuery.sizeOf(context).width * 0.92).clamp(720.0, 1480.0);

    final dialogHeight = MediaQuery.sizeOf(context).height;
        // (MediaQuery.sizeOf(context).height * 0.86).clamp(620.0, 980.0);

    _debugLog('build.dialog', {
      'dialogWidth': dialogWidth,
      'dialogHeight': dialogHeight,
      'stateKey': stateKey,
    });

    return PopPageLauncher(
      key: ValueKey('file_viewer_${file.id}_$stateKey'),
      width: dialogWidth.toDouble(),
      height: dialogHeight.toDouble(),
      hasBackButton: false,
      parentContext: context,
      tag: _tag,
      isBig: true,
      verticalButtonsPc: _buildFloatingActionButtons(
        theme: theme,
        file: file,
        previewUrl: previewUrl,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          width: dialogWidth.toDouble(),
          height: dialogHeight.toDouble(),
          child: fileDataContent,
        ),
      ),
    );
  }
}

class _FullScreenImagePreview extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImagePreview({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: GestureDetector(
                  onTap: () {},
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: SafeArea(
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}