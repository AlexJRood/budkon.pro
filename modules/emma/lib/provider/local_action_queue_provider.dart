import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EmmaActionPolicy {
  queue,
  replace,
}

extension EmmaActionPolicyX on EmmaActionPolicy {
  String get apiValue {
    switch (this) {
      case EmmaActionPolicy.queue:
        return 'queue';
      case EmmaActionPolicy.replace:
        return 'replace';
    }
  }

  bool get isQueue => this == EmmaActionPolicy.queue;
  bool get isReplace => this == EmmaActionPolicy.replace;
}

enum EmmaActionKind {
  llm,
  stt,
  tts,
  talk,
  modelChange,
}

typedef EmmaLocalActionRun = Future<void> Function();
typedef EmmaLocalActionCancel = Future<void> Function();

@immutable
class EmmaLocalQueuedAction {
  final String id;
  final EmmaActionKind kind;
  final EmmaActionPolicy policy;
  final String label;
  final EmmaLocalActionRun run;
  final EmmaLocalActionCancel? cancel;

  const EmmaLocalQueuedAction({
    required this.id,
    required this.kind,
    required this.policy,
    required this.label,
    required this.run,
    this.cancel,
  });
}

@immutable
class EmmaLocalActionQueueState {
  final bool running;
  final String? activeJobId;
  final EmmaActionKind? activeKind;
  final String activeLabel;
  final int queuedCount;
  final String? lastError;

  const EmmaLocalActionQueueState({
    required this.running,
    required this.activeJobId,
    required this.activeKind,
    required this.activeLabel,
    required this.queuedCount,
    this.lastError,
  });

  factory EmmaLocalActionQueueState.initial() {
    return const EmmaLocalActionQueueState(
      running: false,
      activeJobId: null,
      activeKind: null,
      activeLabel: '',
      queuedCount: 0,
      lastError: null,
    );
  }

  EmmaLocalActionQueueState copyWith({
    bool? running,
    String? activeJobId,
    EmmaActionKind? activeKind,
    String? activeLabel,
    int? queuedCount,
    String? lastError,
    bool clearActive = false,
    bool clearError = false,
  }) {
    return EmmaLocalActionQueueState(
      running: running ?? this.running,
      activeJobId: clearActive ? null : activeJobId ?? this.activeJobId,
      activeKind: clearActive ? null : activeKind ?? this.activeKind,
      activeLabel: clearActive ? '' : activeLabel ?? this.activeLabel,
      queuedCount: queuedCount ?? this.queuedCount,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}

final emmaLocalActionQueueProvider = StateNotifierProvider<
    EmmaLocalActionQueueNotifier, EmmaLocalActionQueueState>((ref) {
  return EmmaLocalActionQueueNotifier();
});

class EmmaLocalActionQueueNotifier
    extends StateNotifier<EmmaLocalActionQueueState> {
  EmmaLocalActionQueueNotifier() : super(EmmaLocalActionQueueState.initial());

  final Queue<EmmaLocalQueuedAction> _queue = Queue<EmmaLocalQueuedAction>();

  EmmaLocalQueuedAction? _activeAction;
  int _generation = 0;
  bool _draining = false;

  Future<void> submit(EmmaLocalQueuedAction action) async {
    if (action.policy == EmmaActionPolicy.replace) {
      await cancelActiveAndClearQueue();

      _queue.addFirst(action);

      state = state.copyWith(
        queuedCount: _queue.length,
        clearError: true,
      );

      unawaited(_drain());
      return;
    }

    _queue.addLast(action);

    state = state.copyWith(
      queuedCount: _queue.length,
      clearError: true,
    );

    unawaited(_drain());
  }

  Future<void> cancelActiveAndClearQueue() async {
    _generation++;

    final active = _activeAction;
    _activeAction = null;
    _queue.clear();

    state = state.copyWith(
      running: false,
      queuedCount: 0,
      clearActive: true,
    );

    if (active?.cancel != null) {
      try {
        await active!.cancel!();
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint('Emma local action cancel failed: $error\n$stack');
        }
      }
    }
  }

  Future<void> clearQueueOnly() async {
    _queue.clear();

    state = state.copyWith(
      queuedCount: 0,
    );
  }

  Future<void> _drain() async {
    if (_draining) return;

    _draining = true;

    try {
      while (_queue.isNotEmpty) {
        final action = _queue.removeFirst();
        final jobGeneration = _generation;

        _activeAction = action;

        state = state.copyWith(
          running: true,
          activeJobId: action.id,
          activeKind: action.kind,
          activeLabel: action.label,
          queuedCount: _queue.length,
          clearError: true,
        );

        try {
          await action.run();

          if (jobGeneration != _generation) {
            continue;
          }
        } catch (error, stack) {
          if (kDebugMode) {
            debugPrint('Emma local action failed: $error\n$stack');
          }

          if (jobGeneration == _generation) {
            state = state.copyWith(
              lastError: error.toString(),
            );
          }
        } finally {
          if (jobGeneration == _generation) {
            _activeAction = null;

            state = state.copyWith(
              running: false,
              queuedCount: _queue.length,
              clearActive: true,
            );
          }
        }
      }
    } finally {
      _draining = false;
    }
  }
}