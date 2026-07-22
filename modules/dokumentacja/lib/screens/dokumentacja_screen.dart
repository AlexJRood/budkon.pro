import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/dokumentacja_model.dart';
import '../data/providers/dokumentacja_provider.dart';

class DokumentacjaScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;

  const DokumentacjaScreen(
      {super.key, required this.budowaId, required this.budowaNazwa});

  @override
  ConsumerState<DokumentacjaScreen> createState() => _DokumentacjaScreenState();
}

class _DokumentacjaScreenState extends ConsumerState<DokumentacjaScreen> {
  KategoriaDokumentu? _filterKat;
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dokumentacjaProvider.notifier).init(widget.budowaId);
    });
  }

  void _showAddSheet(ThemeColors theme) {
    KategoriaDokumentu kat = KategoriaDokumentu.inne;
    final tytulCtrl = TextEditingController();
    final numerCtrl = TextEditingController();
    final opisCtrl = TextEditingController();
    DateTime dataWydania = DateTime.now();
    DateTime? dataWaznosci;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.userTile,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dodaj dokument',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: KategoriaDokumentu.values.map((k) {
                    final sel = kat == k;
                    return GestureDetector(
                      onTap: () => setInner(() => kat = k),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sel ? theme.themeColor.withAlpha(40) : theme.userTile,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? theme.themeColor : theme.bordercolor.withAlpha(60)),
                        ),
                        child: Text('${k.emoji} ${k.label}',
                            style: TextStyle(
                                fontSize: 11,
                                color: sel ? theme.themeColor : theme.textColor)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                _tf(tytulCtrl, 'Tytuł *', theme),
                const SizedBox(height: 8),
                _tf(numerCtrl, 'Numer / sygnatura (opcjonalnie)', theme),
                const SizedBox(height: 8),
                _tf(opisCtrl, 'Opis (opcjonalnie)', theme, maxLines: 2),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _datePicker(
                          'Data wydania', dataWydania, (d) => setInner(() => dataWydania = d), theme),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _datePicker(
                          'Ważny do (opcj.)', dataWaznosci,
                          (d) => setInner(() => dataWaznosci = d), theme),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.themeColor, foregroundColor: Colors.white),
                    onPressed: () async {
                      if (tytulCtrl.text.trim().isEmpty) return;
                      Navigator.pop(context);
                      await ref.read(dokumentacjaProvider.notifier).addDokument(
                            DokumentModel(
                              id: 0,
                              budowaId: widget.budowaId,
                              tytul: tytulCtrl.text.trim(),
                              kategoria: kat,
                              numer: numerCtrl.text.trim().isEmpty
                                  ? null
                                  : numerCtrl.text.trim(),
                              opis: opisCtrl.text.trim().isEmpty
                                  ? null
                                  : opisCtrl.text.trim(),
                              dataWydania: dataWydania,
                              dataWaznosci: dataWaznosci,
                            ),
                          );
                    },
                    child: const Text('Dodaj'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tf(TextEditingController ctrl, String label, ThemeColors theme,
          {int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: TextStyle(color: theme.textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );

  Widget _datePicker(String label, DateTime? value, ValueChanged<DateTime> onChanged,
      ThemeColors theme) =>
      InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2010),
            lastDate: DateTime(2040),
          );
          if (d != null) onChanged(d);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: Text(
            value != null ? '${value.day}.${value.month}.${value.year}' : '—',
            style: TextStyle(color: theme.textColor, fontSize: 13),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(dokumentacjaProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      appBar: AppBar(
        backgroundColor: theme.userTile,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dokumentacja',
                style: TextStyle(color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(widget.budowaNazwa,
                style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 11)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              style: TextStyle(color: theme.textColor),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Szukaj dokumentu...',
                hintStyle: TextStyle(color: theme.textColor.withAlpha(100), fontSize: 13),
                prefixIcon: Icon(Icons.search, color: theme.textColor.withAlpha(100), size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          // Category filter
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _FilterChip('Wszystkie', _filterKat == null, theme,
                    () => setState(() => _filterKat = null)),
                ...KategoriaDokumentu.values.map((k) => _FilterChip(
                      '${k.emoji} ${k.label}',
                      _filterKat == k,
                      theme,
                      () => setState(() => _filterKat = _filterKat == k ? null : k),
                    )),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: async.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: theme.themeColor)),
              error: (e, _) => Center(
                  child: Text('Błąd: $e',
                      style: TextStyle(color: Colors.red.shade400))),
              data: (docs) {
                var filtered = docs;
                if (_filterKat != null) {
                  filtered = filtered.where((d) => d.kategoria == _filterKat).toList();
                }
                if (_search.isNotEmpty) {
                  filtered = filtered
                      .where((d) =>
                          d.tytul.toLowerCase().contains(_search) ||
                          (d.numer?.toLowerCase().contains(_search) ?? false) ||
                          (d.opis?.toLowerCase().contains(_search) ?? false))
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('Brak dokumentów',
                        style: TextStyle(color: theme.textColor.withAlpha(100))),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) =>
                      _DokumentTile(dokument: filtered[i], theme: theme),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj dokument'),
        onPressed: () => _showAddSheet(theme),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ThemeColors theme;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.selected, this.theme, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? theme.themeColor.withAlpha(40) : theme.userTile,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? theme.themeColor : theme.bordercolor.withAlpha(60)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: selected ? theme.themeColor : theme.textColor)),
        ),
      );
}

class _DokumentTile extends ConsumerWidget {
  final DokumentModel dokument;
  final ThemeColors theme;
  const _DokumentTile({required this.dokument, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertColor = dokument.przeterminowany
        ? const Color(0xFF7B1F1F)
        : dokument.wygasa
            ? const Color(0xFF7B5E00)
            : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: alertColor?.withAlpha(100) ?? theme.bordercolor.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(dokument.kategoria.emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dokument.tytul,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor)),
                if (dokument.numer != null)
                  Text(dokument.numer!,
                      style: TextStyle(
                          fontSize: 11, color: theme.textColor.withAlpha(120))),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(dokument.kategoria.label,
                        style: TextStyle(
                            fontSize: 10, color: theme.textColor.withAlpha(100))),
                    Text(' · ${dokument.dataWydaniaFmt}',
                        style: TextStyle(
                            fontSize: 10, color: theme.textColor.withAlpha(100))),
                    if (dokument.dataWaznosciFmt != null) ...[
                      Text(' · do: ',
                          style: TextStyle(
                              fontSize: 10, color: theme.textColor.withAlpha(100))),
                      Text(dokument.dataWaznosciFmt!,
                          style: TextStyle(
                              fontSize: 10,
                              color: alertColor ?? theme.textColor.withAlpha(100),
                              fontWeight: alertColor != null
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (dokument.fileUrl != null)
            Icon(Icons.attach_file, size: 16, color: theme.textColor.withAlpha(80)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => ref
                .read(dokumentacjaProvider.notifier)
                .deleteDokument(dokument.id),
            child: Icon(Icons.delete_outline,
                size: 18, color: theme.textColor.withAlpha(60)),
          ),
        ],
      ),
    );
  }
}
