
import 'package:calendar/models/event_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart'; 
import 'package:crm/contact_panel/viewer/viewer_provider.dart';
import 'package:crm/contact_panel/viewer/viewer_models.dart';
import 'package:core/theme/text_field.dart';







class ViewerEventsSheet extends ConsumerStatefulWidget {
  final int txId;
  final ViewerItem viewer;
  final int clientId;
  final VoidCallback? onChanged;

  const ViewerEventsSheet({
    super.key,
    required this.txId,
    required this.viewer,
    required this.clientId,
    this.onChanged,
  });

  @override
  ConsumerState<ViewerEventsSheet> createState() => _ViewerEventsSheetState();
}

class _ViewerEventsSheetState extends ConsumerState<ViewerEventsSheet> {
  late Future<List<EventModel>> _future;

  @override
  void initState() {
    super.initState();
    // start: szybki render z już posiadanych danych
    _future = Future.value(widget.viewer.events);

    // opcjonalny “refresh” po starcie (dociąga najświeższe z API)
    // WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() {
      _future = fetchViewerEvents(
        txId: widget.txId,
        viewerId: widget.viewer.id,
        ref: ref,
      );
    });
    await _future;
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, controller) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text('${'Events'} – ${[widget.viewer.name, widget.viewer.lastName].where((e)=> (e??'').isNotEmpty).join(' ')}',
                      style: AppTextStyles.interSemiBold18.copyWith(color: theme.textColor)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'add_event_tooltip'.tr,
                    icon: AppIcons.add(color: theme.textColor),
                    onPressed: () async {
                      final created = await showDialog<bool>(
                              context: context,
                              builder: (_) => _CreateViewerEventDialog(
                                theme: theme,
                                contactId: widget.clientId,
                                txId: widget.txId,
                                viewerId: widget.viewer.id,
                                ref: ref,
                              ),
                            );
                            if (created == true) {
                              await _refresh();
                            }
                          },

                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<EventModel>>(
                  future: _future,
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      if (snap.hasError) {
                        return Center(child: Text('${'error_prefix'.tr} ${snap.error}'.tr));
                      }
                      return const Center(child: CircularProgressIndicator());
                    }
                    final events = snap.data!;
                    if (events.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppLottie.noResults(),
                            const SizedBox(height: 12),
                            Text('no_events_message'.tr, style: AppTextStyles.interLight16.copyWith(color: theme.textColor)),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: controller,
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = events[i];
                        final range = '${_fmt(e.from)} – ${_fmt(e.to)}';
                        return ListTile(
                          leading: AppIcons.calendar(color: theme.textColor),
                          title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: theme.textColor)),
                          subtitle: Text(range, style: AppTextStyles.interLight14.copyWith(color: theme.textColor)),
                          onTap: () {
                            // tu możesz przejść do szczegółów eventu (twoja routa)
                            // ref.read(navigationService).pushNamedScreen('/calendar/event/${e.id}');
                          },
                          trailing: e.isCompleted
                              ? AppIcons.check(color: theme.textColor)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(DateTime d) {
    // szybki, lokalny format; podmień na swój DateFormat
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} $hh:$mm';
  }
}











class _CreateViewerEventDialog extends StatefulWidget {
  final int txId;
  final int viewerId;
  final int contactId; // ⬅️ DODANE
  final WidgetRef ref;
  final ThemeColors theme;

  const _CreateViewerEventDialog({
    required this.txId,
    required this.viewerId,
    required this.contactId, // ⬅️ DODANE
    required this.ref,
    required this.theme,
  });

  @override
  State<_CreateViewerEventDialog> createState() => _CreateViewerEventDialogState();
}



class _CreateViewerEventDialogState extends State<_CreateViewerEventDialog> {
  final _form = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController(text: 'property_presentation_default_title'.tr);
  final _descCtrl = TextEditingController();
  final _locCtrl  = TextEditingController();

  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _end   = const TimeOfDay(hour: 11, minute: 0);
  bool _saving = false;



ThemeData _pickerTheme(BuildContext context) {
  final base = Theme.of(context);
  final c = widget.theme;

  final scheme = base.colorScheme.copyWith(
    primary: c.themeColor,
    onPrimary: Colors.white,
    surface: c.dashboardContainer,
    onSurface: c.textColor,
    secondary: c.dashboardBoarder,
    onSecondary: c.textColor,
  );

  MaterialStateProperty<T> msp<T>(T v) => MaterialStatePropertyAll<T>(v);

  // Wyraźniejsze sterowanie tłem segmentów (wybrany vs niewybrany)
  final hourMinuteBg = MaterialStateColor.resolveWith((states) {
    if (states.contains(MaterialState.selected)) return c.themeColor;
    return c.dashboardContainer;
  });

  return base.copyWith(
    useMaterial3: true,
    colorScheme: scheme,
    dialogBackgroundColor: c.dashboardContainer,
    dialogTheme: base.dialogTheme.copyWith(
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: msp(Colors.white),
        backgroundColor: msp(c.themeColor),
        shape: msp(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        padding: msp(const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
      ),
    ),

    // DATE PICKER (jak miałeś) ...

    // ───────── TIME PICKER + INPUT STYLING ─────────
    timePickerTheme: base.timePickerTheme.copyWith(
      backgroundColor: c.dashboardContainer,
      dialBackgroundColor: c.themeColor.withAlpha(20),
      dialTextColor: c.textColor,
      entryModeIconColor: c.textColor,
      dayPeriodTextColor: c.textColor,

      // segmenty Godzina/Minuta
      hourMinuteTextColor: c.textColor,
      hourMinuteColor: hourMinuteBg, // wybrany = themeColor, reszta = tło dialogu
      hourMinuteShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.dashboardBoarder),
      ),

      // separator „:” pomiędzy polami
      timeSelectorSeparatorColor: MaterialStatePropertyAll(c.textColor.withAlpha(153)),
      timeSelectorSeparatorTextStyle: MaterialStatePropertyAll(
        base.textTheme.displayLarge?.copyWith(color: c.textColor.withAlpha(204)),
      ),

      // Tekst w nagłówku
      helpTextStyle: base.textTheme.labelLarge?.copyWith(color: c.textColor),

      // Przyciski
      confirmButtonStyle: ButtonStyle(
        foregroundColor: msp(Colors.white),
        backgroundColor: msp(c.themeColor),
        shape: msp(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        padding: msp(const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
      ),
      cancelButtonStyle: ButtonStyle(
        foregroundColor: msp(Colors.white),
        backgroundColor: msp(c.dashboardBoarder),
        shape: msp(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        padding: msp(const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
      ),



  inputDecorationTheme: InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: c.adPopBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    hintStyle: TextStyle(color: c.textColor.withAlpha(128)),
    labelStyle: TextStyle(color: c.textColor.withAlpha(204)),

    // ⬇️ helper (czyli „Godzina” / „Minuta” pod inputem)
    helperStyle: TextStyle(
      color: c.textColor.withAlpha(153),   // tu ustaw kolor
      fontSize: 12,
    ),
    // (opcjonalnie)
    counterStyle: TextStyle(color: c.textColor.withAlpha(115)),
    errorStyle: TextStyle(color: (c.themeColor ?? Colors.red).withAlpha(242)),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c.dashboardBoarder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c.dashboardBoarder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c.themeColor, width: 1.5),
    ),
  ),
),
  );
}



Future<void> _pickDate() async {
  final d = await showDatePicker(
    context: context,
    initialDate: _date,
    firstDate: DateTime.now().subtract(const Duration(days: 1)),
    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    builder: (context, child) => Theme(
      data: _pickerTheme(context),
      child: child!,
    ),
  );
  if (d != null) setState(() => _date = d);
}

Future<void> _pickStartTime() async {
  final t = await showTimePicker(
    context: context,
    initialTime: _start,
    builder: (context, child) => Theme(
      data: _pickerTheme(context),
      child: child!,
    ),
  );
  if (t != null) setState(() => _start = t);
}

Future<void> _pickEndTime() async {
  final t = await showTimePicker(
    context: context,
    initialTime: _end,
    builder: (context, child) => Theme(
      data: _pickerTheme(context),
      child: child!,
    ),
  );
  if (t != null) setState(() => _end = t);
}



  DateTime _combine(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    final startLocal = _combine(_date, _start);
    final endLocal   = _combine(_date, _end);

    if (!endLocal.isAfter(startLocal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('end_time_after_start_error'.tr)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = {
        "title": _titleCtrl.text.trim(),
        "description": _descCtrl.text.trim(),
        "location": _locCtrl.text.trim(),
        "start_time": startLocal.toUtc().toIso8601String(),
        "end_time": endLocal.toUtc().toIso8601String(),

        // ⬇️ ważne: przypnij klienta już z frontu
        "client_id": widget.contactId,

        // (opcjonalnie) jeśli wolisz nie polegać na defaultach backendu:
        "transaction_id": widget.txId,
        "transaction_content_type": "agenttransaction",
        // możesz też dopiąć viewer FK (Event.viewer -> UserContact):
        "viewer": widget.contactId,
      };


      await createViewerEvent(
        txId: widget.txId,
        viewerId: widget.viewerId,
        payload: payload,
        ref: widget.ref,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'event_creation_error'.tr} $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Dialog(
      backgroundColor: widget.theme.dashboardContainer,

      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('new_event_title'.tr, style: TextStyle(color: widget.theme.textColor, fontSize:18)),
                const SizedBox(height: 12),

                CoreTextFormField(
                  controller: _titleCtrl,
                  label: 'title_label'.tr,                  
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'title_required_error'.tr : null,
                ),
                const SizedBox(height: 8),

                // TextFormField(
                //   controller: _locCtrl,
                //   decoration: const InputDecoration(labelText: 'Lokalizacja (opcjonalnie)'),
                // ),
                // const SizedBox(height: 8),

                  CoreTextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  label: 'description_optional_label'.tr
                ),
                const SizedBox(height: 12),

                // Data
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: Icon(Icons.event, color: widget.theme.textColor),
                        label: Text(
                          '${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}',
                          style: TextStyle(color: widget.theme.textColor)
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Czas start/koniec
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickStartTime,
                        icon: Icon(Icons.schedule, color: widget.theme.textColor),
                        label: Text('${_start.hour.toString().padLeft(2,'0')}:${_start.minute.toString().padLeft(2,'0')}', style: TextStyle(color: widget.theme.textColor)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickEndTime,
                        icon: Icon(Icons.schedule_outlined, color: widget.theme.textColor),
                        label: Text('${_end.hour.toString().padLeft(2,'0')}:${_end.minute.toString().padLeft(2,'0')}', style: TextStyle(color: widget.theme.textColor)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child:  Text('cancel_button'.tr, style: TextStyle(color: widget.theme.textColor))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: buttonStyleRounded10ThemeRedWithPadding15,
                      onPressed: _saving ? null : _save,
                      child: 
                      Row(
                        children:[
                        _saving ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.check),
                       Text('save_button'.tr, style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

