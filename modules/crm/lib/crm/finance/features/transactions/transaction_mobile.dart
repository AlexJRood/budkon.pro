import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:crm/crm/finance/dashboard/api_dashboard.dart';
import 'package:crm/crm/finance/features/futures_selected_view_widget.dart';
import 'package:crm/crm/finance/features/revenue/buttons.dart';
import 'package:crm/crm/finance/features/transactions/buttons.dart';
import 'package:crm/crm/finance/features/transactions/transaction_board.dart';
import 'package:crm/crm/finance/providers/finance_company_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class DraggableFinanceTransactionsCrmPc extends ConsumerStatefulWidget {
  final AppModule appModule;
  final int? companyId;

  const DraggableFinanceTransactionsCrmPc({
    super.key,
    required this.appModule,
    this.companyId,
  });

  @override
  ConsumerState<DraggableFinanceTransactionsCrmPc> createState() =>
      _DraggableFinanceTransactionsCrmPcState();
}

class _DraggableFinanceTransactionsCrmPcState
    extends ConsumerState<DraggableFinanceTransactionsCrmPc> {
  final sideMenuKey = GlobalKey<SideMenuState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kind = widget.appModule == AppModule.association
          ? FinanceScopeKind.association
          : FinanceScopeKind.company;

      ref.read(financeScopeKindProvider.notifier).state = kind;

      if (widget.companyId != null) {
        ref.read(financeCompanyIdProvider.notifier).state = widget.companyId;
      }

      ref.invalidate(unifiedTransactionsProvider);
      ref.invalidate(upcomingUnpaidTransactionsProvider);
    });
  }

  @override
  void didUpdateWidget(
    covariant DraggableFinanceTransactionsCrmPc oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final kind = widget.appModule == AppModule.association
        ? FinanceScopeKind.association
        : FinanceScopeKind.company;

    final oldKind = oldWidget.appModule == AppModule.association
        ? FinanceScopeKind.association
        : FinanceScopeKind.company;

    if (oldKind != kind) {
      ref.read(financeScopeKindProvider.notifier).state = kind;
      ref.read(financeCompanyIdProvider.notifier).state = null;

      ref.invalidate(unifiedTransactionsProvider);
      ref.invalidate(upcomingUnpaidTransactionsProvider);
    }

    if (oldWidget.companyId != widget.companyId && widget.companyId != null) {
      ref.read(financeCompanyIdProvider.notifier).state = widget.companyId;

      ref.invalidate(unifiedTransactionsProvider);
      ref.invalidate(upcomingUnpaidTransactionsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: widget.appModule,
      layoutTypePc: LayoutTypePc.stack,
      enableScrool: false,

      childrenPc: [
        Column(
          children: [
            _TransactionsTopBar(
              companyId: widget.companyId,
              appModule: widget.appModule,
            ),
            Expanded(
              child: CrmTransactionBoard(
                ref: ref,
                isMobile: false,
              ),
            ),
          ],
        ),
      ],

      childMobile: Padding(
        padding: EdgeInsets.only(
          top: TopAppBarSize.resolve(context),
          bottom: BottomBarSize.resolve(context),
        ),
        child: CrmTransactionBoard(
          ref: ref,
          isMobile: true,
        ),
      ),

      verticalButtons: TransactionsFloatingPanel(
        refFromParent: ref,
      ),
    );
  }
}

class _TransactionsTopBar extends ConsumerWidget {
  final int? companyId;
  final AppModule appModule;

  const _TransactionsTopBar({
    required this.companyId,
    required this.appModule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.textColor.withAlpha(25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    color: theme.textColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Transactions'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            FinanceCompanyScopeButton(
              isMobile: false,
              initialCompanyId: companyId,
            ),
            const SizedBox(width: 10),
            FinanaceTransactionsButtons(
              ref: ref,
              isMobile: false,
            ),
            const SizedBox(width: 10),
            const FinanceViewModeSelector(),
          ],
        ),
      ),
    );
  }
}

class TransactionsFloatingPanel extends ConsumerStatefulWidget {
  final WidgetRef refFromParent;

  const TransactionsFloatingPanel({
    super.key,
    required this.refFromParent,
  });

  @override
  ConsumerState<TransactionsFloatingPanel> createState() =>
      _TransactionsFloatingPanelState();
}

class _TransactionsFloatingPanelState
    extends ConsumerState<TransactionsFloatingPanel> {
  bool _viewOpen = false;
  bool _actionsOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_viewOpen)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.dark50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FinanceViewModeSelector(
                  isMobile: true,
                  onSelectionChanged: () {
                    setState(() => _viewOpen = false);
                  },
                ),
              ),
            _SmallFloatingButton(
              icon: Icons.view_kanban_outlined,
              theme: theme,
              isActive: _viewOpen,
              onTap: () {
                setState(() {
                  _viewOpen = !_viewOpen;
                  _actionsOpen = false;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_actionsOpen)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  color: AppColors.dark50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FinanaceTransactionsButtons(
                  ref: widget.refFromParent,
                  isMobile: true,
                ),
              ),
            _SmallFloatingButton(
              icon: Icons.tune_rounded,
              theme: theme,
              isActive: _actionsOpen,
              onTap: () {
                setState(() {
                  _actionsOpen = !_actionsOpen;
                  _viewOpen = false;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _SmallFloatingButton extends StatelessWidget {
  final IconData icon;
  final dynamic theme;
  final bool isActive;
  final VoidCallback onTap;

  const _SmallFloatingButton({
    required this.icon,
    required this.theme,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        color: isActive ? theme.themeColor : theme.textFieldColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: isActive ? theme.themeTextColor : theme.textColor,
        ),
      ),
    );
  }
}