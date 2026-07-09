import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/oferty_model.dart';
import '../../data/providers/oferty_provider.dart';
import '../formularz/oferta_formularz_screen.dart';
import '../podglad/oferta_detail_screen.dart';

class OfertyListScreen extends ConsumerStatefulWidget {
  final int? budowaId;
  final String budowaNazwa;

  const OfertyListScreen({
    super.key,
    this.budowaId,
    this.budowaNazwa = 'Wszystkie oferty',
  });

  @override
  ConsumerState<OfertyListScreen> createState() => _OfertyListScreenState();
}

class _OfertyListScreenState extends ConsumerState<OfertyListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  static const _statusTabs = [
    null,
    StatusOferty.roboczy,
    StatusOferty.wyslana,
    StatusOferty.zaakceptowana,
    StatusOferty.odrzucona,
  ];

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
    final state = ref.watch(ofertyProvider(widget.budowaId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Oferty'),
            if (widget.budowaId != null)
              Text(
                widget.budowaNazwa,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(ofertyProvider(widget.budowaId).notifier).load(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Wszystkie'),
            Tab(text: 'Robocze'),
            Tab(text: 'Wysłane'),
            Tab(text: 'Zaakceptowane'),
            Tab(text: 'Odrzucone'),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nowa oferta'),
        onPressed: () => _nowaOferta(context),
      ),

      body: state.loading && state.lista.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: _statusTabs.map((filterStatus) {
                final filtered = filterStatus == null
                    ? state.lista
                    : state.lista
                        .where((o) => o.status == filterStatus)
                        .toList();
                return _OfertyTabView(
                  oferty: filtered,
                  budowaId: widget.budowaId,
                  error: state.error,
                );
              }).toList(),
            ),
    );
  }

  Future<void> _nowaOferta(BuildContext context) async {
    final wynik = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OfertyFormularzScreen(
          budowaId: widget.budowaId,
          budowaNazwa: widget.budowaNazwa,
        ),
      ),
    );
    if (wynik == true) {
      ref.read(ofertyProvider(widget.budowaId).notifier).load();
    }
  }
}

class _OfertyTabView extends ConsumerWidget {
  final List<OfertyListItem> oferty;
  final int? budowaId;
  final String? error;

  const _OfertyTabView({
    required this.oferty,
    required this.budowaId,
    this.error,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (error != null && oferty.isEmpty) {
      return Center(child: Text(error!));
    }
    if (oferty.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined,
                size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Brak ofert',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(ofertyProvider(budowaId).notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: oferty.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => _OfertyCard(oferta: oferty[i]),
      ),
    );
  }
}

class _OfertyCard extends StatelessWidget {
  final OfertyListItem oferta;
  const _OfertyCard({required this.oferta});

  Color _statusColor(BuildContext ctx, StatusOferty s) {
    final cs = Theme.of(ctx).colorScheme;
    return switch (s) {
      StatusOferty.roboczy => cs.outline,
      StatusOferty.wyslana => const Color(0xFF2196F3),
      StatusOferty.zaakceptowana => const Color(0xFF4CAF50),
      StatusOferty.odrzucona => cs.error,
      StatusOferty.wygasla => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColor(context, oferta.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OfertyDetailScreen(ofertaId: oferta.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        oferta.numer.isNotEmpty
                            ? oferta.numer
                            : 'Szkic',
                        style: TextStyle(
                          color: cs.outline,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        oferta.tytul,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withAlpha(80)),
                  ),
                  child: Text(
                    oferta.status.label,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ]),

              const SizedBox(height: 8),

              Row(children: [
                Icon(Icons.person_outline, size: 14, color: cs.outline),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    oferta.klientNazwa,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ]),

              const SizedBox(height: 10),

              Row(children: [
                Text(
                  '${oferta.wartoscBrutto.toStringAsFixed(0)} PLN',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  ' brutto',
                  style: TextStyle(color: cs.outline, fontSize: 11),
                ),
                const Spacer(),
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: cs.outline),
                const SizedBox(width: 4),
                Text(
                  oferta.dataWystawienia,
                  style: TextStyle(color: cs.outline, fontSize: 11),
                ),
                if (oferta.waznaDo != null) ...[
                  Text(
                    ' → ${oferta.waznaDo}',
                    style: TextStyle(color: cs.outline, fontSize: 11),
                  ),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
