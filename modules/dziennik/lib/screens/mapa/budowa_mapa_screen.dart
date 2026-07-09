import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/dziennik_model.dart';
import '../../data/providers/dziennik_provider.dart';

class BudowaMapaScreen extends ConsumerWidget {
  final int budowaId;
  final String budowaNazwa;

  const BudowaMapaScreen({
    super.key,
    required this.budowaId,
    required this.budowaNazwa,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(marketyProvider(budowaId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mapa budowy'),
            Text(
              budowaNazwa,
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
            onPressed: () => ref.invalidate(marketyProvider(budowaId)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(e.toString()),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(marketyProvider(budowaId)),
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
        data: (data) => _MapView(
          budowaLat: data.budowaLat,
          budowaLon: data.budowaLon,
          budowaNazwa: budowaNazwa,
          markety: data.markety,
        ),
      ),
    );
  }
}

class _MapView extends StatefulWidget {
  final double budowaLat;
  final double budowaLon;
  final String budowaNazwa;
  final List<MarketBudowlany> markety;

  const _MapView({
    required this.budowaLat,
    required this.budowaLon,
    required this.budowaNazwa,
    required this.markety,
  });

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  MarketBudowlany? _selected;

  @override
  Widget build(BuildContext context) {
    final budowaPoint = LatLng(widget.budowaLat, widget.budowaLon);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: budowaPoint,
            initialZoom: 13,
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'budkon.pro',
            ),
            MarkerLayer(
              markers: [
                // Budowa — czerwona szpilka
                Marker(
                  point: budowaPoint,
                  width: 40,
                  height: 48,
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = null),
                    child: const _BudowaPin(),
                  ),
                ),
                // Markety — pomarańczowe ikony
                ...widget.markety.map(
                  (m) => Marker(
                    point: LatLng(m.lat, m.lon),
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = m),
                      child: _MarketPin(isSelected: _selected == m),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Legenda
        Positioned(
          top: 12,
          right: 12,
          child: _Legend(marketCount: widget.markety.length),
        ),

        // Popup wybranego marketu
        if (_selected != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _MarketSheet(
              market: _selected!,
              budowaLat: widget.budowaLat,
              budowaLon: widget.budowaLon,
              onClose: () => setState(() => _selected = null),
            ),
          ),
      ],
    );
  }
}

// ---- Piny ---------------------------------------------------------------

class _BudowaPin extends StatelessWidget {
  const _BudowaPin();

  @override
  Widget build(BuildContext context) => const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.red,
            child: Icon(Icons.construction, color: Colors.white, size: 18),
          ),
          SizedBox(
            width: 2,
            height: 8,
            child: ColoredBox(color: Colors.red),
          ),
        ],
      );
}

class _MarketPin extends StatelessWidget {
  final bool isSelected;
  const _MarketPin({required this.isSelected});

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 18,
        backgroundColor: isSelected ? Colors.orange : Colors.orange.shade700,
        child: Icon(
          Icons.store,
          color: Colors.white,
          size: isSelected ? 20 : 16,
        ),
      );
}

// ---- UI -----------------------------------------------------------------

class _Legend extends StatelessWidget {
  final int marketCount;
  const _Legend({required this.marketCount});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendRow(color: Colors.red, label: 'Budowa'),
            const SizedBox(height: 4),
            _LegendRow(
              color: Colors.orange.shade700,
              label: 'Sklepy ($marketCount)',
            ),
          ],
        ),
      );
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
}

class _MarketSheet extends StatelessWidget {
  final MarketBudowlany market;
  final double budowaLat;
  final double budowaLon;
  final VoidCallback onClose;

  const _MarketSheet({
    required this.market,
    required this.budowaLat,
    required this.budowaLon,
    required this.onClose,
  });

  double _dystansKm() {
    const dist = Distance();
    return dist.as(
      LengthUnit.Kilometer,
      LatLng(budowaLat, budowaLon),
      LatLng(market.lat, market.lon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final km = _dystansKm();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.secondaryContainer,
            child: const Icon(Icons.store),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  market.nazwa,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (market.adres.isNotEmpty)
                  Text(
                    market.adres,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  '${km.toStringAsFixed(1)} km od budowy',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
