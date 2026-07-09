// lib/screens/association_notifications/create/create_campaign_dialog.dart
// Comments are in English as requested.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:association/providers/notifications.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

import 'status_selector.dart';
import 'schedule_picker.dart';

class CreateCampaignDialog extends ConsumerStatefulWidget {
  const CreateCampaignDialog({
    super.key,
    required this.baseUrl,
    required this.associationId,
    required this.onCreated,
    required this.theme,
  });

  final String baseUrl;
  final int associationId;
  final void Function(String id) onCreated;
  final ThemeColors theme;

  @override
  ConsumerState<CreateCampaignDialog> createState() =>
      _CreateCampaignDialogState();
}

class _CreateCampaignDialogState extends ConsumerState<CreateCampaignDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _text = TextEditingController();
  final _image = TextEditingController();
  final _actions =
      TextEditingController(text: '[{"title":"Open","url":"https://superbee.cloud"}]');

  final _memberStatuses = <String>{'active'}; // default filter
  DateTime? _scheduledAt;
  bool _respectConsent = true;
  bool _sending = false;
  int? _dryCount;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    _image.dispose();
    _actions.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>>? _parseActions(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is List) {
        return parsed
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(assocNotifApiProvider(widget.baseUrl));

    Future<void> handleDryRun() async {
      if (!_form.currentState!.validate()) return;
      setState(() => _sending = true);
      try {
        final count = await api.dryRun(
          associationId: widget.associationId,
          title: _title.text.trim(),
          text: _text.text.trim(),
          image: _image.text.trim().isEmpty ? null : _image.text.trim(),
          memberStatuses: _memberStatuses.toList(),
          respectConsent: _respectConsent,
        );
        if (!mounted) return;
        setState(() => _dryCount = count);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Dry-run błąd: $e')));
        }
      } finally {
        if (mounted) setState(() => _sending = false);
      }
    }

    Future<void> handleSubmit() async {
      if (!_form.currentState!.validate()) return;
      setState(() => _sending = true);
      try {
        final id = await api.createCampaign(
          associationId: widget.associationId,
          title: _title.text.trim(),
          text: _text.text.trim(),
          image: _image.text.trim().isEmpty ? null : _image.text.trim(),
          actions: _parseActions(_actions.text),
          memberStatuses: _memberStatuses.toList(),
          respectConsent: _respectConsent,
          scheduledAt: _scheduledAt,
          sendNow: _scheduledAt == null, // if no schedule, send now
        );
        widget.onCreated(id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Błąd tworzenia: $e')));
        }
      } finally {
        if (mounted) setState(() => _sending = false);
      }
    }

    return Dialog(
      backgroundColor: widget.theme.dashboardContainer,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  Text(
                    'Nowa kampania',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: widget.theme.textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: widget.theme.textColor),
                  ),
                ],
              ),
              const Divider(height: 16),

              // BODY (responsive)
              Expanded(
                child: Form(
                  key: _form,
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isMobile = constraints.maxWidth < 600;

                      // MOBILE: single column, scrollable
                      if (isMobile) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.only(
                            right: isMobile ? 4 : 28,
                            bottom: isMobile ? 8 : 32,
                            top: isMobile ? 0 : 24,
                            left: isMobile ? 0 : 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CoreTextFormField(
                                label: 'Tytuł*',
                                controller: _title,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Wpisz tytuł'.tr
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              CoreTextFormField(
                                label: 'Treść*',
                                controller: _text,
                                minLines: 4,
                                maxLines: 8,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Wpisz treść'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              CoreTextFormField(
                                label: 'Obraz (URL)',
                                controller: _image,
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                value: _respectConsent,
                                onChanged: (v) => setState(() => _respectConsent = v),
                                title: Text(
                                  'Szanuj zgody (respect_consent)',
                                  style: TextStyle(color: widget.theme.textColor),
                                ),
                                subtitle: Text(
                                  'Wyślij tylko do członków zezwalających na powiadomienia.',
                                  style: TextStyle(color: widget.theme.textColor),
                                ),
                              ),
                              const SizedBox(height: 12),
                              StatusSelector(
                                theme: widget.theme,
                                selected: _memberStatuses,
                                onChanged: (s) => setState(() {
                                  _memberStatuses
                                    ..clear()
                                    ..addAll(s);
                                }),
                              ),
                              const SizedBox(height: 12),
                              SchedulePicker(
                                theme: widget.theme,
                                scheduledAt: _scheduledAt,
                                onPick: (dt) => setState(() => _scheduledAt = dt),
                              ),
                              const SizedBox(height: 12),
                              CoreTextFormField(
                                label: 'Akcje (JSON list)',
                                controller: _actions,
                                minLines: 6,
                                maxLines: 12,
                                hintText: '[{"title":"Open","url":"..."}]',
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  try {
                                    final parsed = jsonDecode(v);
                                    if (parsed is! List) return 'Musi być listą obiektów';
                                  } catch (_) {
                                    return 'Nieprawidłowy JSON';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _sending ? null : handleDryRun,
                                    icon: Icon(Icons.visibility, color: widget.theme.textColor),
                                    label: Text('Dry-run', style: TextStyle(color: widget.theme.textColor)),
                                  ),
                                  if (_dryCount != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        'Potencjalni odbiorcy: $_dryCount',
                                        style: TextStyle(color: widget.theme.textColor),
                                      ),
                                    ),
                                  ElevatedButton.icon(
                                    onPressed: _sending ? null : handleSubmit,
                                    icon: Icon(Icons.save, color: widget.theme.textColor),
                                    label: Text(
                                      'Zapisz i wyślij / zaplanuj',
                                      style: TextStyle(color: widget.theme.textColor),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      // DESKTOP: 2-column layout
                      return Row(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.only(right: 12),
                              children: [
                                CoreTextFormField(
                                  label: 'Tytuł*',
                                  controller: _title,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Wpisz tytuł'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                CoreTextFormField(
                                  label: 'Treść*',
                                  controller: _text,
                                  minLines: 4,
                                  maxLines: 8,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Wpisz treść'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                CoreTextFormField(
                                  label: 'Obraz (URL)',
                                  controller: _image,
                                ),
                                const SizedBox(height: 12),
                                SwitchListTile(
                                  activeTrackColor: widget.theme.themeColor,
                                  value: _respectConsent,
                                  onChanged: (v) => setState(() => _respectConsent = v),
                                  title: Text(
                                    'Szanuj zgody (respect_consent)',
                                    style: TextStyle(color: widget.theme.textColor),
                                  ),
                                  subtitle: Text(
                                    'Wyślij tylko do członków zezwalających na powiadomienia.',
                                    style: TextStyle(color: widget.theme.textColor),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                StatusSelector(
                                  theme: widget.theme,
                                  selected: _memberStatuses,
                                  onChanged: (s) => setState(() {
                                    _memberStatuses
                                      ..clear()
                                      ..addAll(s);
                                  }),
                                ),
                                const SizedBox(height: 12),
                                SchedulePicker(
                                  theme: widget.theme,
                                  scheduledAt: _scheduledAt,
                                  onPick: (dt) => setState(() => _scheduledAt = dt),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: CoreTextFormField(
                                    label: 'Akcje (JSON list)',
                                    controller: _actions,
                                    minLines: 12,
                                    maxLines: 100,
                                    hintText: '[{"title":"Open","url":"..."}]',
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return null;
                                      try {
                                        final parsed = jsonDecode(v);
                                        if (parsed is! List) return 'Musi być listą obiektów';
                                      } catch (_) {
                                        return 'Nieprawidłowy JSON';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _sending ? null : handleDryRun,
                                      icon: Icon(Icons.visibility, color: widget.theme.textColor),
                                      label: Text('Dry-run', style: TextStyle(color: widget.theme.textColor)),
                                    ),
                                    const SizedBox(width: 12),
                                    if (_dryCount != null)
                                      Text(
                                        'Potencjalni odbiorcy: $_dryCount',
                                        style: TextStyle(color: widget.theme.textColor),
                                      ),
                                    ElevatedButton.icon(
                                      onPressed: _sending ? null : handleSubmit,
                                      icon: Icon(Icons.save, color: widget.theme.textColor),
                                      label: Text(
                                        'Zapisz i wyślij / zaplanuj',
                                        style: TextStyle(color: widget.theme.textColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
