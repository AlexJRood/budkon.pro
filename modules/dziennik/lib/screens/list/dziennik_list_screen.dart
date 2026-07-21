import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:intl/intl.dart';
import '../../data/models/dziennik_model.dart';
import '../../data/providers/dziennik_provider.dart';
import '../../widgets/pogoda_badge.dart';

class DziennikListScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;

  const DziennikListScreen({
    super.key,
    required this.budowaId,
    required this.budowaNazwa,
  });

  @override
  ConsumerState<DziennikListScreen> createState() => _DziennikListScreenState();
}

class _DziennikListScreenState extends ConsumerState<DziennikListScreen> {
  static final _fmt = DateFormat('dd.MM.yyyy', 'pl_PL');

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(dziennikListProvider(widget.budowaId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: theme.textColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dziennik budowy', style: TextStyle(color: theme.textColor)),
            Text(
              widget.budowaNazwa,
              style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(160)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.map_outlined, color: theme.textColor),
            tooltip: 'Mapa budowy',
            onPressed: () => Navigator.pushNamed(
              context,
              '/dziennik/mapa',
              arguments: {'budowaId': widget.budowaId, 'budowaNazwa': widget.budowaNazwa},
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.textColor),
            onPressed: () =>
                ref.read(dziennikListProvider(widget.budowaId).notifier).load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.themeColor,
        icon: Icon(Icons.add, color: theme.buttonTextColor),
        label: Text('Nowy wpis', style: TextStyle(color: theme.buttonTextColor)),
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/dziennik/form',
            arguments: {
              'budowaId': widget.budowaId,
              'budowaNazwa': widget.budowaNazwa,
            },
          );
          if (result == true) {
            ref.read(dziennikListProvider(widget.budowaId).notifier).load();
          }
        },
      ),
      body: Builder(builder: (_) {
        if (state.loading && state.wpisy.isEmpty) {
          return Center(child: CircularProgressIndicator(color: theme.themeColor));
        }
        if (state.error != null && state.wpisy.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(state.error!, style: TextStyle(color: theme.textColor)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref
                      .read(dziennikListProvider(widget.budowaId).notifier)
                      .load(),
                  child: const Text('Spróbuj ponownie'),
                ),
              ],
            ),
          );
        }
        if (state.wpisy.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.book_outlined, size: 64, color: theme.textColor.withAlpha(80)),
                const SizedBox(height: 16),
                Text(
                  'Brak wpisów',
                  style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dodaj pierwszy wpis do dziennika budowy',
                  style: TextStyle(color: theme.textColor.withAlpha(150)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(dziennikListProvider(widget.budowaId).notifier).load(),
          color: theme.themeColor,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: state.wpisy.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _WpisCard(
              wpis: state.wpisy[i],
              budowaId: widget.budowaId,
              budowaNazwa: widget.budowaNazwa,
              theme: theme,
            ),
          ),
        );
      }),
    );
  }
}

class _WpisCard extends StatelessWidget {
  final WpisListItem wpis;
  final int budowaId;
  final String budowaNazwa;
  final ThemeColors theme;

  const _WpisCard({
    required this.wpis,
    required this.budowaId,
    required this.budowaNazwa,
    required this.theme,
  });

  static final _fmt = DateFormat('dd.MM.yyyy (EEEE)', 'pl_PL');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          '/dziennik/detail',
          arguments: {
            'wpisId': wpis.id,
            'budowaId': budowaId,
            'budowaNazwa': budowaNazwa,
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _fmt.format(wpis.data),
                      style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  PogodaBadge(pogoda: wpis.pogoda, temperatura: wpis.temperatura),
                ],
              ),
              if (wpis.etapNazwa != null) ...[
                const SizedBox(height: 6),
                _Chip(
                  icon: Icons.construction,
                  label: wpis.etapNazwa!,
                  color: theme.themeColor.withAlpha(30),
                  textColor: theme.themeColor,
                ),
              ],
              if (wpis.opis.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  wpis.opis,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.textColor.withAlpha(180), fontSize: 13),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _Chip(
                    icon: Icons.people_outline,
                    label: '${wpis.liczbaPracownikow} os.',
                    color: theme.secondaryWidgetColor,
                    textColor: theme.textColor,
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    icon: Icons.schedule,
                    label: '${wpis.godzinyPracy.toStringAsFixed(0)} h',
                    color: theme.secondaryWidgetColor,
                    textColor: theme.textColor,
                  ),
                  if (wpis.zdjeciaCount > 0) ...[
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.photo_library_outlined,
                      label: '${wpis.zdjeciaCount}',
                      color: theme.secondaryWidgetColor,
                      textColor: theme.textColor,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  const _Chip({required this.icon, required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor.withAlpha(180)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: textColor)),
        ],
      ),
    );
  }
}
