// lib/crm/finance/widgets/finance_transactions_list_widget.dart

import 'package:crm/crm/finance/dashboard/api_dashboard.dart';
import 'package:crm/crm_urls.dart';
import 'package:crm/crm/finance/dashboard/model_dashboard.dart';
import 'package:crm/invoices/widgets/invoice_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/lottie.dart';

class FinanceTransactionsListWidget extends ConsumerWidget {
  final List<UnifiedTransactionModel> data;
  final bool isMobile;
  final bool isTablet;

  /// ✅ if this widget is placed inside an outer scroll (e.g. mobile dashboard),
  /// then the internal list must be shrinkWrap + non-scrollable.
  final bool embedInScroll;

  const FinanceTransactionsListWidget({
    super.key,
    required this.data,
    required this.isMobile,
    this.isTablet = false,
    this.embedInScroll = false,
  });

  Future<void> _markAsPaid(WidgetRef ref, UnifiedTransactionModel tx) async {
    final id = tx.id;

    final String url =
        tx.kind == UnifiedTransactionKind.revenue
            ? '${CrmUrls.financeAppRevenues}$id/'
            : '${CrmUrls.financeAppExpenses}$id/';

    await ApiServices.patch(
      ref: ref,
      url,
      hasToken: true,
      data: {'is_paid': true},
    );

    ref.invalidate(upcomingUnpaidTransactionsProvider);
    ref.invalidate(unifiedTransactionsProvider);
  }

  /// ✅ Builds the correct details widget depending on tx.kind
  Widget _detailsWidgetForTx({
    required UnifiedTransactionModel tx,
    required bool isMobile,
    ScrollController? scrollController,
  }) {
    if (tx.kind == UnifiedTransactionKind.revenue) {
      return ExpensesViewDetailsWidget(
        revenue: tx.revenue,
        isMobile: isMobile,
        scrollController: scrollController,
      );
    }

    return ExpensesViewDetailsWidget(
      transaction: tx.expense,
      isMobile: isMobile,
      scrollController: scrollController,
    );
  }

  Future<void> _openDetails(
    BuildContext context,
    WidgetRef ref, {
    required UnifiedTransactionModel tx,
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
            builder:
                (context, scrollController) => _detailsWidgetForTx(
                  tx: tx,
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
            child: _detailsWidgetForTx(tx: tx, isMobile: false),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    // -------- LIST BODY (can be embedded or expanded) --------
    final Widget listBody =
        data.isEmpty
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppLottie.noResults(size: 450),
                  const SizedBox(height: 8),
                  Text(
                    'Brak nieopłaconych transakcji 🎉'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ],
              ),
            )
            : ListView.builder(
              shrinkWrap: embedInScroll, // ✅ key
              physics:
                  embedInScroll
                      ? const NeverScrollableScrollPhysics() // ✅ key
                      : null,
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final tx = data[index];

                if (isMobile) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: theme.dashboardBoarder,
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        collapsedBackgroundColor: theme.textFieldColor,
                        backgroundColor: const Color.fromRGBO(
                          87,
                          148,
                          221,
                          0.1,
                        ),
                        iconColor: theme.textColor.withAlpha(
                          (255 * 0.5).toInt(),
                        ),
                        leading: Icon(
                          tx.kind == UnifiedTransactionKind.revenue
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color:
                              tx.kind == UnifiedTransactionKind.revenue
                                  ? AppColors.revenueGreen
                                  : theme.themeColor,
                        ),
                        showTrailingIcon: true,
                        collapsedIconColor: theme.textColor.withAlpha(
                          (255 * 0.5).toInt(),
                        ),

                        // ✅ tap title/subtitle opens details
                        title: InkWell(
                          onTap: () => _openDetails(context, ref, tx: tx),
                          child: Text(
                            tx.name.isNotEmpty ? tx.name : '-',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        subtitle: InkWell(
                          onTap: () => _openDetails(context, ref, tx: tx),
                          child: Text(
                            tx.kind == UnifiedTransactionKind.revenue
                                ? 'Revenue (unpaid)'.tr
                                : 'Expense (unpaid)'.tr,
                            style: TextStyle(
                              color: theme.textColor.withAlpha(
                                (255 * 0.6).toInt(),
                              ),
                            ),
                          ),
                        ),

                        children: [
                          ListTile(
                            title: Text(
                              'Total amount'.tr,
                              style: TextStyle(
                                color: theme.textColor.withAlpha(
                                  (255 * 0.5).toInt(),
                                ),
                              ),
                            ),
                            trailing: Text(tx.amountWithCurrency),
                          ),
                          ListTile(
                            title: Text(
                              'Payment date'.tr,
                              style: TextStyle(
                                color: theme.textColor.withAlpha(
                                  (255 * 0.5).toInt(),
                                ),
                              ),
                            ),
                            trailing: Text(tx.paymentDateHuman),
                          ),
                          ListTile(
                            title: Text(
                              'Client / Contractor'.tr,
                              style: TextStyle(
                                color: theme.textColor.withAlpha(
                                  (255 * 0.5).toInt(),
                                ),
                              ),
                            ),
                            trailing: Text(
                              tx.clientOrContractorName.isNotEmpty
                                  ? tx.clientOrContractorName
                                  : '-',
                            ),
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 16,
                              bottom: 8,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  style: elevatedButtonStyleRounded10,
                                  onPressed: () => _markAsPaid(ref, tx),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: Text('Mark as paid'.tr),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Desktop row: tap opens details (button excluded)
                return InkWell(
                  onTap: () => _openDetails(context, ref, tx: tx),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: theme.textFieldColor,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Icon(
                                tx.kind == UnifiedTransactionKind.revenue
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color:
                                    tx.kind == UnifiedTransactionKind.revenue
                                        ? AppColors.revenueGreen
                                        : theme.themeColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  tx.name.isNotEmpty ? tx.name : '-',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isTablet)
                          Expanded(
                            child: Text(
                              tx.kind == UnifiedTransactionKind.revenue
                                  ? 'Revenue'.tr
                                  : 'Expense'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            tx.amountWithCurrency,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tx.paymentDateHuman,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        if (!isTablet)
                          Expanded(
                            child: Text(
                              tx.clientOrContractorName.isNotEmpty
                                  ? tx.clientOrContractorName
                                  : '-',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textColor,
                              ),
                            ),
                          ),

                        // button without opening details
                        SizedBox(
                          width: 80,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {}, // prevents tap "feel" on InkWell
                              child: SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  style: elevatedButtonStyleRounded10,
                                  onPressed: () => _markAsPaid(ref, tx),
                                  child: Icon(
                                    Icons.check,
                                    size: 18,
                                    color: theme.themeTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

    // If embedded, we must NOT use Expanded (because parent scroll provides height)
    final Widget listContainerChild =
        embedInScroll ? listBody : Expanded(child: listBody);

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: BoxBorder.all(color: theme.dashboardBoarder),
              color: theme.dashboardContainer,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (!isMobile) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
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
                        if (!isTablet)
                          Expanded(
                            child: Text(
                              'Type'.tr,
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
                        if (!isTablet)
                          Expanded(
                            child: Text(
                              'Client / Contractor'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                        const SizedBox(width: 80),
                      ],
                    ),
                  ),
                  const Divider(),
                ],

                // ✅ either Expanded(list) or just list (embedded mode)
                listContainerChild,
              ],
            ),
          ),
        ),





        
      ],
    );
  }
}
