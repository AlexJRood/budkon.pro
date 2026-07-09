import "package:crm/compensation/commission_integration/dialogs/assign_invoice_transaction_dialog.dart";
import "package:crm/compensation/commission_integration/models/commission_integration_models.dart";
import "package:crm/compensation/commission_integration/provider/commission_integration_provider.dart";
import "package:crm/compensation/commission_integration/widgets/commission_summary_panel.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:get/get_utils/get_utils.dart";

class TransactionCommissionIntegrationPanel
    extends ConsumerStatefulWidget {
  final int transactionId;
  final CommissionSummaryModel initialSummary;
  final bool isMobile;
  final ValueChanged<CommissionSummaryModel>? onChanged;
  final ValueChanged<int>? onOpenInvoice;
  final ValueChanged<int>? onOpenSettlement;

  const TransactionCommissionIntegrationPanel({
    super.key,
    required this.transactionId,
    required this.initialSummary,
    this.isMobile = false,
    this.onChanged,
    this.onOpenInvoice,
    this.onOpenSettlement,
  });

  @override
  ConsumerState<TransactionCommissionIntegrationPanel> createState() =>
      _TransactionCommissionIntegrationPanelState();
}

class _TransactionCommissionIntegrationPanelState
    extends ConsumerState<TransactionCommissionIntegrationPanel> {
  late CommissionSummaryModel _summary;

  @override
  void initState() {
    super.initState();
    _summary = widget.initialSummary;
  }

  @override
  void didUpdateWidget(
    covariant TransactionCommissionIntegrationPanel oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.transactionId != widget.transactionId ||
        oldWidget.initialSummary != widget.initialSummary) {
      _summary = widget.initialSummary;
    }
  }

  Future<void> _sync() async {
    try {
      final result = await ref
          .read(commissionActionProvider.notifier)
          .syncTransaction(widget.transactionId);

      if (!mounted) {
        return;
      }

      setState(() => _summary = result);
      widget.onChanged?.call(result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("commission_sync_completed".tr),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(commissionActionProvider);
    final loading = actionState.isLoading &&
        actionState.actionKey ==
            "transaction:${widget.transactionId}";

    return CommissionSummaryPanel(
      summary: _summary,
      isMobile: widget.isMobile,
      isLoading: loading,
      onSync: _sync,
      onOpenInvoice: widget.onOpenInvoice,
      onOpenSettlement: widget.onOpenSettlement,
    );
  }
}

class InvoiceCommissionIntegrationPanel
    extends ConsumerStatefulWidget {
  final int revenueId;
  final int? currentTransactionId;
  final CommissionSummaryModel initialSummary;
  final bool isMobile;
  final TransactionSearchCallback searchTransactions;
  final ValueChanged<CommissionSummaryModel>? onChanged;
  final ValueChanged<int>? onOpenTransaction;
  final ValueChanged<int>? onOpenSettlement;

  const InvoiceCommissionIntegrationPanel({
    super.key,
    required this.revenueId,
    required this.initialSummary,
    required this.searchTransactions,
    this.currentTransactionId,
    this.isMobile = false,
    this.onChanged,
    this.onOpenTransaction,
    this.onOpenSettlement,
  });

  factory InvoiceCommissionIntegrationPanel.fromInvoiceJson({
    Key? key,
    required Map<String, dynamic> invoiceJson,
    required TransactionSearchCallback searchTransactions,
    bool isMobile = false,
    ValueChanged<CommissionSummaryModel>? onChanged,
    ValueChanged<int>? onOpenTransaction,
    ValueChanged<int>? onOpenSettlement,
  }) {
    final integration =
        InvoiceCommissionIntegrationModel.fromJson(invoiceJson);

    return InvoiceCommissionIntegrationPanel(
      key: key,
      revenueId: integration.revenueId,
      currentTransactionId: integration.linkedTransaction?.id,
      initialSummary: integration.commissionSummary,
      searchTransactions: searchTransactions,
      isMobile: isMobile,
      onChanged: onChanged,
      onOpenTransaction: onOpenTransaction,
      onOpenSettlement: onOpenSettlement,
    );
  }

  @override
  ConsumerState<InvoiceCommissionIntegrationPanel> createState() =>
      _InvoiceCommissionIntegrationPanelState();
}

class _InvoiceCommissionIntegrationPanelState
    extends ConsumerState<InvoiceCommissionIntegrationPanel> {
  late CommissionSummaryModel _summary;
  int? _transactionId;

  @override
  void initState() {
    super.initState();
    _summary = widget.initialSummary;
    _transactionId = widget.currentTransactionId;
  }

  @override
  void didUpdateWidget(
    covariant InvoiceCommissionIntegrationPanel oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.revenueId != widget.revenueId) {
      _summary = widget.initialSummary;
      _transactionId = widget.currentTransactionId;
    }
  }

  Future<void> _sync() async {
    try {
      final result = await ref
          .read(commissionActionProvider.notifier)
          .syncInvoice(widget.revenueId);

      if (!mounted) {
        return;
      }

      setState(() => _summary = result);
      widget.onChanged?.call(result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("commission_sync_completed".tr),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _assign() async {
    final selected = await showAssignInvoiceTransactionDialog(
      context: context,
      invoiceId: widget.revenueId,
      currentTransactionId: _transactionId,
      searchTransactions: widget.searchTransactions,
    );

    if (selected == null || !mounted) {
      return;
    }

    try {
      final result = await ref
          .read(commissionActionProvider.notifier)
          .assignInvoiceToTransaction(
            revenueId: widget.revenueId,
            transactionId: selected.id,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = result;
        _transactionId = selected.id;
      });

      widget.onChanged?.call(result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("invoice_transaction_assigned".tr),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(commissionActionProvider);
    final loading = actionState.isLoading &&
        (actionState.actionKey == "invoice:${widget.revenueId}" ||
            actionState.actionKey ==
                "invoice-assignment:${widget.revenueId}");

    return CommissionSummaryPanel(
      title: "invoice_commission_connections".tr,
      summary: _summary,
      isMobile: widget.isMobile,
      isLoading: loading,
      onSync: _transactionId == null ? null : _sync,
      onAssignTransaction: _assign,
      onOpenTransaction: widget.onOpenTransaction,
      onOpenSettlement: widget.onOpenSettlement,
    );
  }
}
