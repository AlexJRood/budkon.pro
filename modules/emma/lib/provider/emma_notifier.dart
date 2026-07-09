// provider/emma_notifier.dart

import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:emma/model/chat_room.dart';
import 'package:emma/model/massage.dart';
import 'package:emma/model/massage_list.dart';
import 'package:emma/model/thinking.dart';
import 'package:emma/provider/context.dart';
import 'package:emma/provider/emma_provider.dart';
import 'package:emma/provider/local_action_queue_provider.dart';
import 'package:emma/provider/runtime_provider.dart';
import 'package:emma/provider/urls.dart';
import 'package:emma/provider/voice_provider.dart';
import 'package:emma/sync/emma_local_db.dart';
import 'package:emma/sync/emma_local_ids.dart';
import 'package:emma/sync/emma_sync_service.dart';
import 'package:emma/tools/actions/action.dart';
import 'package:emma/tools/actions/bus.dart';
import 'package:emma/tools/actions/parser.dart';
import 'package:core/ui/anchors/anchor_registry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/internet_checker/internet_checker_provider.dart'
    as internet_status;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:core/platform/platforms/ws_connect.dart';

import 'package:emma/provider/send_message_box_provider.dart';
import 'package:emma/library/emma_local_model_manager_provider.dart'
    show emmaLocalEngineTokenProvider;
import 'package:emma/automation/emma_automation_service.dart'
    show emmaAutomationServiceProvider;

part 'emma_notifier/local_helper.dart';
part 'emma_notifier/emma_notifier_local_tool_manifest.dart';
part 'emma_notifier/emma_notifier_local_llm_messages.dart';
part 'emma_notifier/emma_notifier_local_tools_runtime.dart';
part 'emma_notifier/emma_notifier_state.dart';
part 'emma_notifier/emma_notifier_models.dart';
part 'emma_notifier/emma_notifier_text_safety.dart';
part 'emma_notifier/emma_notifier_local_db.dart';
part 'emma_notifier/emma_notifier_history.dart';
part 'emma_notifier/emma_notifier_health.dart';
part 'emma_notifier/emma_notifier_message_ids.dart';
part 'emma_notifier/emma_notifier_message_merge.dart';
part 'emma_notifier/emma_notifier_blocks.dart';
part 'emma_notifier/emma_notifier_audio_meta.dart';
part 'emma_notifier/emma_notifier_seen_reactions.dart';
part 'emma_notifier/emma_notifier_ws.dart';
part 'emma_notifier/emma_notifier_local_engine.dart';
part 'emma_notifier/emma_notifier_send.dart';
part 'emma_notifier/emma_notifier_frontend_actions.dart';
part 'emma_notifier/emma_notifier_lifecycle.dart';
part 'emma_notifier/emma_notifier_session_bootstrap.dart';
part 'emma_notifier/emma_notifier_empty_draft.dart';
part 'emma_notifier/emma_notifier_automation.dart';

/// Main Emma chat notifier.
///
/// This file intentionally keeps only shared state, dependencies and provider
/// registration. The implementation is split into `part` files to keep the
/// notifier maintainable without changing the public API used by the UI.
///
/// The split uses `part` / `part of` because many methods rely on private
/// notifier fields. Keeping everything in one Dart library allows private
/// helpers such as `_currentSessionId`, `_channel`, `_safeText` and
/// `_runOfflineLocalFallback` to remain private.
class ChatAiMessagesNotifier extends StateNotifier<ChatAiMessagesState> {
  final Ref ref;

  ChatAiMessagesNotifier({required this.ref})
      : super(const ChatAiMessagesState(messages: []));

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _wsSubscription;
  Timer? _loadingWatchdog;

  final Dio _localDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: Duration.zero,
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  final AudioPlayer _localTalkPlayer = AudioPlayer();

  /// Queue for local TTS audio playback.
  ///
  /// This is not only a list of URLs because each queued audio chunk can belong
  /// to a different message/job/source.
  final List<_LocalTalkAudioQueueItem> _localTalkAudioQueue =
      <_LocalTalkAudioQueueItem>[];

  Completer<void>? _localTalkAudioStopSignal;

  bool _isDrainingLocalTalkAudio = false;

  /// Generation is incremented whenever local audio/TTS is force-stopped.
  /// Any old drain loop/request should become stale after this value changes.
  int _localTalkAudioGeneration = 0;

  String? _localTalkCurrentAudioUrl;
  int? _localTalkCurrentAudioMessageId;
  int? _localTalkCurrentAudioChunkIndex;
  String? _localTalkCurrentAudioJobId;
  String? _localTalkCurrentAudioSourceMessageId;
  String? _localTalkCurrentAudioSource;
  DateTime? _localTalkCurrentAudioStartedAt;

  /// Active TTS HTTP request cancellation.
  CancelToken? _activeLocalTtsCancelToken;
  String? _activeLocalTtsJobId;

  Map<String, dynamic>? _pendingUserInterruptionMeta;

  int? _currentSessionId;
  bool _isConnected = false;
  bool _isDisposed = false;
  int _sessionConnectGeneration = 0;

  int _seenSentUpToId = 0;
  DateTime? _lastWsEventAt;
  DateTime? _lastCloudAssistantProgressAt;

  int _page = 0;
  bool _hasMore = true;
  bool _isFetchingHistory = false;
  final int _pageSize = 50;

  int _localJobGeneration = 0;
  int _cloudResponseGuardGeneration = 0;
  int _tempAssistantSeq = 0;

  String? _activeLocalJobId;

  final Map<int, int> _misroutedDeltaAssistantIds = <int, int>{};

  String? _pendingTurnClientMessageId;
  int? _pendingTurnUserTempId;
  int? _pendingTurnAssistantId;
  DateTime? _pendingTurnStartedAt;
  String? _pendingTurnUserText;

  final Set<String> _handledFrontendActionKeys = <String>{};
  final Set<String> _finishedBlockIds = <String>{};

  Completer<void>? _wsReadyCompleter;

  static const Set<String> _cloudAssistantProgressEvents = <String>{
    'assistant_tool_plan',
    'tool_plan',
    'assistant_tool_call_started',
    'tool_call_started',
    'assistant_tool_call_finished',
    'tool_call_finished',
    'assistant_block_pending',
    'block_pending',
    'assistant_block_ready',
    'block_ready',
    'assistant_block_error',
    'block_error',
    'ai_thinking',
    'thinking',
    'ai_status',
    'ai_delta',
    'local_llm_job',
  };

  bool get isConnected => _isConnected;
  int? get currentSessionId => _currentSessionId;
  bool get hasMoreHistory => _hasMore;
  bool get isFetchingHistory => _isFetchingHistory;

  bool get _canEmit => mounted && !_isDisposed;

  bool _isActiveGeneration(int generation) {
    return _canEmit && generation == _sessionConnectGeneration;
  }

  bool _isActiveSession(int generation, int sessionId) {
    return _isActiveGeneration(generation) && _currentSessionId == sessionId;
  }

  void _emit(ChatAiMessagesState nextState) {
    if (!_canEmit) return;
    state = nextState;
  }

  void _emitFrom(ChatAiMessagesState Function(ChatAiMessagesState current) build) {
    if (!_canEmit) return;
    state = build(state);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sessionConnectGeneration++;
    _cloudResponseGuardGeneration++;
    _localJobGeneration++;
    _activeLocalJobId = null;

    this._stopLoadingWatchdog();

    unawaited(
      Future<void>(() async {
        await this._stopLocalTalkAudio();
        await this._disconnectInternal();

        try {
          await _localTalkPlayer.dispose();
        } catch (_) {}
      }),
    );

    super.dispose();
  }
}

final chatAiMessageProvider =
    StateNotifierProvider<ChatAiMessagesNotifier, ChatAiMessagesState>(
  (ref) => ChatAiMessagesNotifier(ref: ref),
);