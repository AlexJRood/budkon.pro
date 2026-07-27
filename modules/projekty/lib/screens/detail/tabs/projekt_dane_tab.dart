import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../../data/models/projekt_budowlany_model.dart';
import '../../../data/providers/projekty_provider.dart';
import '../../../data/services/projekty_api.dart';

class ProjektDaneTab extends ConsumerWidget {
  const ProjektDaneTab({super.key, required this.projekt});
  final ProjektBudowlanyDetailModel projekt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectionCard(
          theme: theme,
          title: 'Ogólne',
          icon: Icons.info_outline,
          rows: [
            if (projekt.nrProjektu != null) _Row('Nr projektu', projekt.nrProjektu!),
            _Row('Typ', projekt.projektTypowy ? 'Projekt typowy' : 'Projekt indywidualny'),
            if (projekt.status != null) _Row('Status', projekt.status!),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          theme: theme,
          title: 'Inwestor',
          icon: Icons.person_outline,
          rows: [
            if (projekt.inwestorNazwa != null) _Row('Nazwa', projekt.inwestorNazwa!),
            if (projekt.inwestorAdres != null) _Row('Adres', projekt.inwestorAdres!),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          theme: theme,
          title: 'Lokalizacja',
          icon: Icons.location_on_outlined,
          rows: [
            if (projekt.dzialka != null) _Row('Działka nr', projekt.dzialka!),
            if (projekt.miejscowosc != null) _Row('Miejscowość', projekt.miejscowosc!),
            if (projekt.gmina != null) _Row('Gmina', projekt.gmina!),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          theme: theme,
          title: 'Parametry budynku',
          icon: Icons.architecture,
          rows: [
            if (projekt.powierzchniaUzytkowa != null)
              _Row('Pow. użytkowa', '${projekt.powierzchniaUzytkowa!.toStringAsFixed(2)} m²'),
            if (projekt.powierzchniaZabudowy != null)
              _Row('Pow. zabudowy', '${projekt.powierzchniaZabudowy!.toStringAsFixed(2)} m²'),
            if (projekt.kubatura != null)
              _Row('Kubatura', '${projekt.kubatura!.toStringAsFixed(1)} m³'),
            if (projekt.liczbaKondygnacji != null)
              _Row('Kondygnacje', '${projekt.liczbaKondygnacji}'),
          ],
        ),
        if (projekt.walidacje.isNotEmpty) ...[
          const SizedBox(height: 16),
          _WalidacjeSection(walidacje: projekt.walidacje, theme: theme),
        ],
        const SizedBox(height: 16),
        // Sync button
        Consumer(
          builder: (context, ref, _) => OutlinedButton.icon(
            icon: const Icon(Icons.sync),
            label: const Text('Synchronizuj z bazą danych'),
            onPressed: () async {
              try {
                await ref.read(projektyApiProvider).syncDb(projekt.projektId);
                // ignore: unused_result
                ref.refresh(projektDetailProvider(projekt.projektId));
              } catch (_) {}
            },
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.theme,
    required this.title,
    required this.icon,
    required this.rows,
  });

  final dynamic theme;
  final String title;
  final IconData icon;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      color: theme.cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: theme.themeColor),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.themeColor)),
            ]),
            const SizedBox(height: 12),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(r.label,
                            style: TextStyle(
                                fontSize: 13,
                                color: theme.textColor.withOpacity(0.6))),
                      ),
                      Expanded(
                        child: Text(r.value,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: theme.textColor)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;
  const _Row(this.label, this.value);
}

class _WalidacjeSection extends StatelessWidget {
  const _WalidacjeSection({required this.walidacje, required this.theme});
  final List<WalidacjaModel> walidacje;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.warning_amber_outlined, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Text('Walidacje',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red)),
        ]),
        const SizedBox(height: 8),
        ...walidacje.map((w) => _WalidacjaRow(w: w, theme: theme)),
      ],
    );
  }
}

class _WalidacjaRow extends StatelessWidget {
  const _WalidacjaRow({required this.w, required this.theme});
  final WalidacjaModel w;
  final dynamic theme;

  Color get _color {
    switch (w.priorytet) {
      case 'blad':
        return Colors.red;
      case 'ostrzezenie':
        return Colors.orange;
      default:
        return theme.themeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            w.priorytet == 'blad' ? Icons.error_outline : Icons.warning_amber_outlined,
            size: 16,
            color: _color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.opis,
                    style: TextStyle(fontSize: 12, color: theme.textColor)),
                if (w.naprawiono)
                  Text('Naprawiono automatycznie',
                      style: TextStyle(
                          fontSize: 11, color: Colors.green.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
