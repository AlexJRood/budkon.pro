// emma/provider/stt_model_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmmaSttPreset {
  final String id;
  final String label;
  final String shortLabel;
  final String description;
  final String sttModel;
  final String language;

  const EmmaSttPreset({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.sttModel,
    required this.language,
  });

  Map<String, dynamic> toBackendJson() {
    return {
      'id': id,
      'label': label,
      'stt_model': sttModel,
      'language': language,
    };
  }
}

const emmaSttPresets = <EmmaSttPreset>[
  EmmaSttPreset(
    id: 'faster-whisper-small-pl',
    label: 'Whisper Small PL',
    shortLabel: 'S',
    description: 'Szybki lokalny STT. Najlepszy balans jakości i prędkości.',
    sttModel: 'faster-whisper-small-pl',
    language: 'pl',
  ),
  EmmaSttPreset(
    id: 'faster-whisper-base-pl',
    label: 'Whisper Base PL',
    shortLabel: 'B',
    description: 'Lżejszy lokalny STT dla słabszych komputerów.',
    sttModel: 'faster-whisper-base-pl',
    language: 'pl',
  ),
  EmmaSttPreset(
    id: 'faster-whisper-large-v3-turbo',
    label: 'Whisper Turbo',
    shortLabel: 'T',
    description: 'Cięższy i dokładniejszy model STT.',
    sttModel: 'faster-whisper-large-v3-turbo',
    language: 'pl',
  ),
  EmmaSttPreset(
    id: 'mock-stt',
    label: 'Mock STT',
    shortLabel: 'M',
    description: 'Model testowy do debugowania frontu.',
    sttModel: 'mock-stt',
    language: 'pl',
  ),
];

final emmaSelectedSttProvider = StateProvider<EmmaSttPreset>((ref) {
  return emmaSttPresets.first;
});