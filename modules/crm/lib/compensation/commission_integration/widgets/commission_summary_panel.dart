import "package:crm/compensation/commission_integration/models/commission_integration_models.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:get/get_utils/get_utils.dart";
import "package:core/theme/apptheme.dart";
import "package:core/theme/text_field.dart";

class CommissionSummaryPanel extends ConsumerWidget {
  final CommissionSummaryModel summary;
  final bool isMobile;
  final bool isLoading;
  final String? title;
  final VoidCallback? onSync;
  final VoidCallback? onAssignTransaction;
  final ValueChanged<int>? onOpenInvoice;
  final ValueChanged<int>? onOpenTransaction;
  final ValueChanged<int>? onOpenSettlement;

  const CommissionSummaryPanel({
    super.key,
    required this.summary,
    this.isMobile = false,
    this.isLoading = false,
    this.title,
    this.onSync,
    this.onAssignTransaction,
    this.onOpenInvoice,
    this.onOpenTransaction,
    this.onOpenSettlement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            title: title ?? "commission_connections".tr,
            isLoading: isLoading,
            onSync: onSync,
            onAssignTransaction: onAssignTransaction,
          ),
          Divider(
            height: 1,
            color: theme.dashboardBoarder,
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Metrics(
                  summary: summary,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),
                if (!summary.hasEvents)
                  _EmptyState(
                    canSync: onSync != null,
                    isLoading: isLoading,
                    onSync: onSync,
                  )
                else
                  Column(
                    children: [
                      for (final item in summary.items) ...[
                        _EventCard(
                          item: item,
                          isMobile: isMobile,
                          onOpenInvoice: onOpenInvoice,
                          onOpenTransaction: onOpenTransaction,
                          onOpenSettlement: onOpenSettlement,
                        ),
                        if (item != summary.items.last)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final String title;
  final bool isLoading;
  final VoidCallback? onSync;
  final VoidCallback? onAssignTransaction;

  const _Header({
    required this.title,
    required this.isLoading,
    required this.onSync,
    required this.onAssignTransaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(24),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: theme.themeColor.withAlpha(60),
              ),
            ),
            child: Icon(
              Icons.account_tree_outlined,
              color: theme.themeColor,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "commission_connections_hint".tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(150),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onAssignTransaction != null) ...[
            CoreOutlinedButton(
              onPressed: isLoading ? null : onAssignTransaction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_rounded, size: 17),
                  const SizedBox(width: 6),
                  Text("assign_transaction".tr),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (onSync != null)
            CoreFilledButton(
              onPressed: isLoading ? null : onSync,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Icon(Icons.sync_rounded, size: 17),
                  const SizedBox(width: 6),
                  Text("sync_commission".tr),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  final CommissionSummaryModel summary;
  final bool isMobile;

  const _Metrics({
    required this.summary,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricData(
        label: "company_commission".tr,
        value: _money(
          summary.sourceCompanyCommission,
          summary.currency,
        ),
        icon: Icons.business_center_outlined,
      ),
      _MetricData(
        label: "employee_commission".tr,
        value: _money(
          summary.calculatedEmployeeCommission,
          summary.currency,
        ),
        icon: Icons.badge_outlined,
      ),
      _MetricData(
        label: "commission_events".tr,
        value: summary.eventsCount.toString(),
        icon: Icons.bolt_outlined,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            _MetricCard(data: cards[index]),
            if (index < cards.length - 1)
              const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          Expanded(child: _MetricCard(data: cards[index])),
          if (index < cards.length - 1)
            const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;

  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _MetricCard extends ConsumerWidget {
  final _MetricData data;

  const _MetricCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              data.icon,
              size: 20,
              color: theme.themeColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(150),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends ConsumerWidget {
  final CommissionEventItemModel item;
  final bool isMobile;
  final ValueChanged<int>? onOpenInvoice;
  final ValueChanged<int>? onOpenTransaction;
  final ValueChanged<int>? onOpenSettlement;

  const _EventCard({
    required this.item,
    required this.isMobile,
    required this.onOpenInvoice,
    required this.onOpenTransaction,
    required this.onOpenSettlement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final statusColor = _statusColor(item.eventStatus, theme.themeColor);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _triggerIcon(item.trigger),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.eventLabel.isEmpty
                          ? _eventLabel(item.eventType)
                          : item.eventLabel,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Badge(
                          text: _eventLabel(item.eventType),
                          color: theme.themeColor,
                        ),
                        _Badge(
                          text: _statusLabel(item.eventStatus),
                          color: statusColor,
                        ),
                        _Badge(
                          text: _basisLabel(item.basisKind),
                          color: theme.textColor.withAlpha(150),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(
                      item.calculatedCommission,
                      item.currency,
                    ),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${"basis".tr}: ${_money(item.basisAmount, item.currency)}",
                    style: TextStyle(
                      color: theme.textColor.withAlpha(140),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (item.transactionId != null ||
              item.invoiceId != null ||
              item.settlementLines.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: theme.dashboardBoarder,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.transactionId != null)
                  _SourceButton(
                    icon: Icons.handshake_outlined,
                    label:
                        "${"transaction".tr} #${item.transactionId}",
                    onPressed: onOpenTransaction == null
                        ? null
                        : () => onOpenTransaction!(
                              item.transactionId!,
                            ),
                  ),
                if (item.invoiceId != null)
                  _SourceButton(
                    icon: Icons.receipt_long_outlined,
                    label: "${"invoice".tr} #${item.invoiceId}",
                    onPressed: onOpenInvoice == null
                        ? null
                        : () => onOpenInvoice!(item.invoiceId!),
                  ),
                for (final line in item.settlementLines)
                  _SourceButton(
                    icon: Icons.account_balance_wallet_outlined,
                    label:
                        "${"settlement".tr} #${line.settlementId}",
                    onPressed: onOpenSettlement == null
                        ? null
                        : () => onOpenSettlement!(
                              line.settlementId,
                            ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceButton extends ConsumerWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      color: theme.dashboardContainer,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.themeColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onPressed != null) ...[
                const SizedBox(width: 5),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: theme.textColor.withAlpha(130),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final bool canSync;
  final bool isLoading;
  final VoidCallback? onSync;

  const _EmptyState({
    required this.canSync,
    required this.isLoading,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.account_tree_outlined,
              color: theme.themeColor,
              size: 27,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "no_commission_events".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "no_commission_events_hint".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor.withAlpha(150),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          if (canSync) ...[
            const SizedBox(height: 14),
            CoreFilledButton(
              onPressed: isLoading ? null : onSync,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync_rounded, size: 17),
                  const SizedBox(width: 6),
                  Text("sync_commission".tr),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _money(double value, String currency) {
  return "${value.toStringAsFixed(2)} $currency";
}

String _eventLabel(String value) {
  return "commission_event_${value.replaceAll(".", "_")}".tr;
}

String _statusLabel(String value) {
  return "commission_event_status_$value".tr;
}

String _basisLabel(String value) {
  return "commission_basis_$value".tr;
}

IconData _triggerIcon(String trigger) {
  return switch (trigger) {
    "transaction_closed" => Icons.handshake_outlined,
    "invoice_issued" => Icons.receipt_long_outlined,
    "invoice_paid" => Icons.price_check_outlined,
    _ => Icons.tune_outlined,
  };
}

Color _statusColor(String status, Color accentColor) {
  return switch (status) {
    "settled" => Colors.green,
    "eligible" => accentColor,
    "pending" => Colors.orange,
    "cancelled" => Colors.redAccent,
    _ => accentColor,
  };
}
