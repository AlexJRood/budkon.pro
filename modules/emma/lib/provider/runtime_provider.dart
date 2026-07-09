import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

enum EmmaRuntimeMode {
  cloud,
  localText,
  localVoice,
}

@immutable
class EmmaRuntimeModeConfig {
  final EmmaRuntimeMode mode;
  final String label;
  final String shortLabel;
  final String description;
  final String backendMode;
  final bool useLocalEngine;
  final bool useTalk;
  final bool voiceEnabled;
  final bool available;

  const EmmaRuntimeModeConfig({
    required this.mode,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.backendMode,
    required this.useLocalEngine,
    required this.useTalk,
    required this.voiceEnabled,
    this.available = true,
  });

  Map<String, dynamic> toBackendContext() {
    return {
      'mode': backendMode,
      'use_local_engine': useLocalEngine,
      'use_talk': useTalk,
      'voice_enabled': voiceEnabled,
      'available': available,
      'is_web': kIsWeb,
      'source': 'emma_appbar_switch',
    };
  }
}

extension EmmaRuntimeModeX on EmmaRuntimeMode {
  bool get isAvailableOnThisPlatform {
    if (kIsWeb) {
      return this == EmmaRuntimeMode.cloud;
    }

    return true;
  }

  EmmaRuntimeModeConfig get config {
    switch (this) {
      case EmmaRuntimeMode.cloud:
        return EmmaRuntimeModeConfig(
          mode: EmmaRuntimeMode.cloud,
          label: 'cloud_mode_label'.tr,
          shortLabel: 'Cloud',
          description: 'cloud_mode_description'.tr,
          backendMode: 'cloud',
          useLocalEngine: false,
          useTalk: false,
          voiceEnabled: false,
          available: isAvailableOnThisPlatform,
        );

      case EmmaRuntimeMode.localText:
        return EmmaRuntimeModeConfig(
          mode: EmmaRuntimeMode.localText,
          label: 'local_mode_label'.tr,
          shortLabel: 'Local',
          description: kIsWeb
              ? 'local_engine_blocked_web'.tr
              : 'local_mode_description'.tr,
          backendMode: 'local_text',
          useLocalEngine: !kIsWeb,
          useTalk: false,
          voiceEnabled: false,
          available: isAvailableOnThisPlatform,
        );

      case EmmaRuntimeMode.localVoice:
        return EmmaRuntimeModeConfig(
          mode: EmmaRuntimeMode.localVoice,
          label: 'voice_mode_label'.tr,
          shortLabel: 'Voice',
          description: kIsWeb
              ? 'local_voice_blocked_web'.tr
              : 'voice_mode_description'.tr,
          backendMode: 'local_voice',
          useLocalEngine: !kIsWeb,
          useTalk: !kIsWeb,
          voiceEnabled: !kIsWeb,
          available: isAvailableOnThisPlatform,
        );
    }
  }
}

final emmaRuntimeModeProvider = StateProvider<EmmaRuntimeMode>(
  (ref) => EmmaRuntimeMode.cloud,
);

final emmaAvailableRuntimeModesProvider = Provider<List<EmmaRuntimeMode>>(
  (ref) {
    return EmmaRuntimeMode.values
        .where((mode) => mode.isAvailableOnThisPlatform)
        .toList();
  },
);

final emmaEffectiveRuntimeModeProvider = Provider<EmmaRuntimeMode>(
  (ref) {
    final selected = ref.watch(emmaRuntimeModeProvider);

    if (!selected.isAvailableOnThisPlatform) {
      return EmmaRuntimeMode.cloud;
    }

    return selected;
  },
);

final emmaRuntimeModeConfigProvider = Provider<EmmaRuntimeModeConfig>(
  (ref) => ref.watch(emmaEffectiveRuntimeModeProvider).config,
);