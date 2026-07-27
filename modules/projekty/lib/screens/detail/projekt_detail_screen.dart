import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import '../../data/models/projekt_budowlany_model.dart';
import '../../data/providers/projekty_provider.dart';
import 'tabs/projekt_dane_tab.dart';
import 'tabs/projekt_pomieszczenia_tab.dart';
import 'tabs/projekt_kosztorys_tab.dart';
import 'tabs/projekt_rzut_tab.dart';

class ProjektDetailScreen extends ConsumerStatefulWidget {
  const ProjektDetailScreen({super.key, required this.projektId});

  final String projektId;

  @override
  ConsumerState<ProjektDetailScreen> createState() => _ProjektDetailScreenState();
}

class _ProjektDetailScreenState extends ConsumerState<ProjektDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(projektDetailProvider(widget.projektId));

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.budkon,
      childPc: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Błąd ładowania projektu', style: TextStyle(color: theme.textColor)),
              const SizedBox(height: 6),
              Text(e.toString(),
                  style: TextStyle(fontSize: 12, color: theme.textColor.withOpacity(0.6))),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    ref.refresh(projektDetailProvider(widget.projektId)),
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
        data: (projekt) => _ProjektBody(
          projekt: projekt,
          tabController: _tab,
          theme: theme,
        ),
      ),
    );
  }
}

class _ProjektBody extends StatelessWidget {
  const _ProjektBody({
    required this.projekt,
    required this.tabController,
    required this.theme,
  });

  final ProjektBudowlanyDetailModel projekt;
  final TabController tabController;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nagłówek z nazwą
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  BackButton(color: theme.textColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      projekt.nazwa,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: theme.textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (projekt.walidacjaBledy > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${projekt.walidacjaBledy} błędów',
                        style: TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    ),
                ],
              ),
              if (projekt.inwestorNazwa != null)
                Padding(
                  padding: const EdgeInsets.only(left: 40, bottom: 4),
                  child: Text(
                    [
                      projekt.inwestorNazwa!,
                      if (projekt.miejscowosc != null) projekt.miejscowosc!,
                      if (projekt.gmina != null) 'gm. ${projekt.gmina}',
                    ].join(' • '),
                    style: TextStyle(
                        fontSize: 12, color: theme.textColor.withOpacity(0.6)),
                  ),
                ),
            ],
          ),
        ),
        // Tabs
        TabBar(
          controller: tabController,
          labelColor: theme.themeColor,
          unselectedLabelColor: theme.textColor.withOpacity(0.5),
          indicatorColor: theme.themeColor,
          tabs: const [
            Tab(text: 'Dane'),
            Tab(text: 'Pomieszczenia'),
            Tab(text: 'Kosztorys'),
            Tab(text: 'Rzut 2D'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              ProjektDaneTab(projekt: projekt),
              ProjektPomieszczeniaTab(projekt: projekt),
              ProjektKosztorysTab(projektId: projekt.projektId),
              ProjektRzutTab(projekt: projekt),
            ],
          ),
        ),
      ],
    );
  }
}
