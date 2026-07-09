import 'package:crm/crm/finance/charts/chart_settings.dart';
import 'package:crm/crm/finance/dashboard/model_dashboard.dart';

class FinanceChartDayData {
  final DateTime date;
  double revenue;
  double expenses;
  double unpaidRevenue;
  double unpaidExpenses;

  FinanceChartDayData({
    required this.date,
    this.revenue = 0,
    this.expenses = 0,
    this.unpaidRevenue = 0,
    this.unpaidExpenses = 0,
  });
}

/// Build daily buckets based on selected range.
List<FinanceChartDayData> buildFinanceChartData(
  FinanceChartRange range,
  List<UnifiedTransactionModel> all,
) {
  final now = DateTime.now();
  final start = switch (range) {
    FinanceChartRange.week =>
      now.subtract(const Duration(days: 6)),
    FinanceChartRange.month =>
      now.subtract(const Duration(days: 29)),
    FinanceChartRange.year =>
      now.subtract(const Duration(days: 364)),
  };

  final Map<DateTime, FinanceChartDayData> byDay = {};

  DateTime normalize(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  final startDay = normalize(start);
  final endDay = normalize(now);

  for (final tx in all) {
    final raw = tx.paymentDateRaw ?? now;
    final date = normalize(raw);
    if (date.isBefore(startDay) || date.isAfter(endDay)) {
      continue;
    }

    byDay.putIfAbsent(date, () => FinanceChartDayData(date: date));
    final dayData = byDay[date]!;

    final amount = tx.amountValue;

    if (tx.kind == UnifiedTransactionKind.revenue) {
      if (tx.isPaid) {
        dayData.revenue += amount;
      } else {
        dayData.unpaidRevenue += amount;
      }
    } else {
      if (tx.isPaid) {
        dayData.expenses += amount;
      } else {
        dayData.unpaidExpenses += amount;
      }
    }
  }

  final List<FinanceChartDayData> result = [];
  DateTime cursor = startDay;

  while (!cursor.isAfter(endDay)) {
    result.add(byDay[cursor] ?? FinanceChartDayData(date: cursor));
    cursor = cursor.add(const Duration(days: 1));
  }

  return result;
}
