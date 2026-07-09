
// Association Notifications Screen (Flutter Web/Desktop)
// Uses Riverpod. Plug into your routing as a standalone page.
// Comments are in English as requested.

import 'dart:convert';

import 'package:association/models/members_model.dart';
import 'package:association/providers/members_provider.dart';
import 'package:association/widgets/members.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:association/providers/notifications.dart';
import 'package:association/models/notifications_model.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';



class AssociationMemebrsScreen extends ConsumerStatefulWidget {
  const AssociationMemebrsScreen({
    super.key,
    required this.baseUrl,
    required this.associationId,
  });

  final String baseUrl;
  final int associationId;

  @override
  ConsumerState<AssociationMemebrsScreen> createState() =>
      _AssociationMemebrsScreensScreenState();
}

class _AssociationMemebrsScreensScreenState
    extends ConsumerState<AssociationMemebrsScreen> {

  Future<void> _openEditMemberDialog(AssociationMemberModel m) async {
    MemberStatus selected = m.status;
    final api = ref.read(associationMemberApiProvider);

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('edit_member'.tr),
          content: DropdownButton<MemberStatus>(
            value: selected,
            isExpanded: true,
            items: MemberStatus.values
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.apiValue.tr),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => selected = v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await api.update(m.id, {'status': selected.apiValue});
                  ref.invalidate(associationMembersProvider);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: Text('save'.tr),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Load campaigns on first build (if needed for this screen).
    Future.microtask(
      () => ref
          .read(
            campaignListProvider(
              (baseUrl: widget.baseUrl, associationId: widget.associationId),
            ).notifier,
          )
          .load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();

    // Optional: info o rozmiarze, jakbyś chciał kiedyś różnicować logikę
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.association,
      paddingPc: 10,
      paddingMobile: 8,
      // Uwaga: zostawiamy enableScrool = false, bo MembershipStatusBody
      // ma w środku Expanded + ListView – on sam ogarnia scroll.
      enableScrool: false,

      // ============== DESKTOP (PC) ==============
      childrenPc: [
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              border: Border.all(color: theme.dashboardBoarder),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            clipBehavior: Clip.antiAlias,
            child: MembershipStatusBody(
              associationId: widget.associationId,
              isWidget: false, // pełna wersja z dużym headerem/CTA
              theme: theme,
              onManagePayments: null,
              onViewDetails: null,
              onEdit: (m) => _openEditMemberDialog(m),
              onSendInvoice: null,
              onSendReminder: null,
            ),
          ),
        ),
      ],

      // ============== MOBILE ==============
      //
      // Klucz: dajemy Expanded, żeby zaspokoić Expanded w środku MembershipStatusBody.
      // Column w BarManagerze (mobile) ma wtedy bounded height, więc nie ma errorów.

        verticalButtons: isMobile
      ? MembersMobileVerticalButtons(
          associationId: widget.associationId,
          theme: theme,
        )
      : null,
      childrenMobile: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            clipBehavior: Clip.antiAlias,
            child: MembershipStatusBody(
              associationId: widget.associationId,
              isWidget: false, // ta sama "page"-wersja, tylko węższy ekran
              isMobile: true,
              theme: theme,
              onManagePayments: null,
              onViewDetails: null,
              onEdit: (m) => _openEditMemberDialog(m),
              onSendInvoice: null,
              onSendReminder: null,
            ),
          ),
        ),
      ],
    );
  }

  String _subtitleFor(AssociationNotificationCampaign c) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    String left = 'Utworzono: ${df.format(c.createdAt)}';
    if (c.scheduledAt != null) {
      left += '  •  Plan: ${df.format(c.scheduledAt!)}';
    }
    final right = 'Wysłano: ${c.sentSuccess}/${c.totalRecipients}';
    return '$left\n$right';
  }

  Widget _statusChip(String status) {
    Color col;
    switch (status) {
      case AssocCampaignStatus.sending:
        col = Colors.blue;
        break;
      case AssocCampaignStatus.scheduled:
        col = Colors.orange;
        break;
      case AssocCampaignStatus.sent:
        col = Colors.green;
        break;
      case AssocCampaignStatus.cancelled:
        col = Colors.grey;
        break;
      case AssocCampaignStatus.failed:
        col = Colors.red;
        break;
      default:
        col = Colors.indigo;
    }
    return Chip(label: Text(status), backgroundColor: col.withAlpha(38));
  }
}


class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


class _DetailPane extends ConsumerWidget {
  const _DetailPane({required this.baseUrl, required this.selectedId, required this.onActionDone});
  final String baseUrl;
  final String? selectedId;
  final Future<void> Function() onActionDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedId == null) {
      return const Center(child: Text('Wybierz kampanię z listy lub utwórz nową.'));
    }
    final detail = ref.watch(campaignDetailProvider((baseUrl: baseUrl, id: selectedId!)));
    return detail.when(
      data: (c) => c == null
          ? const Center(child: Text('Nie znaleziono kampanii.'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.title, style: Theme.of(context).textTheme.headlineSmall),
                      ),
                      const SizedBox(width: 12),
                      _ActionButtons(baseUrl: baseUrl, campaign: c, onDone: onActionDone),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(c.text),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoTile('Status', c.status),
                      _InfoTile('Plan', c.scheduledAt?.toLocal().toString().substring(0,16) ?? '—'),
                      _InfoTile('Wysłano', '${c.sentSuccess}/${c.totalRecipients} (failed: ${c.sentFailed})'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (c.image != null && c.image!.isNotEmpty)
                    SizedBox(
                      height: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(c.image!, fit: BoxFit.cover),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _PreviewRecipients(c.preview)),
                        const SizedBox(width: 16),
                        Expanded(child: _JsonCard('Akcje (JSON)', c.actions)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Błąd: $e')),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.baseUrl, required this.campaign, required this.onDone});
  final String baseUrl;
  final AssociationNotificationCampaign campaign;
  final Future<void> Function() onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(assocNotifApiProvider(baseUrl));
    final busy = ValueNotifier(false);

    Future<void> _do(Future<void> Function() f) async {
      if (busy.value) return;
      busy.value = true;
      try {
        await f();
        await onDone();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gotowe.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
        }
      } finally {
        busy.value = false;
      }
    }

    return ValueListenableBuilder(
      valueListenable: busy,
      builder: (_, bool isBusy, __) {
        return Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: isBusy ? null : () => _do(() => api.sendNow(campaign.id)),
              icon: const Icon(Icons.send),
              label: const Text('Wyślij teraz'),
            ),
            OutlinedButton.icon(
              onPressed: isBusy ? null : () => _do(() => api.cancelCampaign(campaign.id)),
              icon: const Icon(Icons.cancel),
              label: const Text('Anuluj'),
            ),
          ],
        );
      },
    );
  }
}

class _PreviewRecipients extends StatelessWidget {
  const _PreviewRecipients(this.items);
  final List<RecipientPreview> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Podgląd odbiorców (pierwsze 10)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Brak podglądu.'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final r = items[i];
                        return ListTile(
                          dense: true,
                          title: Text(r.memberName.isEmpty ? r.memberId : r.memberName),
                          subtitle: Text(r.status + (r.error != null && r.error!.isNotEmpty ? '  •  ${r.error}' : '')),
                          trailing: r.sentAt != null ? Text(DateFormat('MM-dd HH:mm').format(r.sentAt!.toLocal())) : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JsonCard extends StatelessWidget {
  const _JsonCard(this.title, this.value);
  final String title;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final encoded = const JsonEncoder.withIndent('  ').convert(value);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(encoded, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// 5) CREATE DIALOG
// =====================
class CreateCampaignDialog extends ConsumerStatefulWidget {
  const CreateCampaignDialog({
    super.key,
    required this.baseUrl,
    required this.associationId,
    required this.onCreated,
  });

  final String baseUrl;
  final int associationId;
  final void Function(String id) onCreated;

  @override
  ConsumerState<CreateCampaignDialog> createState() => _CreateCampaignDialogState();
}

class _CreateCampaignDialogState extends ConsumerState<CreateCampaignDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _text = TextEditingController();
  final _image = TextEditingController();
  final _actions = TextEditingController(
    text: '[{"title":"Open","url":"https://superbee.cloud"}]',
  );
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

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(assocNotifApiProvider(widget.baseUrl));

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Nowa kampania',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 16),
              Expanded(
                child: Form(
                  key: _form,
                  child: Row(
                    children: [
                      // Left form
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(right: 12),
                          children: [
                            CoreTextFormField(
                              label: 'Tytuł*',
                              controller: _title,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Wpisz tytuł' : null,
                            ),
                            const SizedBox(height: 12),
                            CoreTextFormField(
                              label: 'Treść*',
                              controller: _text,
                              minLines: 4,
                              maxLines: 8,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Wpisz treść' : null,
                            ),
                            const SizedBox(height: 12),
                            CoreTextFormField(
                              label: 'Obraz (URL)',
                              controller: _image,
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              value: _respectConsent,
                              onChanged: (v) =>
                                  setState(() => _respectConsent = v),
                              title: const Text('Szanuj zgody (respect_consent)'),
                              subtitle: const Text(
                                'Wyślij tylko do członków zezwalających na powiadomienia.',
                              ),
                            ),
                            const SizedBox(height: 12),
                            _StatusSelector(
                              selected: _memberStatuses,
                              onChanged: (s) => setState(
                                () => _memberStatuses
                                  ..clear()
                                  ..addAll(s),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SchedulePicker(
                              scheduledAt: _scheduledAt,
                              onPick: (dt) =>
                                  setState(() => _scheduledAt = dt),
                            ),
                          ],
                        ),
                      ),

                      // Right actions JSON + dry run
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: CoreTextFormField(
                                label: 'Akcje (JSON list)',
                                hintText: '[{"title":"Open","url":"..."}]',
                                controller: _actions,
                                minLines: 12,
                                maxLines: 100,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return null; // optional
                                  }
                                  try {
                                    final parsed = jsonDecode(v);
                                    if (parsed is! List) {
                                      return 'Musi być listą obiektów';
                                    }
                                  } catch (_) {
                                    return 'Nieprawidłowy JSON';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _sending
                                      ? null
                                      : () async {
                                          if (!_form.currentState!.validate()) {
                                            return;
                                          }
                                          setState(() => _sending = true);
                                          try {
                                            final count = await api.dryRun(
                                              associationId:
                                                  widget.associationId,
                                              title: _title.text.trim(),
                                              text: _text.text.trim(),
                                              image: _image.text
                                                      .trim()
                                                      .isEmpty
                                                  ? null
                                                  : _image.text.trim(),
                                              memberStatuses:
                                                  _memberStatuses.toList(),
                                              respectConsent: _respectConsent,
                                            );
                                            setState(
                                              () => _dryCount = count,
                                            );
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Dry-run błąd: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(
                                                () => _sending = false,
                                              );
                                            }
                                          }
                                        },
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('Dry-run'),
                                ),
                                const SizedBox(width: 12),
                                if (_dryCount != null)
                                  Text('Potencjalni odbiorcy: $_dryCount'),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: _sending
                                      ? null
                                      : () async {
                                          if (!_form.currentState!.validate()) {
                                            return;
                                          }
                                          setState(() => _sending = true);
                                          try {
                                            final id =
                                                await api.createCampaign(
                                              associationId:
                                                  widget.associationId,
                                              title: _title.text.trim(),
                                              text: _text.text.trim(),
                                              image: _image.text
                                                      .trim()
                                                      .isEmpty
                                                  ? null
                                                  : _image.text.trim(),
                                              actions:
                                                  _parseActions(_actions.text),
                                              memberStatuses:
                                                  _memberStatuses.toList(),
                                              respectConsent: _respectConsent,
                                              scheduledAt: _scheduledAt,
                                              // if no schedule, send now
                                              sendNow: _scheduledAt == null,
                                            );
                                            widget.onCreated(id);
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Błąd tworzenia: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(
                                                () => _sending = false,
                                              );
                                            }
                                          }
                                        },
                                  icon: const Icon(Icons.save),
                                  label: const Text(
                                    'Zapisz i wyślij / zaplanuj',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>>? _parseActions(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is List) {
        return parsed.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.selected, required this.onChanged});
  final Set<String> selected;
  final void Function(Set<String>) onChanged;

  @override
  Widget build(BuildContext context) {
    final options = const [
      'active', 'pending', 'suspended', 'former',
    ];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Statusy członków', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: options.map((s) {
                final isSel = selected.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: isSel,
                  onSelected: (v) {
                    final next = {...selected};
                    if (v) {
                      next.add(s);
                    } else {
                      next.remove(s);
                    }
                    onChanged(next);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchedulePicker extends StatelessWidget {
  const _SchedulePicker({required this.scheduledAt, required this.onPick});
  final DateTime? scheduledAt;
  final void Function(DateTime?) onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Text('Plan wysyłki:'),
            const SizedBox(width: 12),
            Text(scheduledAt == null ? 'natychmiast' : DateFormat('yyyy-MM-dd HH:mm').format(scheduledAt!.toLocal())),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  firstDate: now,
                  lastDate: DateTime(now.year + 5),
                  initialDate: scheduledAt ?? now,
                );
                if (d == null) return;
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(scheduledAt ?? now),
                );
                if (t == null) return;
                final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                onPick(dt.toUtc()); // send UTC to backend
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Ustaw'),
            ),
            const SizedBox(width: 8),
            if (scheduledAt != null)
              TextButton(
                onPressed: () => onPick(null),
                child: const Text('Wyczyść'),
              ),
          ],
        ),
      ),
    );
  }
}
