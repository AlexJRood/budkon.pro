import 'dart:async';
import 'package:crm/crm/finance/features/transactions/transaction_card.dart';
import 'package:crm/contact_panel/tabs/dashboard/new_clients_view_full.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/filter_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:crm/contact_panel/components/client_text_styles.dart';
import 'package:crm/contact_panel/components/transaction_filter_button.dart';
import 'package:crm/contact_panel/components/transaction_popup.dart';
import 'package:crm/contact_panel/data/client_view_db_calendar_provider.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';

/// ==============================
/// Provider stanu filtrów
/// ==============================
class TransactionFilterState {
  final String query;
  final String? status;
  final String? type;
  final String? paymentMethod;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? amountMin;
  final double? amountMax;
  final String? ordering;

  const TransactionFilterState({
    this.query = '',
    this.status,
    this.type,
    this.paymentMethod,
    this.dateFrom,
    this.dateTo,
    this.amountMin,
    this.amountMax,
    this.ordering,
  });

  Map<String, dynamic> toQuery() {
    final m = <String, dynamic>{
      'search': query.isEmpty ? null : query,
      'status': status,
      'type': type,
      'payment_method': paymentMethod,
      'date_from': dateFrom?.toIso8601String(),
      'date_to': dateTo?.toIso8601String(),
      'amount_min': amountMin?.toString(),
      'amount_max': amountMax?.toString(),
      'ordering': ordering,
    };
    m.removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
    return m;
  }

  TransactionFilterState copyWith({
    String? query,
    String? status,
    String? type,
    String? paymentMethod,
    DateTime? dateFrom,
    DateTime? dateTo,
    double? amountMin,
    double? amountMax,
    String? ordering,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearAmountMin = false,
    bool clearAmountMax = false,
  }) {
    return TransactionFilterState(
      query: query ?? this.query,
      status: status ?? this.status,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      amountMin: clearAmountMin ? null : (amountMin ?? this.amountMin),
      amountMax: clearAmountMax ? null : (amountMax ?? this.amountMax),
      ordering: ordering ?? this.ordering,
    );
  }

  static const empty = TransactionFilterState();
}

class TransactionFilterNotifier extends StateNotifier<TransactionFilterState> {
  TransactionFilterNotifier() : super(TransactionFilterState.empty);

  void setQuery(String v) => state = state.copyWith(query: v);
  void setStatus(String? v) => state = state.copyWith(status: v);
  void setType(String? v) => state = state.copyWith(type: v);
  void setPaymentMethod(String? v) => state = state.copyWith(paymentMethod: v);
  void setDateRange(DateTime? from, DateTime? to) =>
      state = state.copyWith(dateFrom: from, dateTo: to);
  void setAmountRange(double? min, double? max) =>
      state = state.copyWith(amountMin: min, amountMax: max);
  void setOrdering(String? v) => state = state.copyWith(ordering: v);
  void clear() => state = TransactionFilterState.empty;
}

final transactionFilterProviderClientPanel =
    StateNotifierProvider<TransactionFilterNotifier, TransactionFilterState>(
      (ref) => TransactionFilterNotifier(),
    );

/// ==============================
/// Widok listy transakcji klienta
/// ==============================
class NewClientTransaction extends ConsumerStatefulWidget {
  final dynamic clientId;
  final bool isMobile;
  final ScrollController? scrollController;
  const NewClientTransaction({
    super.key,
    this.isMobile = false,
    this.clientId,
    this.scrollController,
  });

  @override
  ConsumerState<NewClientTransaction> createState() =>
      _NewClientTransactionState();
}

class _NewClientTransactionState extends ConsumerState<NewClientTransaction> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String? _ordering;

  // manualna subskrypcja Riverpoda (żeby ją zamknąć w dispose)
  ProviderSubscription<dynamic>? _filterSub;

  final orderingOptions = <MapEntry<String, String>>[
    MapEntry('Data utworzenia ↓', '-date_create'),
    MapEntry('Data utworzenia ↑', 'date_create'),
    MapEntry('Data aktualizacji ↓', '-date_update'),
    MapEntry('Data aktualizacji ↑', 'date_update'),
    MapEntry('Kwota ↓', '-amount'),
    MapEntry('Kwota ↑', 'amount'),
  ];

  @override
  void initState() {
    super.initState();
    // Pobierz aktualne sortowanie z providera (jeśli było ustawione)
    final s = ref.read(transactionFilterProviderClientPanel);
    _ordering = s.ordering;

    // 🔒 przeniesiony nasłuch z build() do initState()
    _filterSub = ref.listenManual(transactionFilterProviderClientPanel, (
      prev,
      next,
    ) {
      if (!mounted) return;
      // odśwież dane po każdej zmianie filtra
      _fetchForCurrentFilters();
    });

    // 🔄 pierwszy fetch na starcie (z aktualnymi filtrami)
    // robimy to microtaskiem, żeby kontekst był w pełni zainicjowany
    scheduleMicrotask(() {
      if (!mounted) return;
      _fetchForCurrentFilters();
    });
  }

  void _fetchForCurrentFilters() {
    final filters = ref.read(transactionFilterProviderClientPanel).toQuery();
    final clientId = widget.clientId;
    ref
        .read(calendarTransActionByClientProvider.notifier)
        .getTransActionByClient(clientId, queryParams: filters);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _filterSub?.close(); // ✅ zamknięcie subskrypcji
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(transactionFilterProviderClientPanel.notifier).setQuery(v);
    });
  }

  // Changing section
  void _changeSection(int id) {
    ref.read(activeSectionProvider.notifier).state = 'transakcje';
    ref.read(openTransactionIdProvider.notifier).state = id.toString();
    updateUrl('/pro/clients/${widget.clientId}/transakcje/$id');
  }

  InputDecoration _dropdownDecoration(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      hintText: 'sorting_label'.tr,
      hintStyle: TextStyle(fontSize: 12, color: theme.textFieldColor),
      filled: true,
      fillColor: theme.fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final transactionData = ref.watch(calendarTransActionByClientProvider);

    // ❌ już nie słuchamy tu filtra (zrobione w initState)

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          // GÓRNY PASEK: tytuł, szukajka, popup filtrów, sortowanie
          Row(
            children: [
              const SizedBox(width: 10),
              if (!widget.isMobile)
                Text(
                  "Transactions".tr,
                  style: headerStyle(
                    context,
                    ref,
                  ).copyWith(fontSize: 20, color: theme.textColor),
                ),
              if (!widget.isMobile) const Spacer(),
              Expanded(
                flex: widget.isMobile ? 3 : 0,
                child: SizedBox(
                  height: 40,
                  width: widget.isMobile ? 150 : 200,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    cursorColor: theme.textColor,
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      isDense: true,
                      fillColor: theme.clientbuttoncolor,
                      suffixIcon: Icon(Icons.search, color: theme.textColor),
                      hintText: 'Search...'.tr,
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                      ),
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TransactionFilterButton(
                isicon: true,
                text: widget.isMobile ? '' : 'Filters'.tr,
                onTap: () async {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: theme.dashboardContainer,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    builder: (context) {
                      final sheetController = DraggableScrollableController();

                      return DraggableScrollableSheet(
                        controller: sheetController,
                        initialChildSize: 0.5,
                        minChildSize: 0.4,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (context, scrollController) {
                          return TransactionFiltersPopup(
                            scrollController: scrollController,
                            sheetController: sheetController,
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: widget.isMobile ? 2 : 0,
                child: SizedBox(
                  width: widget.isMobile ? double.infinity : 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _ordering,
                    isExpanded: true,
                    hint: Text(
                      'sorting_label'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                    dropdownColor: theme.adPopBackground,
                    style: TextStyle(color: theme.textColor),
                    selectedItemBuilder: (context) {
                      return orderingOptions.map((e) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            e.key,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: theme.textColor),
                          ),
                        );
                      }).toList();
                    },
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.textColor,
                    ),
                    iconEnabledColor: theme.textColor,
                    iconDisabledColor: theme.textColor,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    items:
                        orderingOptions
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.value,
                                child: Text(e.key),
                              ),
                            )
                            .toList(),
                    onChanged: (v) {
                      setState(() => _ordering = v);
                      ref
                          .read(transactionFilterProviderClientPanel.notifier)
                          .setOrdering(v);
                    },
                    decoration: _dropdownDecoration(context).copyWith(
                      filled: true,
                      fillColor: theme.clientbuttoncolor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      constraints: const BoxConstraints.tightFor(height: 40),
                      hintStyle: TextStyle(color: theme.textColor),
                      labelStyle: TextStyle(color: theme.textColor),
                      floatingLabelStyle: TextStyle(color: theme.textColor),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // NAGŁÓWKI KOLUMN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 15),
              Expanded(
                flex: 22,
                child: Text('Project'.tr, style: headerStyle(context, ref)),
              ),
              if (!widget.isMobile) ...[
                Expanded(
                  flex: 5,
                  child: Text('Type'.tr, style: headerStyle(context, ref)),
                ),
                Expanded(
                  flex: 10,
                  child: Text('Status', style: headerStyle(context, ref)),
                ),
                // Expanded(
                //   flex: 8,
                //   child: Text('Kwota'.tr, style: headerStyle(context, ref)),
                // ),
                Expanded(
                  flex: 8,
                  child: Text(
                    'Commission'.tr,
                    style: headerStyle(context, ref),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Text('Date'.tr, style: headerStyle(context, ref)),
                ),
                // Expanded(
                //   flex: 5,
                //   child: Text('Metoda'.tr, style: headerStyle(context, ref)),
                // ),
                const Expanded(flex: 1, child: SizedBox()),
                const SizedBox(width: 15),
              ],
            ],
          ),
          Divider(color: Theme.of(context).dividerColor),

          // LISTA
          Expanded(
            child:
                transactionData.isEmpty
                    ? Center(child: AppLottie.noResults(size: 450))
                    : NotificationListener<OverscrollNotification>(
                      // Gdy wewnętrzna lista dojedzie do granicy, przekazujemy
                      // resztę scrolla do zewnętrznego (dashboardowego) scrolla,
                      // zamiast blokować go w tym widgecie. Lista wewnętrzna ma
                      // własny (nieudostępniany) kontroler, żeby uniknąć
                      // podpięcia jednego ScrollControllera do dwóch scrolli
                      // naraz (widget.scrollController.position by wtedy rzucał
                      // asercją "attached to multiple scroll views").
                      onNotification: (notification) {
                        final outerController =
                            widget.scrollController ??
                            PrimaryScrollController.maybeOf(context);
                        if (outerController != null &&
                            outerController.positions.length == 1) {
                          final pos = outerController.position;
                          final target = (pos.pixels + notification.overscroll)
                              .clamp(pos.minScrollExtent, pos.maxScrollExtent);
                          if (target != pos.pixels) {
                            outerController.jumpTo(target);
                          }
                        }
                        return false;
                      },
                      child: ListView.builder(
                        addAutomaticKeepAlives: false,
                        cacheExtent: 300.0,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: transactionData.length,
                        itemBuilder: (context, index) {
                          final transaction = transactionData[index];
                          if (kDebugMode) print('younis ${transaction.name}');

                          final commision =
                              transaction.isCommisssionPercentage
                                  ? '%'
                                  : transaction.currency;

                          return ElevatedButton(
                            onPressed: () {
                              _changeSection(transaction.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Klient / nazwy
                                  Expanded(
                                    flex: 22,
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 40,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child:
                                              (transaction.client.avatar ==
                                                          null ||
                                                      transaction
                                                          .client
                                                          .avatar!
                                                          .isEmpty)
                                                  ? Image.asset(
                                                    'assets/images/image.png',
                                                    fit: BoxFit.cover,
                                                  )
                                                  : Image.network(
                                                    transaction.client.avatar!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Image.asset(
                                                          'assets/images/image.png',
                                                          fit: BoxFit.cover,
                                                        ),
                                                  ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                transaction.name,
                                                style: customtextStyle(
                                                  context,
                                                  ref,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              Text(
                                                transaction.client.name,
                                                style: textStylesubheading(
                                                  context,
                                                  ref,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (!widget.isMobile) ...[
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        transaction.isSeller
                                            ? 'market_overview_sale'.tr
                                            : 'Buy'.tr,
                                        style: customtextStyle(context, ref),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 10,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child:
                                                TransactionStatusPillDropdown(
                                                  transactionId: transaction.id,
                                                  isTransaprent: true,
                                                ),
                                          ),
                                          const Spacer(),
                                        ],
                                      ),
                                    ),

                                    // Kwota
                                    // Expanded(
                                    //   flex: 8,
                                    //   child: Row(
                                    //     crossAxisAlignment:
                                    //         CrossAxisAlignment.start,
                                    //     children: [
                                    //       Text(
                                    //         '${transaction.amount} ${transaction.currency}',
                                    //         style: customtextStyle(context, ref),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                    // Prowizja
                                    Expanded(
                                      flex: 8,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${transaction.commission} $commision',
                                            style: customtextStyle(
                                              context,
                                              ref,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Data (sformatowana)
                                    Expanded(
                                      flex: 8,
                                      child: Text(
                                        DateFormat(
                                          'dd.MM.yyyy',
                                        ).format(transaction.dateCreate),
                                        style: customtextStyle(context, ref),
                                      ),
                                    ),

                                    // // Metoda
                                    // Expanded(
                                    //   flex: 5,
                                    //   child: Column(
                                    //     crossAxisAlignment:
                                    //         CrossAxisAlignment.start,
                                    //     children: [
                                    //       Text(
                                    //         (transaction.paymentMethods?.trim().isNotEmpty ?? false)
                                    //             ? transaction.paymentMethods!.trim()
                                    //             : 'No Payment Method'.tr,
                                    //         style: customtextStyle(context, ref),
                                    //       ),

                                    //     ],
                                    //   ),
                                    // ),
                                  ],

                                  // Akcje
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Customiconbuttom(
                                      clientId: widget.clientId,
                                      transactionId: transaction.id.toString(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
