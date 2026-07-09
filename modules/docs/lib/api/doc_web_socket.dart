import 'dart:async';
import 'package:docs/docs_urls.dart';
import 'dart:convert';

import 'package:docs/provider/cloud_doc_provider.dart';
import 'package:docs/widgets/document_editing_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DocumentPresenceUser {
  final String userId;
  final String username;
  final String? clientId;
  final Map<String, dynamic>? selection;

  const DocumentPresenceUser({
    required this.userId,
    required this.username,
    this.clientId,
    this.selection,
  });

  DocumentPresenceUser copyWith({
    String? userId,
    String? username,
    String? clientId,
    Map<String, dynamic>? selection,
  }) {
    return DocumentPresenceUser(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      clientId: clientId ?? this.clientId,
      selection: selection ?? this.selection,
    );
  }
}

class DocumentWebSocketService {
  final Ref ref;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  String? _currentDocumentId;

  bool _isConnected = false;
  bool _isDisposed = false;
  bool _allowReconnect = false;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  int _currentRevision = 0;

  final String clientId = const Uuid().v4();

  static const List<int> _reconnectDelays = [1, 2, 5, 10, 15, 20];

  DocumentWebSocketService(this.ref);

  bool get isConnected => !_isDisposed && _isConnected;
  String? get currentDocumentId => _currentDocumentId;
  int get currentRevision => _currentRevision;

  void connect(String documentId) {
    if (_isDisposed) return;

    final cleanId = documentId.trim();

    if (cleanId.isEmpty) {
      debugPrint('WebSocket: empty document id');
      return;
    }

    if (_currentDocumentId == cleanId && _isConnected) {
      return;
    }

    disconnect(clearPresence: false);

    if (_isDisposed) return;

    _currentDocumentId = cleanId;
    _currentRevision = ref.read(documentProvider.notifier).getCurrentRevision();
    _reconnectAttempts = 0;
    _allowReconnect = true;

    _tryConnect();
  }

  void _tryConnect() {
    if (_isDisposed) return;
    if (!_allowReconnect) return;

    final documentId = _currentDocumentId;
    final token = ApiServices.token;

    if (documentId == null || documentId.isEmpty) {
      return;
    }

    if (token == null || token.trim().isEmpty) {
      debugPrint('WebSocket: User not authenticated');
      return;
    }

    try {
      final encodedToken = Uri.encodeComponent(token.trim());
      final wsUrl = '${DocsUrls.documentWebSocket(documentId)}?token=$encodedToken';

      debugPrint('WebSocket: Connecting to $wsUrl');

      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      if (_isDisposed || !_allowReconnect) {
        channel.sink.close();
        return;
      }

      _channel = channel;
      _isConnected = true;

      _safeSetConnected(true);

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleSocketError,
        onDone: _handleSocketDone,
        cancelOnError: false,
      );

      _reconnectTimer?.cancel();
      _reconnectAttempts = 0;

      debugPrint('WebSocket: Connecting to document $documentId');
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _setDisconnected(scheduleReconnect: true);
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    if (!_allowReconnect) return;
    if (_currentDocumentId == null) return;

    _reconnectTimer?.cancel();

    final index = _reconnectAttempts.clamp(0, _reconnectDelays.length - 1);
    final delaySeconds = _reconnectDelays[index];

    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_isDisposed) return;
      if (!_allowReconnect) return;

      if (_currentDocumentId != null) {
        _tryConnect();
      }
    });
  }

  void _handleMessage(dynamic message) {
    if (_isDisposed) return;

    try {
      final raw = message is String ? message : message.toString();
      final decoded = jsonDecode(raw);

      if (_isDisposed) return;

      if (decoded is! Map) {
        debugPrint('WebSocket: invalid message payload: $decoded');
        return;
      }

      final data = Map<String, dynamic>.from(decoded);
      final type = data['type']?.toString();

      switch (type) {
        case 'init':
          _handleInit(data);
          break;

        case 'update_ack':
          _handleUpdateAck(data);
          break;

        case 'update':
        case 'doc_update':
          _handleDocUpdate(data);
          break;

        case 'cursor':
          _handleCursor(data);
          break;

        case 'presence_joined':
          _handlePresenceJoined(data);
          break;

        case 'presence_left':
          _handlePresenceLeft(data);
          break;

        case 'version_saved':
          _handleVersionSaved(data);
          break;

        case 'version_restored':
          _handleVersionRestored(data);
          break;

        case 'pong':
          break;

        case 'error':
          debugPrint(
            'WebSocket backend error: ${data['code'] ?? ''} ${data['message']}',
          );
          break;

        default:
          debugPrint('WebSocket: Unknown message type: $type');
      }
    } catch (e) {
      if (_isDisposed) return;

      debugPrint('WebSocket message parsing error: $e');
    }
  }

  void _handleInit(Map<String, dynamic> data) {
    if (_isDisposed) return;

    try {
      final delta = _normalizeDelta(data['delta']);
      final style = _normalizeMap(data['style']);
      final revision = _toInt(data['revision']);

      _currentRevision = revision;

      if (_isDisposed) return;

      ref.read(documentProvider.notifier).setInitialContent(
            delta,
            style,
            revision: revision,
            title: data['title']?.toString(),
            status: data['status']?.toString(),
            isFinalized: data['is_finalized'] == true,
          );

      _safeSetConnected(true);

      debugPrint('WebSocket: init received, revision=$_currentRevision');
    } catch (e) {
      if (_isDisposed) return;

      debugPrint('WebSocket init handler error: $e');
    }
  }

  void _handleUpdateAck(Map<String, dynamic> data) {
    if (_isDisposed) return;

    try {
      final revision = _toInt(data['revision']);

      if (revision > 0) {
        _currentRevision = revision;
      }

      final delta = _normalizeDelta(data['delta']);
      final style = _normalizeMap(data['style']);

      if (_isDisposed) return;

      ref.read(documentProvider.notifier).updateDocumentContent(
            delta,
            style,
            revision: revision > 0 ? revision : null,
            title: data['title']?.toString(),
            lastEditedByUsername: data['username']?.toString(),
          );

      if (_isDisposed) return;

      ref.invalidate(documentsProvider);

      debugPrint('WebSocket: update_ack received, revision=$_currentRevision');
    } catch (e) {
      if (_isDisposed) return;

      debugPrint('WebSocket update_ack handler error: $e');
    }
  }

  void _handleDocUpdate(Map<String, dynamic> data) {
    if (_isDisposed) return;

    try {
      final incomingClientId = data['client_id']?.toString();
      final revision = _toInt(data['revision']);

      if (revision > 0) {
        _currentRevision = revision;
      }

      if (incomingClientId == clientId) {
        debugPrint('WebSocket: own echo ignored, revision=$_currentRevision');
        return;
      }

      final delta = _normalizeDelta(data['delta']);
      final style = _normalizeMap(data['style']);

      if (_isDisposed) return;

      ref.read(documentProvider.notifier).updateDocumentContent(
            delta,
            style,
            revision: revision > 0 ? revision : null,
            title: data['title']?.toString(),
            lastEditedByUsername: data['username']?.toString(),
          );

      if (_isDisposed) return;

      ref.invalidate(documentsProvider);
    } catch (e) {
      if (_isDisposed) return;

      debugPrint('WebSocket doc_update handler error: $e');
    }
  }

  void _handleCursor(Map<String, dynamic> data) {
    if (_isDisposed) return;

    final userId = data['user_id']?.toString();
    if (userId == null || userId.isEmpty) return;

    final incomingClientId = data['client_id']?.toString();
    if (incomingClientId == clientId) return;

    final username = data['username']?.toString() ?? 'User';
    final selection = data['selection'] is Map
        ? Map<String, dynamic>.from(data['selection'])
        : <String, dynamic>{};

    if (_isDisposed) return;

    ref.read(documentPresenceProvider.notifier).update((state) {
      final next = Map<String, DocumentPresenceUser>.from(state);
      final existing = next[userId];

      next[userId] = existing?.copyWith(
            username: username,
            clientId: incomingClientId,
            selection: selection,
          ) ??
          DocumentPresenceUser(
            userId: userId,
            username: username,
            clientId: incomingClientId,
            selection: selection,
          );

      return next;
    });
  }

  void _handlePresenceJoined(Map<String, dynamic> data) {
    if (_isDisposed) return;

    final userId = data['user_id']?.toString();
    if (userId == null || userId.isEmpty) return;

    final username = data['username']?.toString() ?? 'User';

    if (_isDisposed) return;

    ref.read(documentPresenceProvider.notifier).update((state) {
      final next = Map<String, DocumentPresenceUser>.from(state);

      next[userId] = DocumentPresenceUser(
        userId: userId,
        username: username,
      );

      return next;
    });
  }

  void _handlePresenceLeft(Map<String, dynamic> data) {
    if (_isDisposed) return;

    final userId = data['user_id']?.toString();
    if (userId == null || userId.isEmpty) return;

    if (_isDisposed) return;

    ref.read(documentPresenceProvider.notifier).update((state) {
      final next = Map<String, DocumentPresenceUser>.from(state);
      next.remove(userId);
      return next;
    });
  }

  void _handleVersionSaved(Map<String, dynamic> data) {
    if (_isDisposed) return;

    debugPrint('WebSocket: version saved ${data['version']}');

    final revision = _toInt(data['revision']);
    if (revision > 0) _currentRevision = revision;

    final documentId = _currentDocumentId;
    if (documentId == null) return;

    if (_isDisposed) return;

    ref.read(documentProvider.notifier).fetchDocument(documentId, ref);

    if (_isDisposed) return;

    ref.invalidate(documentsProvider);
  }

  void _handleVersionRestored(Map<String, dynamic> data) {
    if (_isDisposed) return;

    final revision = _toInt(data['revision']);
    if (revision > 0) _currentRevision = revision;

    final delta = data['delta'];
    final documentId = _currentDocumentId;

    if (_isDisposed) return;

    if (delta is Map || delta is List) {
      ref.read(documentProvider.notifier).updateDocumentContent(
            _normalizeDelta(delta),
            _normalizeMap(data['style']),
            revision: revision > 0 ? revision : null,
            title: data['title']?.toString(),
          );
    } else if (documentId != null) {
      ref.read(documentProvider.notifier).fetchDocument(documentId, ref);
    }

    if (_isDisposed) return;

    ref.invalidate(documentsProvider);
  }

  void _handleSocketError(dynamic error) {
    if (_isDisposed) return;
    if (!_allowReconnect) return;

    debugPrint('WebSocket error: $error');
    _setDisconnected(scheduleReconnect: true);
  }

  void _handleSocketDone() {
    if (_isDisposed) return;
    if (!_allowReconnect) return;

    debugPrint('WebSocket connection closed by server');
    _setDisconnected(scheduleReconnect: true);
  }

  void _setDisconnected({
    required bool scheduleReconnect,
  }) {
    if (_isDisposed) return;

    _isConnected = false;
    _channel = null;
    _subscription = null;

    _safeSetConnected(false);

    if (scheduleReconnect && _allowReconnect) {
      _scheduleReconnect();
    }
  }

  bool sendUpdate({
    required Map<String, dynamic> delta,
    required Map<String, dynamic> style,
    String? title,
    int? baseRevision,
    String? updateId,
  }) {
    if (_isDisposed) return false;

    if (_channel == null || !_isConnected) {
      debugPrint('WebSocket sendUpdate skipped - not connected');
      return false;
    }

    try {
      final message = jsonEncode({
        'type': 'update',
        'client_id': clientId,
        'update_id': updateId,
        'base_revision': baseRevision ?? _currentRevision,
        'delta': delta,
        'style': style,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      });

      _channel!.sink.add(message);
      return true;
    } catch (e) {
      if (_isDisposed) return false;

      debugPrint('WebSocket sendUpdate error: $e');
      return false;
    }
  }

  void sendCursor({
    required TextSelection selection,
  }) {
    if (_isDisposed) return;
    if (_channel == null || !_isConnected) return;

    try {
      _channel!.sink.add(
        jsonEncode({
          'type': 'cursor',
          'client_id': clientId,
          'selection': {
            'baseOffset': selection.baseOffset,
            'extentOffset': selection.extentOffset,
            'isCollapsed': selection.isCollapsed,
          },
        }),
      );
    } catch (e) {
      if (_isDisposed) return;

      debugPrint('WebSocket sendCursor error: $e');
    }
  }

  bool saveVersion({
    required QuillController controller,
    String comment = 'Manual version save',
    String? title,
  }) {
    if (_isDisposed) return false;

    if (_channel == null || !_isConnected) {
      debugPrint('Cannot save version - not connected');
      return false;
    }

    try {
      final delta = DeltaUtils.deltaToMap(controller.document.toDelta());
      final style = StyleExtractor.extractStyle(controller);

      final message = jsonEncode({
        'type': 'save_version',
        'client_id': clientId,
        'delta': delta,
        'style': style,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        'comment': comment.trim().isEmpty ? 'Version saved' : comment.trim(),
      });

      _channel!.sink.add(message);
      return true;
    } catch (e) {
      if (_isDisposed) return false;

      debugPrint('WebSocket saveVersion error: $e');
      return false;
    }
  }

  bool restoreVersion({
    required int version,
  }) {
    if (_isDisposed) return false;

    if (_channel == null || !_isConnected) {
      debugPrint('Cannot restore version - not connected');
      return false;
    }

    try {
      _channel!.sink.add(
        jsonEncode({
          'type': 'restore_version',
          'client_id': clientId,
          'version': version,
        }),
      );

      return true;
    } catch (e) {
      if (_isDisposed) return false;

      debugPrint('WebSocket restoreVersion error: $e');
      return false;
    }
  }

  void ping() {
    if (_isDisposed) return;
    if (_channel == null || !_isConnected) return;

    _channel!.sink.add(
      jsonEncode({
        'type': 'ping',
        'client_id': clientId,
      }),
    );
  }

  void retryConnection() {
    if (_isDisposed) return;

    if (_currentDocumentId != null && !_isConnected) {
      _allowReconnect = true;
      _reconnectAttempts = 0;
      _tryConnect();
    }
  }

  void disconnect({
    bool clearPresence = true,
  }) {
    _allowReconnect = false;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;

    _subscription?.cancel();
    _subscription = null;

    _channel?.sink.close();
    _channel = null;

    _currentDocumentId = null;
    _currentRevision = 0;
    _isConnected = false;

    if (!_isDisposed) {
      _safeSetConnected(false);

      if (clearPresence) {
        _safeClearPresence();
      }
    }

    debugPrint('WebSocket: Disconnected');
  }

  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _allowReconnect = false;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;

    _subscription?.cancel();
    _subscription = null;

    _channel?.sink.close();
    _channel = null;

    _currentDocumentId = null;
    _currentRevision = 0;
    _isConnected = false;

    debugPrint('WebSocket: Disposed');
  }

  void _safeSetConnected(bool value) {
    if (_isDisposed) return;
    // Defer to avoid modifying a provider during frame building / dispose.
    Future.microtask(() {
      if (_isDisposed) return;
      try {
        ref.read(documentWebSocketConnectedProvider.notifier).state = value;
      } catch (e) {
        debugPrint('WebSocket: skipped connection provider update: $e');
      }
    });
  }

  void _safeClearPresence() {
    if (_isDisposed) return;
    // Defer to avoid modifying a provider during frame building / dispose.
    Future.microtask(() {
      if (_isDisposed) return;
      try {
        ref.read(documentPresenceProvider.notifier).state = {};
      } catch (e) {
        debugPrint('WebSocket: skipped presence provider clear: $e');
      }
    });
  }

  Map<String, dynamic> _normalizeDelta(dynamic rawDelta) {
    if (rawDelta is Map<String, dynamic>) return rawDelta;
    if (rawDelta is Map) return Map<String, dynamic>.from(rawDelta);
    if (rawDelta is List) return {'ops': rawDelta};

    return {
      'ops': [
        {'insert': '\n'},
      ],
    };
  }

  Map<String, dynamic> _normalizeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DeltaUtils {
  static Map<String, dynamic> deltaToMap(Delta delta) {
    return {
      'ops': delta.toJson(),
    };
  }

  static Delta mapToDelta(Map<String, dynamic> map) {
    final ops = map['ops'] as List? ?? [];
    return Delta.fromJson(ops);
  }
}