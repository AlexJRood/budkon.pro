// lib/emma/widgets/emma_settings_panel.dart
import 'package:emma/library/emma_local_models_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import '../settings/models.dart';
import '../settings/providers.dart';

class EmmaSettingsPanel extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final bool isMobile;

  const EmmaSettingsPanel({
    super.key,
    this.scrollController,
    this.isMobile = false,
  });

  @override
  ConsumerState<EmmaSettingsPanel> createState() => _EmmaSettingsPanelState();
}

class _EmmaSettingsPanelState extends ConsumerState<EmmaSettingsPanel>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String _filter = '';
  final _searchController = TextEditingController();
  List<String> _moduleOrder = [];

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initTabs(List<AiDynamicSetting> settings) {
    final seen = <String>{};
    final order = <String>[];
    for (final s in settings) {
      if (seen.add(s.module)) order.add(s.module);
    }
    if (_moduleOrder.length != order.length ||
        _moduleOrder.asMap().entries.any((e) => e.value != order[e.key])) {
      _tabController?.dispose();
      _tabController = TabController(
        length: order.length + 1, // +1 dla zakładki "Wszystkie"
        vsync: this,
      );
      _moduleOrder = order;
    }
  }

  String _moduleLabel(String module) {
    switch (module) {
      case 'calendar':
        return 'calendar'.tr;
      case 'finance':
        return 'finance'.tr;
      case 'email':
        return 'email'.tr;
      case 'memos':
        return 'memos_daily_plan'.tr;
      case 'tms':
        return 'tasks_tms'.tr;
      case 'buyer_persona':
        return 'buyer_personas'.tr;
      case '':
        return 'general'.tr;
      default:
        return module;
    }
  }

  List<AiDynamicSetting> _applyFilter(List<AiDynamicSetting> settings) {
    if (_filter.isEmpty) return settings;
    final q = _filter.toLowerCase();
    return settings
        .where((s) =>
            s.label.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final asyncSettings = ref.watch(aiDynamicSettingsProvider);
    final hPad = widget.isMobile ? 16.0 : 24.0;

    return Column(
      children: [
        // ---------- Header ----------
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, widget.isMobile ? 12 : 20, hPad, 8),
          child: Row(
            children: [
              AppIcons.moreVertical(color: theme.textColor),
              const SizedBox(width: 8),
              Text(
                'emma_settings'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: widget.isMobile ? 16 : 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: AppIcons.close(
                  color: theme.textColor,
                  height: 18,
                  width: 18,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.textColor.withAlpha(31)),

        // ---------- Biblioteka modeli lokalnych (tylko mobile) ----------
        if (widget.isMobile && !kIsWeb) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton.icon(
                style: elevatedButtonStyleRounded10,
                onPressed: () => showEmmaLocalModelsSheet(context),
                icon: Icon(
                  Icons.inventory_2_rounded,
                  color: theme.textColor,
                  size: 18,
                ),
                label: Text(
                  'local_models_library_tooltip'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: theme.textColor.withAlpha(20)),
        ],

        // ---------- Treść ----------
        Expanded(
          child: asyncSettings.when(
            loading: () => Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.themeColor,
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${'failed_to_load_settings'.tr}\n$e',
                style: TextStyle(
                  color: theme.textColor.withAlpha(178),
                  fontSize: 13,
                ),
              ),
            ),
            data: (settings) {
              if (settings.isEmpty) {
                return Center(
                  child: Text(
                    'no_registered_ai_settings'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(178),
                      fontSize: 13,
                    ),
                  ),
                );
              }

              _initTabs(settings);

              return Column(
                children: [
                  // ---------- Wyszukiwarka ----------
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _filter = v),
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'emma_settings_search_hint'.tr,
                        hintStyle: TextStyle(
                          color: theme.textColor.withAlpha(120),
                          fontSize: 13,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: Colors.white10,
                        prefixIcon: Icon(
                          Icons.search,
                          color: theme.textColor.withAlpha(150),
                          size: 18,
                        ),
                        suffixIcon: _filter.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: theme.textColor.withAlpha(150),
                                  size: 16,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _filter = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white24.withAlpha(178),
                            width: 0.7,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.textColor.withAlpha(40),
                            width: 0.7,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.themeColor.withAlpha(180),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ---------- Zakładki ----------
                  if (_tabController != null)
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: theme.themeColor,
                      unselectedLabelColor: theme.textColor.withAlpha(140),
                      labelStyle: TextStyle(
                        fontSize: widget.isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: widget.isMobile ? 12 : 13,
                        fontWeight: FontWeight.w400,
                      ),
                      indicatorColor: theme.themeColor,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(horizontal: hPad - 8),
                      tabs: [
                        Tab(text: 'emma_settings_all_tab'.tr),
                        ..._moduleOrder
                            .map((m) => Tab(text: _moduleLabel(m))),
                      ],
                    ),
                  Divider(height: 1, color: theme.textColor.withAlpha(20)),

                  // ---------- Zawartość zakładek ----------
                  Expanded(
                    child: _tabController != null
                        ? TabBarView(
                            controller: _tabController,
                            children: [
                              _buildAllModulesView(settings, theme, hPad),
                              ..._moduleOrder.map(
                                (m) => _buildSingleModuleView(
                                  settings
                                      .where((s) => s.module == m)
                                      .toList(),
                                  theme,
                                  hPad,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ---------- Przycisk zapisu ----------
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      8,
                      hPad,
                      widget.isMobile ? 16 : 20,
                    ),
                    child: Align(
                      alignment: widget.isMobile
                          ? Alignment.center
                          : Alignment.centerRight,
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          style: elevatedButtonStyleRounded10,
                          onPressed: () async {
                            await ref
                                .read(aiDynamicSettingsProvider.notifier)
                                .saveAll();
                            Navigator.of(context).maybePop();
                          },
                          icon: AppIcons.check(
                            color: theme.textColor,
                            height: 18,
                            width: 18,
                          ),
                          label: Text(
                            'save_settings'.tr,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllModulesView(
    List<AiDynamicSetting> settings,
    ThemeColors theme,
    double hPad,
  ) {
    final filtered = _applyFilter(settings);
    if (filtered.isEmpty) return _buildEmptyFilter(theme);

    final byModule = <String, List<AiDynamicSetting>>{};
    for (final s in filtered) {
      byModule.putIfAbsent(s.module, () => []).add(s);
    }

    final proactiveSection = _buildProactiveSection(settings, theme);

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (proactiveSection != null && _filter.isEmpty) ...[
            proactiveSection,
            const SizedBox(height: 20),
          ],
          for (final entry in byModule.entries) ...[
            _ModuleSection(
              module: entry.key,
              settings: entry.value,
              theme: theme,
              isMobile: widget.isMobile,
              moduleLabel: _moduleLabel(entry.key),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  static const _emmaAccent = Color(0xFF37B6FF);
  static const _proactiveKeys = [
    'email.proactive_suggestions',
    'calendar.proactive_suggestions',
  ];

  Widget? _buildProactiveSection(
    List<AiDynamicSetting> settings,
    ThemeColors theme,
  ) {

    final proactiveSettings =
        settings.where((s) => _proactiveKeys.contains(s.key)).toList();

    if (proactiveSettings.isEmpty) return null;

    final notifier = ref.read(aiDynamicSettingsProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: _emmaAccent.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _emmaAccent.withAlpha(40)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: _emmaAccent, size: 15),
              const SizedBox(width: 6),
              Text(
                'Proaktywne sugestie Emmy',
                style: TextStyle(
                  color: _emmaAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...proactiveSettings.map(
            (s) => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: s.value == true,
              onChanged: (v) => notifier.updateValue(s, v),
              activeThumbColor: _emmaAccent,
              activeTrackColor: _emmaAccent.withAlpha(100),
              title: Text(
                s.label,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: s.description.isEmpty
                  ? null
                  : Text(
                      s.description,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(153),
                        fontSize: 11,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleModuleView(
    List<AiDynamicSetting> settings,
    ThemeColors theme,
    double hPad,
  ) {
    final filtered = _applyFilter(settings);
    if (filtered.isEmpty) return _buildEmptyFilter(theme);

    final byCategory = <String, List<AiDynamicSetting>>{};
    for (final s in filtered) {
      byCategory.putIfAbsent(s.category, () => []).add(s);
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in byCategory.entries) ...[
            _CategoryLabel(label: entry.key, theme: theme),
            const SizedBox(height: 6),
            if (!widget.isMobile && entry.value.every((s) => s.fieldType == 'bool'))
              _SwitchGrid(settings: entry.value, theme: theme)
            else
              ...entry.value.map((s) => _SettingTile(setting: s, theme: theme)),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyFilter(ThemeColors theme) {
    return Center(
      child: Text(
        'emma_settings_no_results'.tr,
        style: TextStyle(
          color: theme.textColor.withAlpha(120),
          fontSize: 13,
        ),
      ),
    );
  }
}

// ---------- Sekcja modułu ----------

class _ModuleSection extends StatelessWidget {
  final String module;
  final String moduleLabel;
  final List<AiDynamicSetting> settings;
  final ThemeColors theme;
  final bool isMobile;

  const _ModuleSection({
    required this.module,
    required this.moduleLabel,
    required this.settings,
    required this.theme,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, List<AiDynamicSetting>>{};
    for (final s in settings) {
      byCategory.putIfAbsent(s.category, () => []).add(s);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(moduleLabel, theme: theme),
        const SizedBox(height: 8),
        for (final entry in byCategory.entries) ...[
          _CategoryLabel(label: entry.key, theme: theme),
          const SizedBox(height: 4),
          if (!isMobile && entry.value.every((s) => s.fieldType == 'bool'))
            _SwitchGrid(settings: entry.value, theme: theme)
          else
            ...entry.value.map((s) => _SettingTile(setting: s, theme: theme)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ---------- Siatka 2-kolumnowa dla przełączników na PC ----------

class _SwitchGrid extends StatelessWidget {
  final List<AiDynamicSetting> settings;
  final ThemeColors theme;

  const _SwitchGrid({required this.settings, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 0,
      runSpacing: 0,
      children: settings
          .map((s) => SizedBox(
                width: MediaQuery.of(context).size.width > 600
                    ? (MediaQuery.of(context).size.width / 2).clamp(200, 380)
                    : double.infinity,
                child: _SettingTile(setting: s, theme: theme),
              ))
          .toList(),
    );
  }
}

// ---------- Tile ustawienia ----------

class _SettingTile extends ConsumerWidget {
  final AiDynamicSetting setting;
  final ThemeColors theme;

  const _SettingTile({
    required this.setting,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(aiDynamicSettingsProvider.notifier);

    switch (setting.fieldType) {
      case 'bool':
        return _SwitchTile(
          title: setting.label,
          subtitle: setting.description.isEmpty ? null : setting.description,
          value: setting.value == true,
          theme: theme,
          onChanged: (v) => notifier.updateValue(setting, v),
        );

      case 'int':
        return _IntFieldTile(
          setting: setting,
          theme: theme,
          onChanged: (v) => notifier.updateValue(setting, v),
        );

      case 'choice':
        return _ChoiceTile(
          setting: setting,
          theme: theme,
          onChanged: (v) => notifier.updateValue(setting, v),
        );

      case 'str':
      default:
        return _StrFieldTile(
          setting: setting,
          theme: theme,
          onChanged: (v) => notifier.updateValue(setting, v),
        );
    }
  }
}

// ---------- Nagłówek modułu ----------

class _SectionTitle extends StatelessWidget {
  final String text;
  final ThemeColors theme;

  const _SectionTitle(this.text, {required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.themeColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ---------- Nagłówek kategorii ----------

class _CategoryLabel extends StatelessWidget {
  final String label;
  final ThemeColors theme;

  const _CategoryLabel({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: theme.textColor.withAlpha(160),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ---------- Switch ----------

class _SwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ThemeColors theme;

  const _SwitchTile({
    required this.title,
    this.subtitle,
    required this.theme,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      activeColor: theme.themeColor,
      title: Text(
        title,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(
                color: theme.textColor.withAlpha(153),
                fontSize: 11,
              ),
            ),
    );
  }
}

// ---------- Dropdown ----------

class _DropdownTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final ThemeColors theme;

  const _DropdownTile({
    required this.title,
    this.subtitle,
    required this.theme,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              color: theme.textColor.withAlpha(153),
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: theme.dashboardContainer,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white24.withAlpha(178),
                width: 0.7,
              ),
            ),
          ),
          style: TextStyle(
            color: theme.textColor,
            fontSize: 13,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: theme.textColor.withAlpha(178),
          ),
        ),
      ],
    );
  }
}

// ---------- Pole int ----------

class _IntFieldTile extends StatelessWidget {
  final AiDynamicSetting setting;
  final ThemeColors theme;
  final ValueChanged<int> onChanged;

  const _IntFieldTile({
    required this.setting,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: (setting.value ?? setting.defaultValue ?? '').toString(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            setting.label,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (setting.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              setting.description,
              style: TextStyle(
                color: theme.textColor.withAlpha(153),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onSubmitted: (txt) {
                final val = int.tryParse(txt) ?? 0;
                onChanged(val);
              },
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.white24.withAlpha(178),
                    width: 0.7,
                  ),
                ),
              ),
              style: TextStyle(
                color: theme.textColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Pole string ----------

class _StrFieldTile extends StatelessWidget {
  final AiDynamicSetting setting;
  final ThemeColors theme;
  final ValueChanged<String> onChanged;

  const _StrFieldTile({
    required this.setting,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: (setting.value ?? setting.defaultValue ?? '').toString(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            setting.label,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (setting.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              setting.description,
              style: TextStyle(
                color: theme.textColor.withAlpha(153),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: TextField(
              controller: controller,
              onSubmitted: onChanged,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.white24.withAlpha(178),
                    width: 0.7,
                  ),
                ),
              ),
              style: TextStyle(
                color: theme.textColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Choice (dropdown) ----------

class _ChoiceTile extends StatelessWidget {
  final AiDynamicSetting setting;
  final ThemeColors theme;
  final ValueChanged<String> onChanged;

  const _ChoiceTile({
    required this.setting,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentValue =
        (setting.value ?? setting.defaultValue ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _DropdownTile(
        title: setting.label,
        subtitle: setting.description.isEmpty ? null : setting.description,
        value: currentValue,
        items: setting.choices
            .map(
              (c) => DropdownMenuItem<String>(
                value: c.value,
                child: Text(c.label),
              ),
            )
            .toList(),
        theme: theme,
        onChanged: (v) {
          if (v == null) return;
          onChanged(v);
        },
      ),
    );
  }
}
