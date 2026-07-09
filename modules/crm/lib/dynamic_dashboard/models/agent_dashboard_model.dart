class DashboardMetrics {
  final String period;
  final String? previousPeriod;
  final TransactionsData transactions;
  final RevenueData revenue;
  final ExpensesData expenses;
  final ContactsData contacts;
  final double? averageTimeToClose;
  final ComparisonData? compareToPrevious;

  DashboardMetrics({
    required this.period,
    required this.previousPeriod,
    required this.transactions,
    required this.revenue,
    required this.expenses,
    required this.contacts,
    required this.averageTimeToClose,
    required this.compareToPrevious,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      period: json['period'],
      previousPeriod: json['previous_period'],
      transactions: TransactionsData.fromJson(json['transactions']),
      revenue: RevenueData.fromJson(json['revenue']),
      expenses: ExpensesData.fromJson(json['expenses']),
      contacts: ContactsData.fromJson(json['contacts']),
      averageTimeToClose: (json['average_time_to_close'] as num?)?.toDouble(),
      compareToPrevious: json['compare_to_previous'] != null
          ? ComparisonData.fromJson(json['compare_to_previous'])
          : null,
    );
  }
  @override
  String toString() {
    return 'Transactions: ${transactions.total}, Revenue: ${revenue.expectedCommissions}, Contacts: ${contacts.total}';
  }

}

class TransactionsData {
  final int total;
  final int closed;
  final int success;
  final int failed;
  final int newOnes;
  final double conversionRatePeriod;
  final double conversionRateLifetime;

  TransactionsData({
    required this.total,
    required this.closed,
    required this.success,
    required this.failed,
    required this.newOnes,
    required this.conversionRatePeriod,
    required this.conversionRateLifetime,
  });

  factory TransactionsData.fromJson(Map<String, dynamic> json) {
    return TransactionsData(
      total: json['total'],
      closed: json['closed'],
      success: json['success'],
      failed: json['failed'],
      newOnes: json['new'],
      conversionRatePeriod: (json['conversion_rate_period'] as num).toDouble(),
      conversionRateLifetime:
          (json['conversion_rate_lifetime'] as num).toDouble(),
    );
  }
}

class RevenueData {
  final double closedCommissions;
  final double expectedCommissions;
  final double failedCommissions;

  RevenueData({
    required this.closedCommissions,
    required this.expectedCommissions,
    required this.failedCommissions,
  });

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      closedCommissions: (json['closed_commissions'] as num).toDouble(),
      expectedCommissions: (json['expected_commissions'] as num).toDouble(),
      failedCommissions: (json['failed_commissions'] as num).toDouble(),
    );
  }
}

class ExpensesData {
  final double total;

  ExpensesData({required this.total});

  factory ExpensesData.fromJson(Map<String, dynamic> json) {
    return ExpensesData(
      total: (json['total'] as num).toDouble(),
    );
  }
}

class ContactsData {
  final int total;
  final int? contactTypeId;

  ContactsData({required this.total, this.contactTypeId});

  factory ContactsData.fromJson(Map<String, dynamic> json) {
    return ContactsData(
      total: json['total'],
      contactTypeId: json['contact_type_id'],
    );
  }
}

class ComparisonValue {
  final num current;
  final num previous;
  final double changePercent;

  ComparisonValue({
    required this.current,
    required this.previous,
    required this.changePercent,
  });

  factory ComparisonValue.fromJson(Map<String, dynamic> json) {
    return ComparisonValue(
      current: json['current'],
      previous: json['previous'],
      changePercent: (json['change_percent'] as num).toDouble(),
    );
  }
}

class ComparisonData {
  final Map<String, ComparisonValue> transactions;
  final Map<String, ComparisonValue> revenue;
  final Map<String, ComparisonValue> expenses;
  final Map<String, ComparisonValue> contacts;
  final ComparisonValue? averageTimeToClose;

  ComparisonData({
    required this.transactions,
    required this.revenue,
    required this.expenses,
    required this.contacts,
    this.averageTimeToClose,
  });

  factory ComparisonData.fromJson(Map<String, dynamic> json) {
    Map<String, ComparisonValue> parseSection(Map data) =>
        data.map((k, v) => MapEntry(k, ComparisonValue.fromJson(v)));

    return ComparisonData(
      transactions: parseSection(json['transactions']),
      revenue: parseSection(json['revenue']),
      expenses: parseSection(json['expenses']),
      contacts: parseSection(json['contacts']),
      averageTimeToClose: json['average_time_to_close'] != null
          ? ComparisonValue.fromJson(json['average_time_to_close'])
          : null,
    );
  }
}


class DashboardSettings {
  final int? contactTypeId;
  final String commissionDisplay;

  DashboardSettings({
    this.contactTypeId,
    required this.commissionDisplay,
  });

  factory DashboardSettings.fromJson(Map<String, dynamic> json) {
    return DashboardSettings(
      contactTypeId: json['contact_type_id'],
      commissionDisplay: json['commission_display'] ?? 'expected',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact_type_id': contactTypeId,
      'commission_display': commissionDisplay,
    };
  }

  DashboardSettings copyWith({
    int? contactTypeId,
    String? commissionDisplay,
  }) {
    return DashboardSettings(
      contactTypeId: contactTypeId ?? this.contactTypeId,
      commissionDisplay: commissionDisplay ?? this.commissionDisplay,
    );
  }
}
