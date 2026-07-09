import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:reports/reports/report_pdf_page/provider/report_demographics_provider.dart';

const _primaryText = Color(0xFF171A1F);
const _secondaryText = Color(0xFF667085);
const _lightText = Color(0xFF98A2B3);
const _accent = Color(0xFF5FCDD9);
const _background = Color(0xFFF6F7F9);
const _card = Colors.white;
const _border = Color(0xFFE7ECF2);
const _green = Color(0xFF16A34A);
const _orange = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);

class ReportDemographicsSection extends ConsumerWidget {
  final String city;
  final bool isMobile;

  const ReportDemographicsSection({
    super.key,
    required this.city,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (city.isEmpty) return const SizedBox.shrink();

    final async = ref.watch(reportDemographicsProvider(city));
    return async.when(
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        return _DemographicsCard(data: data, isMobile: isMobile);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _DemographicsCard extends StatelessWidget {
  final NeighborhoodDemographics data;
  final bool isMobile;

  const _DemographicsCard({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
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
          _buildHeader(),
          const Divider(height: 1, color: _border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: isMobile ? _buildMobileGrid() : _buildDesktopGrid(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.people_alt_rounded, size: 18, color: _accent),
          const SizedBox(width: 8),
          Text(
            'demographics_title'.tr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primaryText,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data.city,
              style: const TextStyle(fontSize: 11, color: _secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid() {
    final items = _buildItems();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map((i) => SizedBox(width: 160, child: _DemoTile(item: i)))
          .toList(),
    );
  }

  Widget _buildMobileGrid() {
    final items = _buildItems();
    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: _DemoTile(item: items[i])),
                const SizedBox(width: 8),
                if (i + 1 < items.length)
                  Expanded(child: _DemoTile(item: items[i + 1]))
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  List<_DemoItem> _buildItems() {
    final items = <_DemoItem>[];

    if (data.population != null) {
      items.add(_DemoItem(
        icon: Icons.person_rounded,
        label: 'demographics_population'.tr,
        value: _formatNum(data.population),
        year: data.populationYear,
      ));
    }
    if (data.density != null) {
      items.add(_DemoItem(
        icon: Icons.map_rounded,
        label: 'demographics_density'.tr,
        value: '${data.density!.toStringAsFixed(0)} os/km²',
        year: data.densityYear,
      ));
    }
    if (data.unemploymentRate != null) {
      final rate = data.unemploymentRate!;
      final color = rate >= 10 ? _red : (rate >= 6 ? _orange : _green);
      items.add(_DemoItem(
        icon: Icons.work_off_rounded,
        label: 'demographics_unemployment'.tr,
        value: '${rate.toStringAsFixed(1)}%',
        year: data.unemploymentYear,
        valueColor: color,
      ));
    }
    if (data.naturalIncrease != null) {
      final ni = data.naturalIncrease!;
      final color = ni >= 0 ? _green : _red;
      items.add(_DemoItem(
        icon: Icons.child_care_rounded,
        label: 'demographics_natural_increase'.tr,
        value: ni >= 0 ? '+${ni.toStringAsFixed(0)}' : ni.toStringAsFixed(0),
        year: data.naturalIncreaseYear,
        valueColor: color,
      ));
    }
    if (data.births != null && data.deaths != null) {
      items.add(_DemoItem(
        icon: Icons.favorite_rounded,
        label: 'demographics_births_deaths'.tr,
        value: '${_formatNum(data.births)} / ${_formatNum(data.deaths)}',
      ));
    }

    return items;
  }

  String _formatNum(double? v) {
    if (v == null) return '—';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        data.source,
        style: const TextStyle(fontSize: 10, color: _lightText),
      ),
    );
  }
}

class _DemoItem {
  final IconData icon;
  final String label;
  final String value;
  final int? year;
  final Color valueColor;

  const _DemoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.year,
    this.valueColor = _primaryText,
  });
}

class _DemoTile extends StatelessWidget {
  final _DemoItem item;

  const _DemoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 13, color: _accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(fontSize: 10, color: _secondaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: item.valueColor,
            ),
          ),
          if (item.year != null)
            Text(
              '(${item.year})',
              style: const TextStyle(fontSize: 9, color: _lightText),
            ),
        ],
      ),
    );
  }
}
