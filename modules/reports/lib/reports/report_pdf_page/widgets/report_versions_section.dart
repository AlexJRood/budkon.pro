import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:intl/intl.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:reports/reports/all_report_page/provider/all_report_provider.dart';
import 'package:reports/reports/report_pdf_page/provider/report_pdf_provider.dart';

const _primaryText = Color(0xFF171A1F);
const _secondaryText = Color(0xFF667085);
const _lightText = Color(0xFF98A2B3);
const _accent = Color(0xFF5FCDD9);
const _accentStrong = Color(0xFF2FB8C6);
const _background = Color(0xFFF6F7F9);
const _card = Colors.white;
const _border = Color(0xFFE7ECF2);
const _green = Color(0xFF16A34A);

class ReportVersionsSection extends ConsumerWidget {
  final int currentReportId;
  final String? streetAddress;
  final String? city;
  final bool isMobile;

  const ReportVersionsSection({
    super.key,
    required this.currentReportId,
    this.streetAddress,
    this.city,
    required this.isMobile,
  });

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _formatMoney(double? value, String? currency) {
    if (value == null) return '-';
    final fmt = NumberFormat.currency(
      locale: 'pl_PL',
      symbol: '',
      decimalDigits: 0,
    );
    final cur = (currency ?? '').trim();
    return '${fmt.format(value).trim()} $cur'.trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if ((streetAddress == null || streetAddress!.trim().isEmpty) &&
        (city == null || city!.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    final allAsync = ref.watch(reportsListProvider);

    return allAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (allReports) {
        // Filter to reports with same address (case-insensitive)
        final addr = streetAddress?.trim().toLowerCase() ?? '';
        final cty = city?.trim().toLowerCase() ?? '';

        final related = allReports.where((r) {
          if (r.id == null) return false;
          final rAddr = (r.streetAddress ?? '').trim().toLowerCase();
          final rCity = (r.city ?? '').trim().toLowerCase();
          final addrMatch = addr.isNotEmpty && rAddr == addr;
          final cityMatch = cty.isNotEmpty && rCity == cty;
          return addrMatch || (addr.isEmpty && cityMatch);
        }).toList()
          ..sort((a, b) {
            final da = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(2000);
            final db = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(2000);
            return db.compareTo(da); // newest first
          });

        if (related.length <= 1) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(related.length),
              const SizedBox(height: 16),
              _buildTimeline(context, ref, related),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.history_rounded,
              size: 20, color: _accentStrong),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'report_versions'.tr,
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                ),
              ),
              Text(
                '$count ${'report_versions_subtitle'.tr}',
                style: const TextStyle(
                    fontSize: 12, color: _secondaryText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    WidgetRef ref,
    List<ReportsListModel> versions,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: versions.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          final isCurrent = r.id == currentReportId;

          return Container(
            decoration: BoxDecoration(
              color: isCurrent
                  ? _accentStrong.withOpacity(0.06)
                  : Colors.transparent,
              borderRadius: i == 0
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : i == versions.length - 1
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(12))
                      : BorderRadius.zero,
              border: i > 0
                  ? const Border(
                      top: BorderSide(color: _border))
                  : null,
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Timeline dot
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isCurrent ? _accentStrong : _border,
                        border: Border.all(
                          color: isCurrent
                              ? _accentStrong
                              : _lightText,
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatDate(r.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: _secondaryText,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    _accentStrong.withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: Text(
                                'current'.tr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _accentStrong,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (r.valueEstimate != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          _formatMoney(r.valueEstimate, r.currency),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _primaryText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isCurrent && r.id != null)
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(reportPdfProvider.notifier)
                          .selectReport(r.id!);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _accentStrong.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _accentStrong.withOpacity(0.25)),
                      ),
                      child: Text(
                        'view'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _accentStrong,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
