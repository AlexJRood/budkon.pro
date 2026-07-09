import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:crm_agent/add_client_form/provider/send_form_provider.dart';
import 'package:crm_agent/add_client_form/components/usercontact/user_contact_custom_text_field.dart';

import 'package:calendar/state_managers/add_event_provider.dart';
import 'package:calendar/state_managers/appointments_provider.dart';
import 'package:calendar/state_managers/popup_calendar_provider.dart';
import 'package:calendar/widgets/events/event_tab_widget.dart';
import 'package:calendar/widgets/events/selected_calendar_drop_down_widget.dart';

import 'package:core/theme/apptheme.dart';

final showScheduleEventProvider = StateProvider<bool>((ref) => false);
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class AddEventCardWidget extends ConsumerStatefulWidget {
  final bool isMobile;
  final bool showConfirm;
  const AddEventCardWidget({super.key, this.isMobile = false, this.showConfirm = true});

  @override
  ConsumerState<AddEventCardWidget> createState() => _AddEventCardWidgetState();
}

class _AddEventCardWidgetState extends ConsumerState<AddEventCardWidget> {
  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onSave(BuildContext context) async {
    final isEdit = ref.read(appointmentsProvider).isEdit;
    final popup = ref.read(popupCalendarProvider);
    final eventDetails = popup.event;

    if (isEdit) {
      await ref.read(addEventNotifierProvider.notifier).editEvent(ref);
    } else {
      await ref.read(addEventNotifierProvider.notifier).addEventAndAssignToClient(
            isClientDashboard: false,
            clientId: '0',
            ref: ref,
          );

      ref.read(popupCalendarProvider.notifier).clearAllFields();

      await Future.delayed(const Duration(milliseconds: 600));
      ref.read(selectedDateProvider.notifier).state = eventDetails.from;
    }

    final updated = ref.read(popupCalendarProvider).event;
    final customRecurrence = ref.read(appointmentsProvider).isEdit
        ? null
        : updated.repeat.recurrenceRule(updated.from);

    ref.read(appointmentsProvider).saveAppointment(
          context: context,
          event: updated,
          index: 0,
          customRecurrence: customRecurrence,
        );
  }

  void _closeCard() {
    ref.read(showScheduleEventProvider.notifier).state = false;
  }

  Duration _eventDuration(DateTime from, DateTime to) {
    final diff = to.difference(from);
    if (diff.inMinutes <= 0) {
      return const Duration(hours: 1);
    }
    return diff;
  }

  void _updateEvent({
    String? title,
    DateTime? from,
    DateTime? to,
  }) {
    final popup = ref.read(popupCalendarProvider);
    final current = popup.event;

    ref.read(popupCalendarProvider).event = current.copyWith(
      title: title ?? current.title,
      from: from ?? current.from,
      to: to ?? current.to,
    );
  }

  void _updateTitle(String title) {
    final addClientForm = ref.read(addClientFormProvider);
    final addClientFormNotifier = ref.read(addClientFormProvider.notifier);

    addClientFormNotifier.updateTextField(
      addClientForm.eventTitleController,
      title,
    );

    _updateEvent(title: title);
  }

  void _applySelectedDate(DateTime selectedDay) {
    ref.read(selectedDateProvider.notifier).state = selectedDay;

    final current = ref.read(popupCalendarProvider).event;
    final duration = _eventDuration(current.from, current.to);

    final newFrom = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      current.from.hour,
      current.from.minute,
    );

    _updateEvent(
      from: newFrom,
      to: newFrom.add(duration),
    );
  }

  void _applyQuickDate(DateTime date) {
    _applySelectedDate(date);
  }

  void _applyQuickTime(
    TimeOfDay time, {
    Duration? duration,
  }) {
    final baseDate = ref.read(selectedDateProvider);
    final current = ref.read(popupCalendarProvider).event;
    final eventDuration = duration ?? _eventDuration(current.from, current.to);

    final newFrom = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      time.hour,
      time.minute,
    );

    _updateEvent(
      from: newFrom,
      to: newFrom.add(eventDuration),
    );
  }

  void _applyQuickDuration(Duration duration) {
    final current = ref.read(popupCalendarProvider).event;
    _updateEvent(
      from: current.from,
      to: current.from.add(duration),
    );
  }

  void _applyQuickTemplate({
    required String title,
    TimeOfDay? startTime,
    Duration? duration,
  }) {
    _updateTitle(title);

    if (startTime != null || duration != null) {
      final current = ref.read(popupCalendarProvider).event;
      final nextDuration = duration ?? _eventDuration(current.from, current.to);
      final baseDate = ref.read(selectedDateProvider);

      final from = startTime == null
          ? current.from
          : DateTime(
              baseDate.year,
              baseDate.month,
              baseDate.day,
              startTime.hour,
              startTime.minute,
            );

      _updateEvent(
        title: title,
        from: from,
        to: from.add(nextDuration),
      );
    }
  }

  String _formatDateSummary(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (target == today) return 'Today'.tr;
    if (target == tomorrow) return 'Tomorrow'.tr;

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _sectionCard({
    required ThemeColors theme,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.textFieldColor.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.bordercolor.withOpacity(0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _quickChip({
    required ThemeColors theme,
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    bool filled = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: filled
              ? theme.themeColor
              : theme.dashboardContainer.withOpacity(0.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled
                ? theme.themeColor
                : theme.bordercolor.withOpacity(0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: filled ? Colors.white : theme.textColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : theme.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors theme) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.themeColor.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.event_available_rounded,
            color: theme.themeColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Add Event'.tr,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
        ),
        _headerIconButton(
          theme: theme,
          icon: Icons.close_rounded,
          onTap: _closeCard,
        ),
      ],
    );
  }

  Widget _headerIconButton({
    required ThemeColors theme,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.textFieldColor.withOpacity(0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.bordercolor.withOpacity(0.18),
          ),
        ),
        child: Icon(
          icon,
          color: theme.textColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeColors theme) {
    final selectedDate = ref.watch(selectedDateProvider);
    final event = ref.watch(popupCalendarProvider).event;

    return Column(
      children: [
        _sectionCard(
          theme: theme,
          title: 'quick_actions'.tr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickChip(
                    theme: theme,
                    label: 'Today'.tr,
                    icon: Icons.today_rounded,
                    onTap: () => _applyQuickDate(DateTime.now()),
                  ),
                  _quickChip(
                    theme: theme,
                    label: 'tomorrow'.tr,
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _applyQuickDate(
                      DateTime.now().add(const Duration(days: 1)),
                    ),
                  ),
                  _quickChip(
                    theme: theme,
                    label: '09:00',
                    icon: Icons.wb_sunny_outlined,
                    onTap: () => _applyQuickTime(
                      const TimeOfDay(hour: 9, minute: 0),
                    ),
                  ),
                  _quickChip(
                    theme: theme,
                    label: '12:00',
                    icon: Icons.wb_twilight_outlined,
                    onTap: () => _applyQuickTime(
                      const TimeOfDay(hour: 12, minute: 0),
                    ),
                  ),
                  _quickChip(
                    theme: theme,
                    label: '18:00',
                    icon: Icons.nights_stay_outlined,
                    onTap: () => _applyQuickTime(
                      const TimeOfDay(hour: 18, minute: 0),
                    ),
                  ),
                  _quickChip(
                    theme: theme,
                    label: '15 min',
                    onTap: () => _applyQuickDuration(
                      const Duration(minutes: 15),
                    ),
                  ),
                  _quickChip(
                    theme: theme,
                    label: '30 min',
                    onTap: () => _applyQuickDuration(
                      const Duration(minutes: 30),
                    ),
                  ),
                  _quickChip(
                    theme: theme,
                    label: '60 min',
                    onTap: () => _applyQuickDuration(
                      const Duration(hours: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickChip(
                    theme: theme,
                    label: 'Call'.tr,
                    filled: true,
                    onTap: () => _applyQuickTemplate(
                      title: 'Call'.tr,
                      duration: const Duration(minutes: 15),
                    ),
                  ),
                  _quickChip(
                    theme: theme,
                    label: 'Meeting'.tr,
                    filled: true,
                    onTap: () => _applyQuickTemplate(
                      title: 'Meeting'.tr,
                      duration: const Duration(hours: 1),
                    ),
                  ),
                  _quickChip(
                    theme: theme,
                    label: 'follow_up'.tr,
                    filled: true,
                    onTap: () => _applyQuickTemplate(
                      title: 'follow_up'.tr,
                      duration: const Duration(minutes: 30),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          theme: theme,
          title: 'Summary'.tr,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoBadge(
                theme: theme,
                icon: Icons.event_note_rounded,
                label: _formatDateSummary(selectedDate),
              ),
              _infoBadge(
                theme: theme,
                icon: Icons.schedule_rounded,
                label: '${_formatTime(event.from)} - ${_formatTime(event.to)}',
              ),
              _infoBadge(
                theme: theme,
                icon: Icons.timelapse_rounded,
                label: '${_eventDuration(event.from, event.to).inMinutes} min',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoBadge({
    required ThemeColors theme,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withOpacity(0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.bordercolor.withOpacity(0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: theme.themeColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildBottomActions(ThemeColors theme) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: OutlinedButton(
  //           onPressed: _closeCard,
  //           style: OutlinedButton.styleFrom(
  //             minimumSize: const Size.fromHeight(46),
  //             side: BorderSide(
  //               color: theme.bordercolor.withOpacity(0.20),
  //             ),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //           ),
  //           child: Text(
  //             'Cancel'.tr,
  //             style: TextStyle(
  //               color: theme.textColor,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ),
  //       ),
  //       const SizedBox(width: 10),
  //       Expanded(
  //         child: ElevatedButton.icon(
  //           onPressed: () => _onSave(context),
  //           style: ElevatedButton.styleFrom(
  //             minimumSize: const Size.fromHeight(46),
  //             backgroundColor: theme.themeColor,
  //             foregroundColor: Colors.white,
  //             elevation: 0,
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //           ),
  //           icon: const Icon(Icons.check_rounded),
  //           label: Text(
  //             'Save event'.tr,
  //             style: const TextStyle(
  //               fontWeight: FontWeight.w700,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildEventContent(
    WidgetRef ref,
    DateTime selectedDate,
    var addClientForm,
    var addClientFormNotifier,
    ThemeColors theme,
  ) {
    final popup = ref.watch(popupCalendarProvider);
    final eventDetails = popup.event;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          theme: theme,
          title: 'Event details'.tr,
          child: Column(
            children: [
              UserContactCustomTextField(
                id: 29,
                hintText: 'Add title'.tr,
                valueKey: 'title',
                formatThousands: false,
                focusNode: _titleFocusNode,
                controller: addClientForm.eventTitleController,
                validator: (value) => value == null || value.isEmpty
                    ? "Description can't be empty".tr
                    : null,
                onFieldSubmitted: (_) => _onSave(context),
                onChanged: (valueKey, value) {
                  addClientFormNotifier.updateTextField(
                    addClientForm.eventTitleController,
                    value,
                  );

                  final newEvent = eventDetails.copyWith(title: value ?? '');
                  ref.read(popupCalendarProvider).event = newEvent;
                },
              ),
              const SizedBox(height: 12),
              const SelectedCalendarDropDownWidget(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickActions(theme),
        const SizedBox(height: 12),
        _sectionCard(
          theme: theme,
          title: 'advanced_options'.tr,
          child: EventTabWidget(
            index: 0,
            clientId: '0',
            isClientDashboard: false,
            showBottomButtons: false,
            onSaveFromChild: () => _onSave(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarContent(
    WidgetRef ref,
    DateTime selectedDate,
    var addClientForm,
    var addClientFormNotifier,
    ThemeColors theme,
  ) {
    return Column(
      children: [
        _sectionCard(
          theme: theme,
          title: 'Choose date'.tr,
          trailing: Text(
            _formatDateSummary(selectedDate),
            style: TextStyle(
              color: theme.themeColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: selectedDate,
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            onDaySelected: (selectedDay, focusedDay) {
              _applySelectedDate(selectedDay);
            },
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(color: theme.textColor),
              weekendTextStyle: TextStyle(color: theme.textColor),
              outsideTextStyle: TextStyle(
                color: theme.textColor.withOpacity(0.35),
              ),
              todayTextStyle: TextStyle(color: theme.dashboardContainer),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.themeColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.themeColor.withAlpha((255 * 0.7).toInt()),
                shape: BoxShape.circle,
              ),
              cellMargin: const EdgeInsets.all(4),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w700,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: theme.textColor,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: theme.textColor,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: theme.textColor.withOpacity(0.72),
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: theme.textColor.withOpacity(0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final addClientForm = ref.watch(addClientFormProvider);
    final addClientFormNotifier = ref.read(addClientFormProvider.notifier);
    final selectedDate = ref.watch(selectedDateProvider);
    final theme = ref.watch(themeColorsProvider);

    final body = widget.isMobile
        ? Column(
            children: [
              _buildCalendarContent(
                ref,
                selectedDate,
                addClientForm,
                addClientFormNotifier,
                theme,
              ),
              const SizedBox(height: 16),
              _buildEventContent(
                ref,
                selectedDate,
                addClientForm,
                addClientFormNotifier,
                theme,
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 10,
                child: _buildCalendarContent(
                  ref,
                  selectedDate,
                  addClientForm,
                  addClientFormNotifier,
                  theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 14,
                child: _buildEventContent(
                  ref,
                  selectedDate,
                  addClientForm,
                  addClientFormNotifier,
                  theme,
                ),
              ),
            ],
          );

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.bordercolor.withOpacity(0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // padding: const EdgeInsets.all(18),
        child: Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter):
                const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS):
                const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  _onSave(context);
                  return null;
                },
              ),
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) {
                  _closeCard();
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 14),
                  body,
                  const SizedBox(height: 16),
                  // if(widget.showConfirm)
                  // _buildBottomActions(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}