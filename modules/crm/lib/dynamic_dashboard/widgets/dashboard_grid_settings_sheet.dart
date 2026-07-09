import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:crm/dynamic_dashboard/providers/dashboard_layout_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class DashboardGridSettingsSheet extends ConsumerWidget {
  const DashboardGridSettingsSheet({
    super.key,
    required this.dashboardKey,
    required this.breakpoint,
  });

  final String dashboardKey;
  final DashboardBreakpoint breakpoint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(dashboardLayoutProvider(dashboardKey));
    final notifier = ref.read(dashboardLayoutProvider(dashboardKey).notifier);
    final config = state.config;
    if (config == null) return const SizedBox.shrink();

    final layout = config.layoutOf(breakpoint);

    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.3,
      maxChildSize: 0.75,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.textColor.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 20, color: theme.textColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Grid settings'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close_rounded, color: theme.textColor),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Divider(color: theme.dashboardBoarder, height: 1),
                    const SizedBox(height: 16),
                    _SliderRow(
                      label: 'Tile height'.tr,
                      icon: Icons.height_rounded,
                      value: layout.rowHeight,
                      min: 60,
                      max: 220,
                      divisions: 32,
                      unit: 'px',
                      themeColor: theme.themeColor,
                      textColor: theme.textColor,
                      tileColor: theme.adPopBackground,
                      borderColor: theme.dashboardBoarder,
                      onChanged: (v) => notifier.updateGridSettings(
                        breakpoint: breakpoint,
                        rowHeight: v,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SliderRow(
                      label: 'Widget spacing'.tr,
                      icon: Icons.space_bar_rounded,
                      value: layout.gap,
                      min: 0,
                      max: 48,
                      divisions: 48,
                      unit: 'px',
                      themeColor: theme.themeColor,
                      textColor: theme.textColor,
                      tileColor: theme.adPopBackground,
                      borderColor: theme.dashboardBoarder,
                      onChanged: (v) => notifier.updateGridSettings(
                        breakpoint: breakpoint,
                        gap: v,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SliderRow(
                      label: 'Side padding'.tr,
                      icon: Icons.padding_rounded,
                      value: layout.horizontalPadding,
                      min: 0,
                      max: 80,
                      divisions: 80,
                      unit: 'px',
                      themeColor: theme.themeColor,
                      textColor: theme.textColor,
                      tileColor: theme.adPopBackground,
                      borderColor: theme.dashboardBoarder,
                      onChanged: (v) => notifier.updateGridSettings(
                        breakpoint: breakpoint,
                        horizontalPadding: v,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: theme.dashboardBoarder, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, size: 20, color: theme.textColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Theme'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _ThemeSelector(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeProvider) ?? ThemeMode.system;
    final theme = ref.read(themeColorsProvider);

    Future<void> pick(ThemeMode mode) async {
      ref.read(themeProvider.notifier).state = mode;
      await saveThemeMode(mode);
    }

    return Row(
      children: [
        _ThemeChip(
          label: 'System'.tr,
          icon: Icons.brightness_auto_rounded,
          selected: current == ThemeMode.system,
          textColor: theme.textColor,
          themeColor: theme.themeColor,
          borderColor: theme.dashboardBoarder,
          tileColor: theme.adPopBackground,
          onTap: () => pick(ThemeMode.system),
        ),
        const SizedBox(width: 8),
        _ThemeChip(
          label: 'Light'.tr,
          icon: Icons.light_mode_rounded,
          selected: current == ThemeMode.dark,
          textColor: theme.textColor,
          themeColor: theme.themeColor,
          borderColor: theme.dashboardBoarder,
          tileColor: theme.adPopBackground,
          onTap: () => pick(ThemeMode.dark),
        ),
        const SizedBox(width: 8),
        _ThemeChip(
          label: 'Dark'.tr,
          icon: Icons.dark_mode_rounded,
          selected: current == ThemeMode.light,
          textColor: theme.textColor,
          themeColor: theme.themeColor,
          borderColor: theme.dashboardBoarder,
          tileColor: theme.adPopBackground,
          onTap: () => pick(ThemeMode.light),
        ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.textColor,
    required this.themeColor,
    required this.borderColor,
    required this.tileColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color textColor;
  final Color themeColor;
  final Color borderColor;
  final Color tileColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? themeColor : textColor.withAlpha(160);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? themeColor.withAlpha(28) : tileColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? themeColor : borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.themeColor,
    required this.textColor,
    required this.tileColor,
    required this.borderColor,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final Color themeColor;
  final Color textColor;
  final Color tileColor;
  final Color borderColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: textColor.withAlpha(180)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: themeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${value.round()} $unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: themeColor,
              inactiveTrackColor: themeColor.withAlpha(40),
              thumbColor: themeColor,
              overlayColor: themeColor.withAlpha(30),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
