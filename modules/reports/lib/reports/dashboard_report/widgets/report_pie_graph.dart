import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reports/reports/dashboard_report/models/dashboard_data_model.dart';
import 'package:reports/reports/dashboard_report/provider/dashboard_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as sf_charts;
import 'package:core/theme/backgroundgradient.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

enum VelocitySegmentType {
  offerType,
  marketType,
  estateType,
  city,
}

enum VelocityDetailView {
  segments,
  fastest,
  slowest,
  trend,
}

enum VelocityPersona {
  agent,
  buyer,
  developer,
}

enum VelocityFocusMetric {
  medianDom,
  removed30d,
  new30d,
  absorption,
  removedVsNew,
  velocity,
}

class SalesChart extends ConsumerWidget {
  final bool isTablet;
  const SalesChart({super.key,this.isTablet = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MarketVelocityPanel(isMobile: false,isTablet:isTablet);
  }
}

class SalesChartMobile extends ConsumerWidget {
  const SalesChartMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MarketVelocityPanel(isMobile: true);
  }
}

class MarketVelocityPanel extends ConsumerStatefulWidget {
  final bool isMobile;
  final bool isTablet;

  const MarketVelocityPanel({
    super.key,
    this.isMobile = false,
    this.isTablet = false,
  });

  @override
  ConsumerState<MarketVelocityPanel> createState() =>
      _MarketVelocityPanelState();
}

class _MarketVelocityPanelState extends ConsumerState<MarketVelocityPanel> {
  VelocitySegmentType _selectedSegment = VelocitySegmentType.offerType;
  VelocityDetailView _selectedView = VelocityDetailView.segments;
  VelocityPersona _selectedPersona = VelocityPersona.agent;
  VelocityFocusMetric _selectedMetric = VelocityFocusMetric.medianDom;

  List<VelocityBreakdownItem> _getBreakdown(MarketVelocity velocity) {
    switch (_selectedSegment) {
      case VelocitySegmentType.offerType:
        return velocity.byOfferType;
      case VelocitySegmentType.marketType:
        return velocity.byMarketType;
      case VelocitySegmentType.estateType:
        return velocity.byEstateType;
      case VelocitySegmentType.city:
        return velocity.byCity;
    }
  }

  bool _isPartialPayload(MarketVelocity velocity) =>
      velocity.meta['is_partial_payload'] == true;

  bool _hasInventoryStats(MarketVelocity velocity) =>
      velocity.meta['has_inventory_stats'] == true;

  bool _hasTrendPayload(MarketVelocity velocity) =>
      velocity.meta['has_trend_payload'] == true;

  bool _hasBreakdownPayload(MarketVelocity velocity) =>
      velocity.meta['has_breakdown_payload'] == true;

  bool _hasTopFastestPayload(MarketVelocity velocity) =>
      velocity.meta['has_top_fastest_payload'] == true;

  bool _hasTopSlowestPayload(MarketVelocity velocity) =>
      velocity.meta['has_top_slowest_payload'] == true;

  String _segmentLabel(VelocitySegmentType type) {
    switch (type) {
      case VelocitySegmentType.offerType:
        return 'offer_type'.tr;
      case VelocitySegmentType.marketType:
        return 'market_type'.tr;
      case VelocitySegmentType.estateType:
        return 'estate_type'.tr;
      case VelocitySegmentType.city:
        return 'city'.tr;
    }
  }

  String _viewLabel(VelocityDetailView type) {
    switch (type) {
      case VelocityDetailView.segments:
        return 'segments'.tr;
      case VelocityDetailView.fastest:
        return 'fastest'.tr;
      case VelocityDetailView.slowest:
        return 'slowest'.tr;
      case VelocityDetailView.trend:
        return 'trend'.tr;
    }
  }

  String _personaLabel(VelocityPersona type) {
    switch (type) {
      case VelocityPersona.agent:
        return 'agent'.tr;
      case VelocityPersona.buyer:
        return 'buyer'.tr;
      case VelocityPersona.developer:
        return 'developer'.tr;
    }
  }

  String _personaDescription(VelocityPersona type) {
    switch (type) {
      case VelocityPersona.agent:
        return 'agent_description'.tr;
      case VelocityPersona.buyer:
        return 'buyer_description'.tr;
      case VelocityPersona.developer:
        return 'developer_description'.tr;
    }
  }

  Color _velocityColor(double score) {
    if (score >= 80) return Colors.redAccent;
    if (score >= 60) return Colors.orangeAccent;
    if (score >= 40) return Colors.amber;
    return Colors.green;
  }

  String _formatDays(double? value) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(1)} d';
  }

  String _formatPercentRatio(double value, {int digits = 1}) {
    return '${(value * 100).toStringAsFixed(digits)}%';
  }

  String _formatRatio(double value) {
    return '${value.toStringAsFixed(2)}x';
  }

String _metricExplanation(MarketVelocitySummary summary) {
  switch (_selectedPersona) {
    case VelocityPersona.agent:
      switch (_selectedMetric) {
        case VelocityFocusMetric.medianDom:
          return 'metric_median_dom_agent'.tr;
        case VelocityFocusMetric.removed30d:
          return 'metric_removed_30d_agent'.tr;
        case VelocityFocusMetric.new30d:
          return 'metric_new_30d_agent'.tr;
        case VelocityFocusMetric.absorption:
          return 'metric_absorption_agent'.tr;
        case VelocityFocusMetric.removedVsNew:
          return 'metric_removed_vs_new_agent'.tr;
        case VelocityFocusMetric.velocity:
          return 'metric_velocity_agent'.tr;
      }
    case VelocityPersona.buyer:
      switch (_selectedMetric) {
        case VelocityFocusMetric.medianDom:
          return 'metric_median_dom_buyer'.tr;
        case VelocityFocusMetric.removed30d:
          return 'metric_removed_30d_buyer'.tr;
        case VelocityFocusMetric.new30d:
          return 'metric_new_30d_buyer'.tr;
        case VelocityFocusMetric.absorption:
          return 'metric_absorption_buyer'.tr;
        case VelocityFocusMetric.removedVsNew:
          return 'metric_removed_vs_new_buyer'.tr;
        case VelocityFocusMetric.velocity:
          return 'metric_velocity_buyer'.tr;
      }
    case VelocityPersona.developer:
      switch (_selectedMetric) {
        case VelocityFocusMetric.medianDom:
          return 'metric_median_dom_developer'.tr;
        case VelocityFocusMetric.removed30d:
          return 'metric_removed_30d_developer'.tr;
        case VelocityFocusMetric.new30d:
          return 'metric_new_30d_developer'.tr;
        case VelocityFocusMetric.absorption:
          return 'metric_absorption_developer'.tr;
        case VelocityFocusMetric.removedVsNew:
          return 'metric_removed_vs_new_developer'.tr;
        case VelocityFocusMetric.velocity:
          return 'metric_velocity_developer'.tr;
      }
  }
}

  String _breakdownNarrative(VelocityBreakdownItem item) {
  switch (_selectedPersona) {
    case VelocityPersona.agent:
      if (item.velocityScore >= 60) {
        return item.segment + 'agent_breakdown_fast_narrative'.tr;
      }
      if (item.velocityScore >= 40) {
        return item.segment + 'agent_breakdown_balanced_narrative'.tr;
      }
      return item.segment + 'agent_breakdown_slow_narrative'.tr;
      
    case VelocityPersona.buyer:
      if ((item.medianDaysOnMarket ?? 0) > 45 ||
          item.removalToNewRatio30d < 1) {
        return item.segment + 'buyer_breakdown_negotiation_narrative'.tr;
      }
      return item.segment + 'buyer_breakdown_competitive_narrative'.tr;
      
    case VelocityPersona.developer:
      if (item.absorptionRate30d > 0.2 &&
          (item.relativeVelocityIndex ?? 0) > 1) {
        return item.segment + 'developer_breakdown_strong_narrative'.tr;
      }
      return item.segment + 'developer_breakdown_weak_narrative'.tr;
  }
}

  void _showBreakdownDetails(
    BuildContext context,
    VelocityBreakdownItem item,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final textColor = CustomColors.secondaryWidgetTextColor(context, ref);
        final accent = _velocityColor(item.velocityScore);

        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: CustomColors.secondaryWidgetColor(context, ref),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: ListView(
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.segment,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withAlpha(35),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: accent),
                      ),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _breakdownNarrative(item),
                  style: TextStyle(
                    color: textColor.withAlpha(220),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                _DetailSection(
                  title: 'snapshot'.tr,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(label: 'active'.tr, value: '${item.activeInventory}'),
                      _InfoPill(label: 'new_7d'.tr, value: '${item.newListings7d}'),
                      _InfoPill(label: 'new_30d'.tr, value: '${item.newListings30d}'),
                      _InfoPill(label: 'removed_7d'.tr, value: '${item.removedListings7d}'),
                      _InfoPill(label: 'removed_30d'.tr, value: '${item.removedListings30d}'),
                      _InfoPill(label: 'median_dom'.tr, value: _formatDays(item.medianDaysOnMarket)),
                      _InfoPill(label: 'mean_dom'.tr, value: _formatDays(item.meanDaysOnMarket)),
                      _InfoPill(
                        label: 'absorption'.tr,
                        value: _formatPercentRatio(item.absorptionRate30d),
                      ),
                      _InfoPill(
                        label: 'removed_vs_new'.tr,
                        value: _formatRatio(item.removalToNewRatio30d),
                      ),
                      _InfoPill(label: 'net_flow'.tr, value: '${item.netFlow30d}'),
                      _InfoPill(label: 'balance'.tr, value: item.marketBalance),
                      _InfoPill(
                        label: 'rel_velocity'.tr,
                        value: item.relativeVelocityIndex == null
                            ? '—'
                            : '${item.relativeVelocityIndex!.toStringAsFixed(2)}x',
                      ),
                      _InfoPill(
                        label: 'score'.tr,
                        value: item.velocityScore.toStringAsFixed(1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DetailSection(
                  title: 'how_to_use_this'.tr,
                  child: Text(
                    _usageAdviceForItem(item),
                    style: TextStyle(
                      color: textColor.withAlpha(215),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _DetailSection(
                  title: 'what_to_check_next'.tr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _nextChecksForItem(item)
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    e,
                                    style: TextStyle(
                                      color: textColor.withAlpha(215),
                                      fontSize: 13,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _usageAdviceForItem(VelocityBreakdownItem item) {
    switch (_selectedPersona) {
      case VelocityPersona.agent:
        return 'agent_usage_advice'.tr;
      case VelocityPersona.buyer:
        return 'buyer_usage_advice'.tr;
      case VelocityPersona.developer:
        return 'developer_usage_advice'.tr;
    }
  }

  List<String> _nextChecksForItem(VelocityBreakdownItem item) {
    switch (_selectedPersona) {
      case VelocityPersona.agent:
        return 'agent_next_checks'.tr.split('\n');
      case VelocityPersona.buyer:
        return 'buyer_next_checks'.tr.split('\n');
      case VelocityPersona.developer:
        return 'developer_next_checks'.tr.split('\n');
    }
  }

  void _showListingDetails(
    BuildContext context,
    VelocityListing item, {
    required bool fastest,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final textColor = CustomColors.secondaryWidgetTextColor(context, ref);
        final accent = fastest ? Colors.greenAccent : Colors.orangeAccent;

        return Container(
          height: MediaQuery.of(context).size.height * 0.68,
          decoration: BoxDecoration(
            color: CustomColors.secondaryWidgetColor(context, ref),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: ListView(
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  item.title.isEmpty ? 'offer'.tr : item.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fastest
                      ? 'fastest_listing_description'.tr
                      : 'slowest_listing_description'.tr,
                  style: TextStyle(
                    color: textColor.withAlpha(220),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      label: 'days_on_market'.tr,
                      value: _formatDays(item.daysOnMarket),
                    ),
                    _InfoPill(
                      label: 'city'.tr,
                      value: item.city.isEmpty ? 'Unknown'.tr : item.city,
                    ),
                    _InfoPill(
                      label: 'estate_type'.tr,
                      value: item.estateType.isEmpty ? 'Unknown'.tr : item.estateType,
                    ),
                    _InfoPill(
                      label: 'offer_type'.tr,
                      value: item.offerType.isEmpty ? 'Unknown'.tr : item.offerType,
                    ),
                    _InfoPill(
                      label: 'market_type'.tr,
                      value: item.marketType.isEmpty ? 'Unknown'.tr : item.marketType,
                    ),
                    _InfoPill(
                      label: 'price'.tr,
                      value: item.price == null
                          ? '—'
                          : '${item.currency ?? ''} ${item.price}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'interpretation'.tr,
                  child: Text(
                    _listingNarrative(item, fastest: fastest),
                    style: TextStyle(
                      color: textColor.withAlpha(220),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _DetailSection(
                  title: 'useful_next_step'.tr,
                  child: Text(
                    _listingNextStep(item, fastest: fastest),
                    style: TextStyle(
                      color: textColor.withAlpha(220),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                if ((item.url ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'url'.tr,
                    child: SelectableText(
                      item.url!,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _listingNarrative(
    VelocityListing item, {
    required bool fastest,
  }) {
    switch (_selectedPersona) {
      case VelocityPersona.agent:
        return fastest
            ? 'agent_fast_listing_narrative'.tr
            : 'agent_slow_listing_narrative'.tr;
      case VelocityPersona.buyer:
        return fastest
            ? 'buyer_fast_listing_narrative'.tr
            : 'buyer_slow_listing_narrative'.tr;
      case VelocityPersona.developer:
        return fastest
            ? 'developer_fast_listing_narrative'.tr
            : 'developer_slow_listing_narrative'.tr;
    }
  }

  String _listingNextStep(
    VelocityListing item, {
    required bool fastest,
  }) {
    switch (_selectedPersona) {
      case VelocityPersona.agent:
        return fastest
            ? 'agent_fast_next_step'.tr
            : 'agent_slow_next_step'.tr;
      case VelocityPersona.buyer:
        return fastest
            ? 'buyer_fast_next_step'.tr
            : 'buyer_slow_next_step'.tr;
      case VelocityPersona.developer:
        return fastest
            ? 'developer_fast_next_step'.tr
            : 'developer_slow_next_step'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    return dashboardDataAsync.when(
      data: (dashboardData) {
        final velocity = dashboardData.marketVelocity;
        final breakdown = _getBreakdown(velocity);

        return Container(
          decoration: BoxDecoration(
            color: CustomColors.secondaryWidgetColor(context, ref),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CustomColors.secondaryWidgetTextColor(
                context,
                ref,
              ).withAlpha(76),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.isMobile ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),
                Flexible(child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPersonaSelector(context),
                      const SizedBox(height: 10),
                      _buildInsightBanner(context, velocity),
                      const SizedBox(height: 14),
                      _buildSummaryGrid(context, velocity),
                      const SizedBox(height: 14),
                      if (_selectedView != VelocityDetailView.trend) ...[
                        _buildSectionTitle(
                          context,
                          'visual_overview'.tr,
                          'visual_overview_subtitle'.tr,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          child: SingleChildScrollView(
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: widget.isMobile ? 120 : widget.isTablet ? 200 : 135,
                                      child: _buildHistogram(context, velocity),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SizedBox(
                                      height: widget.isMobile ? 120 : widget.isTablet ? 200 : 135,
                                      child: _buildTrendChartMini(context, velocity),
                                    ),
                                  ),
                                ],
                              ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _buildViewSelector(context),
                      const SizedBox(height: 10),
                      if (_selectedView == VelocityDetailView.segments) ...[
                        _buildSegmentSelector(context),
                        const SizedBox(height: 10),
                      ],
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _selectedView == VelocityDetailView.segments
                            ? _buildBreakdownList(context, breakdown, velocity)
                            : _selectedView == VelocityDetailView.fastest
                            ? _buildListingsList(
                          context,
                          velocity.topFastest,
                          emptyText: _emptyListingText(
                            fastest: true,
                            velocity: velocity,
                          ),
                          fastest: true,
                        )
                            : _selectedView == VelocityDetailView.slowest
                            ? _buildListingsList(
                          context,
                          velocity.topSlowest,
                          emptyText: _emptyListingText(
                            fastest: false,
                            velocity: velocity,
                          ),
                          fastest: false,
                        )
                            : _buildTrendDetails(context, velocity),
                      ),
                    ],
                  ),
                ),)
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        decoration: BoxDecoration(
          color: CustomColors.secondaryWidgetColor(context, ref),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CustomColors.secondaryWidgetTextColor(
              context,
              ref,
            ).withAlpha(76),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        decoration: BoxDecoration(
          color: CustomColors.secondaryWidgetColor(context, ref),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CustomColors.secondaryWidgetTextColor(
              context,
              ref,
            ).withAlpha(76),
          ),
        ),
        child: Center(
          child: Text(
            'error_loading_market_velocity'.tr,
            style: TextStyle(
              color: CustomColors.secondaryWidgetTextColor(context, ref),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'market_velocity'.tr,
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontSize: widget.isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'market_velocity_subtitle'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ).withAlpha(220),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonaSelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VelocityPersona.values
          .map(
            (persona) => ChoiceChip(
              label: Text(_personaLabel(persona), style: TextStyle(color: Colors.black)),
              selected: _selectedPersona == persona,
              onSelected: (_) {
                setState(() {
                  _selectedPersona = persona;
                });
              },
              selectedColor: Colors.greenAccent.withAlpha(45),
              backgroundColor: Colors.black.withAlpha(18),
              labelStyle: TextStyle(
                color: CustomColors.secondaryWidgetTextColor(context, ref),
                fontSize: 12,
                fontWeight: _selectedPersona == persona
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: _selectedPersona == persona
                      ? Colors.greenAccent
                      : Colors.transparent,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInsightBanner(
    BuildContext context,
    MarketVelocity velocity,
  ) {
    final textColor = CustomColors.secondaryWidgetTextColor(context, ref);
    final summary = velocity.summary;

    return Column(
      children: [
        if (_isPartialPayload(velocity))
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orangeAccent.withAlpha(80)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orangeAccent,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'dashboard_partial_payload_warning'.tr,
                    style: TextStyle(
                      color: textColor.withAlpha(225),
                      fontSize: 12.2,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: _velocityColor(summary.velocityScore),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _personaDescription(_selectedPersona),
                  style: TextStyle(
                    color: textColor.withAlpha(225),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: CustomColors.secondaryWidgetTextColor(context, ref),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: CustomColors.secondaryWidgetTextColor(
              context,
              ref,
            ).withAlpha(190),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    MarketVelocity velocity,
  ) {
    final summary = velocity.summary;
    final hasInventoryStats = _hasInventoryStats(velocity);

    final items = [
      _SummaryItem(
        metric: VelocityFocusMetric.medianDom,
        title: 'median_dom'.tr,
        value: _formatDays(summary.medianDaysOnMarket),
        subtitle: 'median_time_on_market'.tr,
        accent: Colors.greenAccent,
      ),
      _SummaryItem(
        metric: VelocityFocusMetric.removed30d,
        title: 'removed_30d'.tr,
        value: hasInventoryStats ? '${summary.removedListings30d}' : '—',
        subtitle: 'listings_gone_from_market'.tr,
        accent: Colors.orangeAccent,
      ),
      _SummaryItem(
        metric: VelocityFocusMetric.new30d,
        title: 'new_30d'.tr,
        value: hasInventoryStats ? '${summary.newListings30d}' : '—',
        subtitle: 'fresh_supply'.tr,
        accent: Colors.lightBlueAccent,
      ),
      _SummaryItem(
        metric: VelocityFocusMetric.absorption,
        title: 'absorption'.tr,
        value: hasInventoryStats
            ? _formatPercentRatio(summary.absorptionRate30d)
            : '—',
        subtitle: 'removed_vs_active_inventory'.tr,
        accent: Colors.purpleAccent,
      ),
      _SummaryItem(
        metric: VelocityFocusMetric.removedVsNew,
        title: 'removed_vs_new'.tr,
        value: hasInventoryStats
            ? _formatRatio(summary.removalToNewRatio30d)
            : '—',
        subtitle: 'demand_pressure_indicator'.tr,
        accent: Colors.amber,
      ),
      _SummaryItem(
        metric: VelocityFocusMetric.velocity,
        title: 'velocity'.tr,
        value: summary.label,
        subtitle: 'score_subtitle'.tr + summary.velocityScore.toStringAsFixed(1),
        accent: _velocityColor(summary.velocityScore),
      ),
    ];

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final itemWidth = widget.isMobile
                ? (width - 8) / 2
                : (width - 16) / 3;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: itemWidth,
                      child: _SummaryCard(
                        item: item,
                        isSelected: _selectedMetric == item.metric,
                        textColor: CustomColors.secondaryWidgetTextColor(
                          context,
                          ref,
                        ),
                        onTap: () {
                          setState(() {
                            _selectedMetric = item.metric;
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(12)),
          ),
          child: Text(
            _metricExplanation(summary),
            style: TextStyle(
              color: CustomColors.secondaryWidgetTextColor(
                context,
                ref,
              ).withAlpha(220),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistogram(BuildContext context, MarketVelocity velocity) {
    final data = velocity.histogram;
    if (data.isEmpty) {
      return _buildEmptyBox(
        context,
        _emptyDataText('histogram', velocity),
      );
    }

    return sf_charts.SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: sf_charts.CategoryAxis(
        labelIntersectAction: sf_charts.AxisLabelIntersectAction.trim,
        maximumLabels: 6,
        labelRotation:270,
        labelStyle: TextStyle(
          color: CustomColors.secondaryWidgetTextColor(context, ref),
          fontSize: widget.isMobile ? 9 : 10,
        ),
        axisLine: const sf_charts.AxisLine(width: 0),
        majorGridLines: const sf_charts.MajorGridLines(width: 0),
        majorTickLines: const sf_charts.MajorTickLines(size: 0),
      ),
      primaryYAxis: sf_charts.NumericAxis(
        isVisible: false,
        axisLine: const sf_charts.AxisLine(width: 0),
        rangePadding: sf_charts.ChartRangePadding.round,
        majorGridLines: const sf_charts.MajorGridLines(width: 0),
      ),
      tooltipBehavior: sf_charts.TooltipBehavior(
        enable: true,
        color: Colors.black87,
        format: 'listings_format'.tr,
      ),
      series: <sf_charts.CartesianSeries<VelocityBucket, String>>[
        sf_charts.ColumnSeries<VelocityBucket, String>(
          dataSource: data,
          xValueMapper: (item, _) => item.label,
          yValueMapper: (item, _) => item.count,
          color: Colors.greenAccent,
          width:  widget.isTablet ? 0.35 : 0.56,
          spacing: 0.1,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildTrendChartMini(BuildContext context, MarketVelocity velocity) {
    final data = velocity.trend;
    if (data.isEmpty) {
      return _buildEmptyBox(
        context,
        _emptyDataText('trend', velocity),
      );
    }

    return sf_charts.SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: sf_charts.CategoryAxis(
        labelStyle: TextStyle(
          color: CustomColors.secondaryWidgetTextColor(context, ref),
          fontSize: widget.isMobile ? 8 : 9,
        ),
        axisLine: const sf_charts.AxisLine(width: 0),
        majorGridLines: const sf_charts.MajorGridLines(width: 0),
        majorTickLines: const sf_charts.MajorTickLines(size: 0),
      ),
      primaryYAxis: sf_charts.NumericAxis(
        isVisible: false,
        axisLine: const sf_charts.AxisLine(width: 0),
        majorGridLines: const sf_charts.MajorGridLines(width: 0),
      ),
      tooltipBehavior: sf_charts.TooltipBehavior(
        enable: true,
        color: Colors.black87,
      ),
      series: <sf_charts.CartesianSeries<VelocityTrendPoint, String>>[
        sf_charts.SplineSeries<VelocityTrendPoint, String>(
          dataSource: data,
          xValueMapper: (item, _) => item.periodLabel,
          yValueMapper: (item, _) => item.newListings,
          color: Colors.lightBlueAccent,
          width: 2,
          markerSettings: const sf_charts.MarkerSettings(isVisible: true),
        ),
        sf_charts.SplineSeries<VelocityTrendPoint, String>(
          dataSource: data,
          xValueMapper: (item, _) => item.periodLabel,
          yValueMapper: (item, _) => item.removedListings,
          color: Colors.orangeAccent,
          width: 2,
          markerSettings: const sf_charts.MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildViewSelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VelocityDetailView.values
          .map(
            (view) => ChoiceChip(
              label: Text(_viewLabel(view), style: TextStyle(color: Colors.black)),
              selected: _selectedView == view,
              onSelected: (_) {
                setState(() {
                  _selectedView = view;
                });
              },
              selectedColor: Colors.greenAccent.withAlpha(40),
              backgroundColor: Colors.black.withAlpha(18),
              labelStyle: TextStyle(
                color: CustomColors.secondaryWidgetTextColor(context, ref),
                fontSize: 12,
                fontWeight: _selectedView == view
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: _selectedView == view
                      ? Colors.greenAccent
                      : Colors.transparent,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSegmentSelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VelocitySegmentType.values
          .map(
            (segment) => ChoiceChip(
              label: Text(_segmentLabel(segment), style: TextStyle(color: Colors.black)),
              selected: _selectedSegment == segment,
              onSelected: (_) {
                setState(() {
                  _selectedSegment = segment;
                });
              },
              selectedColor: Colors.orangeAccent.withAlpha(40),
              backgroundColor: Colors.black.withAlpha(18),
              labelStyle: TextStyle(
                color: CustomColors.secondaryWidgetTextColor(context, ref),
                fontSize: 12,
                fontWeight: _selectedSegment == segment
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: _selectedSegment == segment
                      ? Colors.orangeAccent
                      : Colors.transparent,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBreakdownList(
    BuildContext context,
    List<VelocityBreakdownItem> items,
    MarketVelocity velocity,
  ) {
    if (items.isEmpty) {
      return _buildEmptyBox(
        context,
        _emptyDataText('breakdown', velocity),
      );
    }

    return ListView.separated(
      key: const ValueKey('segments'),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final velocityColor = _velocityColor(item.velocityScore);

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showBreakdownDetails(context, item),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withAlpha(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.segment,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            ref,
                          ),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withAlpha(180),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (item.velocityScore / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8),
                  color: velocityColor,
                  backgroundColor: Colors.white.withAlpha(22),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      label: 'median_dom'.tr,
                      value: _formatDays(item.medianDaysOnMarket),
                    ),
                    _InfoPill(
                      label: 'removed_30d'.tr,
                      value: '${item.removedListings30d}',
                    ),
                    _InfoPill(
                      label: 'new_30d'.tr,
                      value: '${item.newListings30d}',
                    ),
                    _InfoPill(
                      label: 'absorption'.tr,
                      value: _formatPercentRatio(item.absorptionRate30d),
                    ),
                    _InfoPill(
                      label: 'removed_vs_new'.tr,
                      value: _formatRatio(item.removalToNewRatio30d),
                    ),
                    _InfoPill(
                      label: 'score'.tr,
                      value: item.velocityScore.toStringAsFixed(1),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _breakdownNarrative(item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(
                      context,
                      ref,
                    ).withAlpha(205),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListingsList(
    BuildContext context,
    List<VelocityListing> listings, {
    required String emptyText,
    required bool fastest,
  }) {
    if (listings.isEmpty) {
      return _buildEmptyBox(context, emptyText);
    }

    return ListView.separated(
      key: ValueKey(fastest ? 'fastest' : 'slowest'),
      itemCount: listings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = listings[index];
        final accentColor = fastest ? Colors.greenAccent : Colors.orangeAccent;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showListingDetails(
            context,
            item,
            fastest: fastest,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withAlpha(18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isEmpty ? 'offer'.tr : item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            ref,
                          ),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _TinyTag(
                            text: item.city.isEmpty ? 'unknown_city'.tr : item.city,
                          ),
                          _TinyTag(
                            text: item.estateType.isEmpty
                                ? 'Unknown'.tr
                                : item.estateType,
                          ),
                          _TinyTag(
                            text: item.offerType.isEmpty
                                ? 'Unknown'.tr
                                : item.offerType,
                          ),
                          _TinyTag(
                            text: item.marketType.isEmpty
                                ? 'Unknown'.tr
                                : item.marketType,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDays(item.daysOnMarket),
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withAlpha(170),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendDetails(BuildContext context, MarketVelocity velocity) {
    final data = velocity.trend;
    if (data.isEmpty) {
      return _buildEmptyBox(
        context,
        _emptyDataText('trend', velocity),
      );
    }

    return Column(
      key: const ValueKey('trend'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context,
          'trend_deep_dive'.tr,
          'trend_deep_dive_subtitle'.tr,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: widget.isMobile ? 160 : 180,
          child: _buildTrendChartLarge(context, velocity),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = data[index];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.periodLabel,
                      style: TextStyle(
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          ref,
                        ),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(label: 'new_label'.tr, value: '${item.newListings}'),
                        _InfoPill(
                          label: 'removed_label'.tr,
                          value: '${item.removedListings}',
                        ),
                        _InfoPill(
                          label: 'median_dom'.tr,
                          value: _formatDays(item.medianDaysOnMarket),
                        ),
                        _InfoPill(
                          label: 'removed_vs_new'.tr,
                          value: _formatRatio(item.removalToNewRatio),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChartLarge(BuildContext context, MarketVelocity velocity) {
    final data = velocity.trend;

    return sf_charts.SfCartesianChart(
      plotAreaBorderWidth: 0,
      legend: sf_charts.Legend(
        isVisible: true,
        textStyle: TextStyle(
          color: CustomColors.secondaryWidgetTextColor(context, ref),
          fontSize: 10,
        ),
      ),
      primaryXAxis: sf_charts.CategoryAxis(
        labelStyle: TextStyle(
          color: CustomColors.secondaryWidgetTextColor(context, ref),
          fontSize: widget.isMobile ? 8 : 9,
        ),
        axisLine: const sf_charts.AxisLine(width: 0),
        majorGridLines: const sf_charts.MajorGridLines(width: 0),
        majorTickLines: const sf_charts.MajorTickLines(size: 0),
      ),
      primaryYAxis: sf_charts.NumericAxis(
        labelStyle: TextStyle(
          color: CustomColors.secondaryWidgetTextColor(context, ref),
          fontSize: widget.isMobile ? 8 : 9,
        ),
        axisLine: const sf_charts.AxisLine(width: 0),
        majorGridLines: sf_charts.MajorGridLines(
          width: 0.5,
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(50),
        ),
        majorTickLines: const sf_charts.MajorTickLines(size: 0),
      ),
      tooltipBehavior: sf_charts.TooltipBehavior(
        enable: true,
        color: Colors.black87,
      ),
      series: <sf_charts.CartesianSeries<VelocityTrendPoint, String>>[
        sf_charts.SplineSeries<VelocityTrendPoint, String>(
          dataSource: data,
          name: 'new_label'.tr,
          xValueMapper: (item, _) => item.periodLabel,
          yValueMapper: (item, _) => item.newListings,
          color: Colors.lightBlueAccent,
          width: 2,
          markerSettings: const sf_charts.MarkerSettings(isVisible: true),
        ),
        sf_charts.SplineSeries<VelocityTrendPoint, String>(
          dataSource: data,
          name: 'removed_label'.tr,
          xValueMapper: (item, _) => item.periodLabel,
          yValueMapper: (item, _) => item.removedListings,
          color: Colors.orangeAccent,
          width: 2,
          markerSettings: const sf_charts.MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  String _emptyListingText({
    required bool fastest,
    required MarketVelocity velocity,
  }) {
    if (fastest && !_hasTopFastestPayload(velocity)) {
      return 'no_top_fastest_payload'.tr;
    }
    if (!fastest && !_hasTopSlowestPayload(velocity)) {
      return 'no_top_slowest_payload'.tr;
    }

    switch (_selectedPersona) {
      case VelocityPersona.agent:
        return fastest
            ? 'no_fast_listings_agent'.tr
            : 'no_slow_listings_agent'.tr;
      case VelocityPersona.buyer:
        return fastest
            ? 'no_fast_listings_buyer'.tr
            : 'no_slow_listings_buyer'.tr;
      case VelocityPersona.developer:
        return fastest
            ? 'no_fast_listings_developer'.tr
            : 'no_slow_listings_developer'.tr;
    }
  }

  String _emptyDataText(String section, MarketVelocity velocity) {
    if (section == 'trend' && !_hasTrendPayload(velocity)) {
      return 'no_trend_payload'.tr;
    }

    if (section == 'breakdown' && !_hasBreakdownPayload(velocity)) {
      return 'no_breakdown_payload'.tr;
    }

    switch (_selectedPersona) {
      case VelocityPersona.agent:
        if (section == 'breakdown') {
          return 'no_breakdown_data_agent'.tr;
        }
        if (section == 'trend') {
          return 'no_trend_data_agent'.tr;
        }
        return 'no_data_agent'.tr;
      case VelocityPersona.buyer:
        if (section == 'breakdown') {
          return 'no_breakdown_data_buyer'.tr;
        }
        if (section == 'trend') {
          return 'no_trend_data_buyer'.tr;
        }
        return 'no_data_buyer'.tr;
      case VelocityPersona.developer:
        if (section == 'breakdown') {
          return 'no_breakdown_data_developer'.tr;
        }
        if (section == 'trend') {
          return 'no_trend_data_developer'.tr;
        }
        return 'no_data_developer'.tr;
    }
  }

  Widget _buildEmptyBox(BuildContext context, String text) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(210),
          height: 1.45,
        ),
      ),
    );
  }
}

class _SummaryItem {
  final VelocityFocusMetric metric;
  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  _SummaryItem({
    required this.metric,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;
  final bool isSelected;
  final Color textColor;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.item,
    required this.isSelected,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? item.accent : Colors.white.withAlpha(16);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(isSelected ? 22 : 16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: item.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor.withAlpha(220),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor.withAlpha(185),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: Colors.white),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.white70),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  final String text;

  const _TinyTag({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}