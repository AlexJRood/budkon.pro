import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/kontakty_provider.dart';
import '../form/kontrahent_form_screen.dart';

class KontrahentProfilScreen extends ConsumerWidget {
  final int kontrahentId;
  const KontrahentProfilScreen({super.key, required this.kontrahentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(kontrahentDetailProvider(kontrahentId));

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Błąd: $e')),
      ),
      data: (k) => Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(k.displayName,
                    style: const TextStyle(fontSize: 16)),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.secondaryContainer,
                        Theme.of(context).colorScheme.surface,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          Theme.of(context).colorScheme.secondary,
                      child: Text(
                        k.inicjaly,
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSecondary,
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
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final wynik = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              KontrahentFormScreen(existing: k)),
                    );
                    if (wynik == true) {
                      ref.invalidate(kontrahentDetailProvider(kontrahentId));
                    }
                  },
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Branża
                    if (k.branza != null)
                      _InfoChip(
                        icon: Text(k.branza!.emoji,
                            style: const TextStyle(fontSize: 18)),
                        label: k.branza!.label,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                    const SizedBox(height: 20),

                    // Dane kontaktowe
                    _SectionHeader('Dane kontaktowe'),
                    const SizedBox(height: 8),

                    if (k.firma.isNotEmpty && k.pelneImie.isNotEmpty)
                      _InfoRow(Icons.person_outline, 'Imię i nazwisko',
                          k.pelneImie),
                    if (k.telefon.isNotEmpty)
                      _InfoRow(Icons.phone_outlined, 'Telefon', k.telefon,
                          onTap: () =>
                              _kopiuj(context, k.telefon, 'Telefon skopiowany')),
                    if (k.email.isNotEmpty)
                      _InfoRow(Icons.email_outlined, 'E-mail', k.email,
                          onTap: () =>
                              _kopiuj(context, k.email, 'E-mail skopiowany')),
                    if (k.nip.isNotEmpty)
                      _InfoRow(Icons.badge_outlined, 'NIP', k.nip,
                          onTap: () =>
                              _kopiuj(context, k.nip, 'NIP skopiowany')),
                    if (k.adres.isNotEmpty)
                      _InfoRow(Icons.location_on_outlined, 'Adres', k.adres),

                    if (k.uwagi.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionHeader('Uwagi'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(k.uwagi,
                            style: Theme.of(context).textTheme.bodyMedium),
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _InfoRow(this.icon, this.label, this.value, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: cs.outline, fontSize: 11)),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.copy_outlined, size: 14, color: cs.outline),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          icon,
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ]),
      );
}
