import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:emma/provider/urls.dart';
import 'package:emma/provider/voice_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';

@immutable
class EmmaAudioMessageState {
  final int? playingMessageId;
  final bool isBusy;
  final String? error;
  final String? ttsModel;
  final String? voice;

  const EmmaAudioMessageState({
    this.playingMessageId,
    this.isBusy = false,
    this.error,
    this.ttsModel,
    this.voice,
  });

  EmmaAudioMessageState copyWith({
    int? playingMessageId,
    bool clearPlayingMessageId = false,
    bool? isBusy,
    String? error,
    bool clearError = false,
    String? ttsModel,
    bool clearTtsModel = false,
    String? voice,
    bool clearVoice = false,
  }) {
    return EmmaAudioMessageState(
      playingMessageId:
          clearPlayingMessageId ? null : (playingMessageId ?? this.playingMessageId),
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      ttsModel: clearTtsModel ? null : (ttsModel ?? this.ttsModel),
      voice: clearVoice ? null : (voice ?? this.voice),
    );
  }
}

final emmaAutoReadMessagesProvider = StateProvider<bool>((ref) => false);

final emmaAudioMessageProvider =
    StateNotifierProvider<EmmaAudioMessageNotifier, EmmaAudioMessageState>(
  (ref) => EmmaAudioMessageNotifier(ref: ref),
);

class EmmaAudioMessageNotifier extends StateNotifier<EmmaAudioMessageState> {
  EmmaAudioMessageNotifier({required this.ref})
      : super(const EmmaAudioMessageState());

  final Ref ref;
  final AudioPlayer _player = AudioPlayer();

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}

    state = state.copyWith(
      clearPlayingMessageId: true,
      isBusy: false,
    );
  }

  Future<void> readMessage({
    required int messageId,
    required String text,
    required Map<String, dynamic> meta,
    String? model,
    String? voice,
    String? language,
    bool? normalize,
    String? referenceAudioPath,
  }) async {
    if (kIsWeb) {
      state = state.copyWith(
        isBusy: false,
        clearPlayingMessageId: true,
        error: 'local_reading_disabled_web'.tr,
      );
      return;
    }

    final cleanText = _cleanTextForSpeech(text);

    if (cleanText.isEmpty) {
      state = state.copyWith(
        isBusy: false,
        clearPlayingMessageId: true,
        error: 'no_text_to_read'.tr,
      );
      return;
    }

    if (state.isBusy && state.playingMessageId == messageId) {
      await stop();
      return;
    }

    final selectedVoice = ref.read(emmaSelectedVoiceProvider);

    final ttsModel = (model ?? selectedVoice.ttsModel).trim();
    final ttsVoice = (voice ?? selectedVoice.voice).trim();
    final ttsLanguage = (language ?? selectedVoice.language).trim();
    final ttsNormalize = normalize ?? selectedVoice.normalize;
    final ttsReferenceAudioPath =
        (referenceAudioPath ?? selectedVoice.referenceAudioPath).trim();

    state = state.copyWith(
      playingMessageId: messageId,
      isBusy: true,
      clearError: true,
      ttsModel: ttsModel,
      voice: ttsVoice,
    );

    try {
      await _player.stop();

      final existingUrls = _extractAudioUrls(meta);
      final canUseExistingAudio = _metaAudioMatchesSelectedVoice(
        meta: meta,
        selectedModel: ttsModel,
        selectedVoice: ttsVoice,
      );

      if (existingUrls.isNotEmpty && canUseExistingAudio) {
        await _playUrls(existingUrls, messageId: messageId);
        return;
      }

      final audioUrl = await _synthesizeSpeech(
        text: cleanText,
        model: ttsModel,
        voice: ttsVoice,
        language: ttsLanguage,
        normalize: ttsNormalize,
        referenceAudioPath: ttsReferenceAudioPath,
      );

      if (audioUrl == null || audioUrl.trim().isEmpty) {
        throw StateError('tts_no_audio_url'.tr);
      }

      await _playUrls([audioUrl], messageId: messageId);
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        clearPlayingMessageId: true,
        error: e.toString(),
      );
    }
  }

  Future<String?> _synthesizeSpeech({
    required String text,
    required String model,
    required String voice,
    required String language,
    required bool normalize,
    required String referenceAudioPath,
  }) async {
    final payload = <String, dynamic>{
      'input': text,
      'model': model,
      'voice': voice,
      'language': language,
      'format': 'wav',
      'auto_load': true,
      'normalize': normalize,
    };

    if (referenceAudioPath.trim().isNotEmpty) {
      payload['reference_audio_path'] = referenceAudioPath.trim();
    }

    final response = await ApiServices.post(
      URLsEmma.superbeeTtsSpeech,
      hasToken: false,
      ref: ref,
      data: payload,
    );

    if (response == null) {
      throw StateError('no_response_from_local_tts'.tr);
    }

    if (response.statusCode != 200) {
      throw StateError(
        '${'tts_error_prefix'.tr} ${response.statusCode}: ${response.data}',
      );
    }

    final decoded = _decodeResponseData(response.data);

    if (decoded == null) {
      throw StateError('failed_to_parse_tts_response'.tr);
    }

    final status = (decoded['status'] ?? '').toString();

    if (status.isNotEmpty && status != 'success') {
      throw StateError(
        (decoded['error'] ?? 'tts_non_success_status'.tr).toString(),
      );
    }

    return (decoded['audio_url'] ?? '').toString();
  }

  Future<void> _playUrls(
    List<String> urls, {
    required int messageId,
  }) async {
    for (final url in urls) {
      if (state.playingMessageId != messageId) return;

      final cleanUrl = url.trim();
      if (cleanUrl.isEmpty) continue;

      await _player.stop();
      await _player.play(UrlSource(cleanUrl));

      await _player.onPlayerComplete.first.timeout(
        const Duration(minutes: 5),
        onTimeout: () {},
      );
    }

    if (state.playingMessageId == messageId) {
      state = state.copyWith(
        isBusy: false,
        clearPlayingMessageId: true,
      );
    }
  }

  Map<String, dynamic>? _decodeResponseData(dynamic raw) {
    try {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);

      if (raw is List<int>) {
        final text = utf8.decode(raw);
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }

      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return null;
  }

  bool _metaAudioMatchesSelectedVoice({
    required Map<String, dynamic> meta,
    required String selectedModel,
    required String selectedVoice,
  }) {
    final audioMeta = _collectAudioMeta(meta);

    if (audioMeta.isEmpty) return false;

    final modelCandidates = <String>[
      _readString(audioMeta['model']),
      _readString(audioMeta['tts_model']),
      _readString(audioMeta['ttsModel']),
    ].where((value) => value.isNotEmpty).toList();

    final voiceCandidates = <String>[
      _readString(audioMeta['voice']),
      _readString(audioMeta['tts_voice']),
      _readString(audioMeta['ttsVoice']),
    ].where((value) => value.isNotEmpty).toList();

    if (modelCandidates.isEmpty) {
      return false;
    }

    final modelMatches = modelCandidates.any((value) => value == selectedModel);

    if (!modelMatches) {
      return false;
    }

    if (voiceCandidates.isEmpty) {
      return true;
    }

    return voiceCandidates.any((value) {
      return value == selectedVoice ||
          selectedVoice == 'default' ||
          value == 'default';
    });
  }

  Map<String, dynamic> _collectAudioMeta(Map<String, dynamic> meta) {
    final result = <String, dynamic>{};

    void merge(dynamic value) {
      if (value is Map<String, dynamic>) {
        result.addAll(value);
        return;
      }

      if (value is Map) {
        result.addAll(Map<String, dynamic>.from(value));
      }
    }

    merge(meta);
    merge(meta['audio']);
    merge(meta['talk']);

    return result;
  }

  String _readString(dynamic value) {
    return (value ?? '').toString().trim();
  }

  List<String> _extractAudioUrls(Map<String, dynamic> meta) {
    final urls = <String>[];

    void addUrl(dynamic value) {
      final url = (value ?? '').toString().trim();
      if (url.isEmpty) return;
      if (!urls.contains(url)) urls.add(url);
    }

    addUrl(meta['audio_url']);

    final audio = meta['audio'];
    if (audio is Map) {
      addUrl(audio['audio_url']);
      addUrl(audio['url']);
    }

    final talk = meta['talk'];
    if (talk is Map) {
      addUrl(talk['audio_url']);

      final chunks = talk['audio_chunks'];
      if (chunks is List) {
        for (final item in chunks) {
          if (item is Map) {
            addUrl(item['audio_url']);
            addUrl(item['url']);
          }
        }
      }
    }

    final chunks = meta['audio_chunks'];
    if (chunks is List) {
      for (final item in chunks) {
        if (item is Map) {
          addUrl(item['audio_url']);
          addUrl(item['url']);
        }
      }
    }

    return urls;
  }

  String _cleanTextForSpeech(String value) {
    var text = value.trim();

    if (text.isEmpty) return '';

    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
    text = text.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
    text = text.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    text = text.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
    text = text.replaceAll(RegExp(r'__([^_]+)__'), r'$1');
    text = text.replaceAll(RegExp(r'_([^_]+)_'), r'$1');
    text = text.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');

    text = text.replaceAll(
      RegExp(
        r'[^\p{L}\p{N}\s.,!?;:()\-"ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]',
        unicode: true,
      ),
      ' ',
    );

    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }
}