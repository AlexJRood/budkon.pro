import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import '../../data/models/pracownicy_model.dart';
import '../../data/providers/pracownicy_provider.dart';
import '../../widgets/skill_matrix.dart';

class PracownicyListScreen extends ConsumerStatefulWidget {
  final int? budowaId;
  final String budowaNazwa;

  const PracownicyListScreen({
    super.key,
    this.budowaId,
    this.budowaNazwa = 'Wszyscy',
  });

  @override
  ConsumerState<PracownicyListScreen> createState() =>
      _PracownicyListScreenState();
}

class _PracownicyListScreenState extends ConsumerState<PracownicyListScreen> {
  late final _sideMenuKey = GlobalKey<SideMenuState>();
  Specjalizacja? _filterSpec;

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(pracownicyProvider);
    final lista = _filterSpec == null
        ? state.lista
        : state.lista
            .where((p) => p.specjalizacje
                .any((s) => s['specjalizacja'] == _filterSpec!.value))
            .toList();

    final content = Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _SpecFilter(
                label: 'Wszyscy',
                selected: _filterSpec == null,
                theme: theme,
                onTap: () => setState(() => _filterSpec = null),
              ),
              ...Specjalizacja.values.map(
                (s) => _SpecFilter(
                  label: '${s.emoji} ${s.label.split('/').first}',
                  selected: _filterSpec == s,
                  theme: theme,
                  onTap: () => setState(() => _filterSpec = s),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Builder(builder: (_) {
            if (state.loading && lista.isEmpty) {
              return Center(
                  child: CircularProgressIndicator(color: theme.themeColor));
            }
            if (state.error != null && lista.isEmpty) {
              return Center(
                  child: Text(state.error!,
                      style: TextStyle(color: theme.textColor)));
            }
            if (lista.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_outlined,
                        size: 56,
                        color: theme.textColor.withAlpha(80)),
                    const SizedBox(height: 16),
                    Text('Brak pracowników',
                        style: TextStyle(color: theme.textColor)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: theme.themeColor,
              onRefresh: () =>
                  ref.read(pracownicyProvider.notifier).load(),
              child: ListView.separated(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: lista.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (ctx, i) =>
                    _PracownikCard(pracownik: lista[i], theme: theme),
              ),
            );
          }),
        ),
      ],
    );

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      verticalButtonsPc: IconButton(
        icon: Icon(Icons.refresh, color: theme.textColor),
        onPressed: () => ref.read(pracownicyProvider.notifier).load(),
      ),
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
              label: Text('Dodaj pracownika',
                  style: TextStyle(color: theme.buttonTextColor)),
              onPressed: () => ref.read(navigationService).pushNamedScreen('/pracownicy/nowy'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeColors theme;
  const _SpecFilter(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          selectedColor: theme.themeColor.withAlpha(40),
          checkmarkColor: theme.themeColor,
          backgroundColor: theme.userTile,
          side: BorderSide(
              color: selected
                  ? theme.themeColor
                  : theme.bordercolor.withAlpha(60)),
          onSelected: (_) => onTap(),
          showCheckmark: false,
        ),
      );
}

class _PracownikCard extends ConsumerWidget {
  final PracownikListItem pracownik;
  final ThemeColors theme;
  const _PracownikCard({required this.pracownik, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(navigationService).pushNamedScreen('/pracownicy/${pracownik.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.themeColor.withAlpha(40),
                child: Text(
                  pracownik.inicjaly,
                  style: TextStyle(
                    color: theme.themeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          pracownik.pelneImie,
                          style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ),
                      if (pracownik.aktualnaStawka != null)
                        Text(
                          '${pracownik.aktualnaStawka!.toStringAsFixed(0)} PLN/h',
                          style: TextStyle(
                            color: theme.themeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                    ]),

                    const SizedBox(height: 4),

                    Row(children: [
                      Text(
                        pracownik.glownaSpecjalizacja.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        pracownik.glownaSpecjalizacja.label,
                        style: TextStyle(
                            color: theme.textColor.withAlpha(150),
                            fontSize: 12),
                      ),
                    ]),

                    if (pracownik.specjalizacje.length > 1) ...[
                      const SizedBox(height: 6),
                      SkillChips(
                          specjalizacje: pracownik.specjalizacje,
                          max: 4),
                    ],

                    if (pracownik.telefon.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.phone_outlined,
                            size: 12,
                            color: theme.textColor.withAlpha(130)),
                        const SizedBox(width: 4),
                        Text(pracownik.telefon,
                            style: TextStyle(
                                color: theme.textColor.withAlpha(130),
                                fontSize: 11)),
                      ]),
                    ],
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
