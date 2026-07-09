import "package:crm/compensation/commission_integration/models/commission_integration_models.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:get/get_utils/get_utils.dart";
import "package:core/theme/apptheme.dart";

class CommissionSourcePanel extends ConsumerWidget {
  final CommissionSourceModel source;
  final double? percentageRate;
  final double? calculatedAmount;
  final String? calculatedCurrency;
  final bool isMobile;
  final ValueChanged<int>? onOpenTransaction;
  final ValueChanged<int>? onOpenInvoice;

  const CommissionSourcePanel({
    super.key,
    required this.source,
    this.percentageRate,
    this.calculatedAmount,
    this.calculatedCurrency,
    this.isMobile = false,
    this.onOpenTransaction,
    this.onOpenInvoice,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: theme.themeColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.account_tree_outlined,
                  color: theme.themeColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "commission_source".tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "commission_source_hint".tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(145),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _Badge(
                text:
                    "commission_basis_${source.basisKind}".tr,
                color: theme.themeColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (source.transaction != null)
            _SourceCard(
              icon: Icons.handshake_outlined,
              title: source.transaction!.name,
              subtitle: [
                source.transaction!.transactionType,
                "ID: ${source.transaction!.id}",
              ].where((value) => value.trim().isNotEmpty).join(" • "),
              rows: [
                _SourceRowData(
                  label: "transaction_value".tr,
                  value: _money(
                    source.transaction!.value,
                    source.currency,
                  ),
                ),
                _SourceRowData(
                  label: "company_commission".tr,
                  value: _money(
                    source.transaction!.companyCommission,
                    source.currency,
                  ),
                ),
              ],
              onTap: onOpenTransaction == null
                  ? null
                  : () => onOpenTransaction!(
                        source.transaction!.id,
                      ),
            ),
          if (source.transaction != null && source.invoice != null)
            const SizedBox(height: 10),
          if (source.invoice != null)
            _SourceCard(
              icon: Icons.receipt_long_outlined,
              title: source.invoice!.invoiceNumber,
              subtitle: "ID: ${source.invoice!.id}",
              rows: [
                _SourceRowData(
                  label: "invoice_net_amount".tr,
                  value: _money(
                    source.invoice!.netAmount,
                    source.currency,
                  ),
                ),
                _SourceRowData(
                  label: "invoice_tax_amount".tr,
                  value: _money(
                    source.invoice!.taxAmount,
                    source.currency,
                  ),
                ),
                _SourceRowData(
                  label: "invoice_gross_amount".tr,
                  value: _money(
                    source.invoice!.grossAmount,
                    source.currency,
                  ),
                ),
              ],
              onTap: onOpenInvoice == null
                  ? null
                  : () => onOpenInvoice!(source.invoice!.id),
            ),
          const SizedBox(height: 12),
          _CalculationFlow(
            source: source,
            percentageRate: percentageRate,
            calculatedAmount: calculatedAmount,
            calculatedCurrency:
                calculatedCurrency ?? source.currency,
          ),
        ],
      ),
    );
  }
}

class _CalculationFlow extends ConsumerWidget {
  final CommissionSourceModel source;
  final double? percentageRate;
  final double? calculatedAmount;
  final String calculatedCurrency;

  const _CalculationFlow({
    required this.source,
    required this.percentageRate,
    required this.calculatedAmount,
    required this.calculatedCurrency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final parts = <Widget>[
      _FlowValue(
        label: "basis".tr,
        value: _money(source.basisAmount, source.currency),
      ),
      if (percentageRate != null)
        _FlowValue(
          label: "rate".tr,
          value: "${percentageRate!.toStringAsFixed(4)}%",
        ),
      if (calculatedAmount != null)
        _FlowValue(
          label: "employee_commission".tr,
          value: _money(
            calculatedAmount!,
            calculatedCurrency,
          ),
          highlighted: true,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              children: [
                for (var index = 0; index < parts.length; index++) ...[
                  parts[index],
                  if (index < parts.length - 1) ...[
                    const SizedBox(height: 7),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.textColor.withAlpha(120),
                    ),
                    const SizedBox(height: 7),
                  ],
                ],
              ],
            );
          }

          return Row(
            children: [
              for (var index = 0; index < parts.length; index++) ...[
                Expanded(child: parts[index]),
                if (index < parts.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: theme.textColor.withAlpha(120),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FlowValue extends ConsumerWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _FlowValue({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textColor.withAlpha(145),
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                highlighted ? theme.themeColor : theme.textColor,
            fontWeight: FontWeight.w900,
            fontSize: highlighted ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

class _SourceRowData {
  final String label;
  final String value;

  const _SourceRowData({
    required this.label,
    required this.value,
  });
}

class _SourceCard extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_SourceRowData> rows;
  final VoidCallback? onTap;

  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      color: theme.adPopBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: theme.themeColor,
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: theme.textColor.withAlpha(140),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.textColor.withAlpha(130),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: theme.dashboardBoarder,
              ),
              const SizedBox(height: 9),
              for (var index = 0; index < rows.length; index++) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rows[index].label,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(145),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      rows[index].value,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                if (index < rows.length - 1)
                  const SizedBox(height: 6),
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

String _money(double value, String currency) {
  return "${value.toStringAsFixed(2)} $currency";
}
