import 'package:core/kernel/kernel.dart';
import 'dart:async';

import 'package:core/theme/button_style.dart';
import 'package:core/theme/text_field.dart';
import 'package:crm/crm/finance/features/transactions/transaction_card.dart';
import 'package:crm/contact_panel/tabs/transactions/transaction_docs_view.dart';
import 'package:crm/contact_panel/tabs/transactions/transaction_view.dart';
import 'package:crm/data/clients/ad_provider.dart';
import 'package:crm/pie_menu/revenue_crm.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';

import 'tx_client_provider.dart';

import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';

class TransactionSectionPc extends ConsumerStatefulWidget {
  final int id;
  final String activeSection;
  final String? selectedTransactionId;
  final String? activeAd;
  final bool isMobile;

  const TransactionSectionPc({
    super.key,
    required this.id,
    required this.activeSection,
    this.selectedTransactionId,
    this.activeAd,
    this.isMobile = false,
  });

  @override
  ConsumerState<TransactionSectionPc> createState() =>
      TransactionSectionPcState();
}

class TransactionSectionPcState extends ConsumerState<TransactionSectionPc> {
  late final ProviderSubscription<AsyncValue<List<AgentTransactionModel>>>
  _txSub;

  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  bool _preselectApplied = false;
  bool _isFilterBarOpen = false;

  @override
  void initState() {
    super.initState();

    final initialFilter = ref.read(transactionListFilterProvider(widget.id));
    _searchController = TextEditingController(text: initialFilter.search);
    _isFilterBarOpen = initialFilter.hasAnyFilter;

    _txSub = ref.listenManual<AsyncValue<List<AgentTransactionModel>>>(
      transactionListProvider(widget.id),
      (prev, next) {
        final list = next.value;
        if (list == null || list.isEmpty) return;

        final sel = ref.read(selectedTransactionIdProvider(widget.id));
        final hasValidSelection =
            sel != null && sel != 0 && list.any((t) => t.id == sel);

        if (!hasValidSelection) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _selectTransaction(list.first);
          });
        }
      },
      fireImmediately: false,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_preselectApplied) return;
    final preselect = widget.selectedTransactionId ?? widget.activeAd;
    if (preselect != null && preselect.isNotEmpty) {
      final id = int.tryParse(preselect);
      if (id != null) {
        _preselectApplied = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(selectedTransactionIdProvider(widget.id).notifier).state =
              id;
          updateUrl('/pro/clients/${widget.id}/transakcje/$id');
        });
      }
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _txSub.close();
    super.dispose();
  }

  Future<void> setTransaction(AgentTransactionModel transaction) async {
    ref.read(selectedTransactionIdProvider(widget.id).notifier).state =
        transaction.id;

    if (!transaction.isSeller) {
      final notifier = ref.read(filterProvider.notifier);
      notifier.setClientId('', ref);
      notifier.filteredScope(widget.id, transaction.id, ref);
      notifier.setSavedSearches(null, ref, transaction.id);
    }

    updateUrl('/pro/clients/${widget.id}/transakcje/${transaction.id}');
  }

  void _selectTransaction(AgentTransactionModel tx) {
    ref.read(selectedTransactionIdProvider(widget.id).notifier).state = tx.id;

    if (!tx.isSeller) {
      final notifier = ref.read(filterProvider.notifier);
      notifier.setClientId('', ref);
      notifier.filteredScope(widget.id, tx.id, ref);
      notifier.setSavedSearches(null, ref, tx.id);
    }

    updateUrl('/pro/clients/${widget.id}/transakcje/${tx.id}');
  }

  void _updateFilters(
    TransactionListFilter Function(TransactionListFilter current) update,
  ) {
    final current = ref.read(transactionListFilterProvider(widget.id));
    ref.read(transactionListFilterProvider(widget.id).notifier).state = update(
      current,
    );
  }

  void _resetFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    ref.read(transactionListFilterProvider(widget.id).notifier).state =
        const TransactionListFilter();
  }

  String _roleLabel(String value) {
    switch (value) {
      case TransactionListFilter.roleSeller:
        return 'sale_label'.tr;
      case TransactionListFilter.roleBuyer:
        return 'purchase_label'.tr;
      case TransactionListFilter.roleAll:
      default:
        return 'all_label'.tr;
    }
  }

  String _orderingLabel(String value) {
    switch (value) {
      case 'date_create':
        return 'oldest_label'.tr;
      case '-date_update':
        return 'recently_updated_label'.tr;
      case '-amount':
        return 'amount_descending_label'.tr;
      case 'amount':
        return 'amount_ascending_label'.tr;
      case '-last_viewed':
        return 'recently_viewed_label'.tr;
      case 'last_viewed':
        return 'least_recently_viewed_label'.tr;
      case TransactionListFilter.defaultOrdering:
      default:
        return 'newest_label'.tr;
    }
  }

  Widget _buildSummaryChip({
    required String label,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: textColor.withValues(alpha: 0.08),
        border: Border.all(color: textColor.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor.withValues(alpha: 0.85)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.92),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilterSummaryChips(
    TransactionListFilter filters,
    Color textColor,
  ) {
    final chips = <Widget>[];

    if (filters.hasAnyFilter) {
      chips.add(
        _buildSummaryChip(
          label: '${filters.activeCount}',
          textColor: textColor,
          icon: Icons.filter_alt_outlined,
        ),
      );
    }

    if (filters.search.trim().isNotEmpty) {
      chips.add(
        _buildSummaryChip(
          label: filters.search.trim(),
          textColor: textColor,
          icon: Icons.search,
        ),
      );
    }

    if (filters.role != TransactionListFilter.roleAll) {
      chips.add(
        _buildSummaryChip(
          label: _roleLabel(filters.role),
          textColor: textColor,
        ),
      );
    }

    if (filters.includeArchived) {
      chips.add(
        _buildSummaryChip(
          label: 'archived_label'.tr,
          textColor: textColor,
        ),
      );
    }

    if (filters.includeCompleted) {
      chips.add(
        _buildSummaryChip(
          label: 'completed_label'.tr,
          textColor: textColor,
        ),
      );
    }

    if (filters.includeClosed) {
      chips.add(
        _buildSummaryChip(
          label: 'closed_label'.tr,
          textColor: textColor,
        ),
      );
    }

    if (filters.onlyCompleted) {
      chips.add(
        _buildSummaryChip(
          label: 'only_closed_label'.tr,
          textColor: textColor,
        ),
      );
    }

    if (filters.onlyMine) {
      chips.add(
        _buildSummaryChip(
          label: 'only_mine_label'.tr,
          textColor: textColor,
        ),
      );
    }

    return chips;
  }

  Widget _buildFiltersTopBar() {
    final theme = ref.watch(themeColorsProvider);
    final filters = ref.watch(transactionListFilterProvider(widget.id));
    final summaryChips = _buildFilterSummaryChips(filters, theme.textColor);

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.textColor.withValues(alpha: 0.10)),
        color: theme.textColor.withValues(alpha: 0.02),
      ),
      child: Row(
        children: [
          CoreIconButton(
            icon: Icons.tune_rounded,
            onPressed: () {
              setState(() {
                _isFilterBarOpen = !_isFilterBarOpen;
              });
            },
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'filters_label'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (summaryChips.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    ...summaryChips.expand(
                      (chip) => [chip, const SizedBox(width: 8)],
                    ),
                  ],
                ],
              ),
            ),
          ),
          CoreIconButton(
            icon: Icons.refresh,
            onPressed:
                () => ref.read(transactionListProvider(widget.id).notifier).refresh(),
          ),
          if (filters.hasAnyFilter)
            CoreIconButton(
              icon: Icons.clear_all,
              onPressed: _resetFilters,
            ),
          AnimatedRotation(
            turns: _isFilterBarOpen ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 220),
            child: CoreIconButton(
              icon: Icons.keyboard_arrow_down_rounded,
              onPressed: () {
                setState(() {
                  _isFilterBarOpen = !_isFilterBarOpen;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedFiltersPanel() {
    final theme = ref.watch(themeColorsProvider);
    final filters = ref.watch(transactionListFilterProvider(widget.id));

    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        child:
            !_isFilterBarOpen
                ? const SizedBox.shrink()
                : Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.textColor.withValues(alpha: 0.10),
                    ),
                    color: theme.textColor.withValues(alpha: 0.02),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CoreTextField(
                        label: 'search_label'.tr,
                        hintText: 'search_by_name_note_hint'.tr,
                        controller: _searchController,
                        prefixIcon: Icon(
                          Icons.search,
                          color: theme.textColor.withValues(alpha: 0.7),
                        ),
                        onChanged: (value) {
                          _searchDebounce?.cancel();
                          _searchDebounce = Timer(
                            const Duration(milliseconds: 350),
                            () {
                              if (!mounted) return;
                              _updateFilters((f) => f.copyWith(search: value));
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      CoreDropdown<String>(
                        label: 'transaction_type_label'.tr,
                        value: filters.role,
                        options: const [
                          TransactionListFilter.roleAll,
                          TransactionListFilter.roleSeller,
                          TransactionListFilter.roleBuyer,
                        ],
                        display: _roleLabel,
                        onChanged: (value) {
                          if (value == null) return;
                          _updateFilters((f) => f.copyWith(role: value));
                        },
                      ),
                      const SizedBox(height: 12),
                      CoreDropdown<String>(
                        label: 'sorting_label'.tr,
                        value: filters.ordering,
                        options: const [
                          TransactionListFilter.defaultOrdering,
                          'date_create',
                          '-date_update',
                          '-amount',
                          'amount',
                          '-last_viewed',
                          'last_viewed',
                        ],
                        display: _orderingLabel,
                        onChanged: (value) {
                          if (value == null) return;
                          _updateFilters((f) => f.copyWith(ordering: value));
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: Text('archived_label'.tr),
                            selected: filters.includeArchived,
                            onSelected:
                                (value) => _updateFilters(
                                  (f) => f.copyWith(includeArchived: value),
                                ),
                          ),
                          FilterChip(
                            label: Text('completed_label'.tr),
                            selected: filters.includeCompleted,
                            onSelected:
                                (value) => _updateFilters(
                                  (f) => f.copyWith(includeCompleted: value),
                                ),
                          ),
                          FilterChip(
                            label: Text('closed_label'.tr),
                            selected: filters.includeClosed,
                            onSelected:
                                (value) => _updateFilters(
                                  (f) => f.copyWith(includeClosed: value),
                                ),
                          ),
                          FilterChip(
                            label: Text('only_closed_label'.tr),
                            selected: filters.onlyCompleted,
                            onSelected:
                                (value) => _updateFilters(
                                  (f) => f.copyWith(onlyCompleted: value),
                                ),
                          ),
                          FilterChip(
                            label: Text('only_mine_label'.tr),
                            selected: filters.onlyMine,
                            onSelected:
                                (value) => _updateFilters(
                                  (f) => f.copyWith(onlyMine: value),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<AgentTransactionModel> transactions,
  ) {
    final theme = ref.watch(themeColorsProvider);
    final notifier = ref.read(filterProvider.notifier);
    final selectedId = ref.watch(selectedTransactionIdProvider(widget.id));

    final needsAutoSelect =
        transactions.isNotEmpty &&
        (selectedId == null ||
            selectedId == 0 ||
            !transactions.any((t) => t.id == selectedId));

    if (needsAutoSelect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _selectTransaction(transactions.first);
      });
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (transactions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.textColor.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                'no_transactions_for_filters'.tr,
                style: TextStyle(color: theme.textColor),
              ),
            ),
          ...transactions.map((tx) {
            return PieMenu(
              theme: PieTheme.of(context).copyWith(
                overlayColor: (() {
                  final bool uiIsDark =
                      theme.textColor.computeLuminance() > 0.5;
                  final base = uiIsDark ? Colors.black : Colors.white;
                  return base.withValues(alpha: 0.70);
                })(),
              ),
              onPressedWithDevice: (kind) {
                ref
                    .read(selectedTransactionIdProvider(widget.id).notifier)
                    .state = tx.id;
                notifier.setClientId('', ref);
                notifier.filteredScope(widget.id, tx.id, ref);
                notifier.setSavedSearches(null, ref, tx.id);
                updateUrl('/pro/clients/${widget.id}/transakcje/${tx.id}');
              },
              actions: pieMenuCrmRevenues(
                ref: ref,
                action: tx,
                actionId: tx.id,
                context: context,
                textColor: theme.textColor,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 7.0),
                child: TransactionCard(
                  transaction: tx,
                  activeSection: widget.activeSection,
                  isSeller: tx.isSeller,
                  selectedTransactionId: selectedId,
                  hasDelete: false,
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: PieMenu(
              theme: PieTheme.of(context).copyWith(
                overlayColor: (() {
                  final theme = ref.watch(themeColorsProvider);
                  final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;
            
                  final base = uiIsDark ? Colors.black : Colors.white;
                  return base.withValues(alpha: 0.70);
                })(),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: elevatedButtonStyleRounded10,
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder:
                            (_, __, ___) =>
                                (moduleRegistry.slot('crm.addClientForm')?.call(context, {'isClientView': true}) ?? const SizedBox.shrink()),
                        transitionsBuilder:
                            (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                      ),
                    );
                  },
                  child: AppIcons.add(color: theme.textColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final txAsync = ref.watch(transactionListProvider(widget.id));
    final selectedTx = ref.watch(selectedTransactionProvider(widget.id));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: Column(
            children: [
              _buildFiltersTopBar(),
              _buildExpandedFiltersPanel(),
              const SizedBox(height: 12),
              Expanded(
                child: txAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text('${'loading_error_prefix'.tr} $e'.tr),
                  ),
                  data: (transactions) => _buildTransactionList(
                    context,
                    transactions,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child:
              selectedTx != null
                  ? TransactionView(
                    isMobile: widget.isMobile,
                    key: ValueKey(selectedTx.id),
                    transaction: selectedTx,
                    clientId: widget.id,
                    type:
                        selectedTx.isSeller
                            ? TransactionType.sell
                            : TransactionType.buy,
                  )
                  : Container(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'no_transaction_selected'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
        ),
      ],
    );
  }
}