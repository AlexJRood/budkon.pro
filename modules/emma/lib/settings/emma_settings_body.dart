import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

import 'models.dart';
import 'providers.dart';

/// Renders only the settings list — no header, no save button.
/// Designed to be embedded in onboarding or side panels that supply their own chrome.
class EmmaSettingsBody extends ConsumerWidget {
  const EmmaSettingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final asyncSettings = ref.watch(aiDynamicSettingsProvider);

    return asyncSettings.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(strokeWidth: 2, color: theme.themeColor),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '${'failed_to_load_settings'.tr}\n$e',
          style: TextStyle(color: theme.textColor.withAlpha(178), fontSize: 13),
        ),
      ),
      data: (settings) {
        if (settings.isEmpty) {
          return Center(
            child: Text(
              'no_registered_ai_settings'.tr,
              style: TextStyle(color: theme.textColor.withAlpha(178), fontSize: 13),
            ),
          );
        }

        final byModule = <String, List<AiDynamicSetting>>{};
        for (final s in settings) {
          byModule.putIfAbsent(s.module, () => []).add(s);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in byModule.entries) ...[
              _ModuleSection(module: entry.key, settings: entry.value, theme: theme),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

// ── Module section ──────────────────────────────────────────────────────────

class _ModuleSection extends StatelessWidget {
  final String module;
  final List<AiDynamicSetting> settings;
  final ThemeColors theme;

  const _ModuleSection({
    required this.module,
    required this.settings,
    required this.theme,
  });

  String _moduleLabel(String module) {
    return switch (module) {
      'calendar' => 'calendar'.tr,
      'finance'  => 'finance'.tr,
      'email'    => 'email'.tr,
      'memos'    => 'memos_daily_plan'.tr,
      'tms'      => 'tasks_tms'.tr,
      'buyer_persona' => 'buyer_personas'.tr,
      ''         => 'general'.tr,
      _          => module,
    };
  }

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, List<AiDynamicSetting>>{};
    for (final s in settings) {
      byCategory.putIfAbsent(s.category, () => []).add(s);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _moduleLabel(module),
          style: TextStyle(
            color: theme.textColor.withAlpha(204),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in byCategory.entries) ...[
          if (entry.key.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                entry.key,
                style: TextStyle(
                  color: theme.textColor.withAlpha(178),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ...entry.value.map((s) => _SettingTile(setting: s, theme: theme)),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

// ── Setting tile (dispatches by field_type) ─────────────────────────────────

class _SettingTile extends ConsumerWidget {
  final AiDynamicSetting setting;
  final ThemeColors theme;

  const _SettingTile({required this.setting, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(aiDynamicSettingsProvider.notifier);

    return switch (setting.fieldType) {
      'bool' => SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: setting.value == true,
          onChanged: (v) => notifier.updateValue(setting, v),
          activeColor: theme.themeColor,
          title: Text(
            setting.label,
            style: TextStyle(color: theme.textColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          subtitle: setting.description.isEmpty
              ? null
              : Text(
                  setting.description,
                  style: TextStyle(color: theme.textColor.withAlpha(153), fontSize: 11),
                ),
        ),
      'choice' => _ChoiceTile(setting: setting, theme: theme, notifier: notifier),
      'int'    => _NumericTile(setting: setting, theme: theme, notifier: notifier),
      _        => _TextTile(setting: setting, theme: theme, notifier: notifier),
    };
  }
}

// ── Choice ──────────────────────────────────────────────────────────────────

class _ChoiceTile extends StatelessWidget {
  final AiDynamicSetting setting;
  final ThemeColors theme;
  final AiDynamicSettingsNotifier notifier;

  const _ChoiceTile({required this.setting, required this.theme, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final current = (setting.value ?? setting.defaultValue ?? '').toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(setting.label,
              style: TextStyle(color: theme.textColor, fontSize: 13, fontWeight: FontWeight.w500)),
          if (setting.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(setting.description,
                style: TextStyle(color: theme.textColor.withAlpha(153), fontSize: 11)),
          ],
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: setting.choices.any((c) => c.value == current) ? current : null,
            items: setting.choices
                .map((c) => DropdownMenuItem(value: c.value, child: Text(c.label)))
                .toList(),
            onChanged: (v) { if (v != null) notifier.updateValue(setting, v); },
            dropdownColor: theme.dashboardContainer,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: theme.adPopBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dashboardBoarder),
              ),
            ),
            style: TextStyle(color: theme.textColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Numeric ─────────────────────────────────────────────────────────────────

class _NumericTile extends StatefulWidget {
  final AiDynamicSetting setting;
  final ThemeColors theme;
  final AiDynamicSettingsNotifier notifier;

  const _NumericTile({required this.setting, required this.theme, required this.notifier});

  @override
  State<_NumericTile> createState() => _NumericTileState();
}

class _NumericTileState extends State<_NumericTile> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: (widget.setting.value ?? widget.setting.defaultValue ?? '').toString(),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.setting.label,
              style: TextStyle(color: widget.theme.textColor, fontSize: 13, fontWeight: FontWeight.w500)),
          if (widget.setting.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(widget.setting.description,
                style: TextStyle(color: widget.theme.textColor.withAlpha(153), fontSize: 11)),
          ],
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              onSubmitted: (t) {
                final v = int.tryParse(t) ?? 0;
                widget.notifier.updateValue(widget.setting, v);
              },
              style: TextStyle(color: widget.theme.textColor, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: widget.theme.adPopBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: widget.theme.dashboardBoarder),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Text ────────────────────────────────────────────────────────────────────

class _TextTile extends StatefulWidget {
  final AiDynamicSetting setting;
  final ThemeColors theme;
  final AiDynamicSettingsNotifier notifier;

  const _TextTile({required this.setting, required this.theme, required this.notifier});

  @override
  State<_TextTile> createState() => _TextTileState();
}

class _TextTileState extends State<_TextTile> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: (widget.setting.value ?? widget.setting.defaultValue ?? '').toString(),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.setting.label,
              style: TextStyle(color: widget.theme.textColor, fontSize: 13, fontWeight: FontWeight.w500)),
          if (widget.setting.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(widget.setting.description,
                style: TextStyle(color: widget.theme.textColor.withAlpha(153), fontSize: 11)),
          ],
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: TextField(
              controller: _ctrl,
              onSubmitted: (v) => widget.notifier.updateValue(widget.setting, v),
              style: TextStyle(color: widget.theme.textColor, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: widget.theme.adPopBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: widget.theme.dashboardBoarder),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
