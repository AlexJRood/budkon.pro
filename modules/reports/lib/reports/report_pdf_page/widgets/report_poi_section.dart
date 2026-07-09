import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:reports/reports/report_pdf_page/provider/report_poi_provider.dart';

const _primaryText = Color(0xFF171A1F);
const _secondaryText = Color(0xFF667085);
const _lightText = Color(0xFF98A2B3);
const _accent = Color(0xFF5FCDD9);
const _card = Colors.white;
const _border = Color(0xFFE7ECF2);
const _background = Color(0xFFF6F7F9);

class ReportPoiSection extends ConsumerWidget {
  final String address;
  final String city;
  final bool isMobile;

  const ReportPoiSection({
    super.key,
    required this.address,
    required this.city,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (address.isEmpty || city.isEmpty) return const SizedBox.shrink();

    final params = PoiParams(address: address, city: city);
    final async = ref.watch(reportPoiProvider(params));

    return async.when(
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        final hasAny = data.categories.values.any((c) => c.count > 0);
        if (!hasAny) return const SizedBox.shrink();
        return _PoiCard(data: data, isMobile: isMobile);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// icon/label mapping per category key
const _categoryMeta = {
  'schools':        (Icons.school_rounded,        'poi_schools'),
  'universities':   (Icons.account_balance_rounded,'poi_universities'),
  'hospitals':      (Icons.local_hospital_rounded, 'poi_hospitals'),
  'pharmacies':     (Icons.local_pharmacy_rounded, 'poi_pharmacies'),
  'supermarkets':   (Icons.shopping_cart_rounded,  'poi_supermarkets'),
  'parks':          (Icons.park_rounded,           'poi_parks'),
  'bus_stops':      (Icons.directions_bus_rounded, 'poi_bus_stops'),
  'metro_stations': (Icons.subway_rounded,         'poi_metro'),
  'restaurants':    (Icons.restaurant_rounded,     'poi_restaurants'),
  'gyms':           (Icons.fitness_center_rounded, 'poi_gyms'),
};

class _PoiCard extends StatelessWidget {
  final PoiData data;
  final bool isMobile;

  const _PoiCard({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final categories = data.categories.entries
        .where((e) => e.value.count > 0)
        .toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(data.radiusM),
          const Divider(height: 1, color: _border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: isMobile
                ? _buildMobileGrid(categories)
                : _buildDesktopGrid(categories),
          ),
          _buildNearest(categories),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(int radiusM) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.place_rounded, size: 18, color: _accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'poi_title'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${radiusM ~/ 1000} km ${'poi_radius'.tr}',
              style: const TextStyle(fontSize: 11, color: _secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid(
      List<MapEntry<String, PoiCategory>> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories
          .map((e) => SizedBox(width: 130, child: _PoiTile(categoryKey: e.key, cat: e.value)))
          .toList(),
    );
  }

  Widget _buildMobileGrid(
      List<MapEntry<String, PoiCategory>> categories) {
    return Column(
      children: [
        for (int i = 0; i < categories.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: _PoiTile(categoryKey: categories[i].key, cat: categories[i].value)),
                const SizedBox(width: 8),
                if (i + 1 < categories.length)
                  Expanded(child: _PoiTile(categoryKey: categories[i + 1].key, cat: categories[i + 1].value))
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNearest(List<MapEntry<String, PoiCategory>> categories) {
    final anchors = categories.where(
      (e) => ['schools', 'hospitals', 'supermarkets', 'parks']
          .contains(e.key) &&
          e.value.nearest.isNotEmpty,
    );
    if (anchors.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: _border),
          Text(
            'poi_nearest'.tr,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          ...anchors.expand((e) => e.value.nearest.take(2).map(
                (name) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        _categoryMeta[e.key]?.$1 ?? Icons.place_rounded,
                        size: 13,
                        color: _accent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 12, color: _primaryText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        'OpenStreetMap / Overpass API',
        style: const TextStyle(fontSize: 10, color: _lightText),
      ),
    );
  }
}

class _PoiTile extends StatelessWidget {
  final String categoryKey;
  final PoiCategory cat;

  const _PoiTile({required this.categoryKey, required this.cat});

  @override
  Widget build(BuildContext context) {
    final meta = _categoryMeta[categoryKey];
    final icon = meta?.$1 ?? Icons.place_rounded;
    final labelKey = meta?.$2 ?? categoryKey;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.count.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                  ),
                ),
                Text(
                  labelKey.tr,
                  style: const TextStyle(fontSize: 10, color: _secondaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
