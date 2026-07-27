import 'dart:async';
import 'dart:convert';

import 'package:floor_plan/models/floor_plan_document.dart';
import 'package:floor_plan/providers/urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final floorPlanCollaborationProvider = StateNotifierProvider.autoDispose
    .family<FloorPlanCollaborationNotifier, FloorPlanCollaborationState, String>(
  (ref, projectId) {
    return FloorPlanCollaborationNotifier(
      ref: ref,
      projectId: projectId,
    );
  },
);

@immutable
class FloorPlanCollaborationState {
  final String projectId;
  final bool hasStarted;
  final bool isConnecting;
  final bool isConnected;
  final bool isSavingVersion;
  final String? error;

  final int revision;
  final int documentEventSerial;
  final int saveEventSerial;

  final String? lastDocumentEventType;
  final FloorPlanDocument? remoteDocument;

  final int? lastSavedVersionNumber;

  final Map<int, FloorPlanLiveUser> users;
  final List<FloorPlanLiveLock> locks;
  final FloorPlanLiveUser? currentUser;

  const FloorPlanCollaborationState({
    required this.projectId,
    this.hasStarted = false,
    this.isConnecting = false,
    this.isConnected = false,
    this.isSavingVersion = false,
    this.error,
    this.revision = 0,
    this.documentEventSerial = 0,
    this.saveEventSerial = 0,
    this.lastDocumentEventType,
    this.remoteDocument,
    this.lastSavedVersionNumber,
    this.users = const {},
    this.locks = const [],
    this.currentUser,
  });

  factory FloorPlanCollaborationState.initial(String projectId) {
    return FloorPlanCollaborationState(projectId: projectId);
  }

  FloorPlanCollaborationState copyWith({
    bool? hasStarted,
    bool? isConnecting,
    bool? isConnected,
    bool? isSavingVersion,
    String? error,
    bool clearError = false,
    int? revision,
    int? documentEventSerial,
    int? saveEventSerial,
    String? lastDocumentEventType,
    FloorPlanDocument? remoteDocument,
    int? lastSavedVersionNumber,
    Map<int, FloorPlanLiveUser>? users,
    List<FloorPlanLiveLock>? locks,
    FloorPlanLiveUser? currentUser,
  }) {
    return FloorPlanCollaborationState(
      projectId: projectId,
      hasStarted: hasStarted ?? this.hasStarted,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      isSavingVersion: isSavingVersion ?? this.isSavingVersion,
      error: clearError ? null : error ?? this.error,
      revision: revision ?? this.revision,
      documentEventSerial: documentEventSerial ?? this.documentEventSerial,
      saveEventSerial: saveEventSerial ?? this.saveEventSerial,
      lastDocumentEventType:
          lastDocumentEventType ?? this.lastDocumentEventType,
      remoteDocument: remoteDocument ?? this.remoteDocument,
      lastSavedVersionNumber:
          lastSavedVersionNumber ?? this.lastSavedVersionNumber,
      users: users ?? this.users,
      locks: locks ?? this.locks,
      currentUser: currentUser ?? this.currentUser,
    );
  }

  FloorPlanLiveLock? lockFor({
    required String objectType,
    required String objectId,
  }) {
    final key = '$objectType:$objectId';

    for (final lock in locks) {
      if (lock.key == key) return lock;
    }

    return null;
  }

  bool isLockedByOther({
    required String objectType,
    required String objectId,
  }) {
    final lock = lockFor(
      objectType: objectType,
      objectId: objectId,
    );

    if (lock == null) return false;

    final currentUserId = currentUser?.id;
    final lockedById = lock.lockedBy?.id;

    if (currentUserId == null || currentUserId == 0) return true;
    if (lockedById == null || lockedById == 0) return true;

    return lockedById != currentUserId;
  }

  String? lockOwnerLabel({
    required String objectType,
    required String objectId,
  }) {
    final lock = lockFor(
      objectType: objectType,
      objectId: objectId,
    );

    final user = lock?.lockedBy;
    if (user == null) return null;

    if (user.displayName.isNotEmpty) return user.displayName;
    if (user.username.isNotEmpty) return user.username;
    if (user.email.isNotEmpty) return user.email;

    return 'Inny użytkownik';
  }
}

@immutable
class FloorPlanLiveUser {
  final int id;
  final String username;
  final String email;
  final String displayName;

  const FloorPlanLiveUser({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
  });

  factory FloorPlanLiveUser.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];

    return FloorPlanLiveUser(
      id: idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['display_name']?.toString() ??
          json['username']?.toString() ??
          json['email']?.toString() ??
          '',
    );
  }
}

@immutable
class FloorPlanLiveLock {
  final String objectType;
  final String objectId;
  final FloorPlanLiveUser? lockedBy;
  final DateTime? expiresAt;

  const FloorPlanLiveLock({
    required this.objectType,
    required this.objectId,
    this.lockedBy,
    this.expiresAt,
  });

  factory FloorPlanLiveLock.fromJson(Map<String, dynamic> json) {
    final lockedByRaw = json['locked_by'];
    final expiresRaw = json['expires_at']?.toString();

    return FloorPlanLiveLock(
      objectType: json['object_type']?.toString() ?? '',
      objectId: json['object_id']?.toString() ?? '',
      lockedBy: lockedByRaw is Map
          ? FloorPlanLiveUser.fromJson(Map<String, dynamic>.from(lockedByRaw))
          : null,
      expiresAt: expiresRaw == null ? null : DateTime.tryParse(expiresRaw),
    );
  }

  String get key => '$objectType:$objectId';
}

class FloorPlanCollaborationNotifier
    extends StateNotifier<FloorPlanCollaborationState> {
  final Ref ref;
  final String projectId;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  Timer? _documentDebounce;
  FloorPlanDocument? _pendingDocument;

  Completer<void>? _pendingSaveCompleter;

  FloorPlanCollaborationNotifier({
    required this.ref,
    required this.projectId,
  }) : super(FloorPlanCollaborationState.initial(projectId));

  Future<void> connect() async {
    if (state.isConnected || state.isConnecting) return;

    state = state.copyWith(
      hasStarted: true,
      isConnecting: true,
      isConnected: false,
      clearError: true,
    );

    try {
      final token = await SecureStorage().getToken();

      if (token == null || token.trim().isEmpty) {
        throw Exception('missing_auth_token_error'.tr);
      }

      final uri = URLsFloorPlan.floorPlanWebSocketUri(
        projectId: projectId,
        token: token,
      );

      debugPrint('[FloorPlanLive] connecting -> $uri');

      final channel = WebSocketChannel.connect(uri);
      _channel = channel;

      _subscription = channel.stream.listen(
        _handleRawMessage,
        onError: (error, stack) {
          debugPrint('[FloorPlanLive] socket error: $error\n$stack');

          _failPendingSave(Exception(error.toString()));

          state = state.copyWith(
            isConnected: false,
            isConnecting: false,
            isSavingVersion: false,
            error: error.toString(),
          );
        },
        onDone: () {
          debugPrint('[FloorPlanLive] socket closed');

          _failPendingSave(Exception('websocket_disconnected_error'.tr));

          state = state.copyWith(
            isConnected: false,
            isConnecting: false,
            isSavingVersion: false,
          );
        },
        cancelOnError: false,
      );
    } catch (e, stack) {
      debugPrint('[FloorPlanLive] connect error: $e\n$stack');

      _failPendingSave(Exception(e.toString()));

      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        isSavingVersion: false,
        error: e.toString(),
      );
    }
  }

  void queueDocumentReplace(FloorPlanDocument document) {
    _pendingDocument = document;

    _documentDebounce?.cancel();
    _documentDebounce = Timer(
      const Duration(milliseconds: 350),
      () {
        final pending = _pendingDocument;
        if (pending == null) return;

        _pendingDocument = null;
        sendDocumentReplace(pending);
      },
    );
  }

  void sendDocumentReplace(FloorPlanDocument document) {
    if (!state.isConnected) return;

    _send({
      'type': 'document.replace',
      'base_revision': state.revision,
      'client_action_id': 'flutter_${DateTime.now().microsecondsSinceEpoch}',
      'document': document.toJson(),
    });
  }

  Future<void> saveVersion(
    FloorPlanDocument document, {
    String changeNote = 'Manual save from Flutter Floor Plan Builder',
  }) async {
    if (!state.isConnected) {
      throw Exception('Live connection is not active.');
    }

    if (_pendingSaveCompleter != null &&
        !_pendingSaveCompleter!.isCompleted) {
      return _pendingSaveCompleter!.future;
    }

    final completer = Completer<void>();
    _pendingSaveCompleter = completer;

    state = state.copyWith(
      isSavingVersion: true,
      clearError: true,
    );

    _send({
      'type': 'save.version',
      'document': document.toJson(),
      'change_note': changeNote,
      'metadata': {
        'saved_from': 'flutter_live_toolbar',
      },
    });

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _pendingSaveCompleter = null;

        state = state.copyWith(
          isSavingVersion: false,
          error: 'save_timeout_error'.tr,
        );

        throw TimeoutException('save_timeout_error'.tr);
      },
    );
  }

  void acquireLock({
    required String objectType,
    required String objectId,
  }) {
    if (!state.isConnected) return;

    _send({
      'type': 'lock.acquire',
      'object_type': objectType,
      'object_id': objectId,
    });
  }

  void releaseLock({
    required String objectType,
    required String objectId,
  }) {
    if (!state.isConnected) return;

    _send({
      'type': 'lock.release',
      'object_type': objectType,
      'object_id': objectId,
    });
  }

  void sendCursorUpdate({
    required double x,
    required double y,
  }) {
    if (!state.isConnected) return;

    _send({
      'type': 'cursor.update',
      'position': {
        'x': x,
        'y': y,
      },
    });
  }

  void sendSelectionUpdate(Map<String, dynamic> selection) {
    if (!state.isConnected) return;

    _send({
      'type': 'selection.update',
      'selection': selection,
    });
  }

  void _send(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (e, stack) {
      debugPrint('[FloorPlanLive] send error: $e\n$stack');

      state = state.copyWith(
        error: e.toString(),
      );
    }
  }

  void _handleRawMessage(dynamic raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;

      if (decoded is! Map) return;

      final event = Map<String, dynamic>.from(decoded);
      _handleEvent(event);
    } catch (e, stack) {
      debugPrint('[FloorPlanLive] parse error: $e\n$stack');

      state = state.copyWith(
        error: e.toString(),
      );
    }
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString();

    switch (type) {
      case 'state.initial':
        _handleInitialState(event);
        return;

      case 'document.updated':
        _handleDocumentUpdated(event);
        return;

      case 'version.saved':
        _handleVersionSaved(event);
        return;

      case 'user.joined':
        _handleUserJoined(event);
        return;

      case 'user.left':
        _handleUserLeft(event);
        return;

      case 'lock.acquired':
        _handleLockAcquired(event);
        return;

      case 'lock.released':
        _handleLockReleased(event);
        return;

      case 'lock.denied':
        state = state.copyWith(
          error: 'element_locked_by_other_error'.tr,
        );
        return;

      case 'error':
        state = state.copyWith(
          error: event['message']?.toString() ?? 'unknown_live_error'.tr,
        );
        return;

      case 'pong':
        return;

      default:
        return;
    }
  }

  void _handleInitialState(Map<String, dynamic> event) {
    final document = _documentFromEvent(event['document']);
    final revision = _intFrom(event['revision']);

    final locksRaw = event['locks'];
    final locks = locksRaw is List
        ? locksRaw
            .whereType<Map>()
            .map(
              (item) => FloorPlanLiveLock.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <FloorPlanLiveLock>[];

    final userRaw = event['user'];
    final users = Map<int, FloorPlanLiveUser>.from(state.users);

    FloorPlanLiveUser? currentUser;

    if (userRaw is Map) {
      final user = FloorPlanLiveUser.fromJson(
        Map<String, dynamic>.from(userRaw),
      );

      if (user.id != 0) {
        users[user.id] = user;
        currentUser = user;
      }
    }

    state = state.copyWith(
      isConnected: true,
      isConnecting: false,
      revision: revision,
      remoteDocument: document,
      lastDocumentEventType: 'state.initial',
      documentEventSerial: state.documentEventSerial + 1,
      locks: locks,
      users: users,
      currentUser: currentUser,
      clearError: true,
    );
  }

  void _handleDocumentUpdated(Map<String, dynamic> event) {
    final document = _documentFromEvent(event['document']);
    final revision = _intFrom(event['revision']);

    state = state.copyWith(
      isConnected: true,
      isConnecting: false,
      revision: revision,
      remoteDocument: document,
      lastDocumentEventType: 'document.updated',
      documentEventSerial: state.documentEventSerial + 1,
      clearError: true,
    );
  }

  void _handleVersionSaved(Map<String, dynamic> event) {
    final versionRaw = event['version'];
    int? versionNumber;

    if (versionRaw is Map) {
      versionNumber = _intFrom(versionRaw['version_number']);
    }

    state = state.copyWith(
      isSavingVersion: false,
      saveEventSerial: state.saveEventSerial + 1,
      lastSavedVersionNumber: versionNumber ?? state.lastSavedVersionNumber,
      clearError: true,
    );

    final completer = _pendingSaveCompleter;
    _pendingSaveCompleter = null;

    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _handleUserJoined(Map<String, dynamic> event) {
    final raw = event['user'];
    if (raw is! Map) return;

    final user = FloorPlanLiveUser.fromJson(
      Map<String, dynamic>.from(raw),
    );

    if (user.id == 0) return;

    state = state.copyWith(
      users: {
        ...state.users,
        user.id: user,
      },
    );
  }

  void _handleUserLeft(Map<String, dynamic> event) {
    final raw = event['user'];
    if (raw is! Map) return;

    final user = FloorPlanLiveUser.fromJson(
      Map<String, dynamic>.from(raw),
    );

    final users = Map<int, FloorPlanLiveUser>.from(state.users);
    users.remove(user.id);

    state = state.copyWith(users: users);
  }

  void _handleLockAcquired(Map<String, dynamic> event) {
    final lock = FloorPlanLiveLock.fromJson(event);

    final next = [
      ...state.locks.where((item) => item.key != lock.key),
      lock,
    ];

    state = state.copyWith(locks: next);
  }

  void _handleLockReleased(Map<String, dynamic> event) {
    final objectType = event['object_type']?.toString() ?? '';
    final objectId = event['object_id']?.toString() ?? '';
    final key = '$objectType:$objectId';

    state = state.copyWith(
      locks: state.locks.where((item) => item.key != key).toList(),
    );
  }

  FloorPlanDocument _documentFromEvent(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return FloorPlanDocument.fromJson(raw);
    }

    if (raw is Map) {
      return FloorPlanDocument.fromJson(Map<String, dynamic>.from(raw));
    }

    return FloorPlanDocument.empty();
  }

  int _intFrom(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _failPendingSave(Object error) {
    final completer = _pendingSaveCompleter;
    _pendingSaveCompleter = null;

    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
  }

  Future<void> disconnect() async {
    _documentDebounce?.cancel();
    _documentDebounce = null;
    _pendingDocument = null;

    _failPendingSave(Exception('Disconnected.'));

    await _subscription?.cancel();
    _subscription = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}

    _channel = null;

    state = state.copyWith(
      isConnected: false,
      isConnecting: false,
      isSavingVersion: false,
    );
  }

  @override
  void dispose() {
    _documentDebounce?.cancel();
    unawaited(_subscription?.cancel());

    _failPendingSave(Exception('Disposed.'));

    try {
      _channel?.sink.close();
    } catch (_) {}

    super.dispose();
  }
}