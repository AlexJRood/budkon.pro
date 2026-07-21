import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import '../../data/models/portal_model.dart';
import '../../data/providers/portal_provider.dart';
import '../../data/services/portal_api.dart';

class PortalListaScreen extends ConsumerWidget {
  const PortalListaScreen({super.key, required this.budowaId, required this.budowaNazwa});

  final int budowaId;
  final String budowaNazwa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(portalListProvider(budowaId));

    final body = state.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) => Center(child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
      data: (portale) => portale.isEmpty
          ? _PustaLista(
              onAdd: () => ref.read(navigationService).pushNamedScreen('/budowy/$budowaId/portale/nowy'),
              theme: theme,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: portale.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _PortalKarta(
                portal: portale[i],
                budowaId: budowaId,
                theme: theme,
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
              icon: Icon(Icons.add_link, color: theme.buttonTextColor),
              label: Text('Nowy link', style: TextStyle(color: theme.buttonTextColor)),
              onPressed: () => ref.read(navigationService).pushNamedScreen('/budowy/$budowaId/portale/nowy'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalKarta extends StatelessWidget {
  const _PortalKarta({required this.portal, required this.budowaId, required this.theme});

  final PortalKlientaModel portal;
  final int budowaId;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    final aktywny = portal.aktywny && portal.jestWazny;

    return Card(
      color: theme.userTile,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.bordercolor.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: aktywny
                      ? const Color(0xFF26A69A).withAlpha(30)
                      : theme.secondaryWidgetColor,
                  child: Text(
                    portal.nazwaKlienta.isNotEmpty ? portal.nazwaKlienta[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: aktywny ? const Color(0xFF26A69A) : theme.textColor.withAlpha(150),
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
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15, color: theme.textColor),
                      ),
                      if (portal.emailKlienta.isNotEmpty)
                        Text(portal.emailKlienta,
                            style:
                                TextStyle(fontSize: 12, color: theme.textColor.withAlpha(150))),
                    ],
                  ),
                ),
                _StatusBadge(aktywny: aktywny),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _Stat(
                    icon: Icons.remove_red_eye_outlined,
                    label: '${portal.liczbaOdczytow} odczytów',
                    theme: theme),
                const SizedBox(width: 16),
                if (portal.ostatniOdczyt != null)
                  _Stat(
                      icon: Icons.access_time,
                      label: _formatDate(portal.ostatniOdczyt!),
                      theme: theme),
                if (portal.wygasa != null)
                  _Stat(icon: Icons.event, label: 'Wygasa ${portal.wygasa}', theme: theme),
              ],
            ),

            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                if (portal.pokazujFaktury) _Chip('Faktury', theme),
                if (portal.pokazujZdjecia) _Chip('Zdjęcia', theme),
                if (portal.pokazujHarmonogram) _Chip('Harmonogram', theme),
                if (portal.pokazujKosztorys) _Chip('Kosztorys', theme),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Kopiuj link'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.themeColor,
                      side: BorderSide(color: theme.bordercolor.withAlpha(80)),
                    ),
                    onPressed: portal.urlKlienta.isNotEmpty
                        ? () => _kopiuj(context, portal.urlKlienta)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Consumer(
                  builder: (context, ref, _) => PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: theme.textColor),
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
      const SnackBar(
          content: Text('Link skopiowany do schowka'),
          duration: Duration(seconds: 2)),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
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
        color: aktywny ? const Color(0xFF26A69A).withAlpha(25) : Colors.red.withAlpha(25),
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
  const _Stat({required this.icon, required this.label, required this.theme});
  final IconData icon;
  final String label;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.textColor.withAlpha(120)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(150))),
        ],
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.theme);
  final String label;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label,
            style: TextStyle(fontSize: 11, color: theme.textColor)),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        backgroundColor: theme.secondaryWidgetColor,
        side: BorderSide(color: theme.bordercolor.withAlpha(60)),
      );
}

class _PustaLista extends StatelessWidget {
  const _PustaLista({required this.onAdd, required this.theme});
  final VoidCallback onAdd;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔗', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text('Brak portali klienta',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: theme.textColor)),
            const SizedBox(height: 8),
            Text(
              'Wygeneruj link i wyślij klientowi —\nbędzie widział postęp budowy bez logowania.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textColor.withAlpha(150)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_link),
              label: const Text('Utwórz pierwszy link'),
              style: FilledButton.styleFrom(
                  backgroundColor: theme.themeColor, foregroundColor: theme.buttonTextColor),
            ),
          ],
        ),
      );
}
