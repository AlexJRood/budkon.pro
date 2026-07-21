import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import '../../data/models/oferty_model.dart';
import '../../data/providers/oferty_provider.dart';

class OfertyListScreen extends ConsumerStatefulWidget {
  final int? budowaId;
  final String budowaNazwa;

  const OfertyListScreen({super.key, this.budowaId, this.budowaNazwa = 'Wszystkie oferty'});

  @override
  ConsumerState<OfertyListScreen> createState() => _OfertyListScreenState();
}

class _OfertyListScreenState extends ConsumerState<OfertyListScreen> with SingleTickerProviderStateMixin {
  late final _sideMenuKey = GlobalKey<SideMenuState>();
  late final TabController _tabs;
  static const _statusTabs = [null, StatusOferty.roboczy, StatusOferty.wyslana, StatusOferty.zaakceptowana, StatusOferty.odrzucona];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statusTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(ofertyProvider(widget.budowaId));

    final content = Column(
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: theme.themeColor,
          unselectedLabelColor: theme.textColor.withAlpha(150),
          indicatorColor: theme.themeColor,
          tabs: const [Tab(text: 'Wszystkie'), Tab(text: 'Robocze'), Tab(text: 'Wysłane'), Tab(text: 'Zaakceptowane'), Tab(text: 'Odrzucone')],
        ),
        Expanded(
          child: state.loading && state.lista.isEmpty
              ? Center(child: CircularProgressIndicator(color: theme.themeColor))
              : TabBarView(
                  controller: _tabs,
                  children: _statusTabs.map((filterStatus) {
                    final filtered = filterStatus == null ? state.lista : state.lista.where((o) => o.status == filterStatus).toList();
                    return _OfertyTabView(oferty: filtered, budowaId: widget.budowaId, error: state.error, theme: theme);
                  }).toList(),
                ),
        ),
      ],
    );

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      verticalButtonsPc: IconButton(
        icon: Icon(Icons.refresh, color: theme.textColor),
        onPressed: () => ref.read(ofertyProvider(widget.budowaId).notifier).load(),
      ),
      childPc: Stack(
        fit: StackFit.expand,
        children: [
          content,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => ref.read(navigationService).pushNamedScreen(
                '/oferty/new',
                data: {'budowaId': widget.budowaId, 'budowaNazwa': widget.budowaNazwa},
              ),
              backgroundColor: theme.themeColor,
              icon: Icon(Icons.add, color: theme.buttonTextColor),
              label: Text('Nowa oferta', style: TextStyle(color: theme.buttonTextColor)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfertyTabView extends ConsumerWidget {
  final List<OfertyListItem> oferty;
  final int? budowaId;
  final String? error;
  final ThemeColors theme;

  const _OfertyTabView({required this.oferty, required this.budowaId, required this.theme, this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (error != null && oferty.isEmpty) {
      return Center(child: Text(error!, style: TextStyle(color: theme.textColor)));
    }
    if (oferty.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.description_outlined, size: 56, color: theme.textColor.withAlpha(80)),
          const SizedBox(height: 16),
          Text('Brak ofert', style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 14)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(ofertyProvider(budowaId).notifier).load(),
      color: theme.themeColor,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: oferty.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => _OfertyCard(oferta: oferty[i], theme: theme),
      ),
    );
  }
}

class _OfertyCard extends ConsumerWidget {
  final OfertyListItem oferta;
  final ThemeColors theme;
  const _OfertyCard({required this.oferta, required this.theme});

  Color _statusColor(StatusOferty s) => switch (s) {
    StatusOferty.roboczy => theme.textColor.withAlpha(100),
    StatusOferty.wyslana => const Color(0xFF2196F3),
    StatusOferty.zaakceptowana => const Color(0xFF4CAF50),
    StatusOferty.odrzucona => Colors.red,
    StatusOferty.wygasla => theme.textColor.withAlpha(100),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(oferta.status);
    return Container(
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(navigationService).pushNamedScreen(
          '/oferty/detail',
          data: {'ofertaId': oferta.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(oferta.numer.isNotEmpty ? oferta.numer : 'Szkic',
                        style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 11, fontFamily: 'monospace')),
                    Text(oferta.tytul, style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withAlpha(80))),
                  child: Text(oferta.status.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.person_outline, size: 14, color: theme.textColor.withAlpha(120)),
                const SizedBox(width: 5),
                Expanded(child: Text(oferta.klientNazwa, style: TextStyle(color: theme.textColor, fontSize: 13, fontWeight: FontWeight.w500))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Text('${oferta.wartoscBrutto.toStringAsFixed(0)} PLN',
                    style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.w800)),
                Text(' brutto', style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 11)),
                const Spacer(),
                Icon(Icons.calendar_today_outlined, size: 12, color: theme.textColor.withAlpha(120)),
                const SizedBox(width: 4),
                Text(oferta.dataWystawienia, style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 11)),
                if (oferta.waznaDo != null)
                  Text(' → ${oferta.waznaDo}', style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 11)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
