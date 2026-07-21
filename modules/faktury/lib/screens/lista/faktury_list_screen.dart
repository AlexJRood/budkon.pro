import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:intl/intl.dart';
import '../../data/models/faktury_model.dart';
import '../../data/providers/faktury_provider.dart';

class FakturyListScreen extends ConsumerStatefulWidget {
  final int? budowaId;
  const FakturyListScreen({super.key, this.budowaId});

  @override
  ConsumerState<FakturyListScreen> createState() => _FakturyListScreenState();
}

class _FakturyListScreenState extends ConsumerState<FakturyListScreen> {
  late final _sideMenuKey = GlobalKey<SideMenuState>();
  static final _dateFmt = DateFormat('dd.MM.yyyy', 'pl_PL');
  StatusFaktury? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(fakturyProvider);
    final lista = _filterStatus == null
        ? state.lista
        : state.lista.where((f) => f.status == _filterStatus).toList();

    final content = Column(
      children: [
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            children: [
              _StatusChip(
                label: 'Wszystkie',
                color: theme.textColor.withAlpha(150),
                selected: _filterStatus == null,
                onTap: () => setState(() => _filterStatus = null),
                theme: theme,
              ),
              ...StatusFaktury.values.map((s) => _StatusChip(
                    label: s.label,
                    color: s.color,
                    selected: _filterStatus == s,
                    onTap: () => setState(() => _filterStatus = s),
                    theme: theme,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: Builder(builder: (_) {
            if (state.loading && lista.isEmpty) {
              return Center(child: CircularProgressIndicator(color: theme.themeColor));
            }
            if (lista.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 56, color: theme.textColor.withAlpha(80)),
                    const SizedBox(height: 12),
                    Text('Brak faktur', style: TextStyle(color: theme.textColor)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              color: theme.themeColor,
              onRefresh: () =>
                  ref.read(fakturyProvider.notifier).load(budowaId: widget.budowaId),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) => _FakturaTile(
                    faktura: lista[i], dateFmt: _dateFmt, theme: theme),
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
              icon: Icon(Icons.add, color: theme.buttonTextColor),
              label: Text('Nowa faktura', style: TextStyle(color: theme.buttonTextColor)),
              onPressed: () => ref.read(navigationService).pushNamedScreen(
                '/faktury/nowa',
                data: {'budowaId': widget.budowaId},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final ThemeColors theme;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label, style: TextStyle(fontSize: 12, color: selected ? color : theme.textColor)),
          selected: selected,
          selectedColor: color.withAlpha(40),
          checkmarkColor: color,
          onSelected: (_) => onTap(),
          showCheckmark: selected,
          backgroundColor: theme.userTile,
          side: BorderSide(color: selected ? color : theme.bordercolor.withAlpha(60)),
        ),
      );
}

class _FakturaTile extends ConsumerWidget {
  final FakturaListItem faktura;
  final DateFormat dateFmt;
  final ThemeColors theme;
  const _FakturaTile({required this.faktura, required this.dateFmt, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = faktura.jestPrzeterminowana
        ? const Color(0xFFEF5350)
        : faktura.status.color;

    return Container(
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: faktura.jestPrzeterminowana
              ? const Color(0xFFEF5350).withAlpha(120)
              : theme.bordercolor.withAlpha(60),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(navigationService).pushNamedScreen('/faktury/${faktura.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        faktura.numerDisplay,
                        style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          faktura.jestPrzeterminowana
                              ? 'PRZETERMINOWANA'
                              : faktura.status.label.toUpperCase(),
                          style: TextStyle(
                              color: statusColor, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 3),
                    Text(faktura.nabywcaNazwa,
                        style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text(
                        'Termin: ${dateFmt.format(faktura.terminPlatnosci)}',
                        style: TextStyle(
                          color: faktura.jestPrzeterminowana
                              ? const Color(0xFFEF5350)
                              : theme.textColor.withAlpha(150),
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${faktura.wartoscBrutto.toStringAsFixed(2)} zł',
                        style: TextStyle(
                          color: theme.themeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: theme.textColor.withAlpha(120)),
            ],
          ),
        ),
      ),
    );
  }
}
