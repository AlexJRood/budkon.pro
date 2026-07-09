import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';

import 'package:crm/crm/finance/dashboard/api_dashboard.dart';
import 'package:crm/crm/finance/features/futures_selected_view_widget.dart';
import 'package:crm/crm/finance/features/revenue/buttons.dart';
import 'package:crm/crm/finance/features/transactions/buttons.dart';
import 'package:crm/crm/finance/features/transactions/transaction_board.dart';
import 'package:crm/crm/finance/providers/finance_company_scope.dart';

import 'package:crm/draft/components/list.dart';
import 'package:crm_agent/screens/tx/tx_custom_tap_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class TxPc extends ConsumerStatefulWidget {
  final AppModule appModule;
  final int? companyId;

  /// Zostaw true, jeśli ekran transakcji ma pracować na scope firmy/stowarzyszenia.
  final bool enableFinanceScope;

  const TxPc({
    super.key,
    this.appModule = AppModule.agentCrm,
    this.companyId,
    this.enableFinanceScope = true,
  });

  @override
  ConsumerState<TxPc> createState() => _TxPcState();
}

class _TxPcState extends ConsumerState<TxPc> {
  final sideMenuKey = GlobalKey<SideMenuState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyScope();
    });
  }

  @override
  void didUpdateWidget(covariant TxPc oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.enableFinanceScope) return;

    final nextKind = _scopeKindFor(widget.appModule);
    final oldKind = _scopeKindFor(oldWidget.appModule);

    if (nextKind != oldKind) {
      ref.read(financeScopeKindProvider.notifier).state = nextKind;
      ref.read(financeCompanyIdProvider.notifier).state = null;
      _refreshFinanceData();
    }

    if (oldWidget.companyId != widget.companyId && widget.companyId != null) {
      ref.read(financeCompanyIdProvider.notifier).state = widget.companyId;
      _refreshFinanceData();
    }
  }

  FinanceScopeKind _scopeKindFor(AppModule module) {
    return module == AppModule.association
        ? FinanceScopeKind.association
        : FinanceScopeKind.company;
  }

  void _applyScope() {
    if (!widget.enableFinanceScope) return;

    final kind = _scopeKindFor(widget.appModule);
    ref.read(financeScopeKindProvider.notifier).state = kind;

    if (widget.companyId != null) {
      ref.read(financeCompanyIdProvider.notifier).state = widget.companyId;
    }

    _refreshFinanceData();
  }

  void _refreshFinanceData() {
    ref.invalidate(unifiedTransactionsProvider);
    ref.invalidate(upcomingUnpaidTransactionsProvider);
  }

  bool _isTransactionTab(int tabIndex) {
    return tabIndex == 0 || tabIndex == 1;
  }

  Widget _buildBody({
    required int tabIndex,
    required bool isMobile,
  }) {
    return IndexedStack(
      index: tabIndex,
      children: [
        CrmTransactionBoard(
          ref: ref,
          isMobile: isMobile,
        ),
        CrmTransactionBoard(
          ref: ref,
          isMobile: isMobile,
        ),
        const DraftAdvertisementsList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(txTabIndexProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: widget.appModule,
      layoutTypePc: LayoutTypePc.stack,
      enableScrool: false,

      childrenPc: [
        Column(
          children: [
            _TxTopBar(
              tabIndex: tabIndex,
              companyId: widget.companyId,
              showCompanyScope: widget.enableFinanceScope,
              showViewModeSelector: _isTransactionTab(tabIndex),
            ),
            Expanded(
              child: _buildBody(
                tabIndex: tabIndex,
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
        child: Column(
          children: [
            const SizedBox(
              height: 58,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: TxCustomTapBar(),
              ),
            ),
            Expanded(
              child: _buildBody(
                tabIndex: tabIndex,
                isMobile: true,
              ),
            ),
          ],
        ),
      ),

      verticalButtons: TransactionsFloatingPanel(
        refFromParent: ref,
        tabIndex: tabIndex,
        showViewModeSelector: _isTransactionTab(tabIndex),
      ),
    );
  }
}

class _TxTopBar extends ConsumerWidget {
  final int tabIndex;
  final int? companyId;
  final bool showCompanyScope;
  final bool showViewModeSelector;

  const _TxTopBar({
    required this.tabIndex,
    required this.companyId,
    required this.showCompanyScope,
    required this.showViewModeSelector,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const TxCustomTapBar(),

            const Spacer(),

            if (showCompanyScope) ...[
              FinanceCompanyScopeButton(
                isMobile: false,
                initialCompanyId: companyId,
              ),
              const SizedBox(width: 10),
            ],

            if (tabIndex == 0 || tabIndex == 1)
              FinanaceTransactionsButtons(
                ref: ref,
                isMobile: false,
              ),

            if (tabIndex == 2)
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.drafts_outlined,
                      color: theme.textColor,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Drafts'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

            if (showViewModeSelector) ...[
              const SizedBox(width: 10),
              const FinanceViewModeSelector(),
            ],
          ],
        ),
      ),
    );
  }
}

class TransactionsFloatingPanel extends ConsumerStatefulWidget {
  final WidgetRef refFromParent;
  final int tabIndex;
  final bool showViewModeSelector;

  const TransactionsFloatingPanel({
    super.key,
    required this.refFromParent,
    required this.tabIndex,
    required this.showViewModeSelector,
  });

  @override
  ConsumerState<TransactionsFloatingPanel> createState() =>
      _TransactionsFloatingPanelState();
}

class _TransactionsFloatingPanelState
    extends ConsumerState<TransactionsFloatingPanel> {
  bool _viewOpen = false;
  bool _actionsOpen = false;

  bool get _isTransactionTab {
    return widget.tabIndex == 0 || widget.tabIndex == 1;
  }

  @override
  void didUpdateWidget(covariant TransactionsFloatingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tabIndex != widget.tabIndex && !_isTransactionTab) {
      _viewOpen = false;
      _actionsOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    if (!_isTransactionTab) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.showViewModeSelector) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_viewOpen)
                _FloatingPanelContainer(
                  child: FinanceViewModeSelector(
                    isMobile: true,
                    onSelectionChanged: () {
                      setState(() => _viewOpen = false);
                    },
                  ),
                ),
              _SmallFloatingButton(
                icon: Icons.view_kanban_outlined,
                tooltip: 'board_list_tooltip'.tr,
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
        ],

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_actionsOpen)
              _FloatingPanelContainer(
                maxWidth: 340,
                child: FinanaceTransactionsButtons(
                  ref: widget.refFromParent,
                  isMobile: true,
                ),
              ),
            _SmallFloatingButton(
              icon: Icons.tune_rounded,
              tooltip: 'actions_tooltip'.tr,
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

class _FloatingPanelContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const _FloatingPanelContainer({
    required this.child,
    this.maxWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(8),
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: AppColors.dark50,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SmallFloatingButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final dynamic theme;
  final bool isActive;
  final VoidCallback onTap;

  const _SmallFloatingButton({
    required this.icon,
    required this.tooltip,
    required this.theme,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        height: 45,
        width: 45,
        decoration: BoxDecoration(
          color: isActive ? theme.themeColor : theme.textFieldColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(
            icon,
            color: isActive ? theme.themeTextColor : theme.textColor,
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility wrapper.
/// Możesz zostawić stare routy bez zmian.
class DraggableFinanceTransactionsCrmPc extends StatelessWidget {
  final AppModule appModule;
  final int? companyId;

  const DraggableFinanceTransactionsCrmPc({
    super.key,
    required this.appModule,
    this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    return TxPc(
      appModule: appModule,
      companyId: companyId,
      enableFinanceScope: true,
    );
  }
}