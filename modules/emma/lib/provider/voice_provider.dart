import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmmaVoicePreset {
  final String id;
  final String label;
  final String shortLabel;
  final String description;
  final String ttsModel;
  final String voice;
  final String language;

  /// Some models, like Chatterbox, handle Polish text better without our
  /// extra normalizer. Piper may still benefit from normalization.
  final bool normalize;

  /// Optional absolute local path to reference voice WAV.
  /// Used by models like Chatterbox / XTTS.
  final String referenceAudioPath;

  const EmmaVoicePreset({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.ttsModel,
    required this.voice,
    required this.language,
    this.normalize = true,
    this.referenceAudioPath = '',
  });

  Map<String, dynamic> toBackendJson() {
    return {
      'id': id,
      'label': label,
      'tts_model': ttsModel,
      'voice': voice,
      'language': language,
      'normalize': normalize,
      'reference_audio_path': referenceAudioPath,
    };
  }
}

const emmaVoicePresets = <EmmaVoicePreset>[
  EmmaVoicePreset(
    id: 'chatterbox-onnx-pl',
    label: 'Chatterbox PL',
    shortLabel: 'CB',
    description: 'Najlepszy lokalny polski głos ONNX dla Emmy.',
    ttsModel: 'chatterbox-onnx-pl',
    voice: 'default',
    language: 'pl',
    normalize: false,
  ),
  EmmaVoicePreset(
    id: 'piper-pl-female',
    label: 'Polski żeński',
    shortLabel: 'Ż',
    description: 'Szybki lokalny polski głos żeński Piper.',
    ttsModel: 'piper-pl-female',
    voice: 'default',
    language: 'pl',
    normalize: true,
  ),
  EmmaVoicePreset(
    id: 'piper-pl-jarvis',
    label: 'Polski Jarvis',
    shortLabel: 'J',
    description: 'Szybki lokalny polski głos Jarvis Piper.',
    ttsModel: 'piper-pl-jarvis',
    voice: 'default',
    language: 'pl',
    normalize: true,
  ),
  EmmaVoicePreset(
    id: 'xtts-v2-pl',
    label: 'XTTS ref',
    shortLabel: 'XTTS',
    description: 'Eksperymentalny głos referencyjny XTTS.',
    ttsModel: 'xtts-v2-pl',
    voice: 'emma_female_ref',
    language: 'pl',
    normalize: false,
  ),
];

final emmaSelectedVoiceProvider = StateProvider<EmmaVoicePreset>((ref) {
  return emmaVoicePresets.first;
});