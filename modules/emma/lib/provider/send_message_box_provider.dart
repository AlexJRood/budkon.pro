import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// - keeps focus even when UI switches from EmptyChatState -> normal chat view
final emmaChatInputFocusNodeProvider = Provider<FocusNode>((ref) {
  final node = FocusNode(debugLabel: 'emma_chat_input');
  ref.onDispose(node.dispose);
  return node;
});

/// Regexp matching technical tags:
/// @user:xxx, @contact:123, @tx:42
final RegExp mentionRe = RegExp(r'@(user|contact|tx):[A-Za-z0-9\-]+');

/// Controller that highlights mention tags in TextField,
/// but does not change the actual text sent to backend.
class MentionTextController extends TextEditingController {
  MentionTextController({String? text}) : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = value.text;
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final List<InlineSpan> children = [];
    int start = 0;

    for (final match in mentionRe.allMatches(text)) {
      // Normal text before tag
      if (match.start > start) {
        children.add(
          TextSpan(text: text.substring(start, match.start), style: style),
        );
      }

      final full = match.group(0) ?? '';

      // Highlighted tag
      children.add(
        TextSpan(
          text: full,
          style: style?.copyWith(
            fontWeight: FontWeight.w600,
            backgroundColor: Colors.white.withAlpha(26),
          ),
        ),
      );

      start = match.end;
    }

    // Tail text after last tag
    if (start < text.length) {
      children.add(TextSpan(text: text.substring(start), style: style));
    }

    return TextSpan(style: style, children: children);
  }
}

@immutable
class SendMessageBoxUiState {
  final String mentionQuery;
  final int mentionStartIndex;
  final bool showMentions;
  final bool sttStarting;
  final DateTime? sttLastToggleAt;

  /// '@' or '#', depends on trigger
  final String currentTriggerChar;

  final bool sendingNow;

  // ✅ STT
  final int sttEpoch;
  final bool sttReady;
  final bool isListening;

  const SendMessageBoxUiState({
    this.mentionQuery = '',
    this.mentionStartIndex = -1,
    this.showMentions = false,
    this.currentTriggerChar = '',
    this.sendingNow = false,
    this.sttEpoch = 0,
    this.sttReady = false,
    this.isListening = false,
    this.sttLastToggleAt,
    this.sttStarting = false,
  });

  SendMessageBoxUiState copyWith({
    String? mentionQuery,
    int? mentionStartIndex,
    bool? showMentions,
    String? currentTriggerChar,
    bool? sendingNow,
    int? sttEpoch,
    bool? sttReady,
    bool? isListening,
    bool? sttStarting,
    DateTime? sttLastToggleAt,
  }) {
    return SendMessageBoxUiState(
      mentionQuery: mentionQuery ?? this.mentionQuery,
      mentionStartIndex: mentionStartIndex ?? this.mentionStartIndex,
      showMentions: showMentions ?? this.showMentions,
      currentTriggerChar: currentTriggerChar ?? this.currentTriggerChar,
      sendingNow: sendingNow ?? this.sendingNow,
      sttEpoch: sttEpoch ?? this.sttEpoch,
      sttReady: sttReady ?? this.sttReady,
      isListening: isListening ?? this.isListening,
      sttLastToggleAt: sttLastToggleAt ?? this.sttLastToggleAt,
      sttStarting: sttStarting ?? this.sttStarting,
    );
  }
}

class SendMessageBoxUiNotifier extends StateNotifier<SendMessageBoxUiState> {
  SendMessageBoxUiNotifier() : super(const SendMessageBoxUiState());

  void setMentionState({
    required int mentionStartIndex,
    required String mentionQuery,
    required bool showMentions,
    required String currentTriggerChar,
  }) {
    state = state.copyWith(
      mentionStartIndex: mentionStartIndex,
      mentionQuery: mentionQuery,
      showMentions: showMentions,
      currentTriggerChar: currentTriggerChar,
    );
  }

  void setSttStarting(bool v) => state = state.copyWith(sttStarting: v);
  void setSttLastToggleAt(DateTime? v) =>
      state = state.copyWith(sttLastToggleAt: v);

  void hideMentions() {
    if (!state.showMentions) return;
    state = state.copyWith(
      showMentions: false,
      mentionQuery: '',
      mentionStartIndex: -1,
      currentTriggerChar: '',
    );
  }

  void setSendingNow(bool v) {
    if (state.sendingNow == v) return;
    state = state.copyWith(sendingNow: v);
  }

  void setSttReady(bool v) {
    if (state.sttReady == v) return;
    state = state.copyWith(sttReady: v);
  }

  void setIsListening(bool v) {
    if (state.isListening == v) return;
    state = state.copyWith(isListening: v);
  }

  int bumpSttEpoch() {
    final next = state.sttEpoch + 1;
    state = state.copyWith(sttEpoch: next);
    return next;
  }
}

final sendMessageBoxUiProvider =
    StateNotifierProvider<SendMessageBoxUiNotifier, SendMessageBoxUiState>(
      (ref) => SendMessageBoxUiNotifier(),
    );



class EmmaChatDraftsNotifier extends StateNotifier<Map<String, String>> {
  EmmaChatDraftsNotifier() : super(const {});

  static const String emptyDraftKey = '__emma_empty_chat_draft__';

  static String keyForSelectedRoom(String selectedRoom) {
    final value = selectedRoom.trim();

    if (value.isEmpty) {
      return emptyDraftKey;
    }

    return 'session_$value';
  }

  String draftForKey(String key) {
    return state[key] ?? '';
  }

  void setDraftForKey(String key, String text) {
    final current = state[key] ?? '';

    if (current == text) return;

    final next = Map<String, String>.from(state);

    if (text.isEmpty) {
      next.remove(key);
    } else {
      next[key] = text;
    }

    state = next;
  }

  void clearDraftForKey(String key) {
    if (!state.containsKey(key)) return;

    final next = Map<String, String>.from(state)..remove(key);
    state = next;
  }

  void clearAll() {
    state = const {};
  }
}

final emmaChatDraftsProvider =
    StateNotifierProvider<EmmaChatDraftsNotifier, Map<String, String>>(
  (ref) => EmmaChatDraftsNotifier(),
);