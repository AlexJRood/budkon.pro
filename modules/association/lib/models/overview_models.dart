// lib/association/dashboard_overview_widget.dart


// ---------- Models ----------

class OverviewMetric {
  final int count;
  final double avgPerDay;
  OverviewMetric({required this.count, required this.avgPerDay});

  factory OverviewMetric.fromJson(Map<String, dynamic> json) {
    return OverviewMetric(
      count: (json['count'] ?? 0) as int,
      avgPerDay: (json['avg_per_day'] ?? 0).toDouble(),
    );
  }
}

class AssociationOverview {
  final int associationId;
  final int windowDays;
  final OverviewMetric membersTotal;
  final OverviewMetric pendingRequests;
  final OverviewMetric activeOffers;
  final OverviewMetric recentAnnouncements;

  AssociationOverview({
    required this.associationId,
    required this.windowDays,
    required this.membersTotal,
    required this.pendingRequests,
    required this.activeOffers,
    required this.recentAnnouncements,
  });

  factory AssociationOverview.fromJson(Map<String, dynamic> json) {
    final m = json['metrics'] as Map<String, dynamic>? ?? {};
    OverviewMetric _m(String key) =>
        OverviewMetric.fromJson((m[key] as Map<String, dynamic>? ?? const {}));

    return AssociationOverview(
      associationId: json['association_id'] is int
          ? json['association_id']
          : int.tryParse('${json['association_id']}') ?? 0,
      windowDays: json['window_days'] ?? 30,
      membersTotal: _m('members_total'),
      pendingRequests: _m('pending_requests'),
      activeOffers: _m('active_offers'),
      recentAnnouncements: _m('recent_announcements'),
    );
  }
}


