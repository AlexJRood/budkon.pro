import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:reports/reports/report_pdf_page/models/pdf_report_model.dart';

const _primaryText = Color(0xFF171A1F);
const _secondaryText = Color(0xFF667085);
const _lightText = Color(0xFF98A2B3);
const _accent = Color(0xFF5FCDD9);
const _card = Colors.white;
const _border = Color(0xFFE7ECF2);
const _background = Color(0xFFF6F7F9);

// ── Estimation constants ──────────────────────────────────────────────────────

// Administrative fee (PLN/m²/month) by building age
double _adminFee(int? yearBuilt) {
  if (yearBuilt == null) return 15.0;
  if (yearBuilt >= 2010) return 12.0;
  if (yearBuilt >= 1990) return 15.0;
  if (yearBuilt >= 1970) return 18.0;
  return 22.0;
}

// Heating (PLN/m²/month) — higher for older buildings, lower for new ones
double _heatingPerM2(int? yearBuilt) {
  if (yearBuilt == null) return 6.0;
  if (yearBuilt >= 2015) return 3.5; // passive/low energy
  if (yearBuilt >= 2000) return 5.0;
  if (yearBuilt >= 1990) return 7.0;
  return 9.0;
}

// Electricity (PLN/month) — flat estimate by bedroom count
double _electricity(int? bedrooms) {
  if (bedrooms == null) return 250.0;
  if (bedrooms <= 1) return 180.0;
  if (bedrooms == 2) return 250.0;
  if (bedrooms == 3) return 320.0;
  return 400.0;
}

// Water + sewage (PLN/month) — ~55 PLN/person, ~1.5 persons per bedroom
double _water(int? bedrooms) {
  final persons = ((bedrooms ?? 1) + 1).clamp(1, 6);
  return persons * 55.0;
}

class _CostItem {
  final IconData icon;
  final String labelKey;
  final double monthly;
  final String? noteKey;

  const _CostItem({
    required this.icon,
    required this.labelKey,
    required this.monthly,
    this.noteKey,
  });
}

class ReportMaintenanceCostSection extends StatelessWidget {
  final PdfReportModel reportData;
  final bool isMobile;

  const ReportMaintenanceCostSection({
    super.key,
    required this.reportData,
    this.isMobile = false,
  });

  List<_CostItem> _buildItems() {
    final r = reportData.report;
    final area = r?.floorArea;
    final yearBuilt = r?.yearBuilt;
    final bedrooms = r?.bedrooms;

    if (area == null || area <= 0) return [];

    final admin = _adminFee(yearBuilt) * area;
    final heating = _heatingPerM2(yearBuilt) * area;
    final elec = _electricity(bedrooms);
    final water = _water(bedrooms);

    return [
      _CostItem(
        icon: Icons.apartment_rounded,
        labelKey: 'maintenance_admin',
        monthly: admin,
        noteKey: 'maintenance_admin_note',
      ),
      _CostItem(
        icon: Icons.local_fire_department_rounded,
        labelKey: 'maintenance_heating',
        monthly: heating,
        noteKey: yearBuilt != null ? null : 'maintenance_estimate',
      ),
      _CostItem(
        icon: Icons.electric_bolt_rounded,
        labelKey: 'maintenance_electricity',
        monthly: elec,
      ),
      _CostItem(
        icon: Icons.water_drop_rounded,
        labelKey: 'maintenance_water',
        monthly: water,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    if (items.isEmpty) return const SizedBox.shrink();

    final total = items.fold<double>(0, (sum, i) => sum + i.monthly);

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
          _buildHeader(total),
          const Divider(height: 1, color: _border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: isMobile
                ? _buildMobileList(items, total)
                : _buildDesktopGrid(items, total),
          ),
          _buildDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildHeader(double total) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, size: 18, color: _accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'maintenance_title'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${total.toStringAsFixed(0)} PLN',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _primaryText,
                ),
              ),
              Text(
                'maintenance_per_month'.tr,
                style: const TextStyle(fontSize: 10, color: _lightText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid(List<_CostItem> items, double total) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((i) => SizedBox(width: 160, child: _CostTile(item: i)))
              .toList(),
        ),
        const SizedBox(height: 16),
        _buildBar(items, total),
      ],
    );
  }

  Widget _buildMobileList(List<_CostItem> items, double total) {
    return Column(
      children: [
        ...items.map(
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CostRow(item: i, total: total),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(List<_CostItem> items, double total) {
    final colors = [
      const Color(0xFF5FCDD9),
      const Color(0xFF2FB8C6),
      const Color(0xFF0EA5E9),
      const Color(0xFF38BDF8),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'maintenance_breakdown'.tr,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: _secondaryText),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: items.asMap().entries.map((e) {
              final pct = e.value.monthly / total;
              return Expanded(
                flex: (pct * 100).round(),
                child: Container(
                  height: 8,
                  color: colors[e.key % colors.length],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: items.asMap().entries.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors[e.key % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  e.value.labelKey.tr,
                  style: const TextStyle(fontSize: 10, color: _secondaryText),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        'maintenance_disclaimer'.tr,
        style: const TextStyle(fontSize: 10, color: _lightText),
      ),
    );
  }
}

class _CostTile extends StatelessWidget {
  final _CostItem item;

  const _CostTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _background,
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
                  item.labelKey.tr,
                  style: const TextStyle(fontSize: 10, color: _secondaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '~${item.monthly.toStringAsFixed(0)} PLN',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          if (item.noteKey != null)
            Text(
              item.noteKey!.tr,
              style: const TextStyle(fontSize: 9, color: _lightText),
            ),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final _CostItem item;
  final double total;

  const _CostRow({required this.item, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = (item.monthly / total * 100).toStringAsFixed(0);
    return Row(
      children: [
        Icon(item.icon, size: 16, color: _accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.labelKey.tr,
            style: const TextStyle(fontSize: 13, color: _primaryText),
          ),
        ),
        Text(
          '~${item.monthly.toStringAsFixed(0)} PLN',
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '$pct%',
            style: const TextStyle(fontSize: 11, color: _lightText),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
