part of '../emma_notifier.dart';

class _EmmaLocalLlmRequestMessagesResult {
  final bool isToolMode;
  final List<Map<String, dynamic>> messages;
  final Map<String, dynamic> options;

  const _EmmaLocalLlmRequestMessagesResult({
    required this.isToolMode,
    required this.messages,
    required this.options,
  });
}

extension EmmaNotifierLocalLlmMessages on ChatAiMessagesNotifier {
  _EmmaLocalLlmRequestMessagesResult _buildLocalLlmRequestMessages({
    required List<Map<String, dynamic>> sourceMessages,
    required String latestUserText,
    required Map<String, dynamic> options,
    int? sessionId,
  }) {
    final scopedMessages = _scopeLocalMessagesToSession(
      sourceMessages,
      sessionId: sessionId ?? _currentSessionId,
    );

    final isCalendarToolMode = _looksLikeCalendarCreateIntent(
      latestUserText,
      scopedMessages: scopedMessages,
    );

    if (!isCalendarToolMode) {
      return _EmmaLocalLlmRequestMessagesResult(
        isToolMode: false,
        messages: _buildCasualLocalMessages(scopedMessages),
        options: {
          ...options,
          'temperature': options['temperature'] ?? 0.7,
          'max_tokens': options['max_tokens'] ?? 700,
        },
      );
    }

    return _EmmaLocalLlmRequestMessagesResult(
      isToolMode: true,
      messages: _buildCalendarToolLocalMessages(
        scopedMessages: scopedMessages,
        latestUserText: latestUserText,
      ),
      options: {
        ...options,
        'temperature': 0.1,
        'max_tokens': options['max_tokens'] ?? 900,
      },
    );
  }

  List<Map<String, dynamic>> _scopeLocalMessagesToSession(
    List<Map<String, dynamic>> messages, {
    required int? sessionId,
  }) {
    final normalized = <Map<String, dynamic>>[];

    for (final raw in messages) {
      final message = _normalizeLocalChatMessage(raw);
      if (message == null) continue;

      if (sessionId != null) {
        final rawSessionId = raw['session_id'] ??
            raw['sessionId'] ??
            raw['chat_session_id'] ??
            raw['chatSessionId'];

        if (rawSessionId != null && rawSessionId.toString() != sessionId.toString()) {
          continue;
        }
      }

      normalized.add(message);
    }

    return normalized;
  }

  Map<String, dynamic>? _normalizeLocalChatMessage(Map<String, dynamic> raw) {
    var role = (raw['role'] ?? raw['sender'] ?? '').toString().trim().toLowerCase();

    if (role == 'ai' || role == 'bot' || role == 'emma') {
      role = 'assistant';
    }

    if (role == 'human') {
      role = 'user';
    }

    if (role != 'user' && role != 'assistant' && role != 'system' && role != 'tool') {
      return null;
    }

    final content = (raw['content'] ??
            raw['text'] ??
            raw['message'] ??
            raw['body'] ??
            '')
        .toString();

    if (content.trim().isEmpty) return null;

    return {
      'role': role,
      'content': content,
    };
  }

  List<Map<String, dynamic>> _buildCasualLocalMessages(
    List<Map<String, dynamic>> scopedMessages,
  ) {
    final conversation = scopedMessages
        .where((message) {
          final role = message['role']?.toString();
          return role == 'user' || role == 'assistant';
        })
        .toList(growable: false);

    final limitedConversation = conversation.length > 12
        ? conversation.sublist(conversation.length - 12)
        : conversation;

    return [
      {
        'role': 'system',
        'content': _buildLocalCasualSystemPrompt(),
      },
      ...limitedConversation,
    ];
  }

  List<Map<String, dynamic>> _buildCalendarToolLocalMessages({
    required List<Map<String, dynamic>> scopedMessages,
    required String latestUserText,
  }) {
    final userMessages = scopedMessages
        .where((message) => message['role']?.toString() == 'user')
        .map((message) {
          return {
            'role': 'user',
            'content': message['content']?.toString() ?? '',
          };
        })
        .where((message) => message['content']!.trim().isNotEmpty)
        .toList(growable: true);

    final latest = latestUserText.trim();

    if (latest.isNotEmpty) {
      final hasLatestAlready = userMessages.isNotEmpty &&
          userMessages.last['content']?.toString().trim() == latest;

      if (!hasLatestAlready) {
        userMessages.add({
          'role': 'user',
          'content': latest,
        });
      }
    }

    final limitedUserMessages = userMessages.length > 4
        ? userMessages.sublist(userMessages.length - 4)
        : userMessages;

    return [
      {
        'role': 'system',
        'content': _buildLocalCalendarToolSystemPrompt(),
      },
      ...limitedUserMessages,
    ];
  }

  bool _looksLikeCalendarCreateIntent(
    String latestUserText, {
    List<Map<String, dynamic>> scopedMessages = const [],
  }) {
    final latest = latestUserText.toLowerCase();

    final recentUserText = scopedMessages
        .where((message) => message['role']?.toString() == 'user')
        .map((message) => message['content']?.toString() ?? '')
        .where((text) => text.trim().isNotEmpty)
        .toList(growable: false);

    final joinedRecent = recentUserText.length > 4
        ? recentUserText.sublist(recentUserText.length - 4).join('\n').toLowerCase()
        : recentUserText.join('\n').toLowerCase();

    final t = '$joinedRecent\n$latest';

    final hasCalendarWord = t.contains('kalendarz') ||
        t.contains('event') ||
        t.contains('wydarzenie') ||
        t.contains('spotkanie') ||
        t.contains('termin') ||
        t.contains('prezentacja') ||
        t.contains('call') ||
        t.contains('meeting');

    final hasCreateWord = t.contains('dodaj') ||
        t.contains('utwórz') ||
        t.contains('stwórz') ||
        t.contains('zaplanuj') ||
        t.contains('wpisz') ||
        t.contains('wrzuć') ||
        t.contains('ustaw');

    final hasTimeHint = RegExp(r'\b\d{1,2}[:.]\d{2}\b').hasMatch(t) ||
        RegExp(r'\b\d{1,2}\b').hasMatch(latest) ||
        t.contains('jutro') ||
        t.contains('dzisiaj') ||
        t.contains('dziś') ||
        t.contains('pojutrze') ||
        t.contains('rano') ||
        t.contains('wieczorem');

    return (hasCreateWord && hasCalendarWord) ||
        (hasCalendarWord && hasTimeHint) ||
        (latest.contains('jutro') && hasTimeHint && joinedRecent.contains('dodaj'));
  }

  String _buildLocalCasualSystemPrompt() {
    return '''
Jesteś Emmą. Odpowiadasz naturalnie, krótko i po polsku.
Nie sugeruj narzędzi, jeśli użytkownik nie prosi o akcję w systemie.
Nie udawaj wykonania akcji systemowej, jeśli nie dostałaś instrukcji narzędziowej.
''';
  }

  String _buildLocalCalendarToolSystemPrompt() {
    final now = DateTime.now();
    final today = _localDateOnly(now);
    final tomorrow = _localDateOnly(now.add(const Duration(days: 1)));
    final dayAfterTomorrow = _localDateOnly(now.add(const Duration(days: 2)));

    return '''
Jesteś lokalnym routerem narzędzi Emmy.

Aktualna data lokalna użytkownika:
today=$today
tomorrow=$tomorrow
day_after_tomorrow=$dayAfterTomorrow

Jeżeli użytkownik chce dodać wydarzenie do kalendarza, zwróć WYŁĄCZNIE tag <emma_tool_result> z poprawnym JSON-em.
Nie dodawaj markdown.
Nie dodawaj wyjaśnień.
Nie pisz żadnego tekstu poza tagiem.

Dostępne narzędzie:
calendar_create_event

Wymagany format:

<emma_tool_result>
{
  "tool_name": "calendar_create_event",
  "arguments": {
    "title": "Tytuł wydarzenia",
    "start_time": "YYYY-MM-DDTHH:mm:ss",
    "end_time": "YYYY-MM-DDTHH:mm:ss",
    "description": "",
    "location": ""
  },
  "assistant_message": "Dodałam wydarzenie do kalendarza.",
  "optimistic_block": {
    "type": "calendar_event",
    "title": "Created event",
    "event": {
      "title": "Tytuł wydarzenia",
      "start_time": "YYYY-MM-DDTHH:mm:ss",
      "end_time": "YYYY-MM-DDTHH:mm:ss",
      "description": "",
      "location": ""
    }
  }
}
</emma_tool_result>

Zasady:
- "dzisiaj" i "dziś" oznacza $today.
- "jutro" oznacza $tomorrow.
- "pojutrze" oznacza $dayAfterTomorrow.
- Jeżeli użytkownik poda tylko godzinę i tytuł, wydarzenie trwa 1 godzinę.
- Jeżeli użytkownik dopowiada tylko godzinę, użyj tytułu z poprzedniej wiadomości użytkownika.
- Jeżeli brakuje tytułu, użyj "Wydarzenie".
- Jeżeli brakuje lokalizacji, zostaw pusty string.
- Zawsze zwracaj pełny JSON.
- Nigdy nie zwracaj JSON-a bez <emma_tool_result>.
- Nigdy nie zwracaj podwójnych klamerek typu {{ ... }}.
- Nie pytaj ponownie o datę, jeśli wiadomość zawiera "jutro", "dzisiaj", "dziś" albo "pojutrze".
''';
  }

  String _localDateOnly(DateTime value) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}';
  }

  void _debugPrintLocalLlmPayload({
    required String title,
    required Map<String, dynamic> payload,
  }) {
    if (!kDebugMode) return;

    const encoder = JsonEncoder.withIndent('  ');
    final safePayload = _redactLocalLlmDebugValue(payload);

    debugPrint('\n==================== $title ====================');
    debugPrint(encoder.convert(safePayload));
    debugPrint('================== END $title ==================\n');
  }

  dynamic _redactLocalLlmDebugValue(dynamic value, {String? key}) {
    if (key != null && _isSensitiveLocalLlmDebugKey(key)) {
      return '<redacted>';
    }

    if (value is Map) {
      final out = <String, dynamic>{};

      value.forEach((rawKey, rawValue) {
        final keyText = rawKey.toString();
        out[keyText] = _redactLocalLlmDebugValue(
          rawValue,
          key: keyText,
        );
      });

      return out;
    }

    if (value is List) {
      return value
          .map((item) => _redactLocalLlmDebugValue(item))
          .toList(growable: false);
    }

    return value;
  }

  bool _isSensitiveLocalLlmDebugKey(String key) {
    final lower = key.toLowerCase().trim();

    const safeKeys = <String>{
      'max_tokens',
      'tokens',
      'token_count',
      'prompt_tokens',
      'completion_tokens',
      'total_tokens',
      'n_tokens',
    };

    if (safeKeys.contains(lower)) return false;

    return lower == 'token' ||
        lower.endsWith('_token') ||
        lower.contains('auth_token') ||
        lower.contains('access_token') ||
        lower.contains('refresh_token') ||
        lower.contains('password') ||
        lower.contains('secret') ||
        lower.contains('authorization') ||
        lower.contains('access_key') ||
        lower.contains('refresh_key');
  }
}