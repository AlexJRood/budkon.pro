part of '../emma_notifier.dart';

/// Result wrapper for paginated message history requests.
@immutable
class _MessagesPageResult {
  final List<ChatMessageDto> messages;
  final bool hasNext;

  const _MessagesPageResult({
    required this.messages,
    required this.hasNext,
  });
}

/// Normalized NDJSON event emitted by the local Superbee engine.
@immutable
class _LocalEngineStreamEvent {
  final Map<String, dynamic> raw;

  const _LocalEngineStreamEvent(this.raw);

  String get event => (raw['event'] ?? raw['type'] ?? '').toString();

  String get delta => (raw['delta'] ?? '').toString();
}
