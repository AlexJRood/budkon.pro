import 'package:crm/crm/finance/dashboard/finance_dashboard.dart';
import 'package:crm/crm/finance/features/expenses/expenses_board.dart';
import 'package:crm/crm/finance/features/revenue/revenue_board.dart';
import 'package:crm/crm/finance/providers/finance_company_scope.dart';
import 'package:crm_fliper/finance/widget/finance_custom_tap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:crm/crm/finance/features/transactions/buttons.dart';
import 'package:crm/crm/finance/features/revenue/buttons.dart';
import 'package:crm/crm/finance/features/futures_selected_view_widget.dart';
import 'package:core/theme/apptheme.dart';

class FinanceCrmTablet extends ConsumerWidget {
  final AppModule appModule;
  final int? companyId;

  const FinanceCrmTablet({super.key, required this.appModule, this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(financeTabIndexProvider);
    final theme = ref.watch(themeColorsProvider);

    return Column(
      children: [
        // Tablet Header - Stacked for 800-1200px
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dashboardBoarder)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FinanceCustomTapBar(
                    appModule: appModule,
                    isTablet: true,
                    companyId: companyId,
                  ),
                  FinanceCompanyScopeButton(
                    isMobile: false,
                    initialCompanyId: companyId,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IndexedStack(
                        alignment: Alignment.centerLeft,
                        index: tabIndex,
                        children: [
                          FinanaceTransactionsButtons(ref: ref),
                          FinanceButtons(ref: ref, companyId: companyId),
                          FinanceButtons(ref: ref, companyId: companyId),
                        ],
                      ),
                    ),
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
    );
  }
}
