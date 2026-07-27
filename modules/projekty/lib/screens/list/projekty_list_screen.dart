import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/platform/navigation_service.dart';
import '../../data/providers/projekty_provider.dart';
import '../../data/models/projekt_budowlany_model.dart';
import '../../widgets/projekt_status_chip.dart';

class ProjektyListScreen extends ConsumerWidget {
  const ProjektyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(projektyListProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.budkon,
      childPc: Column(
        children: [
          _Header(theme: theme),
          Expanded(
            child: async.when(
              loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
              error: (e, _) =>
                  Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red))),
              data: (list) => list.isEmpty
                  ? _EmptyState(theme: theme)
                  : _ProjektyList(items: list),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.theme});
  final dynamic theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Text('Projekty budowlane',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor)),
          const Spacer(),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text('Wczytaj projekt'),
            onPressed: () => ref
                .read(navigationService)
                .pushNamedScreen('/projekty/upload'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.themeColor,
              foregroundColor: theme.buttonTextColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjektyList extends ConsumerWidget {
  const _ProjektyList({required this.items});
  final List<ProjektBudowlanyListModel> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _ProjektTile(item: items[i], theme: theme),
    );
  }
}

class _ProjektTile extends ConsumerWidget {
  const _ProjektTile({required this.item, required this.theme});
  final ProjektBudowlanyListModel item;
  final dynamic theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: theme.cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(navigationService).pushNamedScreen(
              '/projekty/${item.projektId}',
            ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ikona
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.themeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.home_work_outlined, color: theme.themeColor),
              ),
              const SizedBox(width: 14),
              // Dane
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.nazwa,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor)),
                        ),
                        if (item.walidacjaBledy > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${item.walidacjaBledy} błędów',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.red)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (item.inwestorNazwa != null) item.inwestorNazwa!,
                        if (item.miejscowosc != null) item.miejscowosc!,
                        if (item.gmina != null) 'gm. ${item.gmina}',
                      ].join(' • '),
                      style: TextStyle(fontSize: 12, color: theme.textColor.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (item.powierzchniaUzytkowa != null)
                          ProjektStatusChip(
                            icon: Icons.square_foot,
                            label: '${item.powierzchniaUzytkowa!.toStringAsFixed(1)} m² PUM',
                            theme: theme,
                          ),
                        if (item.liczbaKondygnacji != null)
                          ProjektStatusChip(
                            icon: Icons.layers_outlined,
                            label: '${item.liczbaKondygnacji} kond.',
                            theme: theme,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.textColor.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.theme});
  final dynamic theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_work_outlined, size: 64, color: theme.textColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('Brak projektów budowlanych',
              style: TextStyle(
                  fontSize: 15, color: theme.textColor.withOpacity(0.5))),
          const SizedBox(height: 8),
          Text('Wczytaj PDF z projektem architektonicznym, żeby zacząć',
              style: TextStyle(
                  fontSize: 12, color: theme.textColor.withOpacity(0.35))),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Wczytaj projekt PDF'),
            onPressed: () => ref
                .read(navigationService)
                .pushNamedScreen('/projekty/upload'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.themeColor,
              foregroundColor: theme.buttonTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
