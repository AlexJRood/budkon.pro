import 'package:crm_agent/add_client_form/components/usercontact/contact_list.dart';
import 'package:crm/invoices/providers/invoice_totals_and_payload.dart';
import 'package:crm/data/clients/client_selection_provider.dart';
import 'package:crm/invoices/form/provider/create_revenue_provider.dart';
import 'package:crm/invoices/form/provider/form_provider.dart';
import 'package:crm/invoices/form/provider/invoice_buyer_provider.dart';
import 'package:crm/invoices/form/provider/invoice_flow_provider.dart';
import 'package:crm/invoices/form/provider/invoice_number_provider.dart';
import 'package:crm/invoices/form/provider/invoice_table_provider.dart';
import 'package:crm/invoices/form/widgets/invoice_buyer_gus_section.dart';
import 'package:crm/invoices/form/widgets/invoice_data_table_widget.dart';
import 'package:crm/invoices/form/widgets/invoice_form_widget.dart';
import 'package:crm/invoices/form/widgets/transaction_form_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

class AddInvoiceScreen extends ConsumerStatefulWidget {
  final bool isExpenses;
  final bool isMobile;
  final ScrollController? scrollController;
  final int? initialClientId;
  final AgentTransactionModel? initialTransaction;

  const AddInvoiceScreen({
    super.key,
    this.initialClientId,
    this.initialTransaction,
    this.scrollController,
    this.isExpenses = false,
    this.isMobile = false,
  });

  @override
  ConsumerState<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends ConsumerState<AddInvoiceScreen> {
  bool _didInit = false;

  ProviderSubscription<InvoiceTotals>? _totalsSub;
  ProviderSubscription<AsyncValue<void>>? _createSub;

  @override
  void initState() {
    super.initState();

    _totalsSub = ref.listenManual<InvoiceTotals>(
      invoiceTotalsProvider,
      (prev, next) => _syncTotalsToForm(next),
    );

    _createSub = ref.listenManual<AsyncValue<void>>(
      createRevenueProvider,
      (prev, next) {
        final wasLoading = prev is AsyncLoading<void>;
        final isNowData = next is AsyncData<void>;
        final isNowError = next is AsyncError<void>;

        if (!mounted) return;

        if (wasLoading && isNowData) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('invoice_created_success'.tr)),
          );
        }

        if (wasLoading && isNowError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'invoice_creation_error'.tr}: ${next.error}'),
            ),
          );
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didInit) return;
      _didInit = true;

      final formNotifier = ref.read(revenueFormProvider.notifier);
      formNotifier.ensureDefaults(defaultPaymentTermDays: 14);

      _syncTotalsToForm(ref.read(invoiceTotalsProvider));

      if (widget.initialTransaction != null) {
        ref.read(invoiceFlowModeProvider.notifier).state =
            InvoiceFlowMode.transaction;
        ref.read(selectedTransactionProvider.notifier).state =
            widget.initialTransaction;
      } else {
        ref.read(invoiceFlowModeProvider.notifier).state = InvoiceFlowMode.manual;
        if (widget.initialClientId != null) {
          formNotifier.setClient(widget.initialClientId!);
          ref.read(invoiceBuyerProvider.notifier).setExistingContactId(
                widget.initialClientId!,
              );
        }
      }

      await ref.read(invoiceNumberProvider.notifier).refreshFromForm();
    });
  }

  void _syncTotalsToForm(InvoiceTotals totals) {
    if (!mounted) return;
    final formNotifier = ref.read(revenueFormProvider.notifier);
    final form = ref.read(revenueFormProvider);

    formNotifier.setTotalAmountFromDouble(totals.gross);
    form.taxAmountController.text = totals.vat.toStringAsFixed(2);
  }

  void _resetInvoiceScreenState() {
    ref.read(revenueFormProvider.notifier).clearForm(
          keepMyInvoiceData: true,
        );
    ref.read(invoiceNumberProvider.notifier).clear();
    ref.read(invoiceTableProvider.notifier).clearAll();
    ref.read(selectedClientProvider.notifier).state = null;
    ref.read(selectedTransactionProvider.notifier).state = null;
    ref.read(invoiceFlowModeProvider.notifier).state = InvoiceFlowMode.manual;
    ref.read(selectedCurrencyProvider.notifier).state = 'PLN';
    ref.read(invoiceBuyerProvider.notifier).clearBuyerData(keepMode: false);
  }

  @override
  void dispose() {
    _totalsSub?.close();
    _createSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final mode = ref.watch(invoiceFlowModeProvider);
    final buyer = ref.watch(invoiceBuyerProvider);
    final createState = ref.watch(createRevenueProvider);
    final formState = ref.watch(revenueFormProvider);

    Widget modeSelector() {
      return Padding(
        padding: widget.isMobile
            ? const EdgeInsets.symmetric(horizontal: 10)
            : const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ChoiceChip(
                selected: mode == InvoiceFlowMode.transaction,
                onSelected: (_) {
                  ref.read(invoiceFlowModeProvider.notifier).state =
                      InvoiceFlowMode.transaction;
                },
                label: Text('from_transaction'.tr),
                labelStyle: TextStyle(
                  color: mode == InvoiceFlowMode.transaction
                      ? theme.themeTextColor
                      : theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: theme.themeColor,
                backgroundColor: theme.adPopBackground,
                side: BorderSide(color: theme.dashboardBoarder),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                selected: mode == InvoiceFlowMode.manual,
                onSelected: (_) {
                  ref.read(invoiceFlowModeProvider.notifier).state =
                      InvoiceFlowMode.manual;
                  ref.read(selectedTransactionProvider.notifier).state = null;
                  ref.read(revenueFormProvider.notifier).clearTransaction();
                },
                label: Text('without_transaction'.tr),
                labelStyle: TextStyle(
                  color: mode == InvoiceFlowMode.manual
                      ? theme.themeTextColor
                      : theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: theme.themeColor,
                backgroundColor: theme.adPopBackground,
                side: BorderSide(color: theme.dashboardBoarder),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  mode == InvoiceFlowMode.transaction
                      ? 'prefill_from_transaction'.tr
                      : 'manual_invoice'.tr,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.interRegular12.copyWith(
                    color: theme.textColor.withAlpha(200),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    void close() {
      _resetInvoiceScreenState();
      Navigator.pop(context);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: theme.adPopBackground,
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              color: theme.themeColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ADD INVOICE'.tr,
                  style: AppTextStyles.interBold.copyWith(
                    color: theme.themeTextColor,
                    fontSize: 15,
                  ),
                ),
                InkWell(
                  onTap: close,
                  child: AppIcons.close(
                    color: theme.themeTextColor,
                    height: 24,
                    width: 24,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  modeSelector(),
                  const SizedBox(height: 16),
                  TransactionFormWidget(
                    isExpenses: widget.isExpenses,
                    isMobile: widget.isMobile,
                  ),
                  const SizedBox(height: 12),
                  InvoiceBuyerGusSection(isMobile: widget.isMobile),
                  const SizedBox(height: 12),
                  if (buyer.mode == InvoiceBuyerMode.existingContact) ...[
                    Padding(
                      padding: widget.isMobile
                          ? const EdgeInsets.symmetric(horizontal: 10.0)
                          : const EdgeInsets.symmetric(horizontal: 40.0),
                      child: ClientListAddFormCrm(
                        key: ValueKey<String>(
                          '${mode.name}_${formState.clients}_${widget.initialClientId}',
                        ),
                        isAddInvoice: true,
                        initialClientId:
                            formState.clients ?? widget.initialClientId,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  InvoiceFormWidget(theme: theme, isMobile: widget.isMobile),
                  const SizedBox(height: 16),
                  InvoiceDataTable(isMobile: widget.isMobile),
                  const SizedBox(height: 16),
                  Padding(
                    padding: widget.isMobile
                        ? const EdgeInsets.symmetric(horizontal: 10.0)
                        : const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          style: elevatedButtonStyleRounded10,
                          onPressed: createState is AsyncLoading
                              ? null
                              : () {
                                  _resetInvoiceScreenState();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('form_cleared'.tr),
                                    ),
                                  );
                                },
                          icon: Icon(Icons.refresh, color: theme.textColor),
                          label: Text(
                            'clear'.tr,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: createState is AsyncLoading
                              ? null
                              : () async {
                                  await ref
                                      .read(createRevenueProvider.notifier)
                                      .createRevenue(ref);
                                },
                          icon: createState is AsyncLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(Icons.cloud_upload, color: theme.textColor),
                          label: Text(
                            createState is AsyncLoading
                                ? 'creating'.tr
                                : 'create_invoice'.tr,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                            ),
                          ),
                          style: buttonStyleRounded10ThemeRedWithPadding15,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
