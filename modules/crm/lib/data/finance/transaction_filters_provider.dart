import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionFiltersState {
  final String search;

  final int? statusId;
  final String? ordering;

  final double? amountMin;
  final double? amountMax;
  final double? commissionMin;
  final double? commissionMax;

  final bool? isCommissionNetValue;
  final bool? isPaid;
  final bool? isSeller;
  final bool? isBuyer;

  final int? createdBy;
  final int? responsiblePerson;

  final bool? onlyMine;
  final bool? onlyViewed;
  final bool? onlyCompleted;

  final bool? includeArchived;
  final bool? includeCompleted;
  final bool? includeClosed;

  final String? currency;
  final String? transactionType;
  final String? paymentMethod;

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final DateTime? closedFrom;
  final DateTime? closedTo;

  const TransactionFiltersState({
    this.search = '',
    this.statusId,
    this.ordering,
    this.amountMin,
    this.amountMax,
    this.commissionMin,
    this.commissionMax,
    this.isCommissionNetValue,
    this.isPaid,
    this.isSeller,
    this.isBuyer,
    this.createdBy,
    this.responsiblePerson,
    this.onlyMine,
    this.onlyViewed,
    this.onlyCompleted,
    this.includeArchived,
    this.includeCompleted,
    this.includeClosed,
    this.currency,
    this.transactionType,
    this.paymentMethod,
    this.dateFrom,
    this.dateTo,
    this.closedFrom,
    this.closedTo,
  });

  // 👇 sentinel so we can set nullable fields to null intentionally
  static const Object _unset = Object();

  TransactionFiltersState copyWith({
    Object? search = _unset,

    Object? statusId = _unset,
    Object? ordering = _unset,

    Object? amountMin = _unset,
    Object? amountMax = _unset,
    Object? commissionMin = _unset,
    Object? commissionMax = _unset,

    Object? isCommissionNetValue = _unset,
    Object? isPaid = _unset,
    Object? isSeller = _unset,
    Object? isBuyer = _unset,

    Object? createdBy = _unset,
    Object? responsiblePerson = _unset,

    Object? onlyMine = _unset,
    Object? onlyViewed = _unset,
    Object? onlyCompleted = _unset,

    Object? includeArchived = _unset,
    Object? includeCompleted = _unset,
    Object? includeClosed = _unset,

    Object? currency = _unset,
    Object? transactionType = _unset,
    Object? paymentMethod = _unset,

    Object? dateFrom = _unset,
    Object? dateTo = _unset,
    Object? closedFrom = _unset,
    Object? closedTo = _unset,
  }) {
    return TransactionFiltersState(
      search: identical(search, _unset) ? this.search : (search as String),

      statusId: identical(statusId, _unset) ? this.statusId : (statusId as int?),
      ordering:
          identical(ordering, _unset) ? this.ordering : (ordering as String?),

      amountMin:
          identical(amountMin, _unset) ? this.amountMin : (amountMin as double?),
      amountMax:
          identical(amountMax, _unset) ? this.amountMax : (amountMax as double?),

      commissionMin: identical(commissionMin, _unset)
          ? this.commissionMin
          : (commissionMin as double?),
      commissionMax: identical(commissionMax, _unset)
          ? this.commissionMax
          : (commissionMax as double?),

      isCommissionNetValue: identical(isCommissionNetValue, _unset)
          ? this.isCommissionNetValue
          : (isCommissionNetValue as bool?),
      isPaid: identical(isPaid, _unset) ? this.isPaid : (isPaid as bool?),
      isSeller:
          identical(isSeller, _unset) ? this.isSeller : (isSeller as bool?),
      isBuyer: identical(isBuyer, _unset) ? this.isBuyer : (isBuyer as bool?),

      createdBy:
          identical(createdBy, _unset) ? this.createdBy : (createdBy as int?),
      responsiblePerson: identical(responsiblePerson, _unset)
          ? this.responsiblePerson
          : (responsiblePerson as int?),

      onlyMine:
          identical(onlyMine, _unset) ? this.onlyMine : (onlyMine as bool?),
      onlyViewed: identical(onlyViewed, _unset)
          ? this.onlyViewed
          : (onlyViewed as bool?),
      onlyCompleted: identical(onlyCompleted, _unset)
          ? this.onlyCompleted
          : (onlyCompleted as bool?),

      includeArchived: identical(includeArchived, _unset)
          ? this.includeArchived
          : (includeArchived as bool?),
      includeCompleted: identical(includeCompleted, _unset)
          ? this.includeCompleted
          : (includeCompleted as bool?),
      includeClosed: identical(includeClosed, _unset)
          ? this.includeClosed
          : (includeClosed as bool?),

      currency: identical(currency, _unset) ? this.currency : (currency as String?),
      transactionType: identical(transactionType, _unset)
          ? this.transactionType
          : (transactionType as String?),
      paymentMethod: identical(paymentMethod, _unset)
          ? this.paymentMethod
          : (paymentMethod as String?),

      dateFrom: identical(dateFrom, _unset) ? this.dateFrom : (dateFrom as DateTime?),
      dateTo: identical(dateTo, _unset) ? this.dateTo : (dateTo as DateTime?),
      closedFrom: identical(closedFrom, _unset)
          ? this.closedFrom
          : (closedFrom as DateTime?),
      closedTo: identical(closedTo, _unset) ? this.closedTo : (closedTo as DateTime?),
    );
  }

  TransactionFiltersState cleared() => const TransactionFiltersState();


int activeCount() {
  int c = 0;

  if (search.trim().isNotEmpty) c++;
  if (statusId != null) c++;
  if (ordering != null && ordering!.trim().isNotEmpty) c++;

  if (amountMin != null) c++;
  if (amountMax != null) c++;
  if (commissionMin != null) c++;
  if (commissionMax != null) c++;

  if (isCommissionNetValue != null) c++;
  if (isPaid != null) c++;
  if (isSeller != null) c++;
  if (isBuyer != null) c++;

  if (createdBy != null) c++;
  if (responsiblePerson != null) c++;

  if (onlyMine != null) c++;
  if (onlyViewed != null) c++;
  if (onlyCompleted != null) c++;

  if (includeArchived != null) c++;
  if (includeCompleted != null) c++;
  if (includeClosed != null) c++;

  if (currency != null && currency!.trim().isNotEmpty) c++;
  if (transactionType != null && transactionType!.trim().isNotEmpty) c++;
  if (paymentMethod != null && paymentMethod!.trim().isNotEmpty) c++;

  if (dateFrom != null) c++;
  if (dateTo != null) c++;
  if (closedFrom != null) c++;
  if (closedTo != null) c++;

  return c;
}

  Map<String, dynamic> toQueryParams() {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

    final q = <String, dynamic>{};

    final s = search.trim();
    if (s.isNotEmpty) q['search'] = s;

    if (statusId != null) q['status_id'] = statusId;

    final ord = ordering?.trim();
    if (ord != null && ord.isNotEmpty) q['ordering'] = ord;

    if (amountMin != null) q['amount_min'] = amountMin;
    if (amountMax != null) q['amount_max'] = amountMax;

    if (commissionMin != null) q['commission_min'] = commissionMin;
    if (commissionMax != null) q['commission_max'] = commissionMax;

    if (isCommissionNetValue != null) q['isCommissionNetValue'] = isCommissionNetValue;
    if (isPaid != null) q['is_paid'] = isPaid;
    if (isSeller != null) q['is_seller'] = isSeller;
    if (isBuyer != null) q['is_buyer'] = isBuyer;

    if (createdBy != null) q['created_by'] = createdBy;
    if (responsiblePerson != null) q['responsible_person'] = responsiblePerson;

    if (onlyMine != null) q['only_mine'] = onlyMine;
    if (onlyViewed != null) q['only_viewed'] = onlyViewed;
    if (onlyCompleted != null) q['only_completed'] = onlyCompleted;

    if (includeArchived != null) q['include_archived'] = includeArchived;
    if (includeCompleted != null) q['include_completed'] = includeCompleted;
    if (includeClosed != null) q['include_closed'] = includeClosed;

    final cur = currency?.trim();
    if (cur != null && cur.isNotEmpty) q['currency'] = cur;

    final tt = transactionType?.trim();
    if (tt != null && tt.isNotEmpty) q['transaction_type'] = tt;

    final pm = paymentMethod?.trim();
    if (pm != null && pm.isNotEmpty) q['payment_method'] = pm;

    if (dateFrom != null) q['date_from'] = fmt(dateFrom!);
    if (dateTo != null) q['date_to'] = fmt(dateTo!);
    if (closedFrom != null) q['closed_from'] = fmt(closedFrom!);
    if (closedTo != null) q['closed_to'] = fmt(closedTo!);

    return q;
  }
}

class TransactionFiltersNotifier extends StateNotifier<TransactionFiltersState> {
  TransactionFiltersNotifier(TransactionFiltersState initial)
      : super(initial);

  void setSearch(String v) => state = state.copyWith(search: v);

  void setStatusId(int? v) => state = state.copyWith(statusId: v);
  void setOrdering(String? v) => state = state.copyWith(ordering: v);

  void setCurrency(String? v) => state = state.copyWith(currency: v);
  void setTransactionType(String? v) => state = state.copyWith(transactionType: v);
  void setPaymentMethod(String? v) => state = state.copyWith(paymentMethod: v);

  void setAmountMin(double? v) => state = state.copyWith(amountMin: v);
  void setAmountMax(double? v) => state = state.copyWith(amountMax: v);
  void setCommissionMin(double? v) => state = state.copyWith(commissionMin: v);
  void setCommissionMax(double? v) => state = state.copyWith(commissionMax: v);

  void setIsCommissionNetValue(bool? v) => state = state.copyWith(isCommissionNetValue: v);
  void setIsPaid(bool? v) => state = state.copyWith(isPaid: v);
  void setIsSeller(bool? v) => state = state.copyWith(isSeller: v);
  void setIsBuyer(bool? v) => state = state.copyWith(isBuyer: v);

  void setOnlyMine(bool? v) => state = state.copyWith(onlyMine: v);
  void setOnlyViewed(bool? v) => state = state.copyWith(onlyViewed: v);
  void setOnlyCompleted(bool? v) => state = state.copyWith(onlyCompleted: v);

  void setIncludeArchived(bool? v) => state = state.copyWith(includeArchived: v);
  void setIncludeCompleted(bool? v) => state = state.copyWith(includeCompleted: v);
  void setIncludeClosed(bool? v) => state = state.copyWith(includeClosed: v);

  void setDateFrom(DateTime? v) => state = state.copyWith(dateFrom: v);
  void setDateTo(DateTime? v) => state = state.copyWith(dateTo: v);
  void setClosedFrom(DateTime? v) => state = state.copyWith(closedFrom: v);
  void setClosedTo(DateTime? v) => state = state.copyWith(closedTo: v);

  void clearAll() => state = state.cleared();
}

/// ✅ TU ustawiasz domyślne wartości jak w backendzie (patrz punkt 3)
final transactionFiltersProvider =
    StateNotifierProvider<TransactionFiltersNotifier, TransactionFiltersState>(
  (ref) => TransactionFiltersNotifier(_backendDefaultFilters()),
);

TransactionFiltersState _backendDefaultFilters() {
  // USTAW TO 1:1 jak macie w backendzie defaulty filtrowania.
  // Jeśli backend domyślnie np. NIE pokazuje archived/completed/closed,
  // to ustaw false (a nie null), żeby UI pokazywał "No".
  return const TransactionFiltersState(
    // przykłady – popraw pod swój backend:
    // includeArchived: false,
    // includeCompleted: false,
    // includeClosed: false,
    // ordering: '-date_create',
  );
}


