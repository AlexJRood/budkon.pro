import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/settings/settings.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:crm/contact_panel/tabs/employee_settlements/employee_settlement_dashboard.dart';
import 'package:crm/calendar/widgets/member_calendar_hr_layer.dart';
import 'package:crm/widget/crm_dashboard_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:crm/employee_panel/provider/employee_managment_provider.dart';
import 'package:crm/employee_panel/widgets/employee_absence_widgets.dart';
import 'package:crm/employee_panel/widgets/employee_availability_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

class EmployeeManagementPanelScreen extends StatefulWidget {
  final int? initialEmployeeId;

  /// Kept for backwards compatibility with older routes.
  /// The actual mobile/desktop content is now resolved by BarManager.
  final bool isMobile;

  const EmployeeManagementPanelScreen({
    super.key,
    this.initialEmployeeId,
    this.isMobile = false,
  });

  @override
  State<EmployeeManagementPanelScreen> createState() =>
      _EmployeeManagementPanelScreenState();
}

class _EmployeeManagementPanelScreenState
    extends State<EmployeeManagementPanelScreen> {
  final GlobalKey<SideMenuState> _sideMenuKey = GlobalKey<SideMenuState>(
    debugLabel: 'employee-management-side-menu',
  );

  @override
  Widget build(BuildContext context) {
    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.agentCrm,
      isChildExpanded: true,
      paddingPc: 0,
      paddingTablet: 0,
      paddingMobile: 0,
      tabletScaffoldMode: TabletScaffoldMode.pc,
      childPc: _EmployeeManagementPanelContent(
        initialEmployeeId: widget.initialEmployeeId,
        isMobile: false,
      ),
      childTablet: _EmployeeManagementPanelContent(
        initialEmployeeId: widget.initialEmployeeId,
        isMobile: false,
      ),
      childMobile: _EmployeeManagementPanelContent(
        initialEmployeeId: widget.initialEmployeeId,
        isMobile: true,
      ),
    );
  }
}

class _EmployeeManagementPanelContent extends ConsumerStatefulWidget {
  final bool isMobile;
  final int? initialEmployeeId;

  const _EmployeeManagementPanelContent({
    this.isMobile = false,
    this.initialEmployeeId,
  });

  @override
  ConsumerState<_EmployeeManagementPanelContent> createState() =>
      _EmployeeManagementPanelContentState();
}

class _EmployeeManagementPanelContentState
    extends ConsumerState<_EmployeeManagementPanelContent> {
  final TextEditingController _searchController = TextEditingController();

  late String _period;
  String _currency = 'PLN';
  int? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    _period = _currentPeriod();
    _selectedEmployeeId = widget.initialEmployeeId;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant _EmployeeManagementPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialEmployeeId != widget.initialEmployeeId) {
      setState(() {
        _selectedEmployeeId = widget.initialEmployeeId;
      });
    }
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  EmployeeManagementDashboardParams get _params =>
      EmployeeManagementDashboardParams(
        period: _period,
        currency: _currency,
      );

  Future<void> _refresh({bool showLoading = false}) async {
    await ref
        .read(employeeManagementDashboardProvider(_params).notifier)
        .fetch(showLoading: showLoading);
  }

  Future<void> _openCreateSubAccount(ThemeColors theme) async {
    ref.invalidate(subAccountFormProvider);

    if (_useBottomSheet()) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: theme.dashboardContainer,
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.55,
            maxChildSize: 0.95,
            expand: false,
            shouldCloseOnMinExtent: true,
            builder: (context, scrollController) {
              return CreateSubAccountCardWidgetSheet(
                scrollController: scrollController,
              );
            },
          );
        },
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16),
          child: CreateSubAccountCardWidget(),
        ),
      );
    }

    if (!mounted) return;
    await ref.read(subAccountProvider.notifier).fetchSubAccounts();
    await _refresh(showLoading: false);
  }

  Future<void> _openEditSubAccount(
    ThemeColors theme,
    EmployeeManagementEmployeeModel employee,
  ) async {
    final member = _toSubAccountMember(employee);
    if (member == null) return;

    ref.invalidate(subAccountFormProvider);

    if (_useBottomSheet()) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: theme.dashboardContainer,
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.55,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return CreateSubAccountCardWidgetSheet(
                isEdit: true,
                member: member,
                scrollController: scrollController,
              );
            },
          );
        },
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: CreateSubAccountCardWidget(
            isEdit: true,
            member: member,
          ),
        ),
      );
    }

    if (!mounted) return;
    await ref.read(subAccountProvider.notifier).fetchSubAccounts();
    await _refresh(showLoading: false);
  }

  Future<void> _deactivateEmployee(
    ThemeColors theme,
    EmployeeManagementEmployeeModel employee,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.dashboardContainer,
          title: Text(
            'deactivate_employee'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '${'deactivate_employee_confirm'.tr} ${employee.user.email}',
            style: TextStyle(color: theme.textColor.withAlpha(190)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr, style: TextStyle(color: theme.textColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.themeColor),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'deactivate'.tr,
                style: TextStyle(color: theme.dashboardContainer),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success = await ref
        .read(subAccountProvider.notifier)
        .deActiveSubAccount(employee.user.id.toString());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'employee_deactivated'.tr : 'employee_deactivate_failed'.tr,
        ),
      ),
    );

    if (success) {
      await ref.read(subAccountProvider.notifier).fetchSubAccounts();
      await _refresh(showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(employeeManagementDashboardProvider(_params));

    final topPadding = widget.isMobile ? TopAppBarSize.resolve(context) : 0.0;
    final bottomPadding = widget.isMobile ? BottomBarSize.resolve(context) : 0.0;

    return Padding(
      padding: EdgeInsets.only(
        left: widget.isMobile ? 10 : 24,
        right: widget.isMobile ? 10 : 24,
        top: widget.isMobile ? topPadding + 8 : 18,
        bottom: widget.isMobile ? bottomPadding + 8 : 18,
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: theme.textColor),
        child: IconTheme.merge(
          data: IconThemeData(color: theme.textColor),
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              error: error,
              onRetry: () => _refresh(showLoading: true),
            ),
            data: (data) {
              final employees = _filteredEmployees(data.employees);
              final selected = _resolveSelected(employees);

              void selectEmployee(EmployeeManagementEmployeeModel employee) {
                setState(() {
                  _selectedEmployeeId =
                      _selectedEmployeeId == employee.user.id
                          ? null
                          : employee.user.id;
                });
              }

              // Mobile: full-screen list OR full-screen details (master-detail)
              if (widget.isMobile) {
                if (selected != null) {
                  return _EmployeeDetailsPane(
                    employee: selected,
                    period: _period,
                    currency: _currency,
                    isMobile: true,
                    onEditEmployee: () => _openEditSubAccount(theme, selected),
                    onAbsenceChanged: () => _refresh(showLoading: false),
                    onBackToSummary: () {
                      setState(() { _selectedEmployeeId = null; });
                    },
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MobileHeaderBar(
                      searchController: _searchController,
                      onRefresh: () => _refresh(showLoading: true),
                      onAddEmployee: () => _openCreateSubAccount(theme),
                      onOpenFilters: () => _showMobileFiltersSheet(theme),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _EmployeeListPanel(
                        employees: employees,
                        selectedEmployeeId: null,
                        onSelect: selectEmployee,
                        onEdit: (e) => _openEditSubAccount(theme, e),
                        onDeactivate: (e) => _deactivateEmployee(theme, e),
                      ),
                    ),
                  ],
                );
              }

              // Tablet / desktop layout
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderBar(
                    period: _period,
                    currency: _currency,
                    searchController: _searchController,
                    onPeriodChanged: (value) {
                      if (value == null || value == _period) return;
                      setState(() { _period = value; });
                    },
                    onCurrencyChanged: (value) {
                      if (value == null || value == _currency) return;
                      setState(() { _currency = value; });
                    },
                    onRefresh: () => _refresh(showLoading: true),
                    onAddEmployee: () => _openCreateSubAccount(theme),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 1050) {
                          return Column(
                            children: [
                              Expanded(
                                flex: selected == null ? 5 : 4,
                                child: _EmployeeListPanel(
                                  employees: employees,
                                  selectedEmployeeId: selected?.user.id,
                                  onSelect: selectEmployee,
                                  onEdit: (e) => _openEditSubAccount(theme, e),
                                  onDeactivate: (e) => _deactivateEmployee(theme, e),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Expanded(
                                flex: selected == null ? 7 : 8,
                                child: selected == null
                                    ? _EmployeeOverviewPane(data: data, employees: employees)
                                    : _EmployeeDetailsPane(
                                        employee: selected,
                                        period: _period,
                                        currency: _currency,
                                        isMobile: false,
                                        onEditEmployee: () => _openEditSubAccount(theme, selected),
                                        onAbsenceChanged: () => _refresh(showLoading: false),
                                        onBackToSummary: () {
                                          setState(() { _selectedEmployeeId = null; });
                                        },
                                      ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 430,
                              child: _EmployeeListPanel(
                                employees: employees,
                                selectedEmployeeId: selected?.user.id,
                                onSelect: selectEmployee,
                                onEdit: (e) => _openEditSubAccount(theme, e),
                                onDeactivate: (e) => _deactivateEmployee(theme, e),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: selected == null
                                  ? _EmployeeOverviewPane(data: data, employees: employees)
                                  : _EmployeeDetailsPane(
                                      employee: selected,
                                      period: _period,
                                      currency: _currency,
                                      isMobile: false,
                                      onEditEmployee: () => _openEditSubAccount(theme, selected),
                                      onAbsenceChanged: () => _refresh(showLoading: false),
                                      onBackToSummary: () {
                                        setState(() { _selectedEmployeeId = null; });
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMobileFiltersSheet(ThemeColors theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (sheetCtx, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Material(
            color: theme.dashboardContainer,
            child: SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16, right: 16, top: 12,
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                ),
                child: StatefulBuilder(
                  builder: (_, setSheet) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42, height: 4,
                          decoration: BoxDecoration(
                            color: theme.dashboardBoarder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: CoreDropdown<String>(
                          label: 'period'.tr,
                          value: _period,
                          options: _periodOptions(),
                          display: _periodDisplay,
                          onChanged: (v) {
                            if (v == null || v == _period) return;
                            setSheet(() {});
                            setState(() { _period = v; });
                          },
                          prefixIcon: Icon(Icons.calendar_month_outlined, size: 18, color: theme.textColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: CoreDropdown<String>(
                          label: 'currency'.tr,
                          value: _currency,
                          options: const ['PLN', 'EUR', 'USD', 'GBP'],
                          onChanged: (v) {
                            if (v == null || v == _currency) return;
                            setSheet(() {});
                            setState(() { _currency = v; });
                          },
                          prefixIcon: Icon(Icons.currency_exchange, size: 18, color: theme.textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<EmployeeManagementEmployeeModel> _filteredEmployees(
    List<EmployeeManagementEmployeeModel> employees,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return employees;

    return employees.where((employee) {
      return employee.displayName.toLowerCase().contains(query) ||
          employee.user.email.toLowerCase().contains(query) ||
          employee.membership.role.toLowerCase().contains(query) ||
          employee.membership.status.toLowerCase().contains(query);
    }).toList();
  }

  EmployeeManagementEmployeeModel? _resolveSelected(
    List<EmployeeManagementEmployeeModel> employees,
  ) {
    if (employees.isEmpty || _selectedEmployeeId == null) return null;

    for (final employee in employees) {
      if (employee.user.id == _selectedEmployeeId) return employee;
    }

    return null;
  }
}

class _MobileHeaderBar extends ConsumerWidget {
  final TextEditingController searchController;
  final VoidCallback onRefresh;
  final VoidCallback onAddEmployee;
  final VoidCallback onOpenFilters;

  const _MobileHeaderBar({
    required this.searchController,
    required this.onRefresh,
    required this.onAddEmployee,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: CoreTextField(
              label: 'search_employee'.tr,
              controller: searchController,
              hintText: 'search'.tr,
              fillColor: theme.textFieldColor,
              textInputAction: TextInputAction.search,
              prefixIcon: Icon(Icons.search, size: 18, color: theme.textColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onOpenFilters,
          icon: Icon(Icons.tune_rounded, color: theme.textColor),
          tooltip: 'Filters'.tr,
        ),
        IconButton(
          onPressed: onRefresh,
          icon: Icon(Icons.refresh, color: theme.textColor),
          tooltip: 'refresh'.tr,
        ),
        IconButton(
          onPressed: onAddEmployee,
          icon: Icon(Icons.person_add_alt_1_outlined, color: theme.textColor),
          tooltip: 'new_employee'.tr,
        ),
      ],
    );
  }
}

class _HeaderBar extends ConsumerWidget {
  final String period;
  final String currency;
  final TextEditingController searchController;
  final ValueChanged<String?> onPeriodChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final VoidCallback onRefresh;
  final VoidCallback onAddEmployee;

  const _HeaderBar({
    required this.period,
    required this.currency,
    required this.searchController,
    required this.onPeriodChanged,
    required this.onCurrencyChanged,
    required this.onRefresh,
    required this.onAddEmployee,
  });

  static const double _controlHeight = 48;
  static const double _searchWidth = 230;
  static const double _periodWidth = 180;
  static const double _currencyWidth = 130;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    Widget controlBox({
      required Widget child,
      double? width,
    }) {
      return SizedBox(
        width: width,
        height: _controlHeight,
        child: child,
      );
    }

    Widget actionChild({
      required IconData icon,
      required String label,
    }) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: theme.textColor),
          const SizedBox(width: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.textColor),
          ),
        ],
      );
    }

    final controls = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        controlBox(
          width: _searchWidth,
          child: CoreTextField(
            label: 'search_employee'.tr,
            controller: searchController,
            hintText: 'search'.tr,
            fillColor: theme.textFieldColor,
            textInputAction: TextInputAction.search,
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: theme.textColor,
            ),
          ),
        ),
        controlBox(
          width: _periodWidth,
          child: CoreDropdown<String>(
            label: 'period'.tr,
            value: period,
            options: _periodOptions(),
            display: _periodDisplay,
            onChanged: onPeriodChanged,
            prefixIcon: Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: theme.textColor,
            ),
          ),
        ),
        controlBox(
          width: _currencyWidth,
          child: CoreDropdown<String>(
            label: 'currency'.tr,
            value: currency,
            options: const ['PLN', 'EUR', 'USD', 'GBP'],
            onChanged: onCurrencyChanged,
            prefixIcon: Icon(
              Icons.currency_exchange,
              size: 18,
              color: theme.textColor,
            ),
          ),
        ),
        controlBox(
          width: 126,
          child: CoreOutlinedButton(
            onPressed: onRefresh,
            child: actionChild(
              icon: Icons.refresh,
              label: 'refresh'.tr,
            ),
          ),
        ),
        controlBox(
          width: 172,
          child: CoreFilledButton(
            onPressed: onAddEmployee,
            child: actionChild(
              icon: Icons.person_add_alt_1_outlined,
              label: 'new_employee'.tr,
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'employees_center'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'employees_center_subtitle'.tr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor.withAlpha(165),
                height: 1.35,
              ),
            ),
          ],
        );

        if (constraints.maxWidth < 980) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: controls,
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            Align(
              alignment: Alignment.centerRight,
              child: controls,
            ),
          ],
        );
      },
    );
  }
}


class _SummaryStrip extends ConsumerWidget {
  final EmployeeManagementDashboardModel data;

  const _SummaryStrip({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = data.summary;
    final cards = [
      _SummaryItem(
        title: 'employees'.tr,
        value: summary.employeesCount.toString(),
        subtitle: '${summary.activeCount} ${'active'.tr}',
        icon: Icons.groups_2_outlined,
      ),
      _SummaryItem(
        title: 'monthly_cost'.tr,
        value: _money(summary.employerCost, data.currency),
        subtitle: '${summary.settlementsCount} ${'settlements'.tr}',
        icon: Icons.account_balance_wallet_outlined,
      ),
      _SummaryItem(
        title: 'to_pay'.tr,
        value: _money(summary.outstandingAmount, data.currency),
        subtitle: '${summary.paidAmount.toStringAsFixed(2)} ${'paid'.tr}',
        icon: Icons.payments_outlined,
      ),
      _SummaryItem(
        title: 'needs_attention'.tr,
        value: (summary.withoutAgreementCount + summary.pendingEventsCount).toString(),
        subtitle: '${summary.withoutAgreementCount} ${'without_agreement'.tr}',
        icon: Icons.warning_amber_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 680
            ? constraints.maxWidth
            : constraints.maxWidth < 1120
                ? (constraints.maxWidth - 12) / 2
                : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: CrmDashboardCard(
                  child: Row(
                    children: [
                      CrmDashboardIconBubble(icon: card.icon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.title),
                            const SizedBox(height: 5),
                            Text(
                              card.value,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              card.subtitle,
                              style: TextStyle(
                                color: ref
                                    .watch(themeColorsProvider)
                                    .textColor
                                    .withAlpha(150),
                                fontSize: 12,
                              ),
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
      },
    );
  }
}


class _EmployeeOverviewPane extends ConsumerWidget {
  final EmployeeManagementDashboardModel data;
  final List<EmployeeManagementEmployeeModel> employees;

  const _EmployeeOverviewPane({
    required this.data,
    required this.employees,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final summary = data.summary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          CrmDashboardCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final header = Row(
                  children: [
                    CrmDashboardIconBubble(icon: Icons.insights_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'team_overview'.tr,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'select_employee_to_open'.tr,
                            style: TextStyle(
                              color: theme.textColor.withAlpha(155),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                return header;
              },
            ),
          ),
          const SizedBox(height: 14),
          _SummaryStrip(data: data),
          const SizedBox(height: 14),
          CrmDashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'team_snapshot'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _OverviewBar(
                  label: 'active'.tr,
                  value: summary.activeCount,
                  total: summary.employeesCount,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 12),
                _OverviewBar(
                  label: 'inactive'.tr,
                  value: summary.inactiveCount,
                  total: summary.employeesCount,
                  icon: Icons.pause_circle_outline,
                ),
                const SizedBox(height: 12),
                _OverviewBar(
                  label: 'with_agreement'.tr,
                  value: summary.withAgreementCount,
                  total: summary.employeesCount,
                  icon: Icons.assignment_turned_in_outlined,
                ),
                const SizedBox(height: 12),
                _OverviewBar(
                  label: 'without_agreement'.tr,
                  value: summary.withoutAgreementCount,
                  total: summary.employeesCount,
                  icon: Icons.assignment_late_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CrmDashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'financial_snapshot'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _MoneyProgress(
                  label: 'paid'.tr,
                  value: summary.paidAmount,
                  total: summary.netToPay == 0
                      ? summary.paidAmount + summary.outstandingAmount
                      : summary.netToPay,
                  currency: data.currency,
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 12),
                _MoneyProgress(
                  label: 'to_pay'.tr,
                  value: summary.outstandingAmount,
                  total: summary.netToPay == 0
                      ? summary.paidAmount + summary.outstandingAmount
                      : summary.netToPay,
                  currency: data.currency,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CrmDashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'employees'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (employees.isEmpty)
                  Text(
                    'no_employees_found'.tr,
                    style: TextStyle(color: theme.textColor.withAlpha(150)),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final employee in employees.take(12))
                        CrmDashboardMiniPill(label: employee.displayName),
                      if (employees.length > 12)
                        CrmDashboardMiniPill(label: '+${employees.length - 12}'),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewBar extends ConsumerWidget {
  final String label;
  final int value;
  final int total;
  final IconData icon;

  const _OverviewBar({
    required this.label,
    required this.value,
    required this.total,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final safeTotal = total <= 0 ? 1 : total;
    final progress = (value / safeTotal).clamp(0.0, 1.0).toDouble();

    return Row(
      children: [
        Icon(icon, size: 18, color: theme.textColor.withAlpha(180)),
        const SizedBox(width: 10),
        SizedBox(
          width: 150,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: theme.textFieldColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            '$value / $total',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: theme.textColor.withAlpha(170),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _MoneyProgress extends ConsumerWidget {
  final String label;
  final double value;
  final double total;
  final String currency;
  final IconData icon;

  const _MoneyProgress({
    required this.label,
    required this.value,
    required this.total,
    required this.currency,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final safeTotal = total <= 0 ? 1.0 : total;
    final progress = (value / safeTotal).clamp(0.0, 1.0).toDouble();

    return Row(
      children: [
        Icon(icon, size: 18, color: theme.textColor.withAlpha(180)),
        const SizedBox(width: 10),
        SizedBox(
          width: 150,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: theme.textFieldColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 126,
          child: Text(
            _money(value, currency),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: theme.textColor.withAlpha(170),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmployeeListPanel extends ConsumerWidget {
  final List<EmployeeManagementEmployeeModel> employees;
  final int? selectedEmployeeId;
  final ValueChanged<EmployeeManagementEmployeeModel> onSelect;
  final ValueChanged<EmployeeManagementEmployeeModel> onEdit;
  final ValueChanged<EmployeeManagementEmployeeModel> onDeactivate;

  const _EmployeeListPanel({
    required this.employees,
    required this.selectedEmployeeId,
    required this.onSelect,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return CrmDashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'team'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                CrmDashboardPill(
                  label: '${employees.length} ${'people'.tr}',
                  icon: Icons.groups_outlined,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dashboardBoarder),
          Expanded(
            child: employees.isEmpty
                ? Center(
                    child: Text(
                      'no_employees_found'.tr,
                      style: TextStyle(color: theme.textColor.withAlpha(160)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: employees.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final employee = employees[index];
                      final selected = employee.user.id == selectedEmployeeId;
                      return _EmployeeListTile(
                        employee: employee,
                        selected: selected,
                        onTap: () => onSelect(employee),
                        onEdit: employee.membership.id == null
                            ? null
                            : () => onEdit(employee),
                        onDeactivate: employee.membership.isOwner ||
                                employee.membership.status != 'active'
                            ? null
                            : () => onDeactivate(employee),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeListTile extends ConsumerWidget {
  final EmployeeManagementEmployeeModel employee;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDeactivate;

  const _EmployeeListTile({
    required this.employee,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final status = _statusText(employee.quickStatus);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? theme.themeColor.withAlpha(22)
              : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.themeColor : theme.dashboardBoarder,
          ),
        ),
        child: Row(
          children: [
            _Avatar(employee: employee),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    employee.user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(145),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      CrmDashboardMiniPill(label: employee.membership.role.tr),
                      CrmDashboardMiniPill(label: employee.membership.status.tr),
                      CrmDashboardMiniPill(label: status.tr),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  employee.settlement == null
                      ? '-'
                      : _money(
                          employee.settlement!.outstandingAmount,
                          employee.settlement!.currency,
                        ),
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                PopupMenuButton<String>(
                  color: theme.dashboardContainer,
                  icon: Icon(Icons.more_horiz, color: theme.textColor),
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'deactivate') onDeactivate?.call();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      enabled: onEdit != null,
                      child: Text(
                        'manage_employee'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'deactivate',
                      enabled: onDeactivate != null,
                      child: Text(
                        'deactivate'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


enum _EmployeeDetailsTab {
  summary,
  availability,
  calendar,
  absences,
  settlements,
}

class _EmployeeDetailsPane extends ConsumerStatefulWidget {
  final EmployeeManagementEmployeeModel? employee;
  final String period;
  final String currency;
  final bool isMobile;
  final VoidCallback? onEditEmployee;
  final Future<void> Function()? onAbsenceChanged;
  final VoidCallback? onBackToSummary;

  const _EmployeeDetailsPane({
    required this.employee,
    required this.period,
    required this.currency,
    required this.isMobile,
    required this.onEditEmployee,
    required this.onAbsenceChanged,
    required this.onBackToSummary,
  });

  @override
  ConsumerState<_EmployeeDetailsPane> createState() =>
      _EmployeeDetailsPaneState();
}

class _EmployeeDetailsPaneState extends ConsumerState<_EmployeeDetailsPane> {
  _EmployeeDetailsTab _tab = _EmployeeDetailsTab.summary;

  EmployeeManagementEmployeeModel? get employee => widget.employee;

  @override
  void didUpdateWidget(covariant _EmployeeDetailsPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employee?.user.id != widget.employee?.user.id) {
      setState(() {
        _tab = _EmployeeDetailsTab.summary;
      });
    }
  }

  void _changeTab(_EmployeeDetailsTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  Future<void> _handleEmployeeDataChanged() async {
    await widget.onAbsenceChanged?.call();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final value = employee;

    if (value == null) {
      return CrmDashboardCard(
        child: Center(
          child: Text(
            'select_employee_to_open'.tr,
            style: TextStyle(color: theme.textColor.withAlpha(160)),
          ),
        ),
      );
    }

    final content = _buildTabContent(context, value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EmployeeDetailsHeader(
          employee: value,
          onEditEmployee: widget.onEditEmployee,
          onBackToSummary: widget.onBackToSummary,
        ),
        const SizedBox(height: 12),
        _EmployeeDetailsTabs(
          value: _tab,
          onChanged: _changeTab,
        ),
        const SizedBox(height: 12),
        if (_tab == _EmployeeDetailsTab.settlements)
          EmployeeSettlementDashboardPage(
            employeeId: value.user.id,
            isMobile: widget.isMobile,
            embedded: true,
            externalPeriod: widget.period,
            externalCurrency: widget.currency,
          )
        else
          Expanded(child: content),
      ],
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    EmployeeManagementEmployeeModel value,
  ) {
    switch (_tab) {
      case _EmployeeDetailsTab.summary:
        return _ScrollableDetailContent(
          children: [
            EmployeeAvailabilityCompactCard(
              employeeId: value.user.id,
              onOpenCalendar: () => _changeTab(_EmployeeDetailsTab.calendar),
              onEditAvailability: () => _changeTab(_EmployeeDetailsTab.availability),
            ),
            EmployeeAbsenceCompactCard(
              employee: value,
              period: widget.period,
              onChanged: _handleEmployeeDataChanged,
            ),
            _EmployeeSettlementShortcutCard(
              employee: value,
              currency: widget.currency,
              onOpen: () => _changeTab(_EmployeeDetailsTab.settlements),
            ),
          ],
        );
      case _EmployeeDetailsTab.availability:
        return _ScrollableDetailContent(
          children: [
            EmployeeAvailabilityCompactCard(
              employeeId: value.user.id,
              onOpenCalendar: () => _changeTab(_EmployeeDetailsTab.calendar),
            ),
            EmployeeAvailabilityQuickActions(
              employeeId: value.user.id,
              onDone: _handleEmployeeDataChanged,
            ),
            EmployeeAvailabilityWeekPreview(
              key: ValueKey('availability-week-${value.user.id}'),
              weekStart: DateTime.now(),
              employeeId: value.user.id,
            ),
          ],
        );
      case _EmployeeDetailsTab.calendar:
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : (widget.isMobile ? 520.0 : 640.0);
            final height = (availableHeight - 86.0).clamp(320.0, 680.0);
            return _EmployeeCalendarAvailabilityCard(
              employee: value,
              isMobile: widget.isMobile,
              height: height,
            );
          },
        );
      case _EmployeeDetailsTab.absences:
        return _ScrollableDetailContent(
          children: [
            EmployeeAbsenceCompactCard(
              employee: value,
              period: widget.period,
              onChanged: _handleEmployeeDataChanged,
            ),
          ],
        );
      case _EmployeeDetailsTab.settlements:
        return const SizedBox.shrink();
    }
  }
}

class _EmployeeDetailsHeader extends ConsumerWidget {
  final EmployeeManagementEmployeeModel employee;
  final VoidCallback? onEditEmployee;
  final VoidCallback? onBackToSummary;

  const _EmployeeDetailsHeader({
    required this.employee,
    required this.onEditEmployee,
    required this.onBackToSummary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return CrmDashboardCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final info = Row(
            children: [
              _Avatar(employee: employee, size: 50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.textColor.withAlpha(155)),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (onBackToSummary != null)
                CoreOutlinedButton(
                  onPressed: onBackToSummary,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded, size: 18),
                      const SizedBox(width: 7),
                      Text('summary'.tr),
                    ],
                  ),
                ),
              CrmDashboardPill(label: employee.membership.role.tr, icon: Icons.badge_outlined),
              CrmDashboardPill(label: employee.membership.status.tr, icon: Icons.circle_outlined),
              if (onEditEmployee != null)
                CoreOutlinedButton(
                  onPressed: onEditEmployee,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.manage_accounts_outlined, size: 18),
                      const SizedBox(width: 7),
                      Text('role_and_status'.tr),
                    ],
                  ),
                ),
            ],
          );

          if (constraints.maxWidth < 780) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: info),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _EmployeeDetailsTabs extends StatelessWidget {
  final _EmployeeDetailsTab value;
  final ValueChanged<_EmployeeDetailsTab> onChanged;

  const _EmployeeDetailsTabs({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CrmDashboardCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CrmDashboardTabPill(
              selected: value == _EmployeeDetailsTab.summary,
              icon: Icons.dashboard_outlined,
              label: 'summary'.tr,
              onTap: () => onChanged(_EmployeeDetailsTab.summary),
            ),
            const SizedBox(width: 8),
            CrmDashboardTabPill(
              selected: value == _EmployeeDetailsTab.availability,
              icon: Icons.event_available_outlined,
              label: 'availability'.tr,
              onTap: () => onChanged(_EmployeeDetailsTab.availability),
            ),
            const SizedBox(width: 8),
            CrmDashboardTabPill(
              selected: value == _EmployeeDetailsTab.calendar,
              icon: Icons.calendar_month_outlined,
              label: 'calendar'.tr,
              onTap: () => onChanged(_EmployeeDetailsTab.calendar),
            ),
            const SizedBox(width: 8),
            CrmDashboardTabPill(
              selected: value == _EmployeeDetailsTab.absences,
              icon: Icons.event_busy_outlined,
              label: 'absences'.tr,
              onTap: () => onChanged(_EmployeeDetailsTab.absences),
            ),
            const SizedBox(width: 8),
            CrmDashboardTabPill(
              selected: value == _EmployeeDetailsTab.settlements,
              icon: Icons.account_balance_wallet_outlined,
              label: 'settlements'.tr,
              onTap: () => onChanged(_EmployeeDetailsTab.settlements),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrollableDetailContent extends StatelessWidget {
  final List<Widget> children;

  const _ScrollableDetailContent({required this.children});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      primary: false,
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        for (var i = 0; i < children.length; i++) ...[
          SliverToBoxAdapter(child: children[i]),
          if (i != children.length - 1)
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _EmployeeSettlementShortcutCard extends ConsumerWidget {
  final EmployeeManagementEmployeeModel employee;
  final String currency;
  final VoidCallback onOpen;

  const _EmployeeSettlementShortcutCard({
    required this.employee,
    required this.currency,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final settlement = employee.settlement;
    final outstanding = settlement?.outstandingAmount ?? 0;
    final net = settlement?.netToPay ?? 0;

    return CrmDashboardCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Row(
            children: [
              CrmDashboardIconBubble(icon: Icons.account_balance_wallet_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'settlements'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settlement == null
                          ? 'missing_agreement'.tr
                          : '${_money(outstanding, settlement.currency)} ${'to_pay'.tr} · ${_money(net, settlement.currency)} netto',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.textColor.withAlpha(160)),
                    ),
                  ],
                ),
              ),
            ],
          );

          final button = CoreFilledButton(
            onPressed: onOpen,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.open_in_new_rounded, size: 18),
                const SizedBox(width: 7),
                Text('open'.tr),
              ],
            ),
          );

          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 14),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _EmployeeCalendarAvailabilityCard extends StatelessWidget {
  final EmployeeManagementEmployeeModel employee;
  final bool isMobile;
  final double? height;

  const _EmployeeCalendarAvailabilityCard({
    required this.employee,
    required this.isMobile,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return EmployeeHrCalendarPreview(
      memberId: employee.user.id,
      initialDate: DateTime.now(),
      height: height ?? (isMobile ? 420 : 480),
      initiallyShowEvents: true,
      initiallyShowAvailability: true,
    );
  }
}

class _Avatar extends ConsumerWidget {
  final EmployeeManagementEmployeeModel employee;
  final double size;

  const _Avatar({required this.employee, this.size = 42});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final avatar = employee.user.avatar;
    final initials = _initials(employee.displayName, employee.user.email);

    if (avatar != null && avatar.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialsAvatar(
            initials: initials,
            size: size,
          ),
        ),
      );
    }

    return _InitialsAvatar(initials: initials, size: size);
  }
}

class _InitialsAvatar extends ConsumerWidget {
  final String initials;
  final double size;

  const _InitialsAvatar({required this.initials, required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(28),
        shape: BoxShape.circle,
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: theme.textColor,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ErrorState extends ConsumerWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return CrmDashboardCard(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 42, color: theme.textColor),
            const SizedBox(height: 10),
            Text(
              'unable_to_load_employees'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textColor.withAlpha(150)),
            ),
            const SizedBox(height: 14),
            CoreFilledButton(
              onPressed: onRetry,
              child: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });
}

SubAccountMember? _toSubAccountMember(EmployeeManagementEmployeeModel employee) {
  final membershipId = employee.membership.id;
  if (membershipId == null) return null;

  return SubAccountMember(
    id: membershipId,
    user: SubAccountUser(
      id: employee.user.id,
      username: employee.user.username,
      firstName: employee.user.firstName,
      lastName: employee.user.lastName,
      email: employee.user.email,
      avatar: employee.user.avatar,
      phoneNumber: employee.user.phoneNumber,
    ),
    status: employee.membership.status,
    role: employee.membership.role,
    joinedAt: employee.membership.joinedAt ?? DateTime.now(),
    country: employee.membership.country,
  );
}

bool _useBottomSheet() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

String _money(double value, String currency) {
  return '${value.toStringAsFixed(2)} $currency';
}

String _currentPeriod() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}';
}

List<String> _periodOptions() {
  final now = DateTime.now();
  return List.generate(18, (index) {
    final value = DateTime(now.year, now.month - index, 1);
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}';
  });
}

String _periodDisplay(String value) {
  final parts = value.split('-');
  if (parts.length != 2) return value;
  final month = int.tryParse(parts[1]);
  if (month == null || month < 1 || month > 12) return value;
  const keys = [
    'month_january',
    'month_february',
    'month_march',
    'month_april',
    'month_may',
    'month_june',
    'month_july',
    'month_august',
    'month_september',
    'month_october',
    'month_november',
    'month_december',
  ];
  return '${keys[month - 1].tr} ${parts[0]}';
}

String _statusText(String status) {
  switch (status) {
    case 'inactive':
      return 'inactive';
    case 'on_leave':
      return 'on_leave';
    case 'pending_absence':
      return 'pending_absence';
    case 'missing_agreement':
      return 'missing_agreement';
    case 'unpaid':
      return 'unpaid';
    case 'pending_events':
      return 'pending_events';
    default:
      return 'ok';
  }
}

String _initials(String name, String email) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();

  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  if (parts.isNotEmpty) return parts.first.substring(0, 1).toUpperCase();
  if (email.isNotEmpty) return email.substring(0, 1).toUpperCase();
  return '?';
}
