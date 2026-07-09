import "dart:async";

import "package:crm/compensation/commission_integration/models/commission_integration_models.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:get/get_utils/get_utils.dart";
import "package:core/theme/apptheme.dart";
import "package:core/theme/text_field.dart";

typedef TransactionSearchCallback = Future<List<CommissionTransactionOption>>
    Function(String query);

Future<CommissionTransactionOption?> showAssignInvoiceTransactionDialog({
  required BuildContext context,
  required int invoiceId,
  required TransactionSearchCallback searchTransactions,
  int? currentTransactionId,
}) {
  return showDialog<CommissionTransactionOption>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AssignInvoiceTransactionDialog(
      invoiceId: invoiceId,
      searchTransactions: searchTransactions,
      currentTransactionId: currentTransactionId,
    ),
  );
}

class _AssignInvoiceTransactionDialog
    extends ConsumerStatefulWidget {
  final int invoiceId;
  final TransactionSearchCallback searchTransactions;
  final int? currentTransactionId;

  const _AssignInvoiceTransactionDialog({
    required this.invoiceId,
    required this.searchTransactions,
    required this.currentTransactionId,
  });

  @override
  ConsumerState<_AssignInvoiceTransactionDialog> createState() =>
      _AssignInvoiceTransactionDialogState();
}

class _AssignInvoiceTransactionDialogState
    extends ConsumerState<_AssignInvoiceTransactionDialog> {
  final _searchController = TextEditingController();

  Timer? _debounce;
  bool _isLoading = true;
  Object? _error;
  List<CommissionTransactionOption> _transactions = const [];
  CommissionTransactionOption? _selected;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _search(""));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(value.trim()),
    );
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.searchTransactions(query);

      if (!mounted) {
        return;
      }

      setState(() {
        _transactions = result;
        _isLoading = false;

        if (_selected == null &&
            widget.currentTransactionId != null) {
          for (final transaction in result) {
            if (transaction.id ==
                widget.currentTransactionId) {
              _selected = transaction;
              break;
            }
          }
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  void _submit() {
    final selected = _selected;
    if (selected == null) {
      return;
    }

    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final screen = MediaQuery.of(context).size;
    final compact = screen.width < 680;

    return Dialog(
      insetPadding: EdgeInsets.all(compact ? 12 : 24),
      backgroundColor: theme.dashboardContainer,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dashboardBoarder),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: screen.height * 0.88,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 15, 10, 15),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.themeColor.withAlpha(22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.link_rounded,
                      color: theme.themeColor,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "assign_invoice_to_transaction".tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "assign_invoice_to_transaction_hint".tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(145),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CoreIconButton(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dashboardBoarder),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CoreTextField(
                label: "search_transaction".tr,
                controller: _searchController,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.textColor.withAlpha(160),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: _buildBody(theme),
            ),
            Divider(height: 1, color: theme.dashboardBoarder),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selected == null
                          ? "no_transaction_selected".tr
                          : "${"selected_transaction".tr}: ${_selected!.title}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _selected == null
                            ? theme.textColor.withAlpha(140)
                            : theme.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CoreOutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("cancel".tr),
                  ),
                  const SizedBox(width: 8),
                  CoreFilledButton(
                    onPressed:
                        _selected == null ? null : _submit,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_rounded, size: 17),
                        const SizedBox(width: 6),
                        Text("assign".tr),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(dynamic theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: theme.textColor.withAlpha(150),
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                _error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textColor),
              ),
              const SizedBox(height: 12),
              CoreOutlinedButton(
                onPressed: () => _search(
                  _searchController.text.trim(),
                ),
                child: Text("try_again".tr),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                color: theme.textColor.withAlpha(130),
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                "no_transactions_found".tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final selected = _selected?.id == transaction.id;

        return Material(
          color: selected
              ? theme.themeColor.withAlpha(18)
              : theme.adPopBackground,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => setState(() => _selected = transaction),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? theme.themeColor
                      : theme.dashboardBoarder,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected
                        ? theme.themeColor
                        : theme.textColor.withAlpha(100),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (transaction.subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            transaction.subtitle!,
                            style: TextStyle(
                              color: theme.textColor.withAlpha(145),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${transaction.amount.toStringAsFixed(2)} ${transaction.currency}",
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        transaction.isClosed
                            ? "transaction_closed".tr
                            : "transaction_open".tr,
                        style: TextStyle(
                          color: transaction.isClosed
                              ? theme.themeColor
                              : theme.textColor.withAlpha(130),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
