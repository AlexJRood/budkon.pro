/// ────────────────────────────────────────────────────────────────
/// Dialog: wybór istniejącego / utworzenie nowego + (opcjonalnie) event — JEDEN FORMULARZ
import 'dart:convert';
import 'package:crm/crm_urls.dart';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import 'package:core/theme/text_field.dart';
import 'package:crm/contact_panel/viewer/viewer_provider.dart';

class AddViewerDialog extends ConsumerStatefulWidget {
  final int transactionId;
  const AddViewerDialog({super.key, required this.transactionId});

  @override
  ConsumerState<AddViewerDialog> createState() => _AddViewerDialogState();
}

enum _AddMode { pickExisting, createNew }

class _AddViewerDialogState extends ConsumerState<AddViewerDialog> {
  // tryb
  _AddMode _mode = _AddMode.pickExisting;

  // parse helper
  final _parse = const Utf8Decoder();

  // list existing
  final _searchCtrl = TextEditingController();
  bool _loadingList = false;
  int? _selectedContactId;
  List<Map<String, dynamic>> _items = [];

  // create new contact
  final _formKeyNewContact = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  Uint8List? _avatarBytes;
  String? _avatarFileName;

  // event (opcjonalny)
  bool _addEvent = false;
  final _eventFormKey = GlobalKey<FormState>();
  final _eventTitleCtrl = TextEditingController(text: 'property_presentation_default_title'.tr);
  final _eventDescCtrl = TextEditingController();
  final _eventLocCtrl  = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _end   = const TimeOfDay(hour: 11, minute: 0);

  bool _saving = false;

  // ── helpers ───────────────────────────────────────────────────
  dynamic _parseBody(dynamic data) {
    if (data == null) return null;
    if (data is List<int>) {
      final raw = _parse.convert(data);
      try { return json.decode(raw); } catch (_) { return raw; }
    }
    if (data is String) {
      try { return json.decode(data); } catch (_) { return data; }
    }
    return data;
  }

  Future<void> _pickAvatar() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (res != null && res.files.isNotEmpty) {
      setState(() {
        _avatarBytes = res.files.single.bytes;
        _avatarFileName = res.files.single.name;
      });
    }
  }

  Future<void> _loadCandidates() async {
    setState(() => _loadingList = true);
    try {
      final resp = await ApiServices.get(
        URLs.userContacts,
        hasToken: true,
        ref: ref,
        queryParameters: {
          'viewer_transaction': widget.transactionId,
          'viewer_is_assigned': 'false',
          if (_searchCtrl.text.trim().isNotEmpty) 'search': _searchCtrl.text.trim(),
        },
      );
      final body = _parseBody(resp?.data);
      final results = (body is Map && body['results'] is List)
          ? (body['results'] as List).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      setState(() => _items = results);
    } finally {
      setState(() => _loadingList = false);
    }
  }

  Future<int?> _createContact() async {
    if (!_formKeyNewContact.currentState!.validate()) return null;

    final jsonBody = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      if (_lastNameCtrl.text.trim().isNotEmpty) 'last_name': _lastNameCtrl.text.trim(),
      if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (_phoneCtrl.text.trim().isNotEmpty) 'phone_number': _phoneCtrl.text.trim(),
    };

    Response? resp;

    if (_avatarBytes == null) {
      resp = await ApiServices.post(
        URLs.clientsCreate,
        data: jsonBody,
        hasToken: true,
      );
    } else {
      final form = FormData.fromMap({
        ...jsonBody,
        'avatar': MultipartFile.fromBytes(
          _avatarBytes!,
          filename: _avatarFileName ?? 'avatar.jpg',
        ),
      });

      // jeśli masz osobny postMultipart — użyj; jeśli nie, to:
      resp = await ApiServices.post(
        URLs.clientsCreate,
        formData: form,
        hasToken: true,
      );
    }

    final body = _parseBody(resp?.data);
    if (resp != null && (resp.statusCode == 200 || resp.statusCode == 201)) {
      if (body is Map && body['id'] is int) return body['id'] as int;
    }
    throw Exception('Create contact failed: ${resp?.statusCode} $body');
  }

  /// Dodaje istniejący kontakt jako viewer do transakcji (używane tylko gdy NIE tworzysz eventu)
  Future<int> _addViewerToTransaction(int contactId) async {
    final resp = await ApiServices.post(
      CrmUrls.transactionViewersList(widget.transactionId),
      hasToken: true,
      data: {'contact_id': contactId},
    );
    final body = _parseBody(resp?.data);
    int? vid;
    if (body is Map) {
      if (body['id'] is int) vid = body['id'] as int;
      if (vid == null && body['viewer'] is Map && body['viewer']['id'] is int) {
        vid = body['viewer']['id'] as int;
      }
    }
    return vid ?? -1; // sentinel gdy API nie zwróci id viewer’a
  }

  /// JEDEN request do backendu: utwórz event (i ewentualnie viewera) wg add_client_and_event
  Future<void> _createEventAndViewerIfNeeded({
    required int contactId,
  }) async {
    final startLocal = _combine(_date, _start);
    final endLocal = _combine(_date, _end);

    // 1) First make sure viewer exists for this transaction
    final viewerResp = await ApiServices.post(
      CrmUrls.estateAgentAddViewer,
      hasToken: true,
      data: {
        'client': {'id': contactId},
        'transaction_id': widget.transactionId,
      },
    );

    final viewerBody = _parseBody(viewerResp?.data);

    if (viewerResp == null ||
        (viewerResp.statusCode != 200 && viewerResp.statusCode != 201)) {
      throw Exception(
        'Create viewer failed: ${viewerResp?.statusCode} $viewerBody',
      );
    }

    int? viewerId;
    if (viewerBody is Map) {
      if (viewerBody['viewer'] is Map && viewerBody['viewer']['id'] is int) {
        viewerId = viewerBody['viewer']['id'] as int;
      } else if (viewerBody['id'] is int) {
        viewerId = viewerBody['id'] as int;
      }
    }

    if (viewerId == null || viewerId <= 0) {
      throw Exception('Viewer id not returned from backend.');
    }

    // 2) Then create the event using the working viewer-events endpoint
    final payload = {
      'title': _eventTitleCtrl.text.trim().isEmpty
          ? 'property_presentation_default_title'.tr
          : _eventTitleCtrl.text.trim(),
      'description': _eventDescCtrl.text.trim(),
      'location': _eventLocCtrl.text.trim(),
      'start_time': startLocal.toUtc().toIso8601String(),
      'end_time': endLocal.toUtc().toIso8601String(),
      'client_id': contactId,
      'transaction_id': widget.transactionId,
      'transaction_content_type': 'agenttransaction',
      'viewer': contactId,
    };

    debugPrint('VIEWER CREATE STATUS: ${viewerResp.statusCode}');
    debugPrint('VIEWER CREATE RESPONSE: $viewerBody');
    debugPrint('CREATED VIEWER ID: $viewerId');
    debugPrint('EVENT PAYLOAD: ${jsonEncode(payload)}');

    final event = await createViewerEvent(
      txId: widget.transactionId,
      viewerId: viewerId,
      payload: payload,
      ref: ref,
    );

    debugPrint('CREATED EVENT ID: ${event.id}');
  }

  DateTime _combine(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  Future<void> _submit() async {
    if (_mode == _AddMode.createNew && !_formKeyNewContact.currentState!.validate()) return;
    if (_addEvent && !_eventFormKey.currentState!.validate()) return;

    if (_addEvent) {
      final startLocal = _combine(_date, _start);
      final endLocal   = _combine(_date, _end);
      if (!endLocal.isAfter(startLocal)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('end_time_after_start_error'.tr)),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      int contactId;
      if (_mode == _AddMode.pickExisting) {
        if (_selectedContactId == null) return;
        contactId = _selectedContactId!;
      } else {
        final newId = await _createContact();
        if (newId == null) return;
        contactId = newId;
      }

      if (_addEvent) {
        debugPrint('EVENT FLOW STARTED');
        // ➜ Jeden request: backend sam utworzy/get_or_create Viewera dla transaction_id
        await _createEventAndViewerIfNeeded(contactId: contactId);
      } else {
        debugPrint('VIEWER ONLY FLOW STARTED');
        // ➜ Bez eventu: dodaj samego viewera do transakcji
        await _addViewerToTransaction(contactId);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'operation_failed_error'.tr} $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Theme dla date/time pickera ────────────────────────────────
  ThemeData _pickerTheme(BuildContext context) {
    final base = Theme.of(context);
    final c = ref.read(themeColorsProvider);

    final scheme = base.colorScheme.copyWith(
      primary: c.themeColor,
      onPrimary: Colors.white,
      surface: c.dashboardContainer,
      onSurface: c.textColor,
      secondary: c.dashboardBoarder,
      onSecondary: c.textColor,
    );

    MaterialStateProperty<T> msp<T>(T v) => MaterialStatePropertyAll<T>(v);
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
      datePickerTheme: base.datePickerTheme.copyWith(
        backgroundColor: c.dashboardContainer,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: c.themeColor,
        headerForegroundColor: Colors.white,
        dividerColor: c.dashboardBoarder,
        dayForegroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          if (states.contains(MaterialState.disabled)) return c.textColor.withAlpha(89);
          return c.textColor;
        }),
        dayBackgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.selected)) return c.themeColor;
          if (states.contains(MaterialState.hovered)) return c.themeColor.withAlpha(20);
          return Colors.transparent;
        }),
        todayForegroundColor: msp(c.themeColor),
        todayBackgroundColor: msp(c.themeColor.withAlpha(31)),
        yearForegroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.disabled)) return c.textColor.withAlpha(89);
          if (states.contains(MaterialState.selected)) return Colors.white;
          return c.textColor;
        }),
        yearBackgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.selected)) return c.themeColor;
          return Colors.transparent;
        }),
      ),
      timePickerTheme: base.timePickerTheme.copyWith(
        backgroundColor: c.dashboardContainer,
        dialBackgroundColor: c.themeColor.withAlpha(20),
        dialTextColor: c.textColor,
        entryModeIconColor: c.textColor,
        dayPeriodTextColor: c.textColor,
        hourMinuteTextColor: c.textColor,
        hourMinuteColor: hourMinuteBg,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.dashboardBoarder),
        ),
        timeSelectorSeparatorColor: MaterialStatePropertyAll(c.textColor.withAlpha(153)),
        timeSelectorSeparatorTextStyle: MaterialStatePropertyAll(
          base.textTheme.displayLarge?.copyWith(color: c.textColor.withAlpha(204)),
        ),
        helpTextStyle: base.textTheme.labelLarge?.copyWith(color: c.textColor),
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
          helperStyle: TextStyle(color: c.textColor.withAlpha(153), fontSize: 12),
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
      builder: (ctx, child) => Theme(data: _pickerTheme(ctx), child: child!),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime({required bool start}) async {
    final t = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
      builder: (ctx, child) => Theme(data: _pickerTheme(ctx), child: child!),
    );
    if (t != null) setState(() => start ? _start = t : _end = t);
  }

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return Dialog(
      backgroundColor: theme.dashboardContainer,
      child: SizedBox(
        width: 820,
        height: 760,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // nagłówek + tryby
              Row(
                children: [
                  Expanded(
                    child: Text('add_viewer_title'.tr,
                        style: TextStyle(color: theme.textColor, fontSize: 18)),
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<_AddMode>(
                    style: ButtonStyle(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return theme.themeColor;
                        }
                        return theme.textFieldColor;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return theme.themeTextColor;
                        }
                        return theme.textColor;
                      }),
                      iconColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return theme.themeColorText;
                        }
                        return AppColors.graphite;
                      }),
                    ),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: _AddMode.pickExisting,
                        label: Text('existing_mode_label'.tr),
                      ),
                      ButtonSegment(
                        value: _AddMode.createNew,
                        label: Text('new_contact_mode_label'.tr),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── SEKCJA KONTAKTU (scrolluje się tylko to)
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: _mode == _AddMode.pickExisting
                      ? _ExistingContactsSection(
                          key: const ValueKey('existing'),
                          theme: theme,
                          searchCtrl: _searchCtrl,
                          loading: _loadingList,
                          items: _items,
                          selectedContactId: _selectedContactId,
                          onSearch: _loadCandidates,
                          onSelect: (id) => setState(() => _selectedContactId = id),
                        )
                      : _NewContactSection(
                          key: const ValueKey('new'),
                          theme: theme,
                          formKey: _formKeyNewContact,
                          nameCtrl: _nameCtrl,
                          lastNameCtrl: _lastNameCtrl,
                          emailCtrl: _emailCtrl,
                          phoneCtrl: _phoneCtrl,
                          avatarBytes: _avatarBytes,
                          onPickAvatar: _pickAvatar,
                        ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── SEKCJA EVENTU (STAŁA, ZAWSZE NA DOLE)
              _EventSection(
                theme: theme,
                pickerTheme: _pickerTheme,
                addEvent: _addEvent,
                onToggle: (v) => setState(() => _addEvent = v),
                eventFormKey: _eventFormKey,
                titleCtrl: _eventTitleCtrl,
                descCtrl: _eventDescCtrl,
                locCtrl: _eventLocCtrl,
                date: _date,
                start: _start,
                end: _end,
                onPickDate: _pickDate,
                onPickStart: () => _pickTime(start: true),
                onPickEnd: () => _pickTime(start: false),
              ),

              const SizedBox(height: 12),

              // actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('cancel_button'.tr, style: TextStyle(color: theme.textColor)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: buttonStyleRounded10ThemeRedWithPadding15,
                    onPressed: _saving ? null : _submit,
                    child: Row(
                      spacing: 6,
                      children: [
                        if (_saving)
                          const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2))
                        else
                          const Icon(Icons.check, color: Colors.white),
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
    );
  }
}

/// ────────────────────────────────────────────────────────────────
/// Sekcje pomocnicze (kontakt istniejący / nowy / event)

class _ExistingContactsSection extends StatefulWidget {
  const _ExistingContactsSection({
    super.key,
    required this.theme,
    required this.searchCtrl,
    required this.loading,
    required this.items,
    required this.selectedContactId,
    required this.onSearch,
    required this.onSelect,
  });

  final ThemeColors theme;
  final TextEditingController searchCtrl;
  final bool loading;
  final List<Map<String, dynamic>> items;
  final int? selectedContactId;
  final VoidCallback onSearch;
  final ValueChanged<int?> onSelect;

  @override
  State<_ExistingContactsSection> createState() =>
      _ExistingContactsSectionState();
}

class _ExistingContactsSectionState extends State<_ExistingContactsSection> {
  List<Map<String, dynamic>> get _visibleItems {
    final query = widget.searchCtrl.text.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.items;
    }

    return widget.items.where((item) {
      final name = '${item['name'] ?? ''} ${item['last_name'] ?? ''}'
          .trim()
          .toLowerCase();

      final email = '${item['email'] ?? ''}'.trim().toLowerCase();
      final phone = '${item['phone_number'] ?? ''}'.trim().toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;

    return Column(
      children: [
        CoreTextField(
          controller: widget.searchCtrl,
          label: 'search_contact_label'.tr,
          prefixIcon: Icon(Icons.search, color: widget.theme.textColor),
          suffixIcon: widget.searchCtrl.text.trim().isEmpty
              ? null
              : IconButton(
            icon: Icon(Icons.close, color: widget.theme.textColor),
            onPressed: () {
              widget.searchCtrl.clear();
              setState(() {});
              widget.onSearch();
            },
          ),
          onChanged: (_) {
            setState(() {});
          },
          onSubmitted: (_) => widget.onSearch(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: widget.loading
              ?  Center(child: AppLottie.loading())
              : ListView.builder(
            itemCount: visibleItems.length,
            itemBuilder: (_, i) {
              final it = visibleItems[i];
              final id = it['id'] as int;
              final name = [it['name'], it['last_name']]
                  .where((e) => (e ?? '').toString().isNotEmpty)
                  .join(' ');
              final email = it['email'] ?? '';
              final avatar = (it['avatar'] ?? '') as String;

              return RadioListTile<int>(
                value: id,
                activeColor: widget.theme.themeColor,
                groupValue: widget.selectedContactId,
                onChanged: widget.onSelect,
                title: Text(
                  name,
                  style: TextStyle(color: widget.theme.textColor),
                ),
                subtitle: Text(
                  email,
                  style: TextStyle(color: widget.theme.textColor),
                ),
                secondary: CircleAvatar(
                  radius: 18,
                  backgroundImage:
                  avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty
                      ? AppIcons.person(color: widget.theme.textColor)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NewContactSection extends StatelessWidget {
  const _NewContactSection({
    super.key,
    required this.theme,
    required this.formKey,
    required this.nameCtrl,
    required this.lastNameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.avatarBytes,
    required this.onPickAvatar,
  });

  final ThemeColors theme;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final Uint8List? avatarBytes;
  final VoidCallback onPickAvatar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: (avatarBytes != null) ? MemoryImage(avatarBytes!) : null,
                  child: avatarBytes == null ? AppIcons.person(color: theme.textColor) : null,
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onPickAvatar,
                  icon: Icon(Icons.upload, color: theme.textColor),
                  label: Text('choose_avatar_button'.tr, style: TextStyle(color: theme.textColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CoreTextFormField(
              controller: nameCtrl,
              label: 'first_name_required_label'.tr,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'first_name_required_error'.tr : null,
            ),
            const SizedBox(height: 8),
            CoreTextFormField(controller: lastNameCtrl, label: 'last_name_label'.tr),
            const SizedBox(height: 8),
            CoreTextFormField(
              controller: emailCtrl,
              label: 'email_label'.tr,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            CoreTextFormField(
              controller: phoneCtrl,
              label: 'phone_label'.tr,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}

class _EventSection extends StatelessWidget {
  const _EventSection({
    required this.theme,
    required this.pickerTheme,
    required this.addEvent,
    required this.onToggle,
    required this.eventFormKey,
    required this.titleCtrl,
    required this.descCtrl,
    required this.locCtrl,
    required this.date,
    required this.start,
    required this.end,
    required this.onPickDate,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final ThemeColors theme;
  final ThemeData Function(BuildContext) pickerTheme;
  final bool addEvent;
  final ValueChanged<bool> onToggle;
  final GlobalKey<FormState> eventFormKey;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController locCtrl;
  final DateTime date;
  final TimeOfDay start;
  final TimeOfDay end;
  final VoidCallback onPickDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          value: addEvent,
          onChanged: onToggle,
          activeTrackColor: theme.themeColor,
          title: Text('add_event_optional_label'.tr,
              style: TextStyle(color: theme.textColor)),
        ),
        if (addEvent)
          Theme(
            data: pickerTheme(context),
            child: Form(
              key: eventFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CoreTextFormField(
                    controller: titleCtrl,
                    label: 'event_title_label'.tr,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'event_title_required_error'.tr : null,
                  ),
                  const SizedBox(height: 8),
                  CoreTextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    label: 'description_optional_label'.tr,
                  ),
                  const SizedBox(height: 8),
                  CoreTextFormField(
                    controller: locCtrl,
                    label:'location_optional_label'.tr,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onPickDate,
                          icon:  Icon(Icons.event,color: theme.textColor,),
                          label: Text(
                            '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}',
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onPickStart,
                          icon: Icon(Icons.schedule, color: theme.textColor),
                          label: Text(
                            '${start.hour.toString().padLeft(2,'0')}:${start.minute.toString().padLeft(2,'0')}',
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onPickEnd,
                          icon: Icon(Icons.schedule_outlined, color: theme.textColor),
                          label: Text(
                            '${end.hour.toString().padLeft(2,'0')}:${end.minute.toString().padLeft(2,'0')}',
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
