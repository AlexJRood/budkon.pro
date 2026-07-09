import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FinanceTxType { revenue, expense }

/// ------------------------------
/// Helpers (null-safe)
/// ------------------------------
List<String> _safeStringList(dynamic v) {
  if (v == null) return const <String>[];
  if (v is List<String>) return List.unmodifiable(v);
  if (v is List) {
    // Convert dynamic list to string list (ignore nulls and non-strings)
    final out = <String>[];
    for (final item in v) {
      if (item == null) continue;
      out.add(item.toString());
    }
    return List.unmodifiable(out);
  }
  return const <String>[];
}

String? _safeNullableString(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

int? _safeNullableInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

DateTime? _safeNullableDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;

  final s = v.toString().trim();
  if (s.isEmpty) return null;

  // Accept "YYYY-MM-DD" or full ISO
  return DateTime.tryParse(s);
}

bool? _safeNullableBoolAny(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;

  final s = v.toString().trim().toLowerCase();
  if (s.isEmpty || s == 'any' || s == 'all') return null;
  if (s == '1' || s == 'true' || s == 'yes' || s == 'y') return true;
  if (s == '0' || s == 'false' || s == 'no' || s == 'n') return false;

  return null;
}

String _fmtIsoDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

@immutable
class FinanceFilters {
  final String search;

  /// date_create_desc | date_create_asc | amount_desc | amount_asc | date_update_desc | payment_date_desc ...
  final String sort;

  /// null = any, true = paid, false = unpaid
  final bool? paid;

  /// null = any
  final String? currency;

  /// Multi-select filters
  final List<String> paymentMethods; // e.g. ["bank", "card"]
  final List<String> transactionTypes; // e.g. ["sale", "rent"]

  /// Amount range
  final String? amountMin;
  final String? amountMax;

  /// Created date range (date_create)
  final DateTime? createdFrom;
  final DateTime? createdTo;

  /// Tags (JSON list field on backend) - OR semantics ("any of")
  final List<String> tagsAny;

  /// Invoice template filter
  final int? invoiceTemplateId;

  const FinanceFilters({
    required this.search,
    required this.sort,
    required this.paid,
    required this.currency,
    required this.paymentMethods,
    required this.transactionTypes,
    required this.amountMin,
    required this.amountMax,
    required this.createdFrom,
    required this.createdTo,
    required this.tagsAny,
    required this.invoiceTemplateId,
  });

  factory FinanceFilters.initial() => const FinanceFilters(
        search: '',
        sort: 'date_create_desc',
        paid: null,
        currency: null,
        paymentMethods: <String>[],
        transactionTypes: <String>[],
        amountMin: null,
        amountMax: null,
        createdFrom: null,
        createdTo: null,
        tagsAny: <String>[],
        invoiceTemplateId: null,
      );

  /// ✅ Null-safe factory to migrate old saved states / maps / json
  factory FinanceFilters.fromMap(Map<String, dynamic>? map) {
    final m = map ?? const <String, dynamic>{};

    return FinanceFilters(
      search: (m['search'] ?? '').toString(),
      sort: (m['sort'] ?? 'date_create_desc').toString(),

      paid: _safeNullableBoolAny(m['paid']),
      currency: _safeNullableString(m['currency'])?.toUpperCase(),

      paymentMethods: _safeStringList(m['payment_methods'] ?? m['paymentMethods']),
      transactionTypes: _safeStringList(m['transaction_type'] ?? m['transactionTypes']),

      amountMin: _safeNullableString(m['amount_min'] ?? m['amountMin']),
      amountMax: _safeNullableString(m['amount_max'] ?? m['amountMax']),

      createdFrom: _safeNullableDate(m['created_from'] ?? m['createdFrom']),
      createdTo: _safeNullableDate(m['created_to'] ?? m['createdTo']),

      tagsAny: _safeStringList(m['tags_any'] ?? m['tagsAny']),
      invoiceTemplateId: _safeNullableInt(m['invoice_template'] ?? m['invoiceTemplateId']),
    );
  }

  /// Optional, but useful for saving in prefs/db
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'search': search,
      'sort': sort,
      'paid': paid, // can be null
      'currency': currency,
      'payment_methods': paymentMethods,
      'transaction_type': transactionTypes,
      'amount_min': amountMin,
      'amount_max': amountMax,
      'created_from': createdFrom?.toIso8601String(),
      'created_to': createdTo?.toIso8601String(),
      'tags_any': tagsAny,
      'invoice_template': invoiceTemplateId,
    };
  }

  FinanceFilters copyWith({
    String? search,
    String? sort,

    bool? paid,
    bool paidSet = false, // allows explicit null

    String? currency,
    bool currencySet = false, // allows explicit null

    List<String>? paymentMethods,
    List<String>? transactionTypes,

    String? amountMin,
    bool amountMinSet = false,

    String? amountMax,
    bool amountMaxSet = false,

    DateTime? createdFrom,
    bool createdFromSet = false,

    DateTime? createdTo,
    bool createdToSet = false,

    List<String>? tagsAny,

    int? invoiceTemplateId,
    bool invoiceTemplateIdSet = false,
  }) {
    return FinanceFilters(
      search: search ?? this.search,
      sort: sort ?? this.sort,

      paid: paidSet ? paid : this.paid,
      currency: currencySet ? currency : this.currency,

      // ✅ Always keep lists non-null
      paymentMethods: List.unmodifiable(paymentMethods ?? this.paymentMethods),
      transactionTypes: List.unmodifiable(transactionTypes ?? this.transactionTypes),

      amountMin: amountMinSet ? amountMin : this.amountMin,
      amountMax: amountMaxSet ? amountMax : this.amountMax,

      createdFrom: createdFromSet ? createdFrom : this.createdFrom,
      createdTo: createdToSet ? createdTo : this.createdTo,

      tagsAny: List.unmodifiable(tagsAny ?? this.tagsAny),

      invoiceTemplateId:
          invoiceTemplateIdSet ? invoiceTemplateId : this.invoiceTemplateId,
    );
  }

  /// ✅ Query params for backend.
  /// Lists stay as List<String> - your http client should expand them as repeated keys.
  Map<String, dynamic> toQueryParams() {
    final qp = <String, dynamic>{};

    final s = search.trim();
    if (s.isNotEmpty) qp['search'] = s;

    final so = sort.trim();
    if (so.isNotEmpty) qp['sort'] = so;

    if (paid != null) {
      qp['paid'] = paid == true ? '1' : '0';
    }

    if (currency != null && currency!.trim().isNotEmpty) {
      qp['currency'] = currency!.trim().toUpperCase();
    }

    if (amountMin != null && amountMin!.trim().isNotEmpty) {
      qp['amount_min'] = amountMin!.trim();
    }
    if (amountMax != null && amountMax!.trim().isNotEmpty) {
      qp['amount_max'] = amountMax!.trim();
    }

    if (createdFrom != null) qp['created_from'] = _fmtIsoDate(createdFrom!);
    if (createdTo != null) qp['created_to'] = _fmtIsoDate(createdTo!);

    if (paymentMethods.isNotEmpty) qp['payment_methods'] = paymentMethods;
    if (transactionTypes.isNotEmpty) qp['transaction_type'] = transactionTypes;
    if (tagsAny.isNotEmpty) qp['tags_any'] = tagsAny;

    if (invoiceTemplateId != null) {
      qp['invoice_template'] = invoiceTemplateId.toString();
    }

    return qp;
  }
}

class FinanceFiltersNotifier extends StateNotifier<FinanceFilters> {
  FinanceFiltersNotifier() : super(FinanceFilters.initial());

  void setSearch(String value) =>
      state = state.copyWith(search: value.trim());

  void setSort(String value) =>
      state = state.copyWith(sort: value.trim());

  void setPaid(bool? value) =>
      state = state.copyWith(paid: value, paidSet: true);

  void setCurrency(String? value) => state = state.copyWith(
        currency: (value == null || value.trim().isEmpty)
            ? null
            : value.trim().toUpperCase(),
        currencySet: true,
      );

  void setPaymentMethods(List<String> values) =>
      state = state.copyWith(paymentMethods: List.unmodifiable(values));

  void togglePaymentMethod(String value) {
    final v = value.trim();
    if (v.isEmpty) return;

    final list = [...state.paymentMethods];
    if (list.contains(v)) {
      list.remove(v);
    } else {
      list.add(v);
    }
    state = state.copyWith(paymentMethods: List.unmodifiable(list));
  }

  void clearPaymentMethods() =>
      state = state.copyWith(paymentMethods: const []);

  void setTransactionTypes(List<String> values) =>
      state = state.copyWith(transactionTypes: List.unmodifiable(values));

  void toggleTransactionType(String value) {
    final v = value.trim();
    if (v.isEmpty) return;

    final list = [...state.transactionTypes];
    if (list.contains(v)) {
      list.remove(v);
    } else {
      list.add(v);
    }
    state = state.copyWith(transactionTypes: List.unmodifiable(list));
  }

  void clearTransactionTypes() =>
      state = state.copyWith(transactionTypes: const []);

  void setAmountRange(String? min, String? max) => state = state.copyWith(
        amountMin: (min == null || min.trim().isEmpty) ? null : min.trim(),
        amountMinSet: true,
        amountMax: (max == null || max.trim().isEmpty) ? null : max.trim(),
        amountMaxSet: true,
      );

  void setCreatedRange(DateTime? from, DateTime? to) => state = state.copyWith(
        createdFrom: from,
        createdFromSet: true,
        createdTo: to,
        createdToSet: true,
      );

  void setTagsAny(List<String> values) =>
      state = state.copyWith(tagsAny: List.unmodifiable(values));

  void toggleTagAny(String value) {
    final v = value.trim();
    if (v.isEmpty) return;

    final list = [...state.tagsAny];
    if (list.contains(v)) {
      list.remove(v);
    } else {
      list.add(v);
    }
    state = state.copyWith(tagsAny: List.unmodifiable(list));
  }

  void clearTagsAny() => state = state.copyWith(tagsAny: const []);

  void setInvoiceTemplateId(int? id) => state = state.copyWith(
        invoiceTemplateId: id,
        invoiceTemplateIdSet: true,
      );

  /// ✅ Use this when you load filters from prefs/db to avoid null list crashes
  void loadFromMap(Map<String, dynamic>? map) {
    state = FinanceFilters.fromMap(map);
  }

  void reset() => state = FinanceFilters.initial();
}

/// Family: separate filters for revenue and expense
final financeFiltersProvider = StateNotifierProvider.family<
    FinanceFiltersNotifier,
    FinanceFilters,
    FinanceTxType>((ref, type) => FinanceFiltersNotifier());
