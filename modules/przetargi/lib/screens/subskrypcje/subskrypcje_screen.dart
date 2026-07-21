import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';

import '../../data/models/przetarg_model.dart';
import '../../data/providers/przetargi_provider.dart';
import '../../data/services/przetargi_api.dart';

class SubskrypcjeScreen extends ConsumerWidget {
  const SubskrypcjeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(subskrypcjeProvider);

    final body = state.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) => Center(child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
      data: (lista) => lista.isEmpty
          ? _EmptyState(theme: theme, onAdd: () => _showForm(context, ref, null))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lista.length,
              itemBuilder: (ctx, i) => _SubskrypcjaCard(
                sub: lista[i],
                theme: theme,
                onEdit: () => _showForm(context, ref, lista[i]),
                onDelete: () => _delete(context, ref, lista[i].id),
                onToggle: (v) => _toggle(ref, lista[i], v),
              ),
            ),
    );

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.budkon,
      childPc: Stack(
        fit: StackFit.expand,
        children: [
          body,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              backgroundColor: theme.themeColor,
              icon: Icon(Icons.add_alert_outlined, color: theme.buttonTextColor),
              label: Text('Nowa subskrypcja', style: TextStyle(color: theme.buttonTextColor)),
              onPressed: () => _showForm(context, ref, null),
            ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext ctx, WidgetRef ref, SubskrypcjaPrzetargow? sub) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SubskrypcjaForm(
        sub: sub,
        onSaved: () => ref.invalidate(subskrypcjeProvider),
      ),
    );
  }

  Future<void> _delete(BuildContext ctx, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Usuń subskrypcję?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Anuluj')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Usuń')),
        ],
      ),
    );
    if (ok == true) {
      await PrzetargiApi().deleteSubskrypcja(id);
      ref.invalidate(subskrypcjeProvider);
    }
  }

  Future<void> _toggle(WidgetRef ref, SubskrypcjaPrzetargow sub, bool aktywna) async {
    await PrzetargiApi().updateSubskrypcja(sub.id, {'aktywna': aktywna});
    ref.invalidate(subskrypcjeProvider);
  }
}

class _SubskrypcjaCard extends StatelessWidget {
  final SubskrypcjaPrzetargow sub;
  final ThemeColors theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _SubskrypcjaCard({
    required this.sub,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(sub.nazwa,
                      style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
                Switch(
                    value: sub.aktywna,
                    activeColor: theme.themeColor,
                    onChanged: onToggle),
                PopupMenuButton(
                  icon: Icon(Icons.more_horiz, color: theme.textColor),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                    const PopupMenuItem(value: 'delete', child: Text('Usuń')),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),
            if (sub.cpvKody.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: sub.cpvKody
                    .map((k) => Chip(
                          label: Text(k,
                              style: TextStyle(fontSize: 11, color: theme.textColor)),
                          backgroundColor: theme.secondaryWidgetColor,
                          side: BorderSide(color: theme.bordercolor.withAlpha(40)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            if (sub.slowaKluczowe.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Słowa: ${sub.slowaKluczowe.join(", ")}',
                style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12),
              ),
            ],
            if (sub.wartoscMin != null || sub.wartoscMax != null) ...[
              const SizedBox(height: 4),
              Text(
                'Wartość: ${sub.wartoscMin ?? 0} — ${sub.wartoscMax ?? "∞"} PLN',
                style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12),
              ),
            ],
            if (sub.ostatniePobranie != null) ...[
              const SizedBox(height: 6),
              Text(
                'Ostatnie pobranie: ${_fmt(sub.ostatniePobranie!)}',
                style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}.${local.month.toString().padLeft(2, '0')}.${local.year} '
        '${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _SubskrypcjaForm extends StatefulWidget {
  final SubskrypcjaPrzetargow? sub;
  final VoidCallback onSaved;

  const _SubskrypcjaForm({this.sub, required this.onSaved});

  @override
  State<_SubskrypcjaForm> createState() => _SubskrypcjaFormState();
}

class _SubskrypcjaFormState extends State<_SubskrypcjaForm> {
  final _nazwaCtrl = TextEditingController();
  final _cpvCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _slowaCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  bool _aktywna = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.sub;
    if (s != null) {
      _nazwaCtrl.text = s.nazwa;
      _cpvCtrl.text = s.cpvKody.join(', ');
      _regionCtrl.text = s.regiony.join(', ');
      _slowaCtrl.text = s.slowaKluczowe.join(', ');
      _minCtrl.text = s.wartoscMin?.toString() ?? '';
      _maxCtrl.text = s.wartoscMax?.toString() ?? '';
      _aktywna = s.aktywna;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.sub == null ? 'Nowa subskrypcja' : 'Edytuj subskrypcję',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nazwaCtrl,
            decoration: const InputDecoration(labelText: 'Nazwa subskrypcji'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cpvCtrl,
            decoration: const InputDecoration(
              labelText: 'Kody CPV (oddzielone przecinkami)',
              hintText: '45000000-7, 45210000-2',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regionCtrl,
            decoration: const InputDecoration(
              labelText: 'Województwa',
              hintText: 'małopolskie, śląskie',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _slowaCtrl,
            decoration: const InputDecoration(
              labelText: 'Słowa kluczowe',
              hintText: 'budynek, remont, instalacja',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minCtrl,
                  decoration: const InputDecoration(labelText: 'Wartość min (PLN)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxCtrl,
                  decoration: const InputDecoration(labelText: 'Wartość max (PLN)'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Aktywna'),
            value: _aktywna,
            onChanged: (v) => setState(() => _aktywna = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(widget.sub == null ? 'Utwórz' : 'Zapisz'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<String> _splitList(String s) =>
      s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = {
      'nazwa': _nazwaCtrl.text.trim().isEmpty ? 'Subskrypcja' : _nazwaCtrl.text.trim(),
      'cpv_kody': _splitList(_cpvCtrl.text),
      'regiony': _splitList(_regionCtrl.text),
      'slowa_kluczowe': _splitList(_slowaCtrl.text),
      if (_minCtrl.text.isNotEmpty) 'wartosc_min': double.tryParse(_minCtrl.text),
      if (_maxCtrl.text.isNotEmpty) 'wartosc_max': double.tryParse(_maxCtrl.text),
      'aktywna': _aktywna,
    };

    try {
      final api = PrzetargiApi();
      if (widget.sub == null) {
        await api.createSubskrypcja(data);
      } else {
        await api.updateSubskrypcja(widget.sub!.id, data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  final ThemeColors theme;
  const _EmptyState({required this.onAdd, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined,
                size: 64, color: theme.textColor.withAlpha(80)),
            const SizedBox(height: 16),
            Text('Brak subskrypcji',
                style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Utwórz subskrypcję żeby automatycznie pobierać pasujące przetargi z BZP.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textColor.withAlpha(150)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('Utwórz subskrypcję'),
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                  backgroundColor: theme.themeColor,
                  foregroundColor: theme.buttonTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
