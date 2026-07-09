part of '../emma_notifier.dart';

/// Immutable state consumed by Emma chat UI.
///
/// It stores the visible message list, loading/cancel state, optional public
/// thinking payload and a small activity label shown while Emma is working.
@immutable
class ChatAiMessagesState {
  final List<ChatMessageDto> messages;
  final bool isLoading;
  final EmmaThinkingPublic? thinking;
  final bool canCancel;

  final String? activityTitle;
  final String? activityDetail;

  /// True, gdy status „co Emma robi" jest już renderowany jako blok wewnątrz
  /// wiadomości. Pływający bąbelek myślenia jest wtedy ukrywany, żeby ten sam
  /// komunikat nie pojawiał się dwa razy.
  final bool activityInline;

  /// Trwały, widoczny błąd wysyłki (np. brak sieci, cisza backendu). Wcześniej
  /// porażka tylko czyściła stan — użytkownik nie wiedział, że coś poszło źle.
  final String? errorText;

  /// Treść wiadomości, którą można ponowić po błędzie (null = brak retry).
  final String? retryText;

  const ChatAiMessagesState({
    required this.messages,
    this.isLoading = false,
    this.thinking,
    this.canCancel = false,
    this.activityTitle,
    this.activityDetail,
    this.activityInline = false,
    this.errorText,
    this.retryText,
  });

  bool get hasError => (errorText ?? '').trim().isNotEmpty;
  bool get canRetry => (retryText ?? '').trim().isNotEmpty;

  /// Creates a modified copy of this state.
  ///
  /// `clearThinking` and `clearActivity` are explicit because passing `null`
  /// should not accidentally remove existing values.
  ChatAiMessagesState copyWith({
    List<ChatMessageDto>? messages,
    bool? isLoading,
    EmmaThinkingPublic? thinking,
    bool clearThinking = false,
    bool? canCancel,
    String? activityTitle,
    String? activityDetail,
    bool clearActivity = false,
    bool? activityInline,
    String? errorText,
    String? retryText,
    bool clearError = false,
  }) {
    return ChatAiMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      thinking: clearThinking ? null : (thinking ?? this.thinking),
      canCancel: canCancel ?? this.canCancel,
      activityTitle:
          clearActivity ? null : (activityTitle ?? this.activityTitle),
      activityDetail:
          clearActivity ? null : (activityDetail ?? this.activityDetail),
      // Czyszczenie aktywności zawsze resetuje też tryb inline.
      activityInline:
          clearActivity ? false : (activityInline ?? this.activityInline),
      errorText: clearError ? null : (errorText ?? this.errorText),
      retryText: clearError ? null : (retryText ?? this.retryText),
    );
  }
}
