import 'package:dio/dio.dart';

import 'superbee_client.dart';

typedef EmmaLocalTextDelta = void Function(String delta);
typedef EmmaLocalAudioChunk = void Function(Map<String, dynamic> chunk);
typedef EmmaLocalDone = void Function(Map<String, dynamic> payload);
typedef EmmaLocalError = void Function(Object error);

class EmmaLocalEngineBridge {
  final SuperbeeLocalEngineClient localEngine;
  final Dio backendDio;
  final String backendBaseUrl;

  EmmaLocalEngineBridge({
    required this.localEngine,
    required this.backendDio,
    required this.backendBaseUrl,
  });

  Future<void> handleLocalJob(
    Map<String, dynamic> job, {
    EmmaLocalTextDelta? onTextDelta,
    EmmaLocalAudioChunk? onAudioChunk,
    EmmaLocalDone? onDone,
    EmmaLocalError? onError,
  }) async {
    final mode = (job['mode'] ?? 'text').toString();

    final sessionId = job['session_id'];
    final assistantMessageId = job['assistant_message_id'];
    final localJobId = (job['local_job_id'] ?? '').toString();
    final callbackUrl = (job['callback_url'] ?? '/emma/chat/local-result/').toString();

    final messages = _listOfMap(job['messages']);
    final options = Map<String, dynamic>.from(job['options'] ?? const {});
    final talk = Map<String, dynamic>.from(job['talk'] ?? const {});
    final meta = Map<String, dynamic>.from(job['meta'] ?? const {});

    final contentBuffer = StringBuffer();
    final thinkingBuffer = StringBuffer();
    final audioChunks = <Map<String, dynamic>>[];

    try {
      final Stream<SuperbeeStreamEvent> stream;

      if (mode == 'talk') {
        stream = localEngine.streamTalk(
          input: _lastUserContent(messages),
          messages: messages,
          llmOptions: options,
          ttsModel: (talk['tts_model'] ?? 'piper-pl-female').toString(),
          voice: (talk['voice'] ?? 'default').toString(),
          language: (talk['language'] ?? 'pl').toString(),
          format: (talk['format'] ?? 'wav').toString(),
          includeThinking: talk['include_thinking'] == true,
          autoLoadTts: talk['auto_load_tts'] != false,
          normalizeTts: talk['normalize_tts'] != false,
        );
      } else {
        stream = localEngine.streamLlmChat(
          messages: messages,
          options: options,
          metadata: {
            ...meta,
            'local_job_id': localJobId,
            'session_id': sessionId,
            'assistant_message_id': assistantMessageId,
          },
        );
      }

      await for (final event in stream) {
        final name = event.event;

        if (name == 'answer_delta' || name == 'llm_answer_delta') {
          contentBuffer.write(event.delta);
          onTextDelta?.call(event.delta);
          continue;
        }

        if (name == 'thinking_delta' || name == 'llm_thinking_delta') {
          thinkingBuffer.write(event.delta);
          continue;
        }

        if (name == 'tts_chunk_ready') {
          final chunk = event.raw;
          audioChunks.add(chunk);
          onAudioChunk?.call(chunk);
          continue;
        }

        if (name == 'done') {
          if (event.content.isNotEmpty) {
            contentBuffer
              ..clear()
              ..write(event.content);
          }

          if (event.thinking.isNotEmpty) {
            thinkingBuffer
              ..clear()
              ..write(event.thinking);
          }

          if (event.audioChunks.isNotEmpty) {
            audioChunks
              ..clear()
              ..addAll(event.audioChunks);
          }

          break;
        }

        if (name == 'error') {
          throw SuperbeeLocalEngineException(
            (event.raw['error'] ?? 'Unknown local engine error').toString(),
          );
        }
      }

      final finalPayload = {
        'session_id': sessionId,
        'assistant_message_id': assistantMessageId,
        'content': contentBuffer.toString().trim(),
        'thinking': thinkingBuffer.toString().trim(),
        'audio_chunks': audioChunks,
        'local_job_id': localJobId,
        'engine': 'superbee',
        'mode': mode,
        'meta': {
          ...meta,
          'local_engine_synced_from_frontend': true,
        },
      };

      await backendDio.post(
        '$backendBaseUrl$callbackUrl',
        data: finalPayload,
      );

      onDone?.call(finalPayload);
    } catch (e) {
      onError?.call(e);

      await backendDio.post(
        '$backendBaseUrl$callbackUrl',
        data: {
          'session_id': sessionId,
          'assistant_message_id': assistantMessageId,
          'content': contentBuffer.toString().trim().isNotEmpty
              ? contentBuffer.toString().trim()
              : 'Wystąpił błąd lokalnego silnika Superbee.',
          'thinking': thinkingBuffer.toString().trim(),
          'audio_chunks': audioChunks,
          'local_job_id': localJobId,
          'engine': 'superbee',
          'mode': mode,
          'meta': {
            ...meta,
            'local_engine_error': e.toString(),
          },
        },
      );
    }
  }

  List<Map<String, dynamic>> _listOfMap(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String _lastUserContent(List<Map<String, dynamic>> messages) {
    for (final message in messages.reversed) {
      if ((message['role'] ?? '').toString() == 'user') {
        return (message['content'] ?? '').toString();
      }
    }

    return '';
  }
}