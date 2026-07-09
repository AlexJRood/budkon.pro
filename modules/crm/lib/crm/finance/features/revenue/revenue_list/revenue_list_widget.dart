import 'package:flutter/gestures.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:crm/crm/finance/features/revenue/revenue_list/selected_revenue_status_provider.dart';
import 'package:crm/crm/finance/features/revenue/revenue_provider.dart';
import 'package:crm/data/finance/remove_revenue.dart';
import 'package:crm/pie_menu/revenue_crm.dart' show pieMenuCrmRevenues;
import 'package:crm/invoices/form/screen/add_invoice_screen.dart';
import 'package:crm/invoices/widgets/invoice_details_view.dart';
import 'package:crm/shared/models/revenue_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/navigation_service.dart' show navigationService;
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import 'package:intl/intl.dart';

final _moneyFmt = NumberFormat('#,##0.00', 'pl_PL');


Future<void> _openRevenueDetails(
  BuildContext context,
  bool isMobile,
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


class RevenueListWidget extends ConsumerWidget {
  final RevenueState data;
  final bool isMobile;
  const RevenueListWidget({
    super.key,
    required this.data,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final transactionsMap = {for (var tx in data.transactions) tx.id: tx};
    final selectedStatusName = ref.watch(selectedRevenueStatusProvider);

    final List<AgentRevenueModel> filteredTransactions =
        selectedStatusName == 'All'
            ? data.statuses
                .expand((status) => status.transactionIndex)
                .map((id) => transactionsMap[id])
                .where((tx) => tx != null)
                .cast<AgentRevenueModel>()
                .toList()
            : data.statuses
                .where((status) => status.statusName == selectedStatusName)
                .expand((status) => status.transactionIndex)
                .map((id) => transactionsMap[id])
                .where((tx) => tx != null)
                .cast<AgentRevenueModel>()
                .toList();


double? parseAmount(dynamic v) {
  if (v == null) return null;

  if (v is num) return v.toDouble();

  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;

    // remove spaces (including NBSP) and normalize decimal separator
    final normalized = s
        .replaceAll('\u00A0', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');

    return double.tryParse(normalized);
  }

  return null;
}




    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
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
                        // Expanded(
                        //   child: Text(
                        //     'Type'.tr,
                        //     style: TextStyle(
                        //       fontWeight: FontWeight.bold,
                        //       fontSize: 14,
                        //       color: theme.textColor,
                        //     ),
                        //   ),
                        // ),
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
                            'Is paid?'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.textColor,
                            ),
                          ),
                        ),

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

                        Expanded(
                          child: Text(
                            'Created_by'.tr,
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
                Expanded(
                  child:
                      filteredTransactions.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                AppLottie.noResults(size: 450),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 300,
                                    height: 45,
                                    child: ElevatedButton(
                                      style: elevatedButtonStyleRounded10,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (
                                            BuildContext dialogContext,
                                          ) {
                                            return Dialog(
                                              insetPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 24,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: SizedBox(
                                                width:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.7,
                                                height:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.height *
                                                    0.85,
                                                child: AddInvoiceScreen(
                                                  isMobile: false,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: AppIcons.add(
                                        color: theme.textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView(
                            padding: const EdgeInsets.only(bottom: 16),
                            children: [
                              ...filteredTransactions.map((transaction) {
                                if (isMobile) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: theme.dashboardBoarder,
                                    ),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      collapsedBackgroundColor:
                                          theme.textFieldColor,
                                      backgroundColor: const Color.fromRGBO(
                                        87,
                                        148,
                                        221,
                                        0.1,
                                      ),
                                      iconColor: theme.textColor.withAlpha(
                                        (255 * 0.5).toInt(),
                                      ),
                                      leading: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Color.fromRGBO(145, 145, 145, 1),
                                      ),
                                      showTrailingIcon: false,
                                      collapsedIconColor: theme.textColor
                                          .withAlpha((255 * 0.5).toInt()),
                                    title: InkWell(
                                    onTap: () => _openRevenueDetails(context, true, ref, revenue: transaction),
                                    child: Text(
                                      '${transaction.name}',
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),

                                      children: [
                                        ListTile(
                                          title: Text(
                                            'Status'.tr,
                                            style: TextStyle(
                                              color: theme.textColor.withAlpha(
                                                (255 * 0.5).toInt(),
                                              ),
                                            ),
                                          ),
                                          trailing: Text(
                                            transaction.transactionType ?? '-',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Color.fromRGBO(
                                                161,
                                                236,
                                                230,
                                                1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Email'.tr,
                                            style: TextStyle(
                                              color: theme.textColor.withAlpha(
                                                (255 * 0.5).toInt(),
                                              ),
                                            ),
                                          ),
                                          trailing: Text(
                                            transaction.name ?? '-',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Color.fromRGBO(
                                                161,
                                                236,
                                                230,
                                                1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Phone'.tr,
                                            style: TextStyle(
                                              color: theme.textColor.withAlpha(
                                                (255 * 0.5).toInt(),
                                              ),
                                            ),
                                          ),
                                          trailing: Text(
                                            transaction.dateCreate.toString(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Color.fromRGBO(
                                                161,
                                                236,
                                                230,
                                                1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Divider(),
                                        InkWell(
                                  onTap: () => _openRevenueDetails(context, true, ref, revenue: transaction),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.remove_red_eye,
                                                  color: theme.textColor,
                                                ),
                                                Text(
                                                  "View profile".tr,
                                                  style: TextStyle(
                                                    color: theme.textColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                /// Working Now Revenue
                                return InkWell(
                                  onTap:
                                      () => _openInvoiceDetails(
                                        context,
                                        ref,
                                        transaction: transaction,
                                        isMobile: isMobile,
                                      ),
                                  child: Stack(
                                    children: [
                                      PieMenu(
                                         theme: PieTheme.of(context).copyWith(
                        overlayColor:
                            (() {
                              final theme = ref.watch(themeColorsProvider);
                              final bool uiIsDark =
                                  theme.textColor.computeLuminance() > 0.5;

                              final base =
                                  uiIsDark ? Colors.black : Colors.white;
                              return base.withValues(alpha: 0.70);
                            })(),
                      ),
                                        onPressedWithDevice: (kind) {
                                          if (kind == PointerDeviceKind.mouse ||
                                              kind == PointerDeviceKind.touch) {
                                            _openInvoiceDetails(
                                              context,
                                              ref,
                                              transaction: transaction,
                                              isMobile: isMobile,
                                            );
                                          }
                                        },

                                        actions: pieMenuCrmRevenues(
                                          ref: ref,
                                          action: transaction,
                                          actionId: transaction.id,
                                          context: context,
                                          textColor: theme.textColor,
                                        ),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
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
                                                  '${transaction.name}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                                ),
                                              ),
                                              // Expanded(
                                              //   child: Text(
                                              //     transaction.transactionType ??
                                              //         '-',
                                              //     style: TextStyle(
                                              //       fontSize: 14,
                                              //       color: theme.textColor,
                                              //     ),
                                              //   ),
                                              // ),
                                              

                                          Expanded(
                                            child: Text(
                                              
                                              transaction.amount == null
                                                  ? '-'
                                                  : '${_moneyFmt.format(parseAmount(transaction.amount)).replaceAll('\u00A0', ' ')} ${transaction.currency ?? ''}'.trim(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: theme.textColor,
                                              ),
                                            ),
                                          ),




                                           Expanded(
                                              child: Text(
                                                transaction.paymentDate == null
                                                    ? '-'
                                                    : "${transaction.paymentDate!.year.toString().padLeft(4, '0')}-"
                                                      "${transaction.paymentDate!.month.toString().padLeft(2, '0')}-"
                                                      "${transaction.paymentDate!.day.toString().padLeft(2, '0')}",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: theme.textColor,
                                                ),
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
                                                      color: transaction.isPaid ? AppColors.revenueGreen : AppColors.redBeige,
                                                    )
                                                  ),
                                                  ] 
                                                ),


                                              ),
                                              Expanded(
                                                child: Text(
                                                  transaction.clients
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  transaction.note.toString(),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Positioned(
                                      //   right: 1,
                                      //   child: IconButton(
                                      //     icon: AppIcons.delete(
                                      //       color: theme.textColor,
                                      //     ),
                                      //     onPressed: () async {
                                      //       final confirmed = await showDialog(
                                      //         context: context,
                                      //         builder:
                                      //             (context) => AlertDialog(
                                      //               title: Text(
                                      //                 'Potwierdzenie'.tr,
                                      //               ),
                                      //               content: Text(
                                      //                 'Jesteś pewnien że chcesz usunąć ten przychód?'
                                      //                     .tr,
                                      //               ),
                                      //               actions: [
                                      //                 TextButton(
                                      //                   onPressed:
                                      //                       () => ref
                                      //                           .read(
                                      //                             navigationService,
                                      //                           )
                                      //                           .beamPop(false),
                                      //                   child: Text(
                                      //                     'Anuluj'.tr,
                                      //                   ),
                                      //                 ),
                                      //                 TextButton(
                                      //                   onPressed:
                                      //                       () => ref
                                      //                           .read(
                                      //                             navigationService,
                                      //                           )
                                      //                           .beamPop(true),
                                      //                   child: Text('Usuń'.tr),
                                      //                 ),
                                      //               ],
                                      //             ),
                                      //       );

                                      //       if (confirmed == true) {
                                      //         await ref
                                      //             .read(
                                      //               removeCrmRevenueProvider,
                                      //             )
                                      //             .removeCrmRevenue(
                                      //               transaction.id,
                                      //             );
                                      //       }
                                      //     },
                                      //   ),
                                      // ),
                                    ],
                                ));
                              }),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 300,
                                  height: 45,
                                  child: ElevatedButton(
                                    style: elevatedButtonStyleRounded10,
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (BuildContext dialogContext) {
                                          return Dialog(
                                            insetPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 24,
                                                  vertical: 24,
                                                ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: SizedBox(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.7,
                                              height:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.85,
                                              child: AddInvoiceScreen(
                                                isMobile: false,
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
                ),
                if (!isMobile)
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
                        Text(
                          'Showing ${filteredTransactions.length} out of ${filteredTransactions.length}'
                              .tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(
                              (255 * 0.85).toInt(),
                            ),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: AppIcons.iosArrowLeft(
                            color: theme.textColor.withAlpha(
                              (255 * 0.85).toInt(),
                            ),
                          ),
                          onPressed: () {},
                        ),
                        Text('1', style: TextStyle(color: theme.textColor)),
                        IconButton(
                          icon: AppIcons.iosArrowRight(
                            color: theme.textColor.withAlpha(
                              (255 * 0.85).toInt(),
                            ),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openInvoiceDetails(
    BuildContext context,
    WidgetRef ref, {
    required AgentRevenueModel transaction,
    required bool isMobile,
  }) {
    final theme = ref.read(themeColorsProvider);
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
            builder:
                (context, scrollController) => ExpensesViewDetailsWidget(
                  revenue: transaction,
                  isMobile: isMobile,
                  scrollController: scrollController,
                ),
          );
        },
      );
    } else {
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
              child: ExpensesViewDetailsWidget(
                revenue: transaction,
                isMobile: false,
              ),
            ),
          );
        },
      );
    }
  }

  String removeContactSegment(String path) {
    // This removes the last '/contact/:id/dashboard' from the path
    final regex = RegExp(r'/contact/\d+/dashboard$');
    return path.replaceAll(regex, '');
  }
}
