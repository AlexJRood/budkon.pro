// lib/emma/widgets/ai_app_bar.dart

import 'package:core/ui/device_type_util.dart';
import 'package:emma/library/emma_local_models_dialog.dart';
import 'package:emma/provider/emma_provider.dart';
import 'package:emma/tools/open_emma.dart';
import 'package:emma/provider/local_llm_model_status_provider.dart';
import 'package:emma/provider/local_voice_model_status_provider.dart';
import 'package:emma/provider/runtime_provider.dart';
import 'package:emma/screens/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

class AiAppBar extends ConsumerWidget {
  const AiAppBar({
    super.key,
    this.isMobile = false,
    this.scaffoldKey,
  });

  final bool isMobile;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = isMobile || DeviceTypeUtil.isMobile(context);
    final theme = ref.watch(themeColorsProvider);
    final inChat = ref.watch(selectedAiRoomProvider).trim().isNotEmpty;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: inChat
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.redBeige.withAlpha((255 * 0.25).toInt()),
                      AppColors.redBeige.withAlpha((255 * 0.5).toInt()),
                      AppColors.redBeige.withAlpha((255 * 0.25).toInt()),
                    ],
                  )
                : null,
            color: inChat ? null : Colors.transparent,
          ),
          height: TopAppBarSize.resolve(context),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: mobile ? 8 : 12,
                      horizontal: mobile ? 0 : 24,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [

                    SizedBox(
                      width: mobile ? 54 : 60,
                      height: mobile ? 44 : 60,
                      child: IconButton(
                        style: elevatedButtonStyleRounded10,
                        onPressed: () {
                          Navigator.of(context).maybePop();
                        },
                        icon: AppIcons.iosArrowLeft(
                          height: mobile ? 22 : 25,
                          width: mobile ? 22 : 25,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                        Flexible(
                          flex: 0,
                          child: Text(
                            'Emma',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        if (!mobile) ...[
                          const SizedBox(width: 14),
                          const _EmmaRuntimeStatusDot(),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: _CurrentLocalRuntimeBadges(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 60,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _EmmaRuntimeSwitcher(
                      mobile: mobile,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    if (!mobile) ...[
                      const _LocalModelLibraryButton(
                        mobile: false,
                      ),
                      const SizedBox(width: 8),
                    ],
                    SizedBox(
                      width: mobile ? 54 : 60,
                      height: mobile ? 44 : 60,
                      child: Tooltip(
                        message: 'emma_bubble_tooltip'.tr,
                        child: IconButton(
                          style: elevatedButtonStyleRounded10,
                          onPressed: () => openEmmaOverlay(
                            context: context,
                            ref: ref,
                          ),
                          icon: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.white,
                            size: mobile ? 21 : 23,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: mobile ? 54 : 60,
                      height: mobile ? 44 : 60,
                      child: IconButton(
                        style: elevatedButtonStyleRounded10,
                        onPressed: () {
                          _openSettings(context, mobile, theme);
                        },
                        icon: AppIcons.moreVertical(
                          color: AppColors.white,
                          height: mobile ? 20 : 22,
                          width: mobile ? 20 : 22,
                        ),
                      ),
                    ),
                    // Chat-list opener lives on the right so the open gesture
                    // (swipe-from-right / end-drawer) doesn't clash with iOS'
                    // native swipe-from-left back gesture.
                    if (mobile) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: mobile ? 44 : 60,
                        width: mobile ? 54 : 60,
                        child: IconButton(
                          style: elevatedButtonStyleRounded10,
                          onPressed: () {
                            scaffoldKey?.currentState?.openEndDrawer();
                          },
                          icon: AppIcons.menu(
                            color: AppColors.white,
                            height: mobile ? 20 : null,
                            width: mobile ? 20 : null,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openSettings(BuildContext context, bool mobile, ThemeColors theme) {
    if (mobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (ctx, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.adPopBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(76),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: EmmaSettingsPanel(
                  scrollController: scrollController,
                  isMobile: true,
                ),
              );
            },
          );
        },
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return Dialog(
            backgroundColor: theme.adPopBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 860,
                maxHeight: 820,
              ),
              child: const EmmaSettingsPanel(
                isMobile: false,
              ),
            ),
          );
        },
      );
    }
  }
}

class AiVerticalSidebar extends ConsumerWidget {
  const AiVerticalSidebar({
    super.key,
    this.width = 72,
    this.showMenuButton = false,
    this.showCloseButton = true,
    this.showRuntimeStatus = true,
    this.showRuntimeSwitcher = true,
    this.scaffoldKey,
    this.dockOnRight = true,
  });

  final double width;
  final bool showMenuButton;
  final bool showCloseButton;
  final bool showRuntimeStatus;
  final bool showRuntimeSwitcher;
  final bool dockOnRight;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final inChat = ref.watch(selectedAiRoomProvider).trim().isNotEmpty;
    final expanded = width >= 150;

    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: inChat
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.redBeige.withAlpha((255 * 0.20).toInt()),
                  AppColors.redBeige.withAlpha((255 * 0.38).toInt()),
                  AppColors.redBeige.withAlpha((255 * 0.20).toInt()),
                ],
              )
            : null,
        color: inChat ? null : Colors.transparent,
        border: Border(
          left: dockOnRight
              ? BorderSide(
                  color: Colors.white.withAlpha(24),
                  width: 1,
                )
              : BorderSide.none,
          right: dockOnRight
              ? BorderSide.none
              : BorderSide(
                  color: Colors.white.withAlpha(24),
                  width: 1,
                ),
        ),
      ),
      child: SafeArea(
        bottom: true,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: expanded ? 10 : 8,
          ),
          child: Column(
            children: [
              if (showMenuButton) ...[
                _VerticalIconButton(
                  expanded: expanded,
                  tooltip: 'menu_label'.tr,
                  label: 'menu_label'.tr,
                  icon: AppIcons.menu(
                    color: AppColors.white,
                    height: 24,
                    width: 24,
                  ),
                  onPressed: () {
                    scaffoldKey?.currentState?.openEndDrawer();
                  },
                ),
                const SizedBox(height: 8),
              ],
              _EmmaVerticalBrand(expanded: expanded),
              const SizedBox(height: 14),
              if (showRuntimeStatus) ...[
                _EmmaVerticalRuntimeStatus(expanded: expanded),
                const SizedBox(height: 8),
                _EmmaVerticalCurrentModel(expanded: expanded),
                const SizedBox(height: 8),
                _EmmaVerticalVoiceModels(expanded: expanded),
                const SizedBox(height: 14),
              ],
              if (showRuntimeSwitcher) ...[
                _EmmaVerticalRuntimeSwitcher(
                  expanded: expanded,
                  theme: theme,
                ),
                const SizedBox(height: 14),
              ],
              _LocalModelLibraryButton(mobile: false),
              const Spacer(),
              _VerticalIconButton(
                expanded: expanded,
                tooltip: 'emma_bubble_tooltip'.tr,
                label: 'emma_bubble_label'.tr,
                icon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
                onPressed: () => openEmmaOverlay(
                  context: context,
                  ref: ref,
                ),
              ),
              const SizedBox(height: 8),
              _VerticalIconButton(
                expanded: expanded,
                tooltip: 'emma_settings_tooltip'.tr,
                label: 'settings_label'.tr,
                icon: AppIcons.moreVertical(
                  color: AppColors.white,
                  height: 22,
                  width: 22,
                ),
                onPressed: () {
                  _openVerticalSettings(context, theme);
                },
              ),
              if (showCloseButton) ...[
                const SizedBox(height: 8),
                _VerticalIconButton(
                  expanded: expanded,
                  tooltip:'close_label'.tr,
                  label:'close_label'.tr,
                  icon: AppIcons.close(
                    height: 24,
                    width: 24,
                    color: AppColors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openVerticalSettings(BuildContext context, ThemeColors theme) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: theme.adPopBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 860,
              maxHeight: 820,
            ),
            child: const EmmaSettingsPanel(
              isMobile: false,
            ),
          ),
        );
      },
    );
  }
}

class _EmmaVerticalBrand extends ConsumerWidget {
  const _EmmaVerticalBrand({
    required this.expanded,
  });

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inChat = ref.watch(selectedAiRoomProvider).trim().isNotEmpty;

    if (!expanded) {
      return Tooltip(
        message: 'Emma',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(inChat ? 42 : 24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(42),
            ),
            boxShadow: inChat
                ? [
                    BoxShadow(
                      color: AppColors.redBeige.withAlpha(55),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              'E',
              style: TextStyle(
                color: AppColors.white.withAlpha(235),
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(inChat ? 42 : 24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withAlpha(42),
        ),
        boxShadow: inChat
            ? [
                BoxShadow(
                  color: AppColors.redBeige.withAlpha(55),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Text(
            'E',
            style: TextStyle(
              color: AppColors.white.withAlpha(235),
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Emma',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white.withAlpha(235),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmmaVerticalRuntimeStatus extends ConsumerWidget {
  const _EmmaVerticalRuntimeStatus({
    required this.expanded,
  });

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(emmaRuntimeModeConfigProvider);

    final color = kIsWeb
        ? const Color(0xFF9BC9FF)
        : config.useLocalEngine
            ? const Color(0xFF72F2A1)
            : const Color(0xFF9BC9FF);

    if (!expanded) {
      return Tooltip(
        message: kIsWeb
            ? 'web_cloud_only_tooltip'.tr
            : config.description,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(38),
            ),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(130),
                    blurRadius: 9,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: kIsWeb
          ? 'web_cloud_only_tooltip'.tr
          : config.description,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(24),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withAlpha(38),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(130),
                    blurRadius: 9,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white.withAlpha(235),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kIsWeb ? 'cloud_only_label'.tr : config.shortLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white.withAlpha(150),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (kIsWeb)
              Icon(
                Icons.lock_rounded,
                size: 14,
                color: AppColors.white.withAlpha(165),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmmaVerticalCurrentModel extends ConsumerWidget {
  const _EmmaVerticalCurrentModel({
    required this.expanded,
  });

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(emmaEffectiveRuntimeModeProvider);

    if (kIsWeb || mode == EmmaRuntimeMode.cloud) {
      return _VerticalCurrentModelShell(
        expanded: expanded,
        icon: Icons.cloud_queue_rounded,
        color: const Color(0xFF9BC9FF),
        title: 'cloud_label'.tr,
        subtitle: 'backend_model_label'.tr,
        tooltip: 'emma_cloud_mode_tooltip'.tr,
      );
    }

    final statusAsync = ref.watch(emmaLocalModelStatusProvider);

    return statusAsync.when(
      loading: () {
        return _VerticalCurrentModelShell(
          expanded: expanded,
          icon: Icons.hourglass_top_rounded,
          color: const Color(0xFFFFD27D),
          title: 'checking_status'.tr,
          subtitle: 'local_runtime_label'.tr,
          tooltip: 'checking_local_model'.tr,
        );
      },
      error: (error, stackTrace) {
        return _VerticalCurrentModelShell(
          expanded: expanded,
          icon: Icons.warning_rounded,
          color: const Color(0xFFFFB86B),
          title: 'checking_local_model'.tr,
          subtitle: 'status_error_label'.tr,
          tooltip: '${'failed_to_check_local_model'.tr}\n$error',
        );
      },
      data: (state) {
        final color = !state.available
            ? const Color(0xFFFFB86B)
            : state.loading
                ? const Color(0xFFFFD27D)
                : state.loaded
                    ? const Color(0xFF72F2A1)
                    : const Color(0xFFFFB86B);

        final icon = !state.available
            ? Icons.warning_rounded
            : state.loading
                ? Icons.hourglass_top_rounded
                : state.loaded
                    ? Icons.memory_rounded
                    : Icons.memory_outlined;

        return _VerticalCurrentModelShell(
          expanded: expanded,
          icon: icon,
          color: color,
          title: state.displayName,
          subtitle: state.subtitle,
          tooltip: state.tooltip,
        );
      },
    );
  }
}

class _EmmaVerticalVoiceModels extends ConsumerWidget {
  const _EmmaVerticalVoiceModels({
    required this.expanded,
  });

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(emmaEffectiveRuntimeModeProvider);

    if (kIsWeb || mode != EmmaRuntimeMode.localVoice) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _VerticalVoiceModelBadge(
          expanded: expanded,
          capability: EmmaLocalVoiceCapability.stt,
        ),
        const SizedBox(height: 8),
        _VerticalVoiceModelBadge(
          expanded: expanded,
          capability: EmmaLocalVoiceCapability.tts,
        ),
      ],
    );
  }
}

class _VerticalVoiceModelBadge extends ConsumerWidget {
  const _VerticalVoiceModelBadge({
    required this.expanded,
    required this.capability,
  });

  final bool expanded;
  final EmmaLocalVoiceCapability capability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = capability == EmmaLocalVoiceCapability.stt
        ? ref.watch(emmaLocalSttModelStatusProvider)
        : ref.watch(emmaLocalTtsModelStatusProvider);

    final fallbackTitle = capability == EmmaLocalVoiceCapability.stt ? 'STT' : 'TTS';

    return statusAsync.when(
      loading: () {
        return _VerticalCurrentModelShell(
          expanded: expanded,
          icon: Icons.hourglass_top_rounded,
          color: const Color(0xFFFFD27D),
          title: fallbackTitle,
          subtitle: 'checking_status'.tr,
          tooltip: '${'checking_status'.tr} $fallbackTitle...',
        );
      },
      error: (error, stackTrace) {
        return _VerticalCurrentModelShell(
          expanded: expanded,
          icon: Icons.warning_rounded,
          color: const Color(0xFFFFB86B),
          title: fallbackTitle,
          subtitle: 'status_error_label'.tr,
          tooltip: '${'failed_to_check_prefix'.tr}  $fallbackTitle.\n$error',
        );
      },
      data: (state) {
        final color = !state.available
            ? const Color(0xFFFFB86B)
            : state.loading
                ? const Color(0xFFFFD27D)
                : state.loaded
                    ? const Color(0xFF72F2A1)
                    : const Color(0xFFFFB86B);

        final icon = !state.available
            ? Icons.warning_rounded
            : state.loading
                ? Icons.hourglass_top_rounded
                : capability == EmmaLocalVoiceCapability.stt
                    ? Icons.mic_rounded
                    : Icons.volume_up_rounded;

        return _VerticalCurrentModelShell(
          expanded: expanded,
          icon: icon,
          color: color,
          title: state.loaded ? state.loadedModelName : fallbackTitle,
          subtitle: state.subtitle,
          tooltip: state.tooltip,
        );
      },
    );
  }
}

class _EmmaVerticalRuntimeSwitcher extends ConsumerWidget {
  const _EmmaVerticalRuntimeSwitcher({
    required this.expanded,
    required this.theme,
  });

  final bool expanded;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!expanded) {
      return _EmmaRuntimeSwitcher(
        mobile: true,
        theme: theme,
      );
    }

    if (kIsWeb) {
      return const _ExpandedWebCloudOnlyCard();
    }

    final selectedMode = ref.watch(emmaRuntimeModeProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(36),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withAlpha(40),
        ),
      ),
      child: Column(
        children: EmmaRuntimeMode.values.map((mode) {
          final selected = mode == selectedMode;

          return _VerticalRuntimeModeButton(
            mode: mode,
            selected: selected,
            onTap: () {
              ref.read(emmaRuntimeModeProvider.notifier).state = mode;
            },
          );
        }).toList(),
      ),
    );
  }
}

class _VerticalRuntimeModeButton extends StatelessWidget {
  const _VerticalRuntimeModeButton({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final EmmaRuntimeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final config = mode.config;

    return Tooltip(
      message: config.description,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withAlpha(235) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                _verticalIconForMode(mode),
                size: 17,
                color: selected
                    ? AppColors.redBeige
                    : AppColors.white.withAlpha(220),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  config.shortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? AppColors.redBeige
                        : AppColors.white.withAlpha(220),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedWebCloudOnlyCard extends StatelessWidget {
  const _ExpandedWebCloudOnlyCard();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'web_cloud_only_tooltip'.tr,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(36),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withAlpha(40),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_queue_rounded,
              size: 18,
              color: AppColors.white.withAlpha(225),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
               "cloud_label".tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withAlpha(225),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.lock_rounded,
              size: 15,
              color: AppColors.white.withAlpha(170),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalIconButton extends StatelessWidget {
  const _VerticalIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.expanded,
    this.label,
  });

  final String tooltip;
  final String? label;
  final Widget icon;
  final VoidCallback onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return Tooltip(
        message: tooltip,
        child: SizedBox(
          width: 52,
          height: 52,
          child: IconButton(
            style: elevatedButtonStyleRounded10,
            onPressed: onPressed,
            icon: icon,
          ),
        ),
      );
    }

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: TextButton(
          style: elevatedButtonStyleRounded10,
          onPressed: onPressed,
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Center(child: icon),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label ?? tooltip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withAlpha(230),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _verticalIconForMode(EmmaRuntimeMode mode) {
  switch (mode) {
    case EmmaRuntimeMode.cloud:
      return Icons.cloud_queue_rounded;
    case EmmaRuntimeMode.localText:
      return Icons.memory_rounded;
    case EmmaRuntimeMode.localVoice:
      return Icons.graphic_eq_rounded;
  }
}

class _EmmaRuntimeSwitcher extends ConsumerWidget {
  const _EmmaRuntimeSwitcher({
    required this.mobile,
    required this.theme,
  });

  final bool mobile;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(emmaRuntimeModeProvider);
    final effectiveMode = kIsWeb ? EmmaRuntimeMode.cloud : selectedMode;

    if (kIsWeb) {
      return _WebCloudOnlyPill(compact: mobile);
    }

    if (mobile) {
      return PopupMenuButton<EmmaRuntimeMode>(
        tooltip: 'emma_mode_tooltip'.tr,
        color: theme.adPopBackground,
        initialValue: effectiveMode,
        onSelected: (value) {
          ref.read(emmaRuntimeModeProvider.notifier).state = value;
        },
        itemBuilder: (ctx) {
          return EmmaRuntimeMode.values.map((item) {
            final itemConfig = item.config;
            final selected = item == effectiveMode;

            return PopupMenuItem<EmmaRuntimeMode>(
              value: item,
              child: Row(
                children: [
                  Icon(
                    _iconForMode(item),
                    size: 20,
                    color: selected ? theme.themeColor : theme.textColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemConfig.label,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          itemConfig.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(160),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: theme.themeColor,
                    ),
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          height: 44,
          width: 54,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(31),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withAlpha(45),
            ),
          ),
          child: Icon(
            _iconForMode(effectiveMode),
            color: AppColors.white,
            size: 22,
          ),
        ),
      );
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(40),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: EmmaRuntimeMode.values.map((item) {
          final selected = item == effectiveMode;

          return _RuntimeModePill(
            mode: item,
            selected: selected,
            onTap: () {
              ref.read(emmaRuntimeModeProvider.notifier).state = item;
            },
          );
        }).toList(),
      ),
    );
  }

  static IconData _iconForMode(EmmaRuntimeMode mode) {
    switch (mode) {
      case EmmaRuntimeMode.cloud:
        return Icons.cloud_queue_rounded;
      case EmmaRuntimeMode.localText:
        return Icons.memory_rounded;
      case EmmaRuntimeMode.localVoice:
        return Icons.graphic_eq_rounded;
    }
  }
}

class _RuntimeModePill extends StatelessWidget {
  const _RuntimeModePill({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final EmmaRuntimeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final config = mode.config;

    return Tooltip(
      message: config.description,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withAlpha(235) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 140),
                  child: Icon(
                    _iconForMode(mode),
                    key: ValueKey('${mode.name}-$selected'),
                    size: 17,
                    color: selected
                        ? AppColors.redBeige
                        : AppColors.white.withAlpha(220),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  config.shortLabel,
                  style: TextStyle(
                    color: selected
                        ? AppColors.redBeige
                        : AppColors.white.withAlpha(220),
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconForMode(EmmaRuntimeMode mode) {
    switch (mode) {
      case EmmaRuntimeMode.cloud:
        return Icons.cloud_queue_rounded;
      case EmmaRuntimeMode.localText:
        return Icons.memory_rounded;
      case EmmaRuntimeMode.localVoice:
        return Icons.graphic_eq_rounded;
    }
  }
}

class _EmmaRuntimeStatusDot extends ConsumerWidget {
  const _EmmaRuntimeStatusDot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(emmaRuntimeModeConfigProvider);

    return Tooltip(
      message: kIsWeb
          ? 'web_cloud_only_tooltip'.tr
          : config.description,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(28),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withAlpha(45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: config.useLocalEngine
                    ? const Color(0xFF72F2A1)
                    : const Color(0xFF9BC9FF),
                boxShadow: [
                  BoxShadow(
                    color: (config.useLocalEngine
                            ? const Color(0xFF72F2A1)
                            : const Color(0xFF9BC9FF))
                        .withAlpha(120),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Text(
              config.label,
              style: TextStyle(
                color: AppColors.white.withAlpha(235),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (kIsWeb) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.lock_rounded,
                size: 13,
                color: AppColors.white.withAlpha(165),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrentLocalRuntimeBadges extends ConsumerWidget {
  const _CurrentLocalRuntimeBadges();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(emmaEffectiveRuntimeModeProvider);

    if (kIsWeb || mode == EmmaRuntimeMode.cloud) {
      return const _CurrentLocalModelBadge();
    }

    if (mode == EmmaRuntimeMode.localText) {
      return const _CurrentLocalModelBadge();
    }

    return const FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CurrentLocalModelBadge(),
          SizedBox(width: 8),
          _CurrentLocalVoiceBadge(
            capability: EmmaLocalVoiceCapability.stt,
          ),
          SizedBox(width: 8),
          _CurrentLocalVoiceBadge(
            capability: EmmaLocalVoiceCapability.tts,
          ),
        ],
      ),
    );
  }
}

class _CurrentLocalModelBadge extends ConsumerWidget {
  const _CurrentLocalModelBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(emmaEffectiveRuntimeModeProvider);

    if (kIsWeb || mode == EmmaRuntimeMode.cloud) {
      return Tooltip(
        message: 'emma_cloud_mode_tooltip'.tr,
        child: _ModelBadgeShell(
          icon: Icons.cloud_queue_rounded,
          color: const Color(0xFF9BC9FF),
          title: 'cloud_label'.tr,
          subtitle: 'backend_label'.tr,
        ),
      );
    }

    final statusAsync = ref.watch(emmaLocalModelStatusProvider);

    return statusAsync.when(
      loading: () {
        return Tooltip(
          message: 'checking_local_model'.tr,
          child: _ModelBadgeShell(
            icon: Icons.hourglass_top_rounded,
            color: Color(0xFFFFD27D),
            title: 'checking_status'.tr,
            subtitle: 'local_mode_label'.tr,
          ),
        );
      },
      error: (error, stackTrace) {
        return Tooltip(
          message: '${'failed_to_check_local_model'.tr}\n$error',
          child: _ModelBadgeShell(
            icon: Icons.warning_rounded,
            color: Color(0xFFFFB86B),
            title:'local_offline_label'.tr,
            subtitle: 'error_label'.tr,
          ),
        );
      },
      data: (state) {
        final color = !state.available
            ? const Color(0xFFFFB86B)
            : state.loading
                ? const Color(0xFFFFD27D)
                : state.loaded
                    ? const Color(0xFF72F2A1)
                    : const Color(0xFFFFB86B);

        final icon = !state.available
            ? Icons.warning_rounded
            : state.loading
                ? Icons.hourglass_top_rounded
                : state.loaded
                    ? Icons.memory_rounded
                    : Icons.memory_outlined;

        return Tooltip(
          message: state.tooltip,
          child: _ModelBadgeShell(
            icon: icon,
            color: color,
            title: state.displayName,
            subtitle: state.subtitle,
          ),
        );
      },
    );
  }
}

class _CurrentLocalVoiceBadge extends ConsumerWidget {
  const _CurrentLocalVoiceBadge({
    required this.capability,
  });

  final EmmaLocalVoiceCapability capability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = capability == EmmaLocalVoiceCapability.stt
        ? ref.watch(emmaLocalSttModelStatusProvider)
        : ref.watch(emmaLocalTtsModelStatusProvider);

    final fallbackTitle = capability == EmmaLocalVoiceCapability.stt ? 'stt_label'.tr : 'tts_label'.tr;

    return statusAsync.when(
      loading: () {
        return Tooltip(
          message: '${'checking_status'.tr} $fallbackTitle...',
          child: _CompactModelBadgeShell(
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFFFD27D),
            title: fallbackTitle,
            subtitle: 'check_label'.tr,
          ),
        );
      },
      error: (error, stackTrace) {
        return Tooltip(
          message: '${'failed_to_check_prefix'.tr} $fallbackTitle.\n$error',
          child: _CompactModelBadgeShell(
            icon: Icons.warning_rounded,
            color: const Color(0xFFFFB86B),
            title: fallbackTitle,
            subtitle: 'error_label'.tr,
          ),
        );
      },
      data: (state) {
        final color = !state.available
            ? const Color(0xFFFFB86B)
            : state.loading
                ? const Color(0xFFFFD27D)
                : state.loaded
                    ? const Color(0xFF72F2A1)
                    : const Color(0xFFFFB86B);

        final icon = !state.available
            ? Icons.warning_rounded
            : state.loading
                ? Icons.hourglass_top_rounded
                : capability == EmmaLocalVoiceCapability.stt
                    ? Icons.mic_rounded
                    : Icons.volume_up_rounded;

        return Tooltip(
          message: state.tooltip,
          child: _CompactModelBadgeShell(
            icon: icon,
            color: color,
            title: fallbackTitle,
            subtitle: state.loaded ? state.loadedModelName : state.subtitle,
          ),
        );
      },
    );
  }
}

class _ModelBadgeShell extends StatelessWidget {
  const _ModelBadgeShell({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(
        maxWidth: 270,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withAlpha(45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white.withAlpha(235),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white.withAlpha(145),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactModelBadgeShell extends StatelessWidget {
  const _CompactModelBadgeShell({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(
        maxWidth: 170,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withAlpha(45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.white.withAlpha(235),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white.withAlpha(145),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalCurrentModelShell extends StatelessWidget {
  const _VerticalCurrentModelShell({
    required this.expanded,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.tooltip,
  });

  final bool expanded;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return Tooltip(
        message: tooltip,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(38),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(24),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withAlpha(38),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white.withAlpha(235),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white.withAlpha(150),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebCloudOnlyPill extends StatelessWidget {
  const _WebCloudOnlyPill({
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'web_cloud_only_tooltip'.tr,
      child: Container(
        height: 44,
        width: compact ? 54 : null,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : 13,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(36),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withAlpha(40),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_queue_rounded,
              size: compact ? 20 : 18,
              color: AppColors.white.withAlpha(225),
            ),
            if (!compact) ...[
              const SizedBox(width: 7),
              Text(
                'cloud_label'.tr,
                style: TextStyle(
                  color: AppColors.white.withAlpha(225),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 7),
              Icon(
                Icons.lock_rounded,
                size: 15,
                color: AppColors.white.withAlpha(170),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocalModelLibraryButton extends StatelessWidget {
  const _LocalModelLibraryButton({
    required this.mobile,
  });

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: kIsWeb
          ? 'local_models_library_desktop_only'.tr
          : 'local_models_library_tooltip'.tr,
      child: SizedBox(
        width: mobile ? 54 : 60,
        height: mobile ? 44 : 60,
        child: IconButton(
          style: elevatedButtonStyleRounded10,
          onPressed: kIsWeb
              ? null
              : () {
                  showEmmaLocalModelsDialog(context);
                },
          icon: Icon(
            Icons.inventory_2_rounded,
            color: AppColors.white,
            size: mobile ? 21 : 23,
          ),
        ),
      ),
    );
  }
}