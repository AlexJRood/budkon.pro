// crm/employee_panel/widgets/employee_absence_widgets.dart

import 'package:crm/employee_panel/provider/employee_managment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

class EmployeeAbsenceCompactCard extends ConsumerWidget {
  final EmployeeManagementEmployeeModel employee;
  final String period;
  final Future<void> Function()? onChanged;

  const EmployeeAbsenceCompactCard({
    super.key,
    required this.employee,
    required this.period,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final summary = employee.absenceSummary;
    final active = summary.activeAbsence;
    final annual = summary.annualLeave;

    return _AbsenceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_busy_outlined, color: theme.textColor, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _ui('absences_and_availability', 'Nieobecności i dostępność'),
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              _AbsenceStatusPill(summary: summary),
            ],
          ),
          const SizedBox(height: 14),
          if (active != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.themeColor.withAlpha(12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dashboardBoarder),
              ),
              child: Row(
                children: [
                  Icon(_availabilityIcon(active.availabilityKind), color: theme.textColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active.absenceTypeName,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${active.startDate} - ${active.endDate}',
                          style: TextStyle(color: theme.textColor.withAlpha(155)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              _ui('employee_available_today', 'Dzisiaj dostępny/a'),
              style: TextStyle(color: theme.textColor.withAlpha(165)),
            ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth < 520
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 10) / 2;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _AbsenceMetricTile(
                      label: _ui('annual_leave', 'Urlop'),
                      value: '${annual.usedDays.toStringAsFixed(0)} / ${annual.limitDays.toStringAsFixed(0)}',
                      hint: '${_ui('available', 'Dostępne')}: ${annual.availableDays.toStringAsFixed(0)}',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _AbsenceMetricTile(
                      label: _ui('sick_leave', 'L4'),
                      value: summary.currentMonthSickLeaveDays.toStringAsFixed(1),
                      hint: _ui('days_this_month', 'dni w miesiącu'),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _AbsenceMetricTile(
                      label: _ui('pending_requests', 'Wnioski'),
                      value: summary.pendingRequestsCount.toString(),
                      hint: _ui('waiting_for_decision', 'oczekuje'),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _AbsenceMetricTile(
                      label: _ui('upcoming_absences', 'Nadchodzące'),
                      value: summary.upcomingAbsencesCount.toString(),
                      hint: _ui('planned_absences', 'zaplanowane'),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              CoreFilledButton(
                onPressed: () async {
                  final changed = await showEmployeeAbsenceRequestDialog(
                    context: context,
                    employee: employee,
                  );
                  if (changed == true) {
                    await onChanged?.call();
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 18),
                    const SizedBox(width: 7),
                    Text(_ui('add_absence', 'Dodaj nieobecność')),
                  ],
                ),
              ),
              CoreOutlinedButton(
                onPressed: () async {
                  await showEmployeeAbsenceDashboardDialog(
                    context: context,
                    employee: employee,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 18),
                    const SizedBox(width: 7),
                    Text(_ui('availability_calendar', 'Kalendarz dostępności')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AbsenceStatusPill extends ConsumerWidget {
  final EmployeeManagementAbsenceSummaryModel summary;

  const _AbsenceStatusPill({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final available = summary.isAvailableToday;
    final label = available
        ? _ui('available', 'Dostępny')
        : summary.activeAbsence?.absenceTypeName ?? _ui('unavailable', 'Niedostępny');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.check_circle_outline : Icons.event_busy_outlined,
            size: 14,
            color: theme.textColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AbsenceMetricTile extends ConsumerWidget {
  final String label;
  final String value;
  final String hint;

  const _AbsenceMetricTile({
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withAlpha(145),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hint,
            style: TextStyle(
              color: theme.textColor.withAlpha(130),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AbsenceCard extends ConsumerWidget {
  final Widget child;

  const _AbsenceCard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: theme.textColor),
        child: IconTheme.merge(
          data: IconThemeData(color: theme.textColor),
          child: child,
        ),
      ),
    );
  }
}

Future<bool?> showEmployeeAbsenceRequestDialog({
  required BuildContext context,
  required EmployeeManagementEmployeeModel employee,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: _EmployeeAbsenceRequestDialog(employee: employee),
      ),
    ),
  );
}

class _EmployeeAbsenceRequestDialog extends ConsumerStatefulWidget {
  final EmployeeManagementEmployeeModel employee;

  const _EmployeeAbsenceRequestDialog({required this.employee});

  @override
  ConsumerState<_EmployeeAbsenceRequestDialog> createState() =>
      _EmployeeAbsenceRequestDialogState();
}

class _EmployeeAbsenceRequestDialogState
    extends ConsumerState<_EmployeeAbsenceRequestDialog> {
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  EmployeeAbsenceTypeModel? _type;
  String _halfDayMode = 'none';
  bool _saving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (value == null) return;
    setState(() {
      _startDate = value;
      if (_endDate == null || _endDate!.isBefore(value)) {
        _endDate = value;
      }
    });
  }

  Future<void> _pickEnd() async {
    final start = _startDate ?? DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _endDate ?? start,
      firstDate: start,
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (value == null) return;
    setState(() => _endDate = value);
  }

  Future<void> _save() async {
    final type = _type;
    final start = _startDate;
    final end = _endDate;

    if (type == null || start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ui('fill_absence_required_fields', 'Uzupełnij typ i daty nieobecności.'))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(employeeAbsenceActionsProvider.notifier).requestAbsence(
            employeeId: widget.employee.user.id,
            absenceTypeId: type.id,
            startDate: _date(start),
            endDate: _date(end),
            halfDayMode: _halfDayMode,
            reason: _reasonController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_ui('error', 'Błąd')}: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final typesState = ref.watch(employeeAbsenceTypesProvider);

    return Material(
      color: theme.dashboardContainer,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: typesState.when(
          loading: () => const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_ui('unable_to_load_absence_types', 'Nie udało się załadować typów nieobecności')}: $error',
                style: TextStyle(color: theme.textColor),
              ),
              const SizedBox(height: 12),
              CoreOutlinedButton(
                onPressed: () => ref.read(employeeAbsenceTypesProvider.notifier).fetch(),
                child: Text(_ui('retry', 'Ponów')),
              ),
            ],
          ),
          data: (types) {
            _type ??= types.isNotEmpty ? types.first : null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _ui('add_absence', 'Dodaj nieobecność'),
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                      icon: Icon(Icons.close, color: theme.textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.employee.displayName,
                  style: TextStyle(color: theme.textColor.withAlpha(160)),
                ),
                const SizedBox(height: 16),
                CoreDropdown<EmployeeAbsenceTypeModel>(
                  label: _ui('absence_type', 'Typ nieobecności'),
                  value: _type,
                  options: types,
                  display: (value) => value.name,
                  onChanged: (value) => setState(() => _type = value),
                  prefixIcon: const Icon(Icons.event_busy_outlined, size: 18),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth < 520
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: width,
                          child: CoreOutlinedButton(
                            onPressed: _pickStart,
                            child: _DateButtonText(
                              label: _ui('start_date', 'Od'),
                              value: _startDate == null ? '' : _date(_startDate!),
                              icon: Icons.calendar_today_outlined,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: CoreOutlinedButton(
                            onPressed: _pickEnd,
                            child: _DateButtonText(
                              label: _ui('end_date', 'Do'),
                              value: _endDate == null ? '' : _date(_endDate!),
                              icon: Icons.event_outlined,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                CoreDropdown<String>(
                  label: _ui('half_day_mode', 'Dni częściowe'),
                  value: _halfDayMode,
                  options: const ['none', 'start', 'end', 'both'],
                  display: _halfDayLabel,
                  onChanged: (value) => setState(() => _halfDayMode = value ?? 'none'),
                  prefixIcon: const Icon(Icons.timelapse_outlined, size: 18),
                ),
                const SizedBox(height: 12),
                CoreTextField(
                  label: _ui('reason', 'Powód / notatka'),
                  controller: _reasonController,
                  minLines: 2,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CoreOutlinedButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                      child: Text(_ui('cancel', 'Anuluj')),
                    ),
                    const SizedBox(width: 10),
                    CoreFilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_ui('save', 'Zapisz')),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DateButtonText extends ConsumerWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DateButtonText({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.textColor),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value.isEmpty ? label : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.textColor),
          ),
        ),
      ],
    );
  }
}

Future<void> showEmployeeAbsenceDashboardDialog({
  required BuildContext context,
  required EmployeeManagementEmployeeModel employee,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 820),
        child: _EmployeeAbsenceDashboardDialog(employee: employee),
      ),
    ),
  );
}

class _EmployeeAbsenceDashboardDialog extends ConsumerWidget {
  final EmployeeManagementEmployeeModel employee;

  const _EmployeeAbsenceDashboardDialog({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final year = DateTime.now().year;
    final state = ref.watch(
      employeeAbsenceDashboardProvider(
        EmployeeAbsenceDashboardParams(
          employeeId: employee.user.id,
          year: year,
        ),
      ),
    );

    return Material(
      color: theme.dashboardContainer,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: theme.textColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _ui('availability_calendar', 'Kalendarz dostępności'),
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: theme.textColor),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dashboardBoarder),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  error.toString(),
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              data: (data) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  EmployeeAbsenceCompactCard(
                    employee: employee,
                    period: '${year.toString()}-01',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _ui('upcoming_absences', 'Nadchodzące nieobecności'),
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (data.upcoming.isEmpty)
                    Text(
                      _ui('no_upcoming_absences', 'Brak nadchodzących nieobecności.'),
                      style: TextStyle(color: theme.textColor.withAlpha(160)),
                    )
                  else
                    for (final absence in data.upcoming)
                      ListTile(
                        leading: Icon(_availabilityIcon(absence.availabilityKind), color: theme.textColor),
                        title: Text(
                          absence.absenceTypeName,
                          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${absence.startDate} - ${absence.endDate} • ${absence.status.tr}',
                          style: TextStyle(color: theme.textColor.withAlpha(150)),
                        ),
                        trailing: Text(
                          '${absence.daysCount.toStringAsFixed(1)} d',
                          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _availabilityIcon(String value) {
  switch (value) {
    case 'sick':
      return Icons.healing_outlined;
    case 'remote':
      return Icons.home_work_outlined;
    case 'business_trip':
      return Icons.flight_takeoff_outlined;
    case 'out_of_office':
      return Icons.event_busy_outlined;
    default:
      return Icons.check_circle_outline;
  }
}

String _halfDayLabel(String value) {
  switch (value) {
    case 'start':
      return _ui('half_day_start', 'Pół dnia na początku');
    case 'end':
      return _ui('half_day_end', 'Pół dnia na końcu');
    case 'both':
      return _ui('half_day_both', 'Pół dnia na początku i końcu');
    default:
      return _ui('full_days', 'Pełne dni');
  }
}

String _date(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String _ui(String key, String fallback) {
  final translated = key.tr;
  return translated == key ? fallback : translated;
}
