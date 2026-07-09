import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';

import 'package:crm/data/finance/transaction_filters_provider.dart';
import 'package:crm/data/finance/transaction_provider.dart';
import 'package:crm/shared/models/transaction/transaction_status_model.dart';

import 'transaction_filters_scaffold.dart';
import 'transaction_filters_body.dart';

class TransactionFiltersDialog extends ConsumerStatefulWidget {
  final VoidCallback? onApply;
  final ScrollController? scrollController;
  final bool isMobile;
  final List<TransactionStatus> statuses;

  const TransactionFiltersDialog({
    super.key,
    required this.statuses,
    this.onApply,
    this.scrollController,
    this.isMobile = false,
  });

  @override
  ConsumerState<TransactionFiltersDialog> createState() =>
      _TransactionFiltersDialogState();
}

class _TransactionFiltersDialogState
    extends ConsumerState<TransactionFiltersDialog> {
  late final TextEditingController searchCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(transactionFiltersProvider);
    searchCtrl = TextEditingController(text: s.search);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyAndClose() async {
    // ✅ ensure provider has current search text
    ref.read(transactionFiltersProvider.notifier).setSearch(searchCtrl.text);

    // ✅ one request
    await ref.read(transactionProvider.notifier).applyFiltersAndFetch(ref);

    widget.onApply?.call();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _clear() async {
    ref.read(transactionFiltersProvider.notifier).clearAll();
    searchCtrl.text = '';

    // (opcjonalnie) nie fetchuj tu — ja fetchuję dopiero jak user kliknie Apply.
    // Jeśli chcesz "clear = natychmiast odśwież", odkomentuj:
    // await ref.read(transactionProvider.notifier).applyFiltersAndFetch(ref);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final filters = ref.watch(transactionFiltersProvider);

    final body = SingleChildScrollView(
      controller: widget.scrollController,
      child: TransactionFiltersBody(
        isMobile: widget.isMobile,
        theme: theme,
        filters: filters,
        statuses: widget.statuses,
        searchCtrl: searchCtrl,
      ),
    );

    final actions = TransactionFilterActionsRow(
      theme: theme,
      onClear: _clear,
      onApply: _applyAndClose,
    );

    if (widget.isMobile) {
      return MobileSheetScaffold(
        theme: theme,
        title: 'Transaction Filters'.tr,
        body: body,
        actions: actions,
      );
    }

    return PcDialogScaffold(
      theme: theme,
      title: 'Transaction Filters'.tr,
      body: SizedBox(width: 760, child: body),
      actions: actions,
    );
  }
}
