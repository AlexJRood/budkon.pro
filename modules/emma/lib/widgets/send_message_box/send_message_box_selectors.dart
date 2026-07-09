part of '../send_message_box.dart';

class _EmmaVoiceSelectorButton extends ConsumerWidget {
  const _EmmaVoiceSelectorButton({
    required this.theme,
    required this.onSelected,
  });

  final ThemeColors theme;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(emmaSelectedVoiceProvider);

    return Tooltip(
      message: kIsWeb
          ? 'voice_selection_unavailable_web'.tr
          : '${'emma_voice_tooltip'.tr} ${selected.label}',
      child: PopupMenuButton<EmmaVoicePreset>(
        enabled: !kIsWeb,
        tooltip: 'select_emma_voice'.tr,
        color: theme.adPopBackground,
        initialValue: selected,
        onSelected: (voice) {
          final current = ref.read(emmaSelectedVoiceProvider);

          if (current.id == voice.id) {
            onSelected();
            return;
          }

          ref.read(emmaSelectedVoiceProvider.notifier).state = voice;

          unawaited(
            ref.read(emmaAudioMessageProvider.notifier).stop(),
          );

          final chatNotifier = ref.read(chatAiMessageProvider.notifier);

          unawaited(
            chatNotifier.stopLocalTalkAudio(),
          );

          onSelected();
        },
        itemBuilder: (context) {
          return emmaVoicePresets.map((voice) {
            final isSelected = voice.id == selected.id;

            return PopupMenuItem<EmmaVoicePreset>(
              value: voice,
              child: Row(
                children: [
                  Icon(
                    Icons.record_voice_over_rounded,
                    size: 19,
                    color: isSelected ? theme.themeColor : theme.textColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voice.label,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          voice.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(145),
                            fontSize: 11,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${voice.ttsModel} / ${voice.voice}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(95),
                            fontSize: 10,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_rounded,
                      size: 19,
                      color: theme.themeColor,
                    ),
                  ],
                ],
              ),
            );
          }).toList();
        },
        child: SizedBox(
          height: 50,
          width: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.transparent,
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    kIsWeb
                        ? Icons.voice_over_off_rounded
                        : Icons.record_voice_over_rounded,
                    color: kIsWeb
                        ? theme.textColor.withAlpha(95)
                        : theme.textColor,
                    size: 20,
                  ),
                  if (!kIsWeb)
                    Positioned(
                      right: 3,
                      bottom: 4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 13),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.themeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          selected.shortLabel.isNotEmpty
                              ? selected.shortLabel.characters.first
                                  .toUpperCase()
                              : 'V',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmmaSttSelectorButton extends ConsumerWidget {
  const _EmmaSttSelectorButton({
    required this.theme,
    required this.onSelected,
  });

  final ThemeColors theme;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(emmaSelectedSttProvider);

    return Tooltip(
      message: kIsWeb
          ? 'local_stt_unavailable_web'.tr
          : '${'emma_stt_tooltip'.tr} ${selected.label}',
      child: PopupMenuButton<EmmaSttPreset>(
        enabled: !kIsWeb,
        tooltip: 'select_stt_model'.tr,
        color: theme.adPopBackground,
        initialValue: selected,
        onSelected: (model) {
          final current = ref.read(emmaSelectedSttProvider);

          if (current.id == model.id) {
            onSelected();
            return;
          }

          ref.read(emmaSelectedSttProvider.notifier).state = model;

          unawaited(
            ref
                .read(localSuperbeeSttClientProvider)
                .loadModel(model.sttModel)
                .catchError((_) => <String, dynamic>{}),
          );

          onSelected();
        },
        itemBuilder: (context) {
          return emmaSttPresets.map((model) {
            final isSelected = model.id == selected.id;

            return PopupMenuItem<EmmaSttPreset>(
              value: model,
              child: Row(
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: 19,
                    color: isSelected ? theme.themeColor : theme.textColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.label,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          model.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(145),
                            fontSize: 11,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${model.sttModel} / ${model.language}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(95),
                            fontSize: 10,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_rounded,
                      size: 19,
                      color: theme.themeColor,
                    ),
                  ],
                ],
              ),
            );
          }).toList();
        },
        child: SizedBox(
          height: 50,
          width: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.transparent,
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    kIsWeb
                        ? Icons.mic_off_rounded
                        : Icons.graphic_eq_rounded,
                    color: kIsWeb
                        ? theme.textColor.withAlpha(95)
                        : theme.textColor,
                    size: 20,
                  ),
                  if (!kIsWeb)
                    Positioned(
                      right: 3,
                      bottom: 4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 13),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.themeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          selected.shortLabel.isNotEmpty
                              ? selected.shortLabel.characters.first
                                  .toUpperCase()
                              : 'S',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}