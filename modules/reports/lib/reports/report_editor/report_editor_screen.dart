import 'dart:io';

import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

import 'model/report_template_model.dart';
import 'provider/report_template_provider.dart';

// ── Entry point ──────────────────────────────────────────────────────────────

class ReportEditorScreen extends ConsumerWidget {
  const ReportEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync = ref.watch(activeReportTemplateProvider);

    return templateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('error_loading'.tr)),
      data: (template) => _EditorBody(
        initial: template ?? const ReportTemplateModel(),
      ),
    );
  }
}

// ── Main editor body ─────────────────────────────────────────────────────────

class _EditorBody extends ConsumerStatefulWidget {
  final ReportTemplateModel initial;
  const _EditorBody({required this.initial});

  @override
  ConsumerState<_EditorBody> createState() => _EditorBodyState();
}

class _EditorBodyState extends ConsumerState<_EditorBody> {
  late ReportTemplateModel _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  void _update(ReportTemplateModel updated) => setState(() => _draft = updated);

  Future<void> _save() async {
    setState(() => _saving = true);
    final notifier = ref.reportTemplateListNotifier;
    ReportTemplateModel? result;
    if (_draft.id != null) {
      result = await notifier.updateTemplate(_draft.id!, _draft);
    } else {
      result = await notifier.create(_draft);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (result != null) {
      setState(() => _draft = result!);
      _showSnack('template_saved'.tr);
    } else {
      _showSnack('error_saving'.tr, isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          SizedBox(height: TopAppBarSize.resolve(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'report_editor'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_saving)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  CoreFilledButton(
                    onPressed: _save,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 18),
                        const SizedBox(width: 6),
                        Text('save'.tr),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          TabBar(
            labelColor: _draft.primaryColor,
            unselectedLabelColor: theme.textColor.withValues(alpha: 0.55),
            indicatorColor: _draft.primaryColor,
            tabs: [
              Tab(text: 'branding'.tr),
              Tab(text: 'colors'.tr),
              Tab(text: 'sections'.tr),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _BrandingTab(draft: _draft, onUpdate: _update),
                _ColorsTab(draft: _draft, onUpdate: _update),
                _SectionsTab(draft: _draft, onUpdate: _update),
              ],
            ),
          ),
          SizedBox(height: TopAppBarSize.withTopAppBar(context)),
        ],
      ),
    );
  }
}

// ── Helper to get the notifier ────────────────────────────────────────────────

extension _TemplateNotifier on WidgetRef {
  ReportTemplateListNotifier get reportTemplateListNotifier =>
      read(reportTemplateListProvider.notifier);
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 1 — Branding
// ═══════════════════════════════════════════════════════════════════════════════

class _BrandingTab extends ConsumerStatefulWidget {
  final ReportTemplateModel draft;
  final ValueChanged<ReportTemplateModel> onUpdate;

  const _BrandingTab({required this.draft, required this.onUpdate});

  @override
  ConsumerState<_BrandingTab> createState() => _BrandingTabState();
}

class _BrandingTabState extends ConsumerState<_BrandingTab> {
  final _picker = ImagePicker();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _agentNameCtrl;
  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _footerCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _nameCtrl = TextEditingController(text: d.name);
    _agentNameCtrl = TextEditingController(text: d.agentName ?? '');
    _companyNameCtrl = TextEditingController(text: d.companyName ?? '');
    _phoneCtrl = TextEditingController(text: d.phone ?? '');
    _emailCtrl = TextEditingController(text: d.email ?? '');
    _footerCtrl = TextEditingController(text: d.customFooter ?? '');
  }

  @override
  void didUpdateWidget(_BrandingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final d = widget.draft;
    if (_nameCtrl.text != d.name) _nameCtrl.text = d.name;
    if (_agentNameCtrl.text != d.agentName) _agentNameCtrl.text = d.agentName;
    if (_companyNameCtrl.text != d.companyName) _companyNameCtrl.text = d.companyName;
    if (_phoneCtrl.text != d.phone) _phoneCtrl.text = d.phone;
    if (_emailCtrl.text != d.email) _emailCtrl.text = d.email;
    if (_footerCtrl.text != d.customFooter) _footerCtrl.text = d.customFooter;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _agentNameCtrl.dispose();
    _companyNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 400,
      imageQuality: 90,
    );
    if (xfile == null || !mounted) return;
    final id = widget.draft.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('save_before_logo'.tr)),
      );
      return;
    }
    final updated = await ref.reportTemplateListNotifier
        .uploadLogo(id, File(xfile.path));
    if (updated != null) widget.onUpdate(updated);
  }

  Future<void> _removeLogo() async {
    final id = widget.draft.id;
    if (id == null) return;
    final ok = await ref.reportTemplateListNotifier.removeLogo(id);
    if (ok) widget.onUpdate(widget.draft.copyWith(clearLogo: true));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          children: [
            const _SectionHeader('template_name'),
            CoreTextField(
              label: 'template_name'.tr,
              controller: _nameCtrl,
              onChanged: (v) => widget.onUpdate(d.copyWith(name: v)),
            ),
            const SizedBox(height: 24),

            const _SectionHeader('logo'),
            _LogoWidget(
              logoUrl: d.logoUrl,
              onPick: _pickLogo,
              onRemove: d.logoUrl != null ? _removeLogo : null,
              primaryColor: d.primaryColor,
            ),
            const SizedBox(height: 24),

            const _SectionHeader('agent_info'),
            CoreTextField(
              label: 'agent_name'.tr,
              controller: _agentNameCtrl,
              onChanged: (v) => widget.onUpdate(d.copyWith(agentName: v)),
            ),
            const SizedBox(height: 12),
            CoreTextField(
              label: 'company_name'.tr,
              controller: _companyNameCtrl,
              onChanged: (v) => widget.onUpdate(d.copyWith(companyName: v)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CoreTextField(
                    label: 'phone'.tr,
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => widget.onUpdate(d.copyWith(phone: v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CoreTextField(
                    label: 'email'.tr,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) => widget.onUpdate(d.copyWith(email: v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const _SectionHeader('custom_footer'),
            CoreTextField(
              label: 'footer_placeholder'.tr,
              controller: _footerCtrl,
              maxLines: 3,
              onChanged: (v) => widget.onUpdate(d.copyWith(customFooter: v)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 2 — Colors
// ═══════════════════════════════════════════════════════════════════════════════

class _ColorsTab extends ConsumerWidget {
  final ReportTemplateModel draft;
  final ValueChanged<ReportTemplateModel> onUpdate;

  const _ColorsTab({required this.draft, required this.onUpdate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = draft;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          children: [
            const _SectionHeader('color_scheme'),
            const SizedBox(height: 8),
            // 2-column grid for the 4 color pickers
            Row(
              children: [
                Expanded(
                  child: ColorPickerField(
                    label: 'color_primary'.tr,
                    value: d.colorPrimary,
                    onChanged: (v) => onUpdate(d.copyWith(colorPrimary: v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ColorPickerField(
                    label: 'color_accent'.tr,
                    value: d.colorAccent,
                    onChanged: (v) => onUpdate(d.copyWith(colorAccent: v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ColorPickerField(
                    label: 'color_background'.tr,
                    value: d.colorBackground,
                    onChanged: (v) => onUpdate(d.copyWith(colorBackground: v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ColorPickerField(
                    label: 'color_text'.tr,
                    value: d.colorText,
                    onChanged: (v) => onUpdate(d.copyWith(colorText: v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const _SectionHeader('presets'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _kPresets.map((preset) {
                return GestureDetector(
                  onTap: () => onUpdate(d.copyWith(
                    colorPrimary: preset.primary,
                    colorAccent: preset.accent,
                    colorBackground: preset.bg,
                    colorText: preset.text,
                  )),
                  child: _PresetChip(preset: preset),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const _SectionHeader('preview'),
            const SizedBox(height: 12),
            _ColorPreview(template: d),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 3 — Sections
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionsTab extends ConsumerWidget {
  final ReportTemplateModel draft;
  final ValueChanged<ReportTemplateModel> onUpdate;

  const _SectionsTab({required this.draft, required this.onUpdate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final d = draft;

    final sections = [
      _SectionToggle('show_price_alert', 'section_price_alert'.tr, Icons.notifications_active_outlined, d.showPriceAlert, (v) => onUpdate(d.copyWith(showPriceAlert: v))),
      _SectionToggle('show_value_history', 'section_value_history'.tr, Icons.timeline, d.showValueHistory, (v) => onUpdate(d.copyWith(showValueHistory: v))),
      _SectionToggle('show_investment_score', 'section_investment_score'.tr, Icons.star_outline, d.showInvestmentScore, (v) => onUpdate(d.copyWith(showInvestmentScore: v))),
      _SectionToggle('show_market_velocity', 'section_market_velocity'.tr, Icons.speed_outlined, d.showMarketVelocity, (v) => onUpdate(d.copyWith(showMarketVelocity: v))),
      _SectionToggle('show_daily_market_overview', 'section_daily_market_overview'.tr, Icons.bar_chart, d.showDailyMarketOverview, (v) => onUpdate(d.copyWith(showDailyMarketOverview: v))),
      _SectionToggle('show_government_data', 'section_government_data'.tr, Icons.account_balance_outlined, d.showGovernmentData, (v) => onUpdate(d.copyWith(showGovernmentData: v))),
      _SectionToggle('show_demographics', 'section_demographics'.tr, Icons.people_outline, d.showDemographics, (v) => onUpdate(d.copyWith(showDemographics: v))),
      _SectionToggle('show_price_trend', 'section_price_trend'.tr, Icons.trending_up, d.showPriceTrend, (v) => onUpdate(d.copyWith(showPriceTrend: v))),
      _SectionToggle('show_flood_risk', 'section_flood_risk'.tr, Icons.water_outlined, d.showFloodRisk, (v) => onUpdate(d.copyWith(showFloodRisk: v))),
      _SectionToggle('show_air_quality', 'section_air_quality'.tr, Icons.air, d.showAirQuality, (v) => onUpdate(d.copyWith(showAirQuality: v))),
      _SectionToggle('show_poi', 'section_poi'.tr, Icons.place_outlined, d.showPoi, (v) => onUpdate(d.copyWith(showPoi: v))),
      _SectionToggle('show_maintenance_cost', 'section_maintenance_cost'.tr, Icons.home_repair_service_outlined, d.showMaintenanceCost, (v) => onUpdate(d.copyWith(showMaintenanceCost: v))),
      _SectionToggle('show_comparables', 'section_comparables'.tr, Icons.compare_arrows, d.showComparables, (v) => onUpdate(d.copyWith(showComparables: v))),
      _SectionToggle('show_accuracy_index', 'section_accuracy_index'.tr, Icons.verified_outlined, d.showAccuracyIndex, (v) => onUpdate(d.copyWith(showAccuracyIndex: v))),
      _SectionToggle('show_rental_data', 'section_rental_data'.tr, Icons.key_outlined, d.showRentalData, (v) => onUpdate(d.copyWith(showRentalData: v))),
      _SectionToggle('show_price_distribution', 'section_price_distribution'.tr, Icons.stacked_bar_chart, d.showPriceDistribution, (v) => onUpdate(d.copyWith(showPriceDistribution: v))),
      _SectionToggle('show_agent_notes', 'section_agent_notes'.tr, Icons.edit_note, d.showAgentNotes, (v) => onUpdate(d.copyWith(showAgentNotes: v))),
      _SectionToggle('show_report_versions', 'section_report_versions'.tr, Icons.history, d.showReportVersions, (v) => onUpdate(d.copyWith(showReportVersions: v))),
      _SectionToggle('show_mortgage_calculator', 'section_mortgage_calculator'.tr, Icons.account_balance, d.showMortgageCalculator, (v) => onUpdate(d.copyWith(showMortgageCalculator: v))),
    ];

    final enabledCount = sections.where((s) => s.value).length;
    final isMobile = DeviceTypeUtil.isMobile(context);

    final toolbar = Padding(
      padding: EdgeInsets.fromLTRB(24, isMobile ? 0 : 16, 24, 8),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$enabledCount / ${sections.length} ${'sections_enabled'.tr}',
                  style: TextStyle(
                    color: theme.textColor.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CoreOutlinedButton(
                        onPressed: () => onUpdate(d.copyWith(
                          showPriceAlert: true, showValueHistory: true,
                          showInvestmentScore: true, showMarketVelocity: true,
                          showDailyMarketOverview: true, showGovernmentData: true,
                          showDemographics: true, showPriceTrend: true,
                          showFloodRisk: true, showAirQuality: true, showPoi: true,
                          showMaintenanceCost: true, showComparables: true,
                          showAccuracyIndex: true, showRentalData: true,
                          showPriceDistribution: true, showAgentNotes: true,
                          showReportVersions: true, showMortgageCalculator: true,
                        )),
                        child: Text('select_all'.tr),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CoreOutlinedButton(
                        onPressed: () => onUpdate(d.copyWith(
                          showPriceAlert: false, showValueHistory: false,
                          showInvestmentScore: false, showMarketVelocity: false,
                          showDailyMarketOverview: false, showGovernmentData: false,
                          showDemographics: false, showPriceTrend: false,
                          showFloodRisk: false, showAirQuality: false, showPoi: false,
                          showMaintenanceCost: false, showComparables: false,
                          showAccuracyIndex: false, showRentalData: false,
                          showPriceDistribution: false, showAgentNotes: false,
                          showReportVersions: false, showMortgageCalculator: false,
                        )),
                        child: Text('deselect_all'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    '$enabledCount / ${sections.length} ${'sections_enabled'.tr}',
                    style: TextStyle(
                      color: theme.textColor.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
                ),
                CoreOutlinedButton(
                  onPressed: () => onUpdate(d.copyWith(
                    showPriceAlert: true, showValueHistory: true,
                    showInvestmentScore: true, showMarketVelocity: true,
                    showDailyMarketOverview: true, showGovernmentData: true,
                    showDemographics: true, showPriceTrend: true,
                    showFloodRisk: true, showAirQuality: true, showPoi: true,
                    showMaintenanceCost: true, showComparables: true,
                    showAccuracyIndex: true, showRentalData: true,
                    showPriceDistribution: true, showAgentNotes: true,
                    showReportVersions: true, showMortgageCalculator: true,
                  )),
                  child: Text('select_all'.tr),
                ),
                const SizedBox(width: 8),
                CoreOutlinedButton(
                  onPressed: () => onUpdate(d.copyWith(
                    showPriceAlert: false, showValueHistory: false,
                    showInvestmentScore: false, showMarketVelocity: false,
                    showDailyMarketOverview: false, showGovernmentData: false,
                    showDemographics: false, showPriceTrend: false,
                    showFloodRisk: false, showAirQuality: false, showPoi: false,
                    showMaintenanceCost: false, showComparables: false,
                    showAccuracyIndex: false, showRentalData: false,
                    showPriceDistribution: false, showAgentNotes: false,
                    showReportVersions: false, showMortgageCalculator: false,
                  )),
                  child: Text('deselect_all'.tr),
                ),
              ],
            ),
    );

    // On mobile the toolbar scrolls together with the section list; on
    // larger screens it stays pinned above the scrollable list.
    if (isMobile) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: sections.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return toolbar;
              final s = sections[i - 1];
              return Card(
                color: theme.adPopBackground,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: SwitchListTile(
                  secondary: Icon(s.icon,
                      color: s.value
                          ? d.primaryColor
                          : theme.textColor.withValues(alpha: 0.4)),
                  title: Text(s.label,
                      style: TextStyle(color: theme.textColor, fontSize: 14)),
                  value: s.value,
                  activeColor: d.primaryColor,
                  onChanged: s.onChanged,
                ),
              );
            },
          ),
        ),
      );
    }

    return Column(
      children: [
        // Toolbar: count + select/deselect buttons, centred + constrained
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: toolbar,
          ),
        ),
        // List of section toggles — centred + constrained, fills remaining height
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: sections.length,
                itemBuilder: (context, i) {
                  final s = sections[i];
                  return Card(
                    color: theme.adPopBackground,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: SwitchListTile(
                      secondary: Icon(s.icon,
                          color: s.value
                              ? d.primaryColor
                              : theme.textColor.withValues(alpha: 0.4)),
                      title: Text(s.label,
                          style: TextStyle(color: theme.textColor, fontSize: 14)),
                      value: s.value,
                      activeColor: d.primaryColor,
                      onChanged: s.onChanged,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared small widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends ConsumerWidget {
  final String translationKey;
  const _SectionHeader(this.translationKey);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        translationKey.tr,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _LogoWidget extends ConsumerWidget {
  final String? logoUrl;
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final Color primaryColor;

  const _LogoWidget({
    required this.logoUrl,
    required this.onPick,
    required this.onRemove,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final borderColor = theme.textColor.withValues(alpha: 0.2);

    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: logoUrl != null
          ? Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.network(
                    logoUrl!,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconBtn(icon: Icons.edit, onTap: onPick),
                      if (onRemove != null) ...[
                        const SizedBox(width: 4),
                        _IconBtn(icon: Icons.delete_outline, onTap: onRemove!),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: primaryColor, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'upload_logo'.tr,
                    style: TextStyle(
                      color: theme.textColor.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'PNG, JPG, SVG · max 5 MB',
                    style: TextStyle(
                      color: theme.textColor.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

// ── Preset chip ───────────────────────────────────────────────────────────────

class _ColorPreset {
  final String name;
  final String primary;
  final String accent;
  final String bg;
  final String text;
  const _ColorPreset(this.name, this.primary, this.accent, this.bg, this.text);
}

const _kPresets = [
  _ColorPreset('Hously', '#5FCDD9', '#2FB8C6', '#F6F7F9', '#171A1F'),
  _ColorPreset('Ocean', '#0077B6', '#0096C7', '#F0F8FF', '#03045E'),
  _ColorPreset('Forest', '#2D6A4F', '#40916C', '#F0FFF4', '#1B4332'),
  _ColorPreset('Sunset', '#E07A5F', '#F2CC8F', '#FFFBF5', '#3D405B'),
  _ColorPreset('Slate', '#6B7280', '#9CA3AF', '#F9FAFB', '#111827'),
  _ColorPreset('Rose', '#E11D48', '#FB7185', '#FFF1F2', '#1F1030'),
];

class _PresetChip extends StatelessWidget {
  final _ColorPreset preset;
  const _PresetChip({required this.preset});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _swatch(preset.primary),
            _swatch(preset.accent),
            _swatch(preset.bg),
            _swatch(preset.text),
          ],
        ),
        const SizedBox(height: 4),
        Text(preset.name, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _swatch(String hex) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: ReportTemplateModel.hexToColor(hex),
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}

class _ColorPreview extends StatelessWidget {
  final ReportTemplateModel template;
  const _ColorPreview({required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: template.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: template.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.home, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'preview_report_title'.tr,
                    style: TextStyle(
                      color: template.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'preview_subtitle'.tr,
                    style: TextStyle(
                      color: template.textColor.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: template.accentColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'preview_body_text'.tr,
            style: TextStyle(
              color: template.textColor.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section toggle data ───────────────────────────────────────────────────────

class _SectionToggle {
  final String key;
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SectionToggle(
      this.key, this.label, this.icon, this.value, this.onChanged);
}
