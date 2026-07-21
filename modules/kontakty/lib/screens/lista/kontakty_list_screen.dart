import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import '../../data/models/kontakty_model.dart';
import '../../data/providers/kontakty_provider.dart';

class KontaktyListScreen extends ConsumerStatefulWidget {
  const KontaktyListScreen({super.key});

  @override
  ConsumerState<KontaktyListScreen> createState() => _KontaktyListScreenState();
}

class _KontaktyListScreenState extends ConsumerState<KontaktyListScreen> {
  late final _sideMenuKey = GlobalKey<SideMenuState>();
  final _searchCtrl = TextEditingController();
  Branza? _filterBranza;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(kontaktyProvider);

    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            style: TextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: 'Szukaj firmy, nazwiska, NIP…',
              hintStyle: TextStyle(color: theme.textColor.withAlpha(100)),
              prefixIcon: Icon(Icons.search, size: 20, color: theme.textColor.withAlpha(150)),
              isDense: true,
              filled: true,
              fillColor: theme.secondaryWidgetColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 18, color: theme.textColor.withAlpha(150)),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(kontaktyProvider.notifier).load();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (v) {
              setState(() {});
              ref.read(kontaktyProvider.notifier).load(
                    q: v,
                    branza: _filterBranza?.name,
                  );
            },
          ),
        ),

        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            children: [
              _BranzaChip(
                label: 'Wszyscy',
                selected: _filterBranza == null,
                theme: theme,
                onTap: () {
                  setState(() => _filterBranza = null);
                  ref.read(kontaktyProvider.notifier).load(q: _searchCtrl.text);
                },
              ),
              ...Branza.values.map((b) => _BranzaChip(
                    label: '${b.emoji} ${b.label}',
                    selected: _filterBranza == b,
                    theme: theme,
                    onTap: () {
                      setState(() => _filterBranza = b);
                      ref.read(kontaktyProvider.notifier).load(
                            q: _searchCtrl.text,
                            branza: b.name,
                          );
                    },
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: Builder(builder: (_) {
            if (state.loading && state.lista.isEmpty) {
              return Center(child: CircularProgressIndicator(color: theme.themeColor));
            }
            if (state.error != null && state.lista.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.error!, style: TextStyle(color: theme.textColor)),
                    TextButton(
                      onPressed: () => ref.read(kontaktyProvider.notifier).load(),
                      child: Text('Spróbuj ponownie',
                          style: TextStyle(color: theme.themeColor)),
                    ),
                  ],
                ),
              );
            }
            if (state.lista.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.contacts_outlined,
                        size: 56, color: theme.textColor.withAlpha(80)),
                    const SizedBox(height: 12),
                    Text('Brak kontaktów', style: TextStyle(color: theme.textColor)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: theme.themeColor,
              onRefresh: () => ref.read(kontaktyProvider.notifier).load(
                    q: _searchCtrl.text,
                    branza: _filterBranza?.name,
                  ),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: state.lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) =>
                    _KontrahentTile(kontrahent: state.lista[i], theme: theme),
              ),
            );
          }),
        ),
      ],
    );

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      childPc: Stack(
        fit: StackFit.expand,
        children: [
          content,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              backgroundColor: theme.themeColor,
              icon: Icon(Icons.person_add_outlined, color: theme.buttonTextColor),
              label: Text('Nowy kontakt', style: TextStyle(color: theme.buttonTextColor)),
              onPressed: () => ref.read(navigationService).pushNamedScreen('/kontakty/nowy'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranzaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeColors theme;
  const _BranzaChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: selected,
          selectedColor: theme.themeColor.withAlpha(40),
          checkmarkColor: theme.themeColor,
          backgroundColor: theme.userTile,
          side: BorderSide(
              color: selected ? theme.themeColor : theme.bordercolor.withAlpha(60)),
          onSelected: (_) => onTap(),
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      );
}

class _KontrahentTile extends ConsumerWidget {
  final KontrahentListItem kontrahent;
  final ThemeColors theme;
  const _KontrahentTile({required this.kontrahent, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branza = kontrahent.branza;

    return Container(
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(navigationService).pushNamedScreen('/kontakty/${kontrahent.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.themeColor.withAlpha(40),
                child: Text(
                  kontrahent.inicjaly,
                  style: TextStyle(
                      color: theme.themeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kontrahent.displayName,
                      style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    if (kontrahent.pelneImie.isNotEmpty &&
                        kontrahent.firma.isNotEmpty)
                      Text(kontrahent.pelneImie,
                          style: TextStyle(
                              color: theme.textColor.withAlpha(150),
                              fontSize: 12)),
                    if (branza != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          '${branza.emoji} ${branza.label}',
                          style: TextStyle(
                              color: theme.textColor.withAlpha(130),
                              fontSize: 11),
                        ),
                      ),
                    if (kontrahent.telefon.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(children: [
                          Icon(Icons.phone_outlined,
                              size: 11,
                              color: theme.textColor.withAlpha(130)),
                          const SizedBox(width: 4),
                          Text(kontrahent.telefon,
                              style: TextStyle(
                                  color: theme.textColor.withAlpha(130),
                                  fontSize: 11)),
                        ]),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.textColor.withAlpha(120)),
            ],
          ),
        ),
      ),
    );
  }
}
