import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:crm/crm/finance/dashboard/api_dashboard.dart';
import 'package:crm/crm/finance/features/expenses/expenses_board.dart';
import 'package:crm/crm/finance/features/transactions/buttons.dart';
import 'package:crm/crm/finance/dashboard/finance_dashboard.dart';
import 'package:crm/crm/finance/features/revenue/buttons.dart';
import 'package:crm/crm/finance/features/futures_selected_view_widget.dart';
import 'package:crm/crm/finance/features/revenue/buttons.dart';
import 'package:crm/crm/finance/features/revenue/revenue_board.dart';
import 'package:crm/crm/finance/providers/finance_company_scope.dart';
import 'package:crm_fliper/finance/widget/finance_custom_tap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

enum FinanceMainScreen { unpaid, revenue, expenses, chart }

extension FinanceMainScreenX on FinanceMainScreen {
  String get label {
    switch (this) {
      case FinanceMainScreen.unpaid:
        return 'unpaid_title'.tr;
      case FinanceMainScreen.revenue:
        return 'revenues_title'.tr;
      case FinanceMainScreen.expenses:
        return 'expenses_title'.tr;
      case FinanceMainScreen.chart:
        return 'chart_title'.tr;
    }
  }

  String get description {
    switch (this) {
      case FinanceMainScreen.unpaid:
        return 'unpaid_description'.tr;
      case FinanceMainScreen.revenue:
        return 'revenue_description'.tr;
      case FinanceMainScreen.expenses:
        return 'expenses_description'.tr;
      case FinanceMainScreen.chart:
        return 'chart_description'.tr;
    }
  }

  IconData get icon {
    switch (this) {
      case FinanceMainScreen.unpaid:
        return Icons.payments_outlined;
      case FinanceMainScreen.revenue:
        return Icons.trending_up;
      case FinanceMainScreen.expenses:
        return Icons.trending_down;
      case FinanceMainScreen.chart:
        return Icons.insert_chart_outlined_rounded;
    }
  }
}

class DraggableFinanceCrmPc extends ConsumerStatefulWidget {
  final AppModule appModule;
  final int? companyId;

  const DraggableFinanceCrmPc({
    super.key,
    this.companyId,
    required this.appModule,
  });

  @override
  ConsumerState<DraggableFinanceCrmPc> createState() =>
      _DraggableFinanceCrmPcState();
}

class _DraggableFinanceCrmPcState extends ConsumerState<DraggableFinanceCrmPc> {
  final sideMenuKey = GlobalKey<SideMenuState>();

  late final PageController _mobilePageController;

  FinanceMainScreen _selectedScreen = FinanceMainScreen.unpaid;

  @override
  void initState() {
    super.initState();

    _mobilePageController = PageController(
      initialPage: _pageForScreen(_selectedScreen),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyInitialScope();
    });
  }

  @override
  void didUpdateWidget(covariant DraggableFinanceCrmPc oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextKind = _scopeKindFor(widget.appModule);
    final oldKind = _scopeKindFor(oldWidget.appModule);

    if (oldKind != nextKind) {
      ref.read(financeScopeKindProvider.notifier).state = nextKind;
      ref.read(financeCompanyIdProvider.notifier).state = null;
      _refreshFinanceProviders();
    }

    if (oldWidget.companyId != widget.companyId && widget.companyId != null) {
      ref.read(financeCompanyIdProvider.notifier).state = widget.companyId;
      _refreshFinanceProviders();
    }
  }

  @override
  void dispose() {
    _mobilePageController.dispose();
    super.dispose();
  }

  FinanceScopeKind _scopeKindFor(AppModule module) {
    return module == AppModule.association
        ? FinanceScopeKind.association
        : FinanceScopeKind.company;
  }

  void _applyInitialScope() {
    final kind = _scopeKindFor(widget.appModule);

    ref.read(financeScopeKindProvider.notifier).state = kind;

    if (widget.companyId != null) {
      ref.read(financeCompanyIdProvider.notifier).state = widget.companyId;
    }

    _refreshFinanceProviders();
  }

  void _refreshFinanceProviders() {
    ref.invalidate(unifiedTransactionsProvider);
    ref.invalidate(upcomingUnpaidTransactionsProvider);
  }

  int _pageForScreen(FinanceMainScreen screen) {
    switch (screen) {
      case FinanceMainScreen.expenses:
        return 0;
      case FinanceMainScreen.revenue:
        return 1;
      case FinanceMainScreen.unpaid:
        return 2;
      case FinanceMainScreen.chart:
        return 3;
    }
  }

  FinanceMainScreen _screenForPage(int page) {
    switch (page) {
      case 0:
        return FinanceMainScreen.expenses;
      case 1:
        return FinanceMainScreen.revenue;
      case 2:
        return FinanceMainScreen.unpaid;
      case 3:
      default:
        return FinanceMainScreen.chart;
    }
  }

  void _selectScreen(FinanceMainScreen screen, {bool animate = true}) {
    if (!mounted) return;

    final page = _pageForScreen(screen);

    setState(() {
      _selectedScreen = screen;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_mobilePageController.hasClients) return;

      final currentPage = _mobilePageController.page;
      final currentIndex =
          currentPage?.round() ?? _mobilePageController.initialPage;

      if (currentIndex == page) return;

      if (animate) {
        _mobilePageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      } else {
        _mobilePageController.jumpToPage(page);
      }
    });
  }

  Future<void> _openScreenSelector(BuildContext launcherContext) async {
    final theme = ref.read(themeColorsProvider);

    final selected = await showModalBottomSheet<FinanceMainScreen>(
      context: launcherContext,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(90),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.42,
          minChildSize: 0.28,
          maxChildSize: 0.78,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: _FinanceScreenSheet(
                controller: scrollController,
                selected: _selectedScreen,
                onSelected: (screen) {
                  Navigator.of(sheetContext).pop(screen);
                },
              ),
            );
          },
        );
      },
    );

    if (!mounted || selected == null) return;

    _selectScreen(selected);
  }

  Widget _buildPcLayout() {
    final tabIndex = ref.watch(financeTabIndexProvider);

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 1150;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Flexible(
                            flex: isCompact ? 3 : 4,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: FinanceCustomTapBar(
                                  appModule: widget.appModule,
                                  companyId: widget.companyId,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Flexible(
                            flex: isCompact ? 2 : 2,
                            child: Align(
                              alignment: Alignment.center,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: FinanceCompanyScopeButton(
                                  isMobile: false,
                                  initialCompanyId: widget.companyId,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            flex: isCompact ? 4 : 5,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    FinanceButtons(
                                      ref: ref,
                                      companyId: widget.companyId,
                                    ),
                                    const FinanceViewModeSelector(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: tabIndex,
                  children: [
                    const Center(child: FinanceDashboard()),
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

  Widget _buildMobilePager() {
    return Padding(
      padding: EdgeInsets.only(
        top: TopAppBarSize.resolve(context),
        bottom: BottomBarSize.resolve(context),
      ),
      child: PageView(
        controller: _mobilePageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (page) {
          final screen = _screenForPage(page);

          if (_selectedScreen != screen && mounted) {
            setState(() {
              _selectedScreen = screen;
            });
          }
        },
        children: [
          CrmExpensesBoard(ref: ref, isMobile: true),
          CrmRevenueBoard(ref: ref, isMobile: true),
          const FinanceDashboard(),
          const FinanceFullChartPage(),
        ],
      ),
    );
  }

  bool get _shouldShowViewModeButton {
    return _selectedScreen == FinanceMainScreen.revenue ||
        _selectedScreen == FinanceMainScreen.expenses;
  }

  @override
  Widget build(BuildContext context) {
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: widget.appModule,

      layoutTypePc: LayoutTypePc.stack,
      layoutTypeMobile: LayoutTypeMobile.stack,

      // Narrow/tablet uses mobile shell, so PC top buttons will not render there.
      tabletScaffoldMode: TabletScaffoldMode.mobile,

      enableScrool: false,

      childrenPc: [_buildPcLayout()],

      childMobile: _buildMobilePager(),

      // PC stays like before.
      verticalButtonsPc: const SizedBox.shrink(),

      // Mobile actions only here.
      verticalButtons: FinanceFloatingPanel(
        selectedScreen: _selectedScreen,
        showViewModeButton: _shouldShowViewModeButton,
        onOpenScreenSelector: _openScreenSelector,
        refFromParent: ref,
      ),
    );
  }
}

class _FinanceScreenSheet extends ConsumerWidget {
  final ScrollController controller;
  final FinanceMainScreen selected;
  final ValueChanged<FinanceMainScreen> onSelected;

  const _FinanceScreenSheet({
    required this.controller,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final screens = const [
      FinanceMainScreen.unpaid,
      FinanceMainScreen.revenue,
      FinanceMainScreen.expenses,
      FinanceMainScreen.chart,
    ];

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: theme.textColor.withAlpha(80),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'finance_screens_title'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'finance_screens_subtitle'.tr,
          style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...screens.map((screen) {
          final isSelected = selected == screen;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelected(screen),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? theme.themeColor.withAlpha(220)
                          : theme.textFieldColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isSelected
                            ? theme.themeColor
                            : theme.textColor.withAlpha(25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? theme.themeTextColor.withAlpha(30)
                                : theme.dashboardContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        screen.icon,
                        color:
                            isSelected ? theme.themeTextColor : theme.textColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            screen.label,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? theme.themeTextColor
                                      : theme.textColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            screen.description,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? theme.themeTextColor.withAlpha(190)
                                      : theme.textColor.withAlpha(145),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: theme.themeTextColor,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class FinanceFloatingPanel extends ConsumerStatefulWidget {
  final FinanceMainScreen selectedScreen;
  final bool showViewModeButton;
  final Future<void> Function(BuildContext context) onOpenScreenSelector;
  final WidgetRef refFromParent;

  const FinanceFloatingPanel({
    super.key,
    required this.selectedScreen,
    required this.showViewModeButton,
    required this.onOpenScreenSelector,
    required this.refFromParent,
  });

  @override
  ConsumerState<FinanceFloatingPanel> createState() =>
      _FinanceFloatingPanelState();
}

class _FinanceFloatingPanelState extends ConsumerState<FinanceFloatingPanel> {
  String? _openPanel;

  void _toggle(String panel) {
    setState(() {
      _openPanel = _openPanel == panel ? null : panel;
    });
  }

  Future<void> _openScreens(BuildContext context) async {
    setState(() {
      _openPanel = null;
    });

    await widget.onOpenScreenSelector(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _FloatingPanelRow(
          isOpen: false,
          panel: const SizedBox.shrink(),
          button: _FloatingIconButton(
            icon: widget.selectedScreen.icon,
            tooltip: 'screens_tooltip'.tr,
            theme: theme,
            onTap: () => _openScreens(context),
          ),
        ),
        const SizedBox(height: 6),

        if (widget.showViewModeButton) ...[
          _FloatingPanelRow(
            isOpen: _openPanel == 'view',
            panel: FinanceViewModeSelector(
              isMobile: true,
              onSelectionChanged: () => _toggle('view'),
            ),
            button: _FloatingIconButton(
              icon: Icons.view_kanban_outlined,
              tooltip: 'board_list_tooltip'.tr,
              theme: theme,
              isActive: _openPanel == 'view',
              onTap: () => _toggle('view'),
            ),
          ),
          const SizedBox(height: 6),
        ],

        _FloatingPanelRow(
          isOpen: _openPanel == 'statuses',
          panel: FinanceStatusActionsButton(
            ref: widget.refFromParent,
            isMobile: true,
          ),
          button: _FloatingIconButton(
            icon: Icons.edit_note_rounded,
            tooltip: 'edit_statuses_tooltip'.tr,
            theme: theme,
            isActive: _openPanel == 'statuses',
            onTap: () => _toggle('statuses'),
          ),
        ),
        const SizedBox(height: 6),

        _FloatingPanelRow(
          isOpen: _openPanel == 'filters',
          panel: FinanceFilterActionsButton(
            ref: widget.refFromParent,
            isMobile: true,
          ),
          button: _FloatingIconButton(
            icon: Icons.filter_alt_rounded,
            tooltip: 'filters_tooltip'.tr,
            theme: theme,
            isActive: _openPanel == 'filters',
            onTap: () => _toggle('filters'),
          ),
        ),
      ],
    );
  }
}

class _FloatingPanelRow extends StatelessWidget {
  final bool isOpen;
  final Widget panel;
  final Widget button;

  const _FloatingPanelRow({
    required this.isOpen,
    required this.panel,
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child:
              isOpen
                  ? Container(
                    key: const ValueKey('panel'),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: AppColors.dark50,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(60),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: panel,
                  )
                  : const SizedBox.shrink(key: ValueKey('empty')),
        ),
        button,
      ],
    );
  }
}

class _FloatingIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final dynamic theme;
  final bool isActive;
  final VoidCallback onTap;

  const _FloatingIconButton({
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
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: isActive ? theme.themeColor : theme.textFieldColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 12),
          ],
        ),
        child: IconButton(
          style: elevatedButtonStyleRounded10,
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

class CrmFinanceSegmentSelector extends ConsumerWidget {
  final String selectedSegment;
  final void Function(Set<String>) onSelectionChanged;

  const CrmFinanceSegmentSelector({
    super.key,
    required this.selectedSegment,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentthememode = ref.watch(themeProvider);

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            gradient: CustomBackgroundGradients.crmadgradient(context, ref),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith<Color>(
                (states) => Theme.of(context).iconTheme.color!,
              ),
              padding: WidgetStateProperty.all<EdgeInsets>(
                const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
              ),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return (currentthememode == ThemeMode.system ||
                          currentthememode == ThemeMode.light)
                      ? AppColors.dark75
                      : AppColors.dark25;
                }
                return Colors.transparent;
              }),
              side: WidgetStateProperty.all<BorderSide>(BorderSide.none),
            ),
            multiSelectionEnabled: false,
            selected: {selectedSegment},
            onSelectionChanged: onSelectionChanged,
            segments: <ButtonSegment<String>>[
              _buildSegment('Transakcje', '/transactions', selectedSegment),
              _buildSegment('Przychody', '/revenue', selectedSegment),
              _buildSegment('Koszty', '/expenses', selectedSegment),
            ],
          ),
        ),
      ),
    );
  }

  ButtonSegment<String> _buildSegment(
    String label,
    String value,
    String selected,
  ) {
    return ButtonSegment(
      value: value,
      label: SizedBox(
        height: 40,
        width: 110,
        child: Center(
          child: Text(
            label.tr,
            style: TextStyle(
              fontWeight:
                  selected == value ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              color:
                  selected == value
                      ? const Color.fromRGBO(161, 236, 230, 1)
                      : AppColors.light,
            ),
          ),
        ),
      ),
    );
  }
}

class SegmentFloatingPanel extends ConsumerStatefulWidget {
  final String selectedSegment;
  final Function(Set<String>) onSelectionChanged;

  const SegmentFloatingPanel({
    super.key,
    required this.selectedSegment,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<SegmentFloatingPanel> createState() =>
      _SegmentFloatingPanelState();
}

class _SegmentFloatingPanelState extends ConsumerState<SegmentFloatingPanel>
    with SingleTickerProviderStateMixin {
  bool isOpen = false;
  bool isListModelOpen = false;
  bool isButtonsOpen = false;

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void togglePanel() {
    setState(() {
      isOpen = !isOpen;
      if (isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void toggleListModelPanel() {
    setState(() {
      isListModelOpen = !isListModelOpen;
      if (isListModelOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void toggleButtonsPanel() {
    setState(() {
      isButtonsOpen = !isButtonsOpen;
      if (isButtonsOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(financeTabIndexProvider);
    final theme = ref.watch(themeColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (isOpen)
                  SizedBox(
                    width: 300,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: AppColors.dark50,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: CrmFinanceSegmentSelector(
                            selectedSegment: widget.selectedSegment,
                            onSelectionChanged: (selected) {
                              final notifier = ref.read(
                                financeTabIndexProvider.notifier,
                              );
                              final selectedValue = selected.first;

                              if (selectedValue.contains('/transactions')) {
                                notifier.state = 0;
                              } else if (selectedValue.contains('/revenue')) {
                                notifier.state = 1;
                              } else if (selectedValue.contains('/expenses')) {
                                notifier.state = 2;
                              }

                              widget.onSelectionChanged(selected);
                              togglePanel();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: theme.textFieldColor,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                  child: IconButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed: togglePanel,
                    icon: Icon(
                      isOpen ? Icons.close : Icons.tune,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (isListModelOpen)
                  SlideTransition(
                    position: _slideAnimation,
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: AppColors.dark50,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: FinanceViewModeSelector(
                          onSelectionChanged: () {
                            toggleListModelPanel();
                          },
                          isMobile: true,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: theme.textFieldColor,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                  child: IconButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed: toggleListModelPanel,
                    icon: Icon(Icons.filter_alt, color: theme.textColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (isButtonsOpen)
                  SizedBox(
                    width: 300,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: AppColors.dark50,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: IntrinsicWidth(
                              child: IndexedStack(
                                alignment: Alignment.centerRight,
                                index: tabIndex,
                                children: [
                                  FinanaceTransactionsButtons(
                                    ref: ref,
                                    isMobile: true,
                                  ),
                                  FinanceButtons(ref: ref, isMobile: true),
                                  FinanceButtons(ref: ref, isMobile: true),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: theme.textFieldColor,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                  child: IconButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed: toggleButtonsPanel,
                    icon: Icon(Icons.settings, color: theme.textColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
