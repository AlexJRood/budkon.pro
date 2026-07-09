// crm/employee_panel/widgets/employee_availability_widgets.dart

import 'package:crm/calendar/provider/member_calendar_layer_provider.dart';
import 'package:crm/calendar/widgets/member_calendar_hr_layer.dart';
import 'package:crm/employee_panel/provider/employee_availability_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

class EmployeeAvailabilityCompactCard extends ConsumerWidget {
  final int employeeId;
  final DateTime? start;
  final DateTime? end;
  final VoidCallback? onOpenCalendar;
  final VoidCallback? onEditAvailability;

  const EmployeeAvailabilityCompactCard({
    super.key,
    required this.employeeId,
    this.start,
    this.end,
    this.onOpenCalendar,
    this.onEditAvailability,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final today = DateTime.now();
    final state = ref.watch(
      employeeAvailabilityDashboardProvider(
        EmployeeAvailabilityDashboardParams(
          employeeId: employeeId,
          start: _date(start ?? today),
          end: _date(end ?? today.add(const Duration(days: 30))),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: state.when(
        loading: () => const SizedBox(
          height: 96,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => _ErrorContent(message: error.toString()),
        data: (data) {
          final statusColor = _hexToColor(data.todayStatus.color);
          final profile = data.profile;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(28),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withAlpha(120)),
                    ),
                    child: Icon(
                      _statusIcon(data.todayStatus.key),
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'availability'.tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          data.todayStatus.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onEditAvailability != null)
                    CoreIconButton(
                      icon: Icons.tune_outlined,
                      onPressed: onEditAvailability,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.work_outline,
                    label: _workModeLabel(profile?.workMode ?? 'appointment_based'),
                  ),
                  if (profile?.allowEveningAppointments ?? true)
                    const _InfoChip(
                      icon: Icons.nights_stay_outlined,
                      label: 'Prezentacje wieczorem',
                    ),
                  if (profile?.allowWeekendAppointments ?? true)
                    const _InfoChip(
                      icon: Icons.weekend_outlined,
                      label: 'Weekendowe prezentacje',
                    ),
                  if (profile?.isTimeTrackingEnabled ?? false)
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: '${data.totalHours.toStringAsFixed(1)}h w okresie',
                    ),
                ],
              ),
              if (data.bookableToday.isNotEmpty) ...[
                const SizedBox(height: 14),
                _AvailabilityTimeline(blocks: data.bookableToday.take(3).toList()),
              ],
              if (onOpenCalendar != null || onEditAvailability != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (onOpenCalendar != null)
                      Expanded(
                        child: CoreOutlinedButton(
                          onPressed: onOpenCalendar,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_month_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text('calendar'.tr),
                            ],
                          ),
                        ),
                      ),
                    if (onOpenCalendar != null && onEditAvailability != null)
                      const SizedBox(width: 10),
                    if (onEditAvailability != null)
                      Expanded(
                        child: CoreFilledButton(
                          onPressed: onEditAvailability,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.edit_calendar_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text('edit'.tr),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class EmployeeAvailabilityWeekPreview extends ConsumerWidget {
  final DateTime weekStart;
  final int? employeeId;
  final bool includeAllLayers;

  const EmployeeAvailabilityWeekPreview({
    super.key,
    required this.weekStart,
    this.employeeId,
    this.includeAllLayers = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final start = _monday(weekStart);
    final end = start.add(const Duration(days: 6));
    final state = ref.watch(
      employeeAvailabilityCalendarProvider(
        EmployeeAvailabilityCalendarParams(
          start: _date(start),
          end: _date(end),
          employeeId: employeeId,
          includeRules: includeAllLayers,
          includeAbsences: true,
          includeOverrides: true,
          includeTimeEntries: true,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: state.when(
        loading: () => const SizedBox(height: 110, child: Center(child: CircularProgressIndicator())),
        error: (error, _) => _ErrorContent(message: error.toString()),
        data: (blocks) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dostępność w tygodniu',
                style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 6 ? 0 : 8),
                        child: _DayColumn(
                          day: start.add(Duration(days: i)),
                          blocks: blocks.where((block) => block.occursOn(start.add(Duration(days: i)))).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class EmployeeAvailabilityQuickActions extends ConsumerStatefulWidget {
  final int employeeId;
  final VoidCallback? onDone;

  const EmployeeAvailabilityQuickActions({
    super.key,
    required this.employeeId,
    this.onDone,
  });

  @override
  ConsumerState<EmployeeAvailabilityQuickActions> createState() =>
      _EmployeeAvailabilityQuickActionsState();
}

class _EmployeeAvailabilityQuickActionsState
    extends ConsumerState<EmployeeAvailabilityQuickActions> {
  bool _isRunning = false;

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      await action();
      _refreshAvailabilityProviders(ref, widget.employeeId);
      widget.onDone?.call();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      });
    } catch (error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      });
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _createEveningBusy() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 18);
    final end = DateTime(now.year, now.month, now.day, 20);

    await ref.read(employeeAvailabilityActionsProvider.notifier).createTimeEntry(
          employeeId: widget.employeeId,
          startAt: start,
          endAt: end,
          kind: 'presentation',
          title: 'Prezentacja nieruchomości',
          blocksBooking: true,
        );
  }

  Future<void> _markRemoteToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 9);
    final end = DateTime(now.year, now.month, now.day, 17);

    await ref.read(employeeAvailabilityActionsProvider.notifier).createOverride(
          employeeId: widget.employeeId,
          startAt: start,
          endAt: end,
          kind: 'remote',
          title: 'Praca zdalna',
          isBookable: true,
          blocksBooking: false,
        );
  }

  Future<void> _markUnavailableToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 9);
    final end = DateTime(now.year, now.month, now.day, 17);

    await ref.read(employeeAvailabilityActionsProvider.notifier).createOverride(
          employeeId: widget.employeeId,
          startAt: start,
          endAt: end,
          kind: 'unavailable',
          title: 'Niedostępny',
          isBookable: false,
          blocksBooking: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Szybkie akcje dostępności',
            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              CoreOutlinedButton(
                onPressed: () => _runAction(
                  _markRemoteToday,
                  successMessage: 'Ustawiono pracę zdalną na dziś',
                ),
                child: const _ButtonContent(
                  icon: Icons.home_work_outlined,
                  label: 'Zdalnie dziś',
                ),
              ),
              CoreOutlinedButton(
                onPressed: () => _runAction(
                  _createEveningBusy,
                  successMessage: 'Dodano prezentację 18:00–20:00',
                ),
                child: const _ButtonContent(
                  icon: Icons.real_estate_agent_outlined,
                  label: 'Prezentacja 18-20',
                ),
              ),
              CoreOutlinedButton(
                onPressed: () => _runAction(
                  _markUnavailableToday,
                  successMessage: 'Oznaczono pracownika jako niedostępnego dziś',
                ),
                child: const _ButtonContent(
                  icon: Icons.block_outlined,
                  label: 'Niedostępny dziś',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _AvailabilityEditorSection {
  quick,
  calendar,
  week,
}

class EmployeeAvailabilityEditorPlaceholder extends ConsumerStatefulWidget {
  final int employeeId;
  final VoidCallback? onChanged;

  const EmployeeAvailabilityEditorPlaceholder({
    super.key,
    required this.employeeId,
    this.onChanged,
  });

  @override
  ConsumerState<EmployeeAvailabilityEditorPlaceholder> createState() =>
      _EmployeeAvailabilityEditorPlaceholderState();
}

class _EmployeeAvailabilityEditorPlaceholderState
    extends ConsumerState<EmployeeAvailabilityEditorPlaceholder> {
  _AvailabilityEditorSection _section = _AvailabilityEditorSection.quick;
  int _refreshSeed = 0;

  void _setSection(_AvailabilityEditorSection section) {
    if (_section == section) return;
    setState(() => _section = section);
  }

  void _handleChanged() {
    _refreshAvailabilityProviders(ref, widget.employeeId);
    widget.onChanged?.call();
    if (!mounted) return;
    setState(() => _refreshSeed += 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EmployeeAvailabilityCompactCard(
          key: ValueKey('availability-compact-${widget.employeeId}-$_refreshSeed'),
          employeeId: widget.employeeId,
          onOpenCalendar: () => _setSection(_AvailabilityEditorSection.calendar),
          onEditAvailability: () => _setSection(_AvailabilityEditorSection.quick),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _EditorSectionChip(
              label: 'Szybkie akcje',
              icon: Icons.flash_on_outlined,
              selected: _section == _AvailabilityEditorSection.quick,
              onTap: () => _setSection(_AvailabilityEditorSection.quick),
            ),
            _EditorSectionChip(
              label: 'Kalendarz',
              icon: Icons.calendar_month_outlined,
              selected: _section == _AvailabilityEditorSection.calendar,
              onTap: () => _setSection(_AvailabilityEditorSection.calendar),
            ),
            _EditorSectionChip(
              label: 'Tydzień',
              icon: Icons.view_week_outlined,
              selected: _section == _AvailabilityEditorSection.week,
              onTap: () => _setSection(_AvailabilityEditorSection.week),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey('${_section.name}-$_refreshSeed'),
            child: switch (_section) {
              _AvailabilityEditorSection.quick => EmployeeAvailabilityQuickActions(
                  employeeId: widget.employeeId,
                  onDone: _handleChanged,
                ),
              _AvailabilityEditorSection.calendar => EmployeeHrCalendarPreview(
                  memberId: widget.employeeId,
                  height: 560,
                  initiallyShowEvents: true,
                  initiallyShowAvailability: true,
                  collapseAvailabilityRules: true,
                ),
              _AvailabilityEditorSection.week => EmployeeAvailabilityWeekPreview(
                  weekStart: DateTime.now(),
                  employeeId: widget.employeeId,
                ),
            },
          ),
        ),
        if (_section == _AvailabilityEditorSection.quick) ...[
          const SizedBox(height: 14),
          Text(
            'Po kliknięciu akcja zapisuje wyjątek dostępności i odświeża kartę oraz podgląd tygodnia.',
            style: TextStyle(
              color: theme.textColor.withAlpha(135),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _EditorSectionChip extends ConsumerWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _EditorSectionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? theme.themeColor.withAlpha(26) : theme.adPopBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? theme.themeColor : theme.dashboardBoarder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.textColor),
            const SizedBox(width: 7),
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
      ),
    );
  }
}

void _refreshAvailabilityProviders(WidgetRef ref, int employeeId) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = _monday(today);
  final weekEnd = weekStart.add(const Duration(days: 6));

  ref.invalidate(
    employeeAvailabilityDashboardProvider(
      EmployeeAvailabilityDashboardParams(
        employeeId: employeeId,
        start: _date(today),
        end: _date(today.add(const Duration(days: 30))),
      ),
    ),
  );

  ref.invalidate(
    employeeAvailabilityCalendarProvider(
      EmployeeAvailabilityCalendarParams(
        start: _date(weekStart),
        end: _date(weekEnd),
        employeeId: employeeId,
        includeRules: true,
        includeAbsences: true,
        includeOverrides: true,
        includeTimeEntries: true,
      ),
    ),
  );

  ref.invalidate(memberCalendarLayerProvider);
  ref.invalidate(teamAvailabilityLayerProvider);
}

class _AvailabilityTimeline extends ConsumerWidget {
  final List<EmployeeAvailabilityBlockModel> blocks;

  const _AvailabilityTimeline({required this.blocks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Column(
      children: [
        for (final block in blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _hexToColor(block.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_time(block.startAt)}-${_time(block.endAt)} · ${block.title}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.textColor.withAlpha(180), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayColumn extends ConsumerWidget {
  final DateTime day;
  final List<EmployeeAvailabilityBlockModel> blocks;

  const _DayColumn({required this.day, required this.blocks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final sorted = [...blocks]..sort((a, b) => b.priority.compareTo(a.priority));
    final visible = sorted.take(4).toList();

    return Container(
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _weekdayLabel(day.weekday),
            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 12),
          ),
          Text(
            '${day.day}.${day.month}',
            style: TextStyle(color: theme.textColor.withAlpha(145), fontSize: 11),
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            Text(
              'Brak okien',
              style: TextStyle(color: theme.textColor.withAlpha(115), fontSize: 11),
            )
          else
            for (final block in visible)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: _hexToColor(block.color).withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _hexToColor(block.color).withAlpha(80)),
                ),
                child: Text(
                  block.blocksBooking
                      ? block.title
                      : '${_time(block.startAt)} ${block.title}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 10.5,
                    fontWeight: block.blocksBooking ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _InfoChip extends ConsumerWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.textColor.withAlpha(170)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: theme.textColor.withAlpha(180), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ButtonContent({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class _ErrorContent extends ConsumerWidget {
  final String message;

  const _ErrorContent({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Text(
      message,
      style: TextStyle(color: theme.textColor.withAlpha(165)),
    );
  }
}

IconData _statusIcon(String key) {
  switch (key) {
    case 'available':
    case 'contact':
      return Icons.check_circle_outline;
    case 'presentation':
    case 'presentation_only':
      return Icons.real_estate_agent_outlined;
    case 'remote':
      return Icons.home_work_outlined;
    case 'busy':
      return Icons.event_busy_outlined;
    case 'unavailable':
    case 'out_of_office':
    case 'sick':
      return Icons.block_outlined;
    default:
      return Icons.schedule_outlined;
  }
}

String _workModeLabel(String key) {
  switch (key) {
    case 'fixed_hours':
      return 'Stałe godziny';
    case 'flexible_hours':
      return 'Elastyczne godziny';
    case 'appointment_based':
      return 'Zadaniowy / spotkaniowy';
    case 'shift_based':
      return 'Zmianowy';
    default:
      return 'Własny tryb';
  }
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Pon';
    case DateTime.tuesday:
      return 'Wt';
    case DateTime.wednesday:
      return 'Śr';
    case DateTime.thursday:
      return 'Czw';
    case DateTime.friday:
      return 'Pt';
    case DateTime.saturday:
      return 'Sob';
    default:
      return 'Nd';
  }
}

DateTime _monday(DateTime value) {
  final normalized = DateTime(value.year, value.month, value.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

String _date(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _time(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Color _hexToColor(String value) {
  var hex = value.trim();
  if (!hex.startsWith('#')) hex = '#$hex';
  if (hex.length == 4) {
    final r = hex[1];
    final g = hex[2];
    final b = hex[3];
    hex = '#$r$r$g$g$b$b';
  }
  try {
    if (hex.length == 7) {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    }
  } catch (_) {}
  return const Color(0xFF64748B);
}
