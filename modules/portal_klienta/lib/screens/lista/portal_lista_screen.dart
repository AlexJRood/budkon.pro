import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/portal_model.dart';
import '../../data/providers/portal_provider.dart';
import '../../data/services/portal_api.dart';
import '../form/portal_form_screen.dart';

class PortalListaScreen extends ConsumerWidget {
  const PortalListaScreen({super.key, required this.budowaId, required this.budowaNazwa});

  final int budowaId;
  final String budowaNazwa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(portalListProvider(budowaId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Portale klienta', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            Text(budowaNazwa, style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(180))),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nowyPortal(context, ref),
        icon: const Icon(Icons.add_link),
        label: const Text('Nowy link'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (portale) => portale.isEmpty
            ? _PustaLista(onAdd: () => _nowyPortal(context, ref))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: portale.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _PortalKarta(
                  portal: portale[i],
                  budowaId: budowaId,
                ),
              ),
      ),
    );
  }

  void _nowyPortal(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<PortalKlientaModel>(
      context,
      MaterialPageRoute(
        builder: (_) => PortalFormScreen(budowaId: budowaId),
      ),
    );
    if (result != null) {
      ref.read(portalListProvider(budowaId).notifier).addLocal(result);
    }
  }
}

// ─── Karta portalu ──────────────────────────────────────────────────────────

class _PortalKarta extends ConsumerWidget {
  const _PortalKarta({required this.portal, required this.budowaId});

  final PortalKlientaModel portal;
  final int budowaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktywny = portal.aktywny && portal.jestWazny;
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: aktywny
                      ? const Color(0xFF26A69A).withAlpha(30)
                      : cs.surfaceContainerHighest,
                  child: Text(
                    portal.nazwaKlienta.isNotEmpty
                        ? portal.nazwaKlienta[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: aktywny ? const Color(0xFF26A69A) : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        portal.nazwaKlienta,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      if (portal.emailKlienta.isNotEmpty)
                        Text(portal.emailKlienta,
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                _StatusBadge(aktywny: aktywny),
              ],
            ),

            const SizedBox(height: 12),

            // Stats
            Row(
              children: [
                _Stat(icon: Icons.remove_red_eye_outlined,
                    label: '${portal.liczbaOdczytow} odczytów'),
                const SizedBox(width: 16),
                if (portal.ostatniOdczyt != null)
                  _Stat(icon: Icons.access_time,
                      label: _formatDate(portal.ostatniOdczyt!)),
                if (portal.wygasa != null)
                  _Stat(icon: Icons.event, label: 'Wygasa ${portal.wygasa}'),
              ],
            ),

            // Permissions chips
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                if (portal.pokazujFaktury) _Chip('Faktury'),
                if (portal.pokazujZdjecia) _Chip('Zdjęcia'),
                if (portal.pokazujHarmonogram) _Chip('Harmonogram'),
                if (portal.pokazujKosztorys) _Chip('Kosztorys'),
              ],
            ),

            const SizedBox(height: 14),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Kopiuj link'),
                    onPressed: portal.urlKlienta.isNotEmpty
                        ? () => _kopiuj(context, portal.urlKlienta)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (v) => _akcja(context, ref, v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'regeneruj', child: Text('Odnów token')),
                    if (aktywny)
                      const PopupMenuItem(
                        value: 'dezaktywuj',
                        child: Text('Dezaktywuj', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _kopiuj(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link skopiowany do schowka'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _akcja(BuildContext context, WidgetRef ref, String action) async {
    final api = ref.read(portalApiProvider);
    final notifier = ref.read(portalListProvider(budowaId).notifier);
    try {
      if (action == 'dezaktywuj') {
        await api.dezaktywuj(portal.id);
        notifier.updateLocal(portal.copyWith(aktywny: false));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Portal dezaktywowany')),
          );
        }
      } else if (action == 'regeneruj') {
        final updated = await api.regenerujToken(portal.id);
        notifier.updateLocal(updated);
        if (context.mounted) _kopiuj(context, updated.urlKlienta);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.aktywny});
  final bool aktywny;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: aktywny
            ? const Color(0xFF26A69A).withAlpha(25)
            : Colors.red.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        aktywny ? 'Aktywny' : 'Nieaktywny',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: aktywny ? const Color(0xFF26A69A) : Colors.red,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
}

// ─── Pusta lista ────────────────────────────────────────────────────────────

class _PustaLista extends StatelessWidget {
  const _PustaLista({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔗', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            const Text('Brak portali klienta',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Wygeneruj link i wyślij klientowi —\nbędzie widział postęp budowy bez logowania.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_link),
              label: const Text('Utwórz pierwszy link'),
            ),
          ],
        ),
      );
}
