// Public Event Create Page (Flutter Web/Desktop)
// Redesigned to match the CreateReportPc UI style:
//   - GradientTextField for all text inputs
//   - GradientDropdownAddOffer for dropdowns
//   - Section headings with bordered containers
//   - BarManager layout

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:intl/intl.dart';
import 'package:core/common/shared_widgets/location_components.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:association/providers/events.dart';
import 'package:association/models/events_model.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/button_style.dart';
import 'package:association/providers/events.dart' as create_events;
import 'package:association/models/events_model.dart';
import 'events/providers/event_provider.dart' as list_events;

// ---------------------------------------------------------------------------
// PublicEventCreatePage
// ---------------------------------------------------------------------------
class PublicEventCreatePage extends ConsumerStatefulWidget {
  const PublicEventCreatePage({
    super.key,
    required this.baseUrl,
    this.appModule = AppModule.wall,
  });

  final String baseUrl;
  final AppModule appModule;

  @override
  ConsumerState<PublicEventCreatePage> createState() =>
      _PublicEventCreatePageState();
}

class _PublicEventCreatePageState extends ConsumerState<PublicEventCreatePage> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _ticketUrlController;
  late TextEditingController _cityController;
  late TextEditingController _coverImageController;

  final GlobalKey<SideMenuState> _sideMenuKey = GlobalKey<SideMenuState>();

  @override
  void initState() {
    super.initState();
    final s = ref.read(eventFormProvider);
    _titleController = TextEditingController(text: s.title);
    _locationController = TextEditingController(text: s.location);
    _descriptionController = TextEditingController(text: s.description);
    _ticketUrlController = TextEditingController(text: s.externalTicketUrl);
    _cityController = TextEditingController(text: s.city);
    _coverImageController = TextEditingController(text: s.coverImageUrl);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _ticketUrlController.dispose();
    _cityController.dispose();
    _coverImageController.dispose();
    super.dispose();
  }

Future<void> _submit() async {
  final s = ref.read(eventFormProvider);
  final n = ref.read(eventFormProvider.notifier);
  final nav = ref.read(navigationService);
  if (s.title.trim().isEmpty) {
    n.setError('Please enter a title'.tr);
    return;
  }
  if (s.start == null) {
    n.setError('Please set a start date'.tr);
    return;
  }

  n.setLoading(true);
  try {
    final api =
        ref.read(create_events.publicEventsApiProvider(widget.baseUrl));

    final eventId = await api.createEvent(
      title: s.title.trim(),
      description: s.description.trim().isEmpty ? null : s.description.trim(),
      location: s.location.trim().isEmpty ? null : s.location.trim(),
      start: s.start!,
      end: s.end,
      timeZone: s.timeZone,
    );

    final publishResult = await api.publishSocial(
      eventId: eventId,
      visibility: s.visibility,
      isPublished: s.isPublished,
      coverImageUrl:
          s.coverImageUrl.trim().isEmpty ? null : s.coverImageUrl.trim(),
      isFree: s.isFree,
      externalTicketUrl:
          s.externalTicketUrl.trim().isEmpty ? null : s.externalTicketUrl.trim(),
      categoryIds: s.selectedCategories.toList(),
      city: s.city.trim().isEmpty ? null : s.city.trim(),
    );

    debugPrint('Publish result: $publishResult');

    ref.invalidate(list_events.publicEventsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event published successfully.'.tr)),
      );

      nav.beamPop();
    }
  } catch (e) {
    debugPrint('Error in _submit: $e');
    n.setError(e.toString());
  } finally {
    if (mounted) {
      n.setLoading(false);
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return BarManager(
          sideMenuKey: _sideMenuKey,
          appModule: widget.appModule,
          isChildExpanded: false,
          paddingPc: 10,
          paddingMobile: 8,
          verticalButtonsPc: isMobile
         ? null
         : _ActionButtons(
         onPublish: _submit,
         isLoading: ref.watch(eventFormProvider.select((s) => s.loading)),
      ),
          childPc: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _EventHeader(mobile: false),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _EventFormBody(
                  baseUrl: widget.baseUrl,
                  titleController: _titleController,
                  locationController: _locationController,
                  descriptionController: _descriptionController,
                  ticketUrlController: _ticketUrlController,
                  cityController: _cityController,
                  coverImageController: _coverImageController,
                  showInlineActions: false,
                  onPublish: _submit,
                ),
              ],
            ),
          ),
          childMobile: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _EventHeader(mobile: true),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _EventFormBody(
                  baseUrl: widget.baseUrl,
                  titleController: _titleController,
                  locationController: _locationController,
                  descriptionController: _descriptionController,
                  ticketUrlController: _ticketUrlController,
                  cityController: _cityController,
                  coverImageController: _coverImageController,
                  showInlineActions: true,
                  onPublish: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _EventHeader
// ---------------------------------------------------------------------------
class _EventHeader extends ConsumerWidget {
  final bool mobile;
  const _EventHeader({required this.mobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 10, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Create Public Event'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: mobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fill in the details below to publish a new public event.'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(153),
               fontSize: mobile ? 12 : 14,
               
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ActionButtons
// ---------------------------------------------------------------------------
class _ActionButtons extends ConsumerWidget {
  final VoidCallback onPublish;
  final bool isLoading;

  const _ActionButtons({required this.onPublish, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final nav = ref.watch(navigationService);
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomElevatedButton(
          text: isLoading ? 'Publishing...' : 'Publish Event',
          onTap: isLoading ? null : onPublish, 
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: () =>  nav.beamPop(),
            child: Text('Cancel'.tr, style: TextStyle(color: theme.textColor)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EventFormBody
// ---------------------------------------------------------------------------
class _EventFormBody extends ConsumerWidget {
  final String baseUrl;
  final TextEditingController titleController;
  final TextEditingController locationController;
  final TextEditingController descriptionController;
  final TextEditingController ticketUrlController;
  final TextEditingController cityController;
  final TextEditingController coverImageController;
  final bool showInlineActions;
  final VoidCallback onPublish;

  const _EventFormBody({
    required this.baseUrl,
    required this.titleController,
    required this.locationController,
    required this.descriptionController,
    required this.ticketUrlController,
    required this.cityController,
    required this.coverImageController,
    required this.showInlineActions,
    required this.onPublish,
  });

  Widget _sectionLabel(String text, BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).iconTheme.color,
      ),
    ),
  );

  Widget _divider() => const SizedBox(height: 20);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(eventFormProvider);
    final theme = ref.watch(themeColorsProvider);
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    Widget pickerThemeBuilder(BuildContext context, Widget? child) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Theme(
        data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: theme.themeColor,
                  onPrimary: Colors.white,
                  surface: CustomColors.secondaryWidgetColor(context, ref),
                  onSurface: Colors.white,
                  secondary: theme.secondaryWidgetColor,
                  surfaceContainerHigh: CustomColors.secondaryWidgetColor(
                    context,
                    ref,
                  ),
                )
              : ColorScheme.light(
                  primary: theme.themeColor,
                  onPrimary: Colors.white,
                  surface: CustomColors.secondaryWidgetColor(context, ref),
                  onSurface: Colors.white,
                  secondary: theme.secondaryWidgetColor,
                  surfaceContainerHigh: CustomColors.secondaryWidgetColor(
                    context,
                    ref,
                  ),
                ),
          textTheme: (isDark ? ThemeData.dark() : ThemeData.light()).textTheme
              .copyWith(
                bodyLarge: const TextStyle(color: Colors.white),
                bodyMedium: const TextStyle(color: Colors.white),
                titleMedium: const TextStyle(color: Colors.white),
              ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.themeColor.withAlpha(50)),
            ),
            backgroundColor: CustomColors.secondaryWidgetColor(context, ref),
          ),
          datePickerTheme: DatePickerThemeData(
            headerBackgroundColor: theme.themeColor,
            headerForegroundColor: Colors.white,
            backgroundColor: CustomColors.secondaryWidgetColor(context, ref),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return Colors.white70;
            }),
            yearForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return Colors.white70;
            }),
            todayForegroundColor: WidgetStateProperty.all(Colors.white),
            todayBorder: BorderSide(color: Colors.white),
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: CustomColors.secondaryWidgetColor(context, ref),
            hourMinuteTextColor: Colors.white,
            dayPeriodTextColor: Colors.white,
            dialHandColor: theme.themeColor,
            dialBackgroundColor: theme.secondaryWidgetColor.withAlpha(30),
            dialTextColor: Colors.white,
            entryModeIconColor: theme.themeColor,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: theme.themeColor,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        child: child!,
      );
    }
    Future<void> pickStart() async {
      final now = DateTime.now();
      final d = await showDatePicker(
        context: context,
        firstDate: now.subtract(const Duration(days: 1)),
        lastDate: now.add(const Duration(days: 365 * 3)),
        initialDate: s.start ?? now,
        builder: pickerThemeBuilder,
      );
      if (d == null) return;
      if (!context.mounted) return;
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(s.start ?? now),
        builder: pickerThemeBuilder,
      );
      if (t == null) return;
      ref
          .read(eventFormProvider.notifier)
          .setStart(DateTime(d.year, d.month, d.day, t.hour, t.minute));
    }

    Future<void> pickEnd() async {
      final base = s.start ?? DateTime.now();
      final d = await showDatePicker(
        context: context,
        firstDate: base,
        lastDate: base.add(const Duration(days: 365 * 3)),
        initialDate: s.end ?? base,
        builder: pickerThemeBuilder,
      );
      if (d == null) return;
      if (!context.mounted) return;
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(s.end ?? base),
        builder: pickerThemeBuilder,
      );
      if (t == null) return;
      ref
          .read(eventFormProvider.notifier)
          .setEnd(DateTime(d.year, d.month, d.day, t.hour, t.minute));
    }

    final startText = s.start == null ? '' : dateFmt.format(s.start!);
    final endText = s.end == null ? '' : dateFmt.format(s.end!);
    final startCtrl = TextEditingController(text: startText);
    final endCtrl = TextEditingController(text: endText);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).iconTheme.color!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MaterialBanner(
                              backgroundColor: theme.dashboardContainer,
                              content: Text(
                                s.error!,
                                style: TextStyle(color: theme.textColor),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => ref
                                      .read(eventFormProvider.notifier)
                                      .setError(null),
                                  child: Text('OK', style: TextStyle(color: theme.textColor),),
                                ),
                              ],
                            ),
                          ),

                        _sectionLabel('Event Details'.tr, context),
                        if (isMobile) ...[
                          GradientTextField(
                            key: const ValueKey('title_field'),
                            controller: titleController,
                            hintText: 'Event Title *'.tr,
                            onChanged: (v) => ref
                                .read(eventFormProvider.notifier)
                                .setTitle(v),
                          ),
                          const SizedBox(height: 12),
                          GradientTextField(
                            key: const ValueKey('location_field'),
                            controller: locationController,
                            hintText: 'Location / Venue'.tr,
                            onChanged: (v) => ref
                                .read(eventFormProvider.notifier)
                                .setLocation(v),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: GradientTextField(
                                  key: const ValueKey('title_field'),
                                  controller: titleController,
                                  hintText: 'Event Title *'.tr,
                                  onChanged: (v) => ref
                                      .read(eventFormProvider.notifier)
                                      .setTitle(v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GradientTextField(
                                  key: const ValueKey('location_field'),
                                  controller: locationController,
                                  hintText: 'Location / Venue'.tr,
                                  onChanged: (v) => ref
                                      .read(eventFormProvider.notifier)
                                      .setLocation(v),
                                ),
                              ),
                            ],
                          ),
                        ],
                        _divider(),

                        _sectionLabel('Date & Time'.tr, context),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: pickStart,
                                child: AbsorbPointer(
                                  child: GradientTextField(
                                    controller: startCtrl,
                                    hintText: 'Start Date & Time *'.tr,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: pickEnd,
                                child: AbsorbPointer(
                                  child: GradientTextField(
                                    controller: endCtrl,
                                    hintText: 'End Date & Time'.tr,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        _divider(),

                        _sectionLabel('Description'.tr, context),
                        GradientTextField(
                          key: const ValueKey('desc_field'),
                          controller: descriptionController,
                          hintText: 'Event description…'.tr,
                          maxLines: 4,
                          onChanged: (v) =>
                              ref.read(eventFormProvider.notifier).setDesc(v),
                        ),
                        _divider(),

                        _sectionLabel('Visibility & Settings'.tr, context),
                        if (isMobile) ...[
                          GradientDropdownAddOffer(
                            isPc: false,
                            hintText: 'Visibility'.tr,
                            value: s.visibility.name,
                            selectedItem: s.visibility.name,
                            items: EventVisibility.values
                                .map((e) => e.name)
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              final vis = EventVisibility.values.firstWhere(
                                (e) => e.name == v,
                                orElse: () => EventVisibility.public,
                              );
                              ref
                                  .read(eventFormProvider.notifier)
                                  .setVisibility(vis);
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.textColor.withAlpha(50)),
                            ),
                            child: Row(
                              children: [
                                Switch(
                                  value: s.isPublished,
                                  onChanged: (v) => ref
                                      .read(eventFormProvider.notifier)
                                      .setPublished(v),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Published'.tr,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.textColor.withAlpha(50)),
                            ),
                            child: Row(
                              children: [
                                Switch(
                                  value: s.isFree,
                                  onChanged: (v) => ref
                                      .read(eventFormProvider.notifier)
                                      .setFree(v),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Free Entry'.tr,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: GradientDropdownAddOffer(
                                  isPc: true,
                                  hintText: 'Visibility'.tr,
                                  value: s.visibility.name,
                                  selectedItem: s.visibility.name,
                                  items: EventVisibility.values
                                      .map((e) => e.name)
                                      .toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    final vis = EventVisibility.values.firstWhere(
                                      (e) => e.name == v,
                                      orElse: () => EventVisibility.public,
                                    );
                                    ref
                                        .read(eventFormProvider.notifier)
                                        .setVisibility(vis);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Switch(
                                      value: s.isPublished,
                                      onChanged: (v) => ref
                                          .read(eventFormProvider.notifier)
                                          .setPublished(v),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Published'.tr,
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Switch(
                                      value: s.isFree,
                                      onChanged: (v) => ref
                                          .read(eventFormProvider.notifier)
                                          .setFree(v),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Free Entry'.tr,
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        _divider(),

                        _sectionLabel('Tickets & Cover Image'.tr, context),
                        if (isMobile) ...[
                          GradientTextField(
                            key: const ValueKey('ticket_field'),
                            controller: ticketUrlController,
                            hintText: 'Ticket URL (optional)'.tr,
                            onChanged: (v) => ref
                                .read(eventFormProvider.notifier)
                                .setTicketUrl(v),
                          ),
                          const SizedBox(height: 12),
                          GradientTextField(
                            key: const ValueKey('cover_field'),
                            controller: coverImageController,
                            hintText: 'Cover Image URL'.tr,
                            onChanged: (v) => ref
                                .read(eventFormProvider.notifier)
                                .setCover(v),
                          ),
                          const SizedBox(height: 12),
                          GradientTextField(
                            key: const ValueKey('city_field'),
                            controller: cityController,
                            hintText: 'City (for discovery)'.tr,
                            onChanged: (v) =>
                                ref.read(eventFormProvider.notifier).setCity(v),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: GradientTextField(
                                  key: const ValueKey('ticket_field'),
                                  controller: ticketUrlController,
                                  hintText: 'Ticket URL (optional)'.tr,
                                  onChanged: (v) => ref
                                      .read(eventFormProvider.notifier)
                                      .setTicketUrl(v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GradientTextField(
                                  key: const ValueKey('cover_field'),
                                  controller: coverImageController,
                                  hintText: 'Cover Image URL'.tr,
                                  onChanged: (v) => ref
                                      .read(eventFormProvider.notifier)
                                      .setCover(v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GradientTextField(
                                  key: const ValueKey('city_field'),
                                  controller: cityController,
                                  hintText: 'City (for discovery)'.tr,
                                  onChanged: (v) =>
                                      ref.read(eventFormProvider.notifier).setCity(v),
                                ),
                              ),
                            ],
                          ),
                        ],
                        _divider(),
                        _sectionLabel('Categories'.tr, context),
                        ref
                            .watch(categoriesProvider(baseUrl))
                            .when(
                              data: (list) => Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final c in list)
                                    FilterChip(
                                      
                                      disabledColor: theme.textColor,
                                      backgroundColor: theme.dashboardContainer,
                                      labelStyle: TextStyle(
                                        color: theme.textColor),
                                      label: Text(
                                        c.name,
                                        style: TextStyle(color: theme.textColor),
                                      ),
                                      selected: s.selectedCategories.contains(c.id),
                                      onSelected: (_) => ref
                                          .read(eventFormProvider.notifier)
                                          .toggleCategory(c.id),
                                    ),
                                ],
                              ),
                              loading: () => const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(),
                              ),
                              error: (err, _) => Text(
                                'Categories error: $err'.tr,
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                      ],
                    ),
                  ),
                  if (showInlineActions) ...[
                    const SizedBox(height: 20),
                    _ActionButtons(onPublish: onPublish, isLoading: s.loading),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}