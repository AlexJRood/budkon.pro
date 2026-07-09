import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:association/models/overview_models.dart';
import 'package:association/providers/overview_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:get/get_utils/get_utils.dart';



// ---------- UI Widgets ----------

class AssociationOverviewRow extends ConsumerWidget {
  /// Optional: force association id. When null, backend will infer.
  final int? associationId;
  final ThemeColors theme;
  /// Window size for "recent" & averages.
  final int days;

  const AssociationOverviewRow({
    super.key,
    this.associationId,
    required this.theme,
    this.days = 30,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(associationOverviewProvider((associationId: associationId, days: days))
    );

    return async.when(
      data: (data) => _OverviewContent(data: data, theme: theme),
      loading: () => const _OverviewSkeleton(),
      error: (e, st) => _OverviewError(error: e.toString()),
    );
  }
}

class _OverviewContent extends StatelessWidget {
  final AssociationOverview data;
  final ThemeColors theme;
  const _OverviewContent({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('0.00');
    final items = <_MetricTileData>[
      _MetricTileData(
        title: 'numbers_of_members'.tr,
        primary: '${data.membersTotal.count}',
        secondary: nf.format(data.membersTotal.avgPerDay),
      ),
      _MetricTileData(
        title: 'pending_requests'.tr,
        primary: '${data.pendingRequests.count}',
        secondary: nf.format(data.pendingRequests.avgPerDay),
      ),
      _MetricTileData(
        title: 'active_offers'.tr,
        primary: '${data.activeOffers.count}',
        secondary: nf.format(data.activeOffers.avgPerDay),
      ),
      _MetricTileData(
        title: 'recent_announcements'.tr,
        primary: '${data.recentAnnouncements.count}',
        secondary: nf.format(data.recentAnnouncements.avgPerDay),
      ),
    ];

    // Responsive: compact spacing on small screens.
    final isSmall = MediaQuery.of(context).size.width < 700;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: isSmall ? 4 : 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Expanded(child: _MetricTile(item: items[i], theme: theme)),
              if (i != items.length - 1)
                _VerticalDivider(height: 40, opacity: 0.2),
            ]
          ],
        ),
      ),
    );
  }
}

class _MetricTileData {
  final String title;
  final String primary;   // count
  final String secondary; // avg per day
  _MetricTileData({required this.title, required this.primary, required this.secondary});
}

class _MetricTile extends StatelessWidget {
  final _MetricTileData item;
  final ThemeColors theme;
  const _MetricTile({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(color: theme.textColor, fontWeight: FontWeight.w700, fontSize: 18);
    final primaryStyle = TextStyle(color: theme.textColor.withAlpha(200), fontWeight: FontWeight.w700, fontSize: 14);
    final secondaryStyle = TextStyle(color: theme.textColor.withAlpha(170), fontWeight: FontWeight.w700, fontSize: 12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(item.primary, style: primaryStyle),
              const SizedBox(width: 6),
              Text('/ ${item.secondary}', style: secondaryStyle),
            ],
          ),
        ],
      ),
    );
  }
}




class _VerticalDivider extends StatelessWidget {
  final double height;
  final double opacity;
  const _VerticalDivider({this.height = 48, this.opacity = 0.15});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).dividerColor.withAlpha(((opacity as num).clamp(0, 1) * 255).round());
    return Container(
      width: 1,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: color,
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box() => Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withAlpha(38),
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return Row(
      children: [
        Expanded(child: box()),
        const _VerticalDivider(),
        Expanded(child: box()),
        const _VerticalDivider(),
        Expanded(child: box()),
        const _VerticalDivider(),
        Expanded(child: box()),
      ],
    );
  }
}

class _OverviewError extends StatelessWidget {
  final String error;
  const _OverviewError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 8),
        Expanded(child: Text(error, maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
