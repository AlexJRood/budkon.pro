import 'package:crm/crm/finance/dashboard/finance_dashboard.dart';
import 'package:crm/crm/finance/features/expenses/expenses_board.dart';
import 'package:crm/crm/finance/features/futures_selected_view_widget.dart';
import 'package:crm/crm/finance/features/revenue/revenue_board.dart';
import 'package:crm/crm/finance/providers/finance_company_scope.dart';
import 'package:crm_fliper/finance/widget/finance_custom_tap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:crm/crm/finance/features/transactions/buttons.dart';
import 'package:crm/crm/finance/features/revenue/buttons.dart';

class FinanceCrmPc extends ConsumerWidget {
  final AppModule appModule;
  final int? companyId;

  const FinanceCrmPc({super.key, required this.appModule, this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(financeTabIndexProvider);

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FinanceCustomTapBar(
                      appModule: appModule,
                      companyId: companyId,
                    ),

                    // ✅ selector reads resolved scope from providers
                    FinanceCompanyScopeButton(
                      isMobile: false,
                      initialCompanyId: companyId,
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IndexedStack(
                          alignment: Alignment.centerRight,
                          index: tabIndex,
                          children: [
                            FinanaceTransactionsButtons(ref: ref),
                            FinanceButtons(ref: ref, companyId: companyId),
                            FinanceButtons(ref: ref, companyId: companyId),
                          ],
                        ),
                        FinanceViewModeSelector(),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: tabIndex,
                  children: [
                    Center(child: FinanceDashboard()),
                    Center(child: CrmRevenueBoard(ref: ref)),
                    Center(child: CrmExpensesBoard(ref: ref)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
