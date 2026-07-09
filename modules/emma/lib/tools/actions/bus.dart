// lib/emma/tools/actions/bus.dart
import 'dart:collection';

import 'package:emma/tools/actions/action.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class EmmaFrontendActionBusState {
  final List<EmmaFrontendAction> queue;
  const EmmaFrontendActionBusState(this.queue);

  bool get hasActions => queue.isNotEmpty;
  EmmaFrontendAction? get first => queue.isEmpty ? null : queue.first;

  EmmaFrontendActionBusState copyWith({List<EmmaFrontendAction>? queue}) =>
      EmmaFrontendActionBusState(queue ?? this.queue);
}

class EmmaFrontendActionBusNotifier
    extends StateNotifier<EmmaFrontendActionBusState> {
  final Queue<EmmaFrontendAction> _q = Queue();

  EmmaFrontendActionBusNotifier() : super(const EmmaFrontendActionBusState([]));

  void enqueue(EmmaFrontendAction a) {
    _q.addLast(a);
    _sync();
  }

  void enqueueAll(List<EmmaFrontendAction> items) {
    for (final a in items) {
      _q.addLast(a);
    }
    _sync();
  }

  EmmaFrontendAction? pop() {
    if (_q.isEmpty) return null;
    final a = _q.removeFirst();
    _sync();
    return a;
  }

  void clear() {
    _q.clear();
    _sync();
  }

  void _sync() {
    state = state.copyWith(queue: List<EmmaFrontendAction>.unmodifiable(_q));
  }
}

final emmaFrontendActionBusProvider = StateNotifierProvider<
    EmmaFrontendActionBusNotifier, EmmaFrontendActionBusState>((ref) {
  return EmmaFrontendActionBusNotifier();
});
