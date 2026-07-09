
import 'package:crm/contact_panel/tabs/invoices/provider.dart';
import 'package:crm/invoices/form/screen/add_invoice_screen.dart';
import 'package:crm/invoices/widgets/invoice_details_view.dart';
import 'package:crm/shared/models/revenue_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';

import 'package:intl/intl.dart';

// najlepiej gdzieś globalnie:
final NumberFormat moneyPl = NumberFormat('#,##0.00', 'pl_PL');
final DateFormat datePl = DateFormat('dd.MM.yyyy');




  double _asDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) {
    // obsługa "55 000 000,00" / "55,000,000.00" / "55000000"
    final cleaned = v.trim().replaceAll(' ', '').replaceAll('\u00A0', '');
    final normalized = cleaned.contains(',') && !cleaned.contains('.')
        ? cleaned.replaceAll(',', '.') // polski zapis
        : cleaned;
    return double.tryParse(normalized) ?? fallback;
  }
  return fallback;
}
 

class ClientInvoicesListWidget extends ConsumerWidget {
  final InvoiceState data;
  final bool isMobile;
  final int clientId;

  const ClientInvoicesListWidget({
    super.key,
    required this.clientId,
    required this.data,
    required this.isMobile,
  });



  String _statusForTx(InvoiceState data, int txId) {
    for (final s in data.statuses) {
      if (s.transactionIndex.contains(txId)) return s.statusName;
    }
    return data.statuses.isNotEmpty ? data.statuses.first.statusName : 'All';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final selectedStatusName = ref.watch(selectedInvoiceStatusProvider);
    final bool hasAnyInvoices = data.transactions.isNotEmpty;

    final bool canUseStatuses = data.statuses.isNotEmpty &&
        data.statuses.any((s) => s.transactionIndex.isNotEmpty);

    final transactionsMap = {for (final tx in data.transactions) tx.id: tx};

    final List<AgentRevenueModel> filteredByStatus = !canUseStatuses
        ? data.transactions
        : (selectedStatusName == 'All'
            ? data.statuses
                .expand((s) => s.transactionIndex)
                .map((id) => transactionsMap[id])
                .where((tx) => tx != null)
                .cast<AgentRevenueModel>()
                .toList()
            : data.statuses
                .where((s) => s.statusName == selectedStatusName)
                .expand((s) => s.transactionIndex)
                .map((id) => transactionsMap[id])
                .where((tx) => tx != null)
                .cast<AgentRevenueModel>()
                .toList());

    final List<AgentRevenueModel> itemsToShow = filteredByStatus;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool hasBoundedHeight = constraints.hasBoundedHeight;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: theme.textFieldColor,
                  ),
                  child: Row(
                    children: [

                      Expanded(
                        flex: 2,
                        child: Text(
                          'Name'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                        ),
                      ),

                      Expanded(
                        flex: 2,
                        child: Text(
                          'Invoice number'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Total amount'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Payment date'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'is_paid_label'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Status'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const Divider(),
              ],

              if (itemsToShow.isEmpty)
                _EmptyState(hasAnyInvoices: hasAnyInvoices, isMobile: isMobile)
              else
                hasBoundedHeight
                    ? Expanded(
                        child: _InvoicesList(
                          items: itemsToShow,
                          isMobile: isMobile,
                          data: data,
                          clientId: clientId,
                          statusForTx: _statusForTx,
                        ),
                      )
                    : _InvoicesList(
                        items: itemsToShow,
                        isMobile: isMobile,
                        data: data,
                        clientId: clientId,
                        statusForTx: _statusForTx,
                        shrinkWrap: true,
                        disableScroll: true,
                      ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 300,
                  height: 45,
                  child: ElevatedButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed: () {

    final screenSize = MediaQuery.of(context).size;
                      

    if (isMobile) {
       showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.dashboardContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => 
                           AddInvoiceScreen(
                              isMobile: false,
                              scrollController: scrollController,
                              initialClientId: clientId,
                            ),
          );
        },
      );
      return;
    }

     showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: screenSize.height / 1.2,
            width: screenSize.width / 1.2,
                            child: AddInvoiceScreen(
                              isMobile: false,
                              initialClientId: clientId,
                            ),
          ),
        );
      },
    );

                    },
                    child: AppIcons.add(color: theme.textColor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final bool hasAnyInvoices;
  final bool isMobile;

  const _EmptyState({required this.hasAnyInvoices, required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLottie.noResults(size: 350),
            const SizedBox(height: 8),
            Text(
              !hasAnyInvoices ? 'no_invoices_yet'.tr:'no_results'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoicesList extends ConsumerWidget {
  final List<AgentRevenueModel> items;
  final bool isMobile;
  final bool shrinkWrap;
  final bool disableScroll;

  final InvoiceState data;
  final int clientId;
  final String Function(InvoiceState data, int txId) statusForTx;

  const _InvoicesList({
    required this.items,
    required this.isMobile,
    required this.data,
    required this.clientId,
    required this.statusForTx,
    this.shrinkWrap = false,
    this.disableScroll = false,
  });

  Future<void> _openDetails(
    BuildContext context,
    WidgetRef ref, {
    required AgentRevenueModel revenue,
  }) async {
    final theme = ref.read(themeColorsProvider);
    final screenSize = MediaQuery.of(context).size;

    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.dashboardContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => ExpensesViewDetailsWidget(
              revenue: revenue,
              isMobile: true,
              scrollController: scrollController,
            ),
          );
        },
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: screenSize.height / 1.2,
            width: screenSize.width / 1.2,
            child: ExpensesViewDetailsWidget(
              revenue: revenue,
              isMobile: false,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: disableScroll ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        ...items.map((tx) {
          final currentStatus = statusForTx(data, tx.id);

          // ✅ MOBILE: tap opens bottom sheet
          if (isMobile) {
            return InkWell(
              onTap: () => _openDetails(context, ref, revenue: tx),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.textFieldColor,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 18,
                      color: Color.fromRGBO(145, 145, 145, 1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tx.invoiceNumber ?? "-"}',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tx.amount} ${tx.currency} • ${tx.paymentDate?.toString() ?? "-"} • $currentStatus',
                            style: TextStyle(
                              color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.textColor.withAlpha((255 * 0.5).toInt()),
                    ),
                  ],
                ),
              ),
            );
          }

          // ✅ DESKTOP: row tap opens dialog
          return ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: () => _openDetails(context, ref, revenue: tx),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: theme.textFieldColor,
              ),
              child: Row(
                children: [

                  
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${tx.name ?? "-"}',
                      style: TextStyle(fontSize: 14, color: theme.textColor),
                    ),
                  ),



                  Expanded(
                    flex: 2,
                    child: Text(
                      '${tx.invoiceNumber ?? "-"}',
                      style: TextStyle(fontSize: 14, color: theme.textColor),
                    ),
                  ),


                  Expanded(
                    child: Text(
                      '${moneyPl.format(_asDouble(tx.amount))} ${(tx.currency ?? 'PLN').toString()}',
                      style: TextStyle(fontSize: 14, color: theme.textColor),
                    ),
                  ),


                  Expanded(
                    child: Text(
                      tx.paymentDate == null ? '-' : datePl.format(tx.paymentDate!),
                      style: TextStyle(fontSize: 14, color: theme.textColor),
                    ),
                  ),


                  Expanded(
                    child: Row(
                      children: [

                        Container(
                        height: 20, 
                        width: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          color: tx.isPaid ? AppColors.revenueGreen : AppColors.redBeige,
                        )
                      ),
                      ] 
                    ),


                  ),


                  Expanded(
                    child: Text(
                      currentStatus,
                      style: TextStyle(fontSize: 14, color: theme.textColor),
                    ),
                  ),

                  
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
