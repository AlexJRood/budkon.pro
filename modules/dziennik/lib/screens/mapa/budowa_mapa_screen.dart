import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
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
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(marketyProvider(budowaId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: theme.textColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mapa budowy', style: TextStyle(color: theme.textColor)),
            Text(
              budowaNazwa,
              style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(160)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.textColor),
            onPressed: () => ref.invalidate(marketyProvider(budowaId)),
          ),
        ],
      ),
      body: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(e.toString(), style: TextStyle(color: theme.textColor)),
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
          theme: theme,
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
  final ThemeColors theme;

  const _MapView({
    required this.budowaLat,
    required this.budowaLon,
    required this.budowaNazwa,
    required this.markety,
    required this.theme,
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
                Marker(
                  point: budowaPoint,
                  width: 40,
                  height: 48,
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = null),
                    child: const _BudowaPin(),
                  ),
                ),
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

        Positioned(
          top: 12,
          right: 12,
          child: _Legend(marketCount: widget.markety.length, theme: widget.theme),
        ),

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
              theme: widget.theme,
            ),
          ),
      ],
    );
  }
}

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
          SizedBox(width: 2, height: 8, child: ColoredBox(color: Colors.red)),
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
        child: Icon(Icons.store, color: Colors.white, size: isSelected ? 20 : 16),
      );
}

class _Legend extends StatelessWidget {
  final int marketCount;
  final ThemeColors theme;
  const _Legend({required this.marketCount, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.secondaryWidgetColor.withAlpha(235),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.bordercolor.withAlpha(60)),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendRow(color: Colors.red, label: 'Budowa', theme: theme),
            const SizedBox(height: 4),
            _LegendRow(color: Colors.orange.shade700, label: 'Sklepy ($marketCount)', theme: theme),
          ],
        ),
      );
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final ThemeColors theme;
  const _LegendRow({required this.color, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: theme.textColor, fontSize: 11)),
        ],
      );
}

class _MarketSheet extends StatelessWidget {
  final MarketBudowlany market;
  final double budowaLat;
  final double budowaLon;
  final VoidCallback onClose;
  final ThemeColors theme;

  const _MarketSheet({
    required this.market,
    required this.budowaLat,
    required this.budowaLon,
    required this.onClose,
    required this.theme,
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
    final km = _dystansKm();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryWidgetColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.themeColor.withAlpha(40),
            child: Icon(Icons.store, color: theme.themeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  market.nazwa,
                  style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (market.adres.isNotEmpty)
                  Text(
                    market.adres,
                    style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  '${km.toStringAsFixed(1)} km od budowy',
                  style: TextStyle(color: theme.themeColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.textColor),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
