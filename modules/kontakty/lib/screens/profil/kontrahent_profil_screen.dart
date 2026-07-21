import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import '../../data/providers/kontakty_provider.dart';

class KontrahentProfilScreen extends ConsumerWidget {
  final int kontrahentId;
  const KontrahentProfilScreen({super.key, required this.kontrahentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(kontrahentDetailProvider(kontrahentId));

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.budkon,
      childPc: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) => Center(child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
        data: (k) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(color: theme.textColor),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(k.displayName,
                    style: TextStyle(fontSize: 16, color: theme.textColor)),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.themeColor.withAlpha(60),
                        theme.sidebar,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.themeColor.withAlpha(50),
                      child: Text(
                        k.inicjaly,
                        style: TextStyle(
                          color: theme.themeColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: theme.textColor),
                  onPressed: () => ref.read(navigationService).pushNamedScreen(
                    '/kontakty/$kontrahentId/edit',
                    data: {'existing': k},
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (k.branza != null)
                      _InfoChip(
                        icon: Text(k.branza!.emoji,
                            style: const TextStyle(fontSize: 18)),
                        label: k.branza!.label,
                        theme: theme,
                      ),
                    const SizedBox(height: 20),

                    _SectionHeader('Dane kontaktowe', theme: theme),
                    const SizedBox(height: 8),

                    if (k.firma.isNotEmpty && k.pelneImie.isNotEmpty)
                      _InfoRow(Icons.person_outline, 'Imię i nazwisko',
                          k.pelneImie, theme: theme),
                    if (k.telefon.isNotEmpty)
                      _InfoRow(Icons.phone_outlined, 'Telefon', k.telefon,
                          theme: theme,
                          onTap: () =>
                              _kopiuj(context, k.telefon, 'Telefon skopiowany')),
                    if (k.email.isNotEmpty)
                      _InfoRow(Icons.email_outlined, 'E-mail', k.email,
                          theme: theme,
                          onTap: () =>
                              _kopiuj(context, k.email, 'E-mail skopiowany')),
                    if (k.nip.isNotEmpty)
                      _InfoRow(Icons.badge_outlined, 'NIP', k.nip,
                          theme: theme,
                          onTap: () =>
                              _kopiuj(context, k.nip, 'NIP skopiowany')),
                    if (k.adres.isNotEmpty)
                      _InfoRow(Icons.location_on_outlined, 'Adres', k.adres,
                          theme: theme),

                    if (k.uwagi.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionHeader('Uwagi', theme: theme),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.secondaryWidgetColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: theme.bordercolor.withAlpha(40)),
                        ),
                        child: Text(k.uwagi,
                            style: TextStyle(color: theme.textColor)),
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _kopiuj(BuildContext context, String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final ThemeColors theme;
  const _SectionHeader(this.label, {required this.theme});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w700,
            fontSize: 14),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeColors theme;
  final VoidCallback? onTap;
  const _InfoRow(this.icon, this.label, this.value,
      {required this.theme, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(icon, size: 18, color: theme.themeColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: theme.textColor.withAlpha(130), fontSize: 11)),
                Text(value,
                    style: TextStyle(color: theme.textColor, fontSize: 14)),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.copy_outlined,
                size: 14, color: theme.textColor.withAlpha(130)),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final Widget icon;
  final String label;
  final ThemeColors theme;
  const _InfoChip(
      {required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: theme.themeColor.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.themeColor.withAlpha(60)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          icon,
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: theme.themeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ]),
      );
}
