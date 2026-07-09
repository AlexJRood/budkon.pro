import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

class CompensationLeavePolicyDraft {
  final String entitlementMode;
  final String statutoryCountry;
  final double seniorityYearsAtStart;
  final double educationYearsCredit;
  final double customEntitlementDays;
  final double fullTimeEquivalent;
  final String accrualMethod;
  final bool usePublicHolidays;
  final bool carryOverEnabled;
  final String cashoutPolicy;
  final String cashoutDailyRateMode;
  final double cashoutCustomDailyRate;
  final String note;

  const CompensationLeavePolicyDraft({
    this.entitlementMode = 'statutory_pl',
    this.statutoryCountry = 'PL',
    this.seniorityYearsAtStart = 0,
    this.educationYearsCredit = 0,
    this.customEntitlementDays = 0,
    this.fullTimeEquivalent = 1,
    this.accrualMethod = 'monthly_prorated',
    this.usePublicHolidays = true,
    this.carryOverEnabled = true,
    this.cashoutPolicy = 'termination_only',
    this.cashoutDailyRateMode = 'base_amount',
    this.cashoutCustomDailyRate = 0,
    this.note = '',
  });

  double get statutoryEntitlementDays {
    if (entitlementMode == 'custom') return customEntitlementDays;
    final seniority = seniorityYearsAtStart + educationYearsCredit;
    final base = seniority >= 10 ? 26.0 : 20.0;
    return (base * fullTimeEquivalent).ceilToDouble();
  }

  CompensationLeavePolicyDraft copyWith({
    String? entitlementMode,
    String? statutoryCountry,
    double? seniorityYearsAtStart,
    double? educationYearsCredit,
    double? customEntitlementDays,
    double? fullTimeEquivalent,
    String? accrualMethod,
    bool? usePublicHolidays,
    bool? carryOverEnabled,
    String? cashoutPolicy,
    String? cashoutDailyRateMode,
    double? cashoutCustomDailyRate,
    String? note,
  }) {
    return CompensationLeavePolicyDraft(
      entitlementMode: entitlementMode ?? this.entitlementMode,
      statutoryCountry: statutoryCountry ?? this.statutoryCountry,
      seniorityYearsAtStart: seniorityYearsAtStart ?? this.seniorityYearsAtStart,
      educationYearsCredit: educationYearsCredit ?? this.educationYearsCredit,
      customEntitlementDays: customEntitlementDays ?? this.customEntitlementDays,
      fullTimeEquivalent: fullTimeEquivalent ?? this.fullTimeEquivalent,
      accrualMethod: accrualMethod ?? this.accrualMethod,
      usePublicHolidays: usePublicHolidays ?? this.usePublicHolidays,
      carryOverEnabled: carryOverEnabled ?? this.carryOverEnabled,
      cashoutPolicy: cashoutPolicy ?? this.cashoutPolicy,
      cashoutDailyRateMode: cashoutDailyRateMode ?? this.cashoutDailyRateMode,
      cashoutCustomDailyRate: cashoutCustomDailyRate ?? this.cashoutCustomDailyRate,
      note: note ?? this.note,
    );
  }

  factory CompensationLeavePolicyDraft.fromJson(Map<String, dynamic> json) {
    return CompensationLeavePolicyDraft(
      entitlementMode: _asString(json['entitlement_mode'], fallback: 'statutory_pl'),
      statutoryCountry: _asString(json['statutory_country'], fallback: 'PL'),
      seniorityYearsAtStart: _asDouble(json['seniority_years_at_start']),
      educationYearsCredit: _asDouble(json['education_years_credit']),
      customEntitlementDays: _asDouble(json['custom_entitlement_days']),
      fullTimeEquivalent: _asDouble(json['full_time_equivalent'], fallback: 1),
      accrualMethod: _asString(json['accrual_method'], fallback: 'monthly_prorated'),
      usePublicHolidays: _asBool(json['use_public_holidays'], fallback: true),
      carryOverEnabled: _asBool(json['carry_over_enabled'], fallback: true),
      cashoutPolicy: _asString(json['cashout_policy'], fallback: 'termination_only'),
      cashoutDailyRateMode: _asString(json['cashout_daily_rate_mode'], fallback: 'base_amount'),
      cashoutCustomDailyRate: _asDouble(json['cashout_custom_daily_rate']),
      note: _asString(json['note']),
    );
  }

  Map<String, dynamic> toJson() => {
        'entitlement_mode': entitlementMode,
        'statutory_country': statutoryCountry,
        'seniority_years_at_start': seniorityYearsAtStart,
        'education_years_credit': educationYearsCredit,
        'custom_entitlement_days': customEntitlementDays,
        'full_time_equivalent': fullTimeEquivalent,
        'accrual_method': accrualMethod,
        'use_public_holidays': usePublicHolidays,
        'carry_over_enabled': carryOverEnabled,
        'cashout_policy': cashoutPolicy,
        'cashout_daily_rate_mode': cashoutDailyRateMode,
        'cashout_custom_daily_rate': cashoutCustomDailyRate,
        'note': note,
      };
}

class CompensationLeavePolicySection extends ConsumerStatefulWidget {
  final CompensationLeavePolicyDraft value;
  final ValueChanged<CompensationLeavePolicyDraft> onChanged;
  final String currency;

  const CompensationLeavePolicySection({
    super.key,
    required this.value,
    required this.onChanged,
    this.currency = 'PLN',
  });

  @override
  ConsumerState<CompensationLeavePolicySection> createState() =>
      _CompensationLeavePolicySectionState();
}

class _CompensationLeavePolicySectionState
    extends ConsumerState<CompensationLeavePolicySection> {
  late final TextEditingController _seniority;
  late final TextEditingController _education;
  late final TextEditingController _customDays;
  late final TextEditingController _fte;
  late final TextEditingController _customDailyRate;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _seniority = TextEditingController(text: widget.value.seniorityYearsAtStart.toStringAsFixed(2));
    _education = TextEditingController(text: widget.value.educationYearsCredit.toStringAsFixed(2));
    _customDays = TextEditingController(text: widget.value.customEntitlementDays.toStringAsFixed(2));
    _fte = TextEditingController(text: widget.value.fullTimeEquivalent.toStringAsFixed(2));
    _customDailyRate = TextEditingController(text: widget.value.cashoutCustomDailyRate.toStringAsFixed(2));
    _note = TextEditingController(text: widget.value.note);
  }

  @override
  void didUpdateWidget(covariant CompensationLeavePolicySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    _seniority.text = widget.value.seniorityYearsAtStart.toStringAsFixed(2);
    _education.text = widget.value.educationYearsCredit.toStringAsFixed(2);
    _customDays.text = widget.value.customEntitlementDays.toStringAsFixed(2);
    _fte.text = widget.value.fullTimeEquivalent.toStringAsFixed(2);
    _customDailyRate.text = widget.value.cashoutCustomDailyRate.toStringAsFixed(2);
    _note.text = widget.value.note;
  }

  @override
  void dispose() {
    _seniority.dispose();
    _education.dispose();
    _customDays.dispose();
    _fte.dispose();
    _customDailyRate.dispose();
    _note.dispose();
    super.dispose();
  }

  void _emit(CompensationLeavePolicyDraft value) {
    widget.onChanged(value);
  }

  void _emitFromControllers() {
    _emit(widget.value.copyWith(
      seniorityYearsAtStart: _parse(_seniority.text),
      educationYearsCredit: _parse(_education.text),
      customEntitlementDays: _parse(_customDays.text),
      fullTimeEquivalent: _parse(_fte.text, fallback: 1).clamp(0, 1),
      cashoutCustomDailyRate: _parse(_customDailyRate.text),
      note: _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final value = widget.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 240,
              child: CoreDropdown<String>(
                label: 'leave_entitlement_mode'.tr,
                value: value.entitlementMode,
                options: const ['statutory_pl', 'custom'],
                display: _entitlementModeLabel,
                onChanged: (selected) {
                  if (selected == null) return;
                  _emit(value.copyWith(entitlementMode: selected));
                },
              ),
            ),
            SizedBox(
              width: 180,
              child: CoreTextFormField(
                label: 'seniority_years'.tr,
                controller: _seniority,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalFormatter],
                onChanged: (_) => _emitFromControllers(),
              ),
            ),
            SizedBox(
              width: 180,
              child: CoreTextFormField(
                label: 'education_credit_years'.tr,
                controller: _education,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalFormatter],
                onChanged: (_) => _emitFromControllers(),
              ),
            ),
            SizedBox(
              width: 150,
              child: CoreTextFormField(
                label: 'fte'.tr,
                controller: _fte,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalFormatter],
                onChanged: (_) => _emitFromControllers(),
              ),
            ),
            if (value.entitlementMode == 'custom')
              SizedBox(
                width: 180,
                child: CoreTextFormField(
                  label: 'custom_leave_days'.tr,
                  controller: _customDays,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [_decimalFormatter],
                  onChanged: (_) => _emitFromControllers(),
                ),
              ),
            SizedBox(
              width: 240,
              child: CoreDropdown<String>(
                label: 'leave_accrual_method'.tr,
                value: value.accrualMethod,
                options: const ['monthly_prorated', 'upfront_prorated', 'manual'],
                display: _accrualMethodLabel,
                onChanged: (selected) {
                  if (selected == null) return;
                  _emit(value.copyWith(accrualMethod: selected));
                },
              ),
            ),
            SizedBox(
              width: 240,
              child: CoreDropdown<String>(
                label: 'leave_cashout_policy'.tr,
                value: value.cashoutPolicy,
                options: const ['termination_only', 'manual_allowed', 'disabled'],
                display: _cashoutPolicyLabel,
                onChanged: (selected) {
                  if (selected == null) return;
                  _emit(value.copyWith(cashoutPolicy: selected));
                },
              ),
            ),
            SizedBox(
              width: 240,
              child: CoreDropdown<String>(
                label: 'cashout_daily_rate'.tr,
                value: value.cashoutDailyRateMode,
                options: const ['base_amount', 'hourly_expected', 'custom_daily_rate'],
                display: _dailyRateModeLabel,
                onChanged: (selected) {
                  if (selected == null) return;
                  _emit(value.copyWith(cashoutDailyRateMode: selected));
                },
              ),
            ),
            if (value.cashoutDailyRateMode == 'custom_daily_rate')
              SizedBox(
                width: 180,
                child: CoreTextFormField(
                  label: '${'daily_rate'.tr} ${widget.currency}',
                  controller: _customDailyRate,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [_decimalFormatter],
                  onChanged: (_) => _emitFromControllers(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SwitchPill(
              label: 'public_holidays'.tr,
              value: value.usePublicHolidays,
              onChanged: (selected) => _emit(value.copyWith(usePublicHolidays: selected)),
            ),
            _SwitchPill(
              label: 'carry_over'.tr,
              value: value.carryOverEnabled,
              onChanged: (selected) => _emit(value.copyWith(carryOverEnabled: selected)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.themeColor.withAlpha(14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.textColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Roczny limit wg ustawień: ${value.statutoryEntitlementDays.toStringAsFixed(0)} dni. Naliczenie: ${_accrualMethodLabel(value.accrualMethod)}.',
                  style: TextStyle(color: theme.textColor.withAlpha(190), height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CoreTextFormField(
          label: 'leave_policy_note'.tr,
          controller: _note,
          minLines: 2,
          maxLines: 4,
          onChanged: (_) => _emitFromControllers(),
        ),
      ],
    );
  }
}

class _SwitchPill extends ConsumerWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchPill({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: value ? theme.themeColor.withAlpha(28) : theme.adPopBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: value ? theme.themeColor : theme.dashboardBoarder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(value ? Icons.check_circle_outline : Icons.circle_outlined, size: 15, color: theme.textColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: theme.textColor, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

final _decimalFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'));

double _parse(String value, {double fallback = 0}) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
}

String _entitlementModeLabel(String value) {
  switch (value) {
    case 'custom':
      return 'Własny limit';
    default:
      return 'Ustawowy PL';
  }
}

String _accrualMethodLabel(String value) {
  switch (value) {
    case 'upfront_prorated':
      return 'Limit roczny proporcjonalny';
    case 'manual':
      return 'Ręcznie';
    default:
      return 'Miesięcznie proporcjonalnie';
  }
}

String _cashoutPolicyLabel(String value) {
  switch (value) {
    case 'manual_allowed':
      return 'Dozwolony ręcznie';
    case 'disabled':
      return 'Wyłączony';
    default:
      return 'Tylko przy zakończeniu';
  }
}

String _dailyRateModeLabel(String value) {
  switch (value) {
    case 'hourly_expected':
      return 'Stawka godzinowa x godziny';
    case 'custom_daily_rate':
      return 'Własna dniówka';
    default:
      return 'Podstawa / dni robocze';
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}
