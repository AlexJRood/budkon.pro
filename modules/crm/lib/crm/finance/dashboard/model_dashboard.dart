import 'package:crm/shared/models/revenue_model.dart';
import 'package:crm/shared/models/transaction/transaction_expenses_model.dart';

enum UnifiedTransactionKind { revenue, expense }

String _formatDate(DateTime? dt) {
  if (dt == null) return '-';
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final y = dt.year.toString();
  return '$d.$m.$y';
}

String _safeNameFromDynamic(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is int) return value.toString();
  if (value is Map) {
    final n = value['name'];
    if (n is String) return n;
    return value.toString();
  }
  return value.toString();
}

class UnifiedTransactionModel {
  final UnifiedTransactionKind kind;
  final AgentRevenueModel? revenue;
  final TransactionExpensesModel? expense;

  const UnifiedTransactionModel._({
    required this.kind,
    this.revenue,
    this.expense,
  });

  factory UnifiedTransactionModel.fromRevenue(AgentRevenueModel r) {
    return UnifiedTransactionModel._(
      kind: UnifiedTransactionKind.revenue,
      revenue: r,
    );
  }

  factory UnifiedTransactionModel.fromExpense(TransactionExpensesModel e) {
    return UnifiedTransactionModel._(
      kind: UnifiedTransactionKind.expense,
      expense: e,
    );
  }

  int get id => switch (kind) {
        UnifiedTransactionKind.revenue => revenue!.id,
        UnifiedTransactionKind.expense => expense!.id,
      };

  String get name => switch (kind) {
        UnifiedTransactionKind.revenue => revenue!.name ?? '',
        UnifiedTransactionKind.expense => expense!.name ?? '',
      };

  String get typeLabel => switch (kind) {
        UnifiedTransactionKind.revenue => revenue!.transactionType ?? '',
        UnifiedTransactionKind.expense => expense!.transactionType ?? '',
      };

  double get amountValue {
    final String raw = switch (kind) {
      UnifiedTransactionKind.revenue => revenue!.amount,
      UnifiedTransactionKind.expense => expense!.totalAmount,
    };
    return double.tryParse(raw) ?? 0.0;
  }

  String get amountWithCurrency {
    final String amount = switch (kind) {
      UnifiedTransactionKind.revenue => revenue!.amount,
      UnifiedTransactionKind.expense => expense!.totalAmount,
    };
    final String currency = switch (kind) {
      UnifiedTransactionKind.revenue => revenue!.currency,
      UnifiedTransactionKind.expense => expense!.currency,
    };
    return '$amount $currency';
  }

  DateTime? get paymentDateRaw => switch (kind) {
        UnifiedTransactionKind.revenue => revenue!.paymentDate,
        UnifiedTransactionKind.expense => expense!.paymentDate,
      };

  String get paymentDateHuman => _formatDate(paymentDateRaw);

  bool get isPaid => switch (kind) {
        UnifiedTransactionKind.revenue => revenue!.isPaid,
        UnifiedTransactionKind.expense => expense!.isPaid,
      };

  String get clientOrContractorName => switch (kind) {
        UnifiedTransactionKind.revenue => _safeNameFromDynamic(revenue!.clients),
        UnifiedTransactionKind.expense =>
          _safeNameFromDynamic(expense!.contractor) != ''
              ? _safeNameFromDynamic(expense!.contractor)
              : _safeNameFromDynamic(expense!.clients),
      };

  String get note => switch (kind) {
        UnifiedTransactionKind.revenue => revenue!.note ?? '',
        UnifiedTransactionKind.expense => expense!.note ?? '',
      };
}
