// emma/model/massage_list.dart

import 'package:emma/model/massage.dart';

class MessageListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<ChatMessageDto> results;

  const MessageListResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory MessageListResponse.fromJson(Map<String, dynamic> json) {
    return MessageListResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((x) => ChatMessageDto.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }
}