import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/backgroundgradient.dart';

class ReportStatCard extends ConsumerWidget {
  final String title;
  final String value;
  final double? percentage;
  final String? subtitle;
  final bool positiveWhenDown;
  final IconData icon;

  const ReportStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.percentage,
    this.subtitle,
    this.positiveWhenDown = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTrend = percentage != null;
    final trendValue = percentage ?? 0.0;

    final isPositive =
        positiveWhenDown ? trendValue <= 0 : trendValue >= 0;

    final trendColor = isPositive ? Colors.greenAccent : Colors.redAccent;
    final trendIcon =
        trendValue >= 0 ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: CustomColors.secondaryWidgetTextColor(context, ref),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CustomColors.secondaryWidgetTextColor(context, ref),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (hasTrend) ...[
                Icon(
                  trendIcon,
                  color: trendColor,
                  size: 17,
                ),
                const SizedBox(width: 4),
                Text(
                  '${trendValue > 0 ? '+' : ''}${trendValue.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  subtitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(
                      context,
                      ref,
                    ).withAlpha(210),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}