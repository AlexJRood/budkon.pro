import 'package:core/ui/device_type_util.dart';
import 'package:crm/contact_panel/tabs/employee_settlements/dialogs/compensation_agreement_dialog.dart';
import 'package:crm/widget/crm_dashboard_widgets.dart';
import 'package:crm/contact_panel/tabs/employee_settlements/dialogs/compensation_rule_dialog.dart';
import 'package:crm/contact_panel/tabs/employee_settlements/dialogs/settlement_action_dialogs.dart';
import 'package:crm/contact_panel/tabs/employee_settlements/provider/employee_settlement_dashboard_provider.dart';
import 'package:crm/contact_panel/tabs/employee_settlements/widgets/compensation_agreement_documents_section.dart';
import 'package:crm/contact_panel/tabs/employee_settlements/widgets/compensation_notification_preferences_card.dart';
import 'package:crm/contact_panel/tabs/employee_settlements/dialogs/compensation_notification_preferences_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/text_field.dart';

enum _SettlementDashboardTab {
  dashboard,
  history,
  rules,
  documents,
  settings,
}

enum _SettlementRange {
  currentMonth,
  previousMonth,
  allHistory,
}

enum _SettlementAudienceView {
  manager,
  employee,
}

class EmployeeSettlementDashboardPage extends ConsumerStatefulWidget {
  final int employeeId;
  final bool isMobile;

  /// Use this when the dashboard is displayed inside Employee Center.
  /// In embedded mode period/currency/refresh/range controls are hidden,
  /// because they are already controlled by the parent employee screen.
  final bool embedded;

  /// Optional period inherited from parent screen, formatted as YYYY-MM.
  final String? externalPeriod;

  /// Optional currency inherited from parent screen, for example PLN.
  final String? externalCurrency;

  const EmployeeSettlementDashboardPage({
    super.key,
    required this.employeeId,
    this.isMobile = false,
    this.embedded = false,
    this.externalPeriod,
    this.externalCurrency,
  });

  @override
  ConsumerState<EmployeeSettlementDashboardPage> createState() =>
      _EmployeeSettlementDashboardPageState();
}

class _EmployeeSettlementDashboardPageState
    extends ConsumerState<EmployeeSettlementDashboardPage> {
  late String _period;
  String _currency = 'PLN';
  bool _actionInProgress = false;
  _SettlementDashboardTab _tab = _SettlementDashboardTab.dashboard;
  _SettlementRange _range = _SettlementRange.currentMonth;
  _SettlementAudienceView _audienceView = _SettlementAudienceView.manager;

  @override
  void initState() {
    super.initState();
    _period = widget.externalPeriod ?? _currentPeriod();
    _currency = widget.externalCurrency ?? 'PLN';
  }

  @override
  void didUpdateWidget(covariant EmployeeSettlementDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final employeeChanged = oldWidget.employeeId != widget.employeeId;
    final externalPeriodChanged =
        oldWidget.externalPeriod != widget.externalPeriod &&
            widget.externalPeriod != null;
    final externalCurrencyChanged =
        oldWidget.externalCurrency != widget.externalCurrency &&
            widget.externalCurrency != null;

    if (employeeChanged) {
      setState(() {
        _period = widget.externalPeriod ?? _currentPeriod();
        _currency = widget.externalCurrency ?? 'PLN';
        _range = _SettlementRange.currentMonth;
        _tab = _SettlementDashboardTab.dashboard;
        _audienceView = _SettlementAudienceView.manager;
      });
      return;
    }

    if (externalPeriodChanged || externalCurrencyChanged) {
      setState(() {
        if (externalPeriodChanged) {
          _period = widget.externalPeriod!;
          _range = _SettlementRange.currentMonth;
          if (_tab == _SettlementDashboardTab.history) {
            _tab = _SettlementDashboardTab.dashboard;
          }
        }
        if (externalCurrencyChanged) {
          _currency = widget.externalCurrency!;
        }
      });
    }
  }

  bool get _isAllHistory => _range == _SettlementRange.allHistory;

  bool _isEmployeePreview(EmployeeSettlementDashboardModel data) {
    return data.permissions.canManage &&
        _audienceView == _SettlementAudienceView.employee;
  }

  void _changeAudienceView(
    _SettlementAudienceView value,
    EmployeeSettlementDashboardModel data,
  ) {
    if (_audienceView == value) return;

    setState(() {
      _audienceView = value;

      if (value == _SettlementAudienceView.employee) {
        final employeeCanSeeRules = data.agreement?.employeeCanViewRules == true;
        if (_tab == _SettlementDashboardTab.settings ||
            (_tab == _SettlementDashboardTab.rules && !employeeCanSeeRules)) {
          _tab = _SettlementDashboardTab.dashboard;
        }
      }
    });
  }

  EmployeeSettlementDashboardParams get _params =>
      EmployeeSettlementDashboardParams(
        employeeId: widget.employeeId,
        period: _period,
        currency: _currency,
        summaryScope: _isAllHistory ? 'all' : 'period',
        historyScope: _isAllHistory ? 'all' : 'recent',
      );

  EmployeeSettlementDashboardNotifier get _notifier =>
      ref.read(employeeSettlementDashboardProvider(_params).notifier);

  Future<T?> _runAction<T>(
    Future<T> Function() action, {
    String? successMessage,
  }) async {
    if (_actionInProgress) return null;

    final theme = ref.read(themeColorsProvider);

    setState(() => _actionInProgress = true);

    try {
      final result = await action();

      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successMessage,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        );
      }

      return result;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'Error'.tr}: $error',
              style: TextStyle(color: theme.textColor),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }

      return null;
    } finally {
      if (mounted) {
        setState(() => _actionInProgress = false);
      }
    }
  }

  Future<void> _editAgreement(EmployeeSettlementDashboardModel data) async {
    final previousAgreement = data.agreement;

    final payload = await showCompensationAgreementDialog(
      context: context,
      employeeId: widget.employeeId,
      agreement: previousAgreement,
    );

    if (payload == null) return;

    final savedAgreement = await _runAction<CompensationAgreementModel>(
      () => _notifier.saveAgreement(payload),
      successMessage: 'compensation_agreement_saved'.tr,
    );

    if (!mounted || savedAgreement == null) return;

    if (previousAgreement == null &&
        savedAgreement.documentBinding?.canManage == true) {
      await showCompensationAgreementDocumentsDialog(
        context: context,
        agreement: savedAgreement,
        isMobile: widget.isMobile,
      );
    }
  }

  Future<void> _openAgreementDocuments(
    CompensationAgreementModel agreement,
  ) async {
    if (agreement.documentBinding?.canView != true) return;

    await showCompensationAgreementDocumentsDialog(
      context: context,
      agreement: agreement,
      isMobile: widget.isMobile,
    );
  }

  Future<void> _editRule(
    EmployeeSettlementDashboardModel data, {
    CompensationRuleModel? rule,
  }) async {
    final agreement = data.agreement;
    if (agreement == null) return;
    final payload = await showCompensationRuleDialog(
      context: context,
      agreementId: agreement.id,
      rule: rule,
    );
    if (payload == null) return;
    await _runAction(
      () => _notifier.saveRule(payload, ruleId: rule?.id),
      successMessage: 'compensation_rule_saved'.tr,
    );
  }

  Future<void> _addManualLine(EmployeeSettlementDashboardModel data) async {
    if (data.currentSettlement == null) return;
    final payload = await showManualSettlementLineDialog(
      context: context,
      currency: data.currentSettlement?.currency ?? data.currency,
    );
    if (payload == null) return;
    await _runAction(
      () => _notifier.addManualLine(payload),
      successMessage: 'settlement_line_added'.tr,
    );
  }

  Future<void> _registerPayment(EmployeeSettlementDashboardModel data) async {
    final settlement = data.currentSettlement;
    if (settlement == null || settlement.outstandingAmount <= 0) return;
    final payload = await showRegisterPaymentDialog(
      context: context,
      outstandingAmount: settlement.outstandingAmount,
      currency: settlement.currency,
    );
    if (payload == null) return;
    await _runAction(
      () => _notifier.markAsPaid(payload),
      successMessage: 'payment_registered'.tr,
    );
  }

  Future<void> _openNotificationSettings(ThemeColors theme) async {
    await showCompensationNotificationPreferencesDialog(
      context: context,
      isMobile: widget.isMobile,
      theme: theme,
    );
  }

  void _changeRange(_SettlementRange value) {
    if (_range == value) return;

    setState(() {
      _range = value;
      if (value == _SettlementRange.currentMonth) {
        _period = _currentPeriod();
        _tab = _SettlementDashboardTab.dashboard;
      } else if (value == _SettlementRange.previousMonth) {
        _period = _previousPeriod();
        _tab = _SettlementDashboardTab.dashboard;
      } else {
        _period = _currentPeriod();
        _tab = _SettlementDashboardTab.history;
      }
    });
  }

  void _changePeriod(String? value) {
    if (value == null || value == _period) return;
    setState(() {
      _period = value;
      _range = value == _currentPeriod()
          ? _SettlementRange.currentMonth
          : value == _previousPeriod()
              ? _SettlementRange.previousMonth
              : _SettlementRange.currentMonth;
      _tab = _SettlementDashboardTab.dashboard;
    });
  }

  void _showMobileMoreOptionsSheet(ThemeColors theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (_, setSheetState) {
              return SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    border: Border.all(color: theme.dashboardBoarder, width: 1.2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.textColor.withAlpha(70),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      _RangeSelector(
                        value: _range,
                        enabled: !_actionInProgress,
                        onChanged: (value) {
                          setSheetState(() {});
                          _changeRange(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      CoreDropdown<String>(
                        label: _ui('period_yyyy_mm', 'Okres'),
                        value: _period,
                        options: _periodOptions(),
                        display: _periodDisplay,
                        enabled: !_actionInProgress,
                        onChanged: (value) {
                          setSheetState(() {});
                          _changePeriod(value);
                        },
                        prefixIcon: Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CoreDropdown<String>(
                        label: 'currency'.tr,
                        value: _currency,
                        options: const ['PLN', 'EUR', 'USD', 'GBP'],
                        enabled: !_actionInProgress,
                        onChanged: (value) {
                          if (value == null || value == _currency) return;
                          setSheetState(() {});
                          setState(() => _currency = value);
                        },
                        prefixIcon: Icon(
                          Icons.currency_exchange,
                          size: 18,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _contentSlivers(
    EmployeeSettlementDashboardModel data,
    ThemeColors theme,
  ) {
    final employeePreview = _isEmployeePreview(data);
    final effectiveEmployeeView = !data.permissions.canManage || employeePreview;
    final canUseManagerActions = !employeePreview;
    final canEditAgreement = canUseManagerActions && data.permissions.canEditAgreement;
    final canCalculate = canUseManagerActions && data.permissions.canCalculate;
    final canAddManualLine = canUseManagerActions && data.permissions.canAddManualLine;
    final canPublish = canUseManagerActions && data.permissions.canPublish;
    final canMarkPaid = canUseManagerActions && data.permissions.canMarkPaid;
    final canEditRules = canUseManagerActions && data.permissions.canManage;
    final employeeCanSeeRules = data.agreement?.employeeCanViewRules == true;

    if (data.agreement == null) {
      return [
        SliverToBoxAdapter(
          child: _NoAgreementState(
            data: data,
            onConfigure: canEditAgreement ? () => _editAgreement(data) : null,
          ),
        ),
      ];
    }

    switch (_tab) {
      case _SettlementDashboardTab.dashboard:
        return [
          SliverToBoxAdapter(
            child: _AgreementCard(
              agreement: data.agreement!,
              onEdit: canEditAgreement ? () => _editAgreement(data) : null,
              onDocuments: data.agreement!.documentBinding?.canView == true
                  ? () => _openAgreementDocuments(data.agreement!)
                  : null,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(child: _Metrics(data: data)),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          if (data.currentSettlement == null)
            SliverToBoxAdapter(
              child: _NoSettlementCard(
                data: data,
                busy: _actionInProgress,
                onCalculate: canCalculate
                    ? () => _runAction(
                          _notifier.calculateSettlement,
                          successMessage: 'settlement_calculated'.tr,
                        )
                    : null,
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: _SettlementOverview(
                data: data,
                busy: _actionInProgress,
                onAddLine: canAddManualLine ? () => _addManualLine(data) : null,
                onPublish: canPublish &&
                        !{'published', 'paid'}.contains(
                          data.currentSettlement!.status,
                        )
                    ? () => _runAction(
                          _notifier.publishSettlement,
                          successMessage: 'settlement_published'.tr,
                        )
                    : null,
                onRegisterPayment: canMarkPaid &&
                        data.currentSettlement!.outstandingAmount > 0
                    ? () => _registerPayment(data)
                    : null,
                onAcknowledge: !employeePreview &&
                        !data.permissions.canManage &&
                        data.permissions.isSelf &&
                        data.currentSettlement!.visibleToEmployee
                    ? () => _runAction(
                          _notifier.acknowledgeSettlement,
                          successMessage: 'settlement_acknowledged'.tr,
                        )
                    : null,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chart = _SettlementBreakdownChart(
                    settlement: data.currentSettlement!,
                    currency: data.currency,
                  );
                  final lines = _SettlementLinesPreviewCard(
                    data: data,
                    theme: theme,
                    onAddLine: canAddManualLine ? () => _addManualLine(data) : null,
                  );

                  if (constraints.maxWidth < 980) {
                    return Column(
                      children: [
                        chart,
                        const SizedBox(height: 14),
                        lines,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: chart),
                      const SizedBox(width: 14),
                      Expanded(flex: 3, child: lines),
                    ],
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _PaymentsCard(data: data)),
          ],
        ];
      case _SettlementDashboardTab.history:
        return [
          SliverToBoxAdapter(
            child: _HistoryCard(data: data, theme: theme),
          ),
        ];
      case _SettlementDashboardTab.rules:
        if (effectiveEmployeeView && !employeeCanSeeRules) {
          return [
            SliverToBoxAdapter(
              child: _EmployeePreviewLockedCard(
                icon: Icons.rule_folder_outlined,
                title: _ui('rules_hidden_in_employee_view', 'Reguły są ukryte w widoku pracownika'),
                message: _ui(
                  'rules_hidden_in_employee_view_message',
                  'Ta umowa nie udostępnia pracownikowi reguł rozliczeń. Wróć do widoku managera, żeby nimi zarządzać.',
                ),
              ),
            ),
          ];
        }
        return [
          SliverToBoxAdapter(
            child: _RulesCard(
              theme: theme,
              data: data,
              onAdd: canEditRules ? () => _editRule(data) : null,
              onEdit: canEditRules ? (rule) => _editRule(data, rule: rule) : null,
            ),
          ),
        ];
      case _SettlementDashboardTab.documents:
        return [
          SliverToBoxAdapter(
            child: _DocumentsTabCard(
              agreement: data.agreement!,
              isMobile: widget.isMobile,
            ),
          ),
        ];
      case _SettlementDashboardTab.settings:
        if (effectiveEmployeeView) {
          return [
            SliverToBoxAdapter(
              child: _EmployeePreviewLockedCard(
                icon: Icons.notifications_active_outlined,
                title: _ui('settings_hidden_in_employee_view', 'Ustawienia są ukryte w widoku pracownika'),
                message: _ui(
                  'settings_hidden_in_employee_view_message',
                  'To są ustawienia użytkownika zalogowanego jako manager. W widoku pracownika ukrywamy je, żeby preview było czytelne.',
                ),
              ),
            ),
          ];
        }
        return [
          SliverToBoxAdapter(
            child: _NotificationSettingsTabCard(
              isMobile: widget.isMobile,
              onOpenDialog: () => _openNotificationSettings(theme),
            ),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(employeeSettlementDashboardProvider(_params));
    // final topPadding = widget.embedded
    //     ? 0.0
    //     : widget.isMobile
    //         ? TopAppBarSize.resolve(context) + 10
    //         : 0.0;
    final bottomPadding = widget.embedded
        ? 0.0
        : widget.isMobile
            ? BottomBarSize.resolve(context) + 14
            : 0.0;
    final horizontalPadding = widget.embedded ? 0.0 : (widget.isMobile ? 10.0 : 24.0);

    return Expanded(
      child: DefaultTextStyle.merge(
        style: TextStyle(color: theme.textColor),
        child: IconTheme.merge(
          data: IconThemeData(color: theme.textColor),
          child: Padding(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              // top: topPadding,
              // bottom: bottomPadding,
            ),
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: CrmDashboardCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 42,
                        color: theme.textColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'unable_to_load_settlements'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.textColor.withAlpha(150)),
                      ),
                      const SizedBox(height: 14),
                      CoreFilledButton(
                        onPressed: _notifier.fetch,
                        child: Text(
                          'retry'.tr,
                          style: TextStyle(color: theme.textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) => Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () => _notifier.fetch(showLoading: false),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _Header(
                            data: data,
                            period: _period,
                            currency: _currency,
                            range: _range,
                            tab: _tab,
                            audienceView: data.permissions.canManage
                                ? _audienceView
                                : _SettlementAudienceView.employee,
                            embedded: widget.embedded,
                            isMobile: widget.isMobile,
                            actionInProgress: _actionInProgress,
                            onRangeChanged: _changeRange,
                            onPeriodChanged: _changePeriod,
                            onCurrencyChanged: (value) {
                              if (value != null && value != _currency) {
                                setState(() => _currency = value);
                              }
                            },
                            onAudienceViewChanged: data.permissions.canManage
                                ? (value) => _changeAudienceView(value, data)
                                : null,
                            onTabChanged: (value) => setState(() => _tab = value),
                            onRefresh: () => _notifier.fetch(showLoading: false),
                            onEditAgreement:
                                !_isEmployeePreview(data) && data.permissions.canEditAgreement
                                    ? () => _editAgreement(data)
                                    : null,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 14)),
                        if (_isEmployeePreview(data)) ...[
                          const SliverToBoxAdapter(
                            child: _EmployeePreviewBanner(),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 14)),
                        ],
                        ..._contentSlivers(data, theme),
                        SliverToBoxAdapter(
                          child: SizedBox(height: BottomBarSize.resolve(context)+10),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.embedded && widget.isMobile)
                    Positioned(
                      bottom: BottomBarSize.resolve(context) + 5,
                      right: 4,
                      child: _SettlementMobileVerticalBar(
                        theme: theme,
                        busy: _actionInProgress,
                        onRefresh: () => _notifier.fetch(showLoading: false),
                        onToggleAudienceView: data.permissions.canManage
                            ? () => _changeAudienceView(
                                  _audienceView == _SettlementAudienceView.manager
                                      ? _SettlementAudienceView.employee
                                      : _SettlementAudienceView.manager,
                                  data,
                                )
                            : null,
                        isEmployeePreview: _isEmployeePreview(data),
                        onEditAgreement:
                            !_isEmployeePreview(data) && data.permissions.canEditAgreement
                                ? () => _editAgreement(data)
                                : null,
                        onMoreOptions: () => _showMobileMoreOptionsSheet(theme),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class _Header extends ConsumerWidget {
  final EmployeeSettlementDashboardModel data;
  final String period;
  final String currency;
  final _SettlementRange range;
  final _SettlementDashboardTab tab;
  final _SettlementAudienceView audienceView;
  final bool embedded;
  final bool isMobile;
  final bool actionInProgress;
  final ValueChanged<_SettlementRange> onRangeChanged;
  final ValueChanged<String?> onPeriodChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<_SettlementDashboardTab> onTabChanged;
  final ValueChanged<_SettlementAudienceView>? onAudienceViewChanged;
  final VoidCallback onRefresh;
  final VoidCallback? onEditAgreement;

  const _Header({
    required this.data,
    required this.period,
    required this.currency,
    required this.range,
    required this.tab,
    required this.audienceView,
    required this.embedded,
    required this.isMobile,
    required this.actionInProgress,
    required this.onRangeChanged,
    required this.onPeriodChanged,
    required this.onCurrencyChanged,
    required this.onTabChanged,
    required this.onAudienceViewChanged,
    required this.onRefresh,
    required this.onEditAgreement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final title = _HeaderTitle(
      embedded: embedded,
      data: data,
      period: period,
      audienceView: audienceView,
    );

    final tabs = _DashboardTabs(
      value: tab,
      permissions: data.permissions,
      audienceView: audienceView,
      hasDocuments: data.agreement?.documentBinding?.canView == true,
      showRules: audienceView == _SettlementAudienceView.manager ||
          data.agreement?.employeeCanViewRules == true,
      showSettings: audienceView == _SettlementAudienceView.manager,
      onChanged: onTabChanged,
      scrollable: false,
    );

    final actions = _HeaderActions(
      embedded: embedded,
      data: data,
      theme: theme,
      range: range,
      period: period,
      currency: currency,
      audienceView: audienceView,
      actionInProgress: actionInProgress,
      onAudienceViewChanged: onAudienceViewChanged,
      onRangeChanged: onRangeChanged,
      onPeriodChanged: onPeriodChanged,
      onCurrencyChanged: onCurrencyChanged,
      onRefresh: onRefresh,
      onEditAgreement: onEditAgreement,
    );

    if (embedded) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Wide embedded: title far left, tabs next to it, important actions on the right.
          if (constraints.maxWidth >= 1040) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  child: title,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeaderScrollRow(
                    child: tabs,
                  ),
                ),
                const SizedBox(width: 12),
                actions,
              ],
            );
          }

          // Medium embedded: title + actions in first row, tabs below with horizontal scroll.
          if (constraints.maxWidth >= 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _HeaderScrollRow(
                          reverse: true,
                          child: actions,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _HeaderScrollRow(child: tabs),
              ],
            );
          }

          // Small embedded: each layer can scroll horizontally, keeping the layout readable.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 10),
              _HeaderScrollRow(child: tabs),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _HeaderScrollRow(
                  reverse: true,
                  child: actions,
                ),
              ),
            ],
          );
        },
      );
    }

    // Mobile, non-embedded: actions live in the floating vertical bar instead
    // of a cramped horizontally-scrolling row, matching the bar manager
    // vertical buttons convention used across the app (e.g. calendar).
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 12),
          _HeaderScrollRow(child: tabs),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1120) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 12),
                  _HeaderScrollRow(child: actions),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: title),
                const SizedBox(width: 16),
                Flexible(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _HeaderScrollRow(
                      reverse: true,
                      child: actions,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _HeaderScrollRow(child: tabs),
      ],
    );
  }
}

/// Floating vertical action bar for the mobile, non-embedded settlement
/// screen. Mirrors the bar manager vertical buttons convention used across
/// the app (e.g. [CalendarVerticalBar], [MailVerticalBar]).
class _SettlementMobileVerticalBar extends StatelessWidget {
  final ThemeColors theme;
  final bool busy;
  final VoidCallback onRefresh;
  final bool isEmployeePreview;
  final VoidCallback? onToggleAudienceView;
  final VoidCallback? onEditAgreement;
  final VoidCallback onMoreOptions;

  const _SettlementMobileVerticalBar({
    required this.theme,
    required this.busy,
    required this.onRefresh,
    required this.isEmployeePreview,
    required this.onToggleAudienceView,
    required this.onEditAgreement,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _SettlementVerticalActionButton(
          theme: theme,
          tooltip: 'refresh'.tr,
          onPressed: busy ? null : onRefresh,
          child: Icon(Icons.refresh, color: theme.textColor),
        ),
        const SizedBox(height: 5),
        if (onToggleAudienceView != null) ...[
          _SettlementVerticalActionButton(
            theme: theme,
            tooltip: isEmployeePreview
                ? _ui('back_to_manager_view', 'Wróć do managera')
                : _ui('preview_as_employee', 'Podgląd pracownika'),
            isActive: isEmployeePreview,
            onPressed: busy ? null : onToggleAudienceView,
            child: Icon(
              isEmployeePreview
                  ? Icons.admin_panel_settings_outlined
                  : Icons.visibility_outlined,
              color: isEmployeePreview ? theme.themeColor : theme.textColor,
            ),
          ),
          const SizedBox(height: 5),
        ],
        if (onEditAgreement != null) ...[
          _SettlementVerticalActionButton(
            theme: theme,
            tooltip: 'manage_compensation'.tr,
            onPressed: busy ? null : onEditAgreement,
            child: Icon(Icons.tune, color: theme.textColor),
          ),
          const SizedBox(height: 5),
        ],
        _SettlementVerticalActionButton(
          theme: theme,
          tooltip: _ui('period_and_currency', 'Okres i waluta'),
          onPressed: busy ? null : onMoreOptions,
          child: Icon(Icons.calendar_month_outlined, color: theme.textColor),
        ),
      ],
    );
  }
}

class _SettlementVerticalActionButton extends StatelessWidget {
  final ThemeColors theme;
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;
  final bool isActive;

  const _SettlementVerticalActionButton({
    required this.theme,
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 450),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: isActive
              ? theme.themeColor.withAlpha(32)
              : theme.textFieldColor,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          border: Border.all(
            color: isActive ? theme.themeColor.withAlpha(180) : Colors.transparent,
          ),
        ),
        child: ElevatedButton(
          style: elevatedButtonStyleRounded10,
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}

class _HeaderTitle extends ConsumerWidget {
  final bool embedded;
  final EmployeeSettlementDashboardModel data;
  final String period;
  final _SettlementAudienceView audienceView;

  const _HeaderTitle({
    required this.embedded,
    required this.data,
    required this.period,
    required this.audienceView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: TopAppBarSize.resolve(context)),
        Text(
          embedded
              ? _ui('employee_settlement_short_title', 'Rozliczenie')
              : 'employee_settlement_dashboard'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
              ),
        ),
        if (!embedded) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                data.employeeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.textColor),
              ),
              if (data.employeeEmail.isNotEmpty)
                Text(
                  data.employeeEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.textColor.withAlpha(175)),
                ),
              CrmDashboardPill(
                label: audienceView == _SettlementAudienceView.manager
                    ? _ui('manager_view', 'Widok managera')
                    : _ui('employee_view', 'Widok pracownika'),
                icon: audienceView == _SettlementAudienceView.manager
                    ? Icons.admin_panel_settings_outlined
                    : Icons.visibility_outlined,
              ),
              CrmDashboardPill(
                label: _periodDisplay(period),
                icon: Icons.date_range_outlined,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  final bool embedded;
  final EmployeeSettlementDashboardModel data;
  final ThemeColors theme;
  final _SettlementRange range;
  final String period;
  final String currency;
  final _SettlementAudienceView audienceView;
  final bool actionInProgress;
  final ValueChanged<_SettlementAudienceView>? onAudienceViewChanged;
  final ValueChanged<_SettlementRange> onRangeChanged;
  final ValueChanged<String?> onPeriodChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final VoidCallback onRefresh;
  final VoidCallback? onEditAgreement;

  const _HeaderActions({
    required this.embedded,
    required this.data,
    required this.theme,
    required this.range,
    required this.period,
    required this.currency,
    required this.audienceView,
    required this.actionInProgress,
    required this.onAudienceViewChanged,
    required this.onRangeChanged,
    required this.onPeriodChanged,
    required this.onCurrencyChanged,
    required this.onRefresh,
    required this.onEditAgreement,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (!embedded) ...[
        _RangeSelector(
          value: range,
          enabled: !actionInProgress,
          onChanged: onRangeChanged,
        ),
        SizedBox(
          width: 160,
          child: CoreDropdown<String>(
            label: _ui('period_yyyy_mm', 'Okres'),
            value: period,
            options: _periodOptions(),
            display: _periodDisplay,
            enabled: !actionInProgress,
            onChanged: onPeriodChanged,
            prefixIcon: Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: theme.textColor,
            ),
          ),
        ),
        SizedBox(
          width: 120,
          child: CoreDropdown<String>(
            label: 'currency'.tr,
            value: currency,
            options: const ['PLN', 'EUR', 'USD', 'GBP'],
            enabled: !actionInProgress,
            onChanged: onCurrencyChanged,
            prefixIcon: Icon(
              Icons.currency_exchange,
              size: 18,
              color: theme.textColor,
            ),
          ),
        ),
        CoreOutlinedButton(
          onPressed: actionInProgress ? null : onRefresh,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, size: 18, color: theme.textColor),
              const SizedBox(width: 7),
              Text(
                'refresh'.tr,
                style: TextStyle(color: theme.textColor),
              ),
            ],
          ),
        ),
      ],
      if (onAudienceViewChanged != null)
        CrmDashboardTabPill(
          label: audienceView == _SettlementAudienceView.manager
              ? _ui('preview_as_employee', 'Podgląd pracownika')
              : _ui('back_to_manager_view', 'Wróć do managera'),
          icon: audienceView == _SettlementAudienceView.manager
              ? Icons.visibility_outlined
              : Icons.admin_panel_settings_outlined,
          selected: false,
          enabled: !actionInProgress,
          onTap: () {
            onAudienceViewChanged!(
              audienceView == _SettlementAudienceView.manager
                  ? _SettlementAudienceView.employee
                  : _SettlementAudienceView.manager,
            );
          },
        ),
      if (onEditAgreement != null)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250),
          child: CoreFilledButton(
            onPressed: actionInProgress ? null : onEditAgreement,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune, size: 18, color: theme.textColor),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    data.agreement == null
                        ? 'configure_settlements'.tr
                        : 'manage_compensation'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          children[i],
        ],
      ],
    );
  }
}

class _HeaderScrollRow extends StatelessWidget {
  final Widget child;
  final bool reverse;

  const _HeaderScrollRow({
    required this.child,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      reverse: reverse,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: child,
    );
  }
}

class _HeaderInlineBar extends StatelessWidget {
  final List<Widget> children;

  const _HeaderInlineBar({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _HeaderSoftDivider extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: theme.dashboardBoarder.withAlpha(150),
    );
  }
}

class _AudienceViewToggleButton extends ConsumerWidget {
  final _SettlementAudienceView value;
  final bool enabled;
  final ValueChanged<_SettlementAudienceView> onChanged;

  const _AudienceViewToggleButton({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = value == _SettlementAudienceView.manager
        ? _SettlementAudienceView.employee
        : _SettlementAudienceView.manager;

    return CrmDashboardTabPill(
      label: value == _SettlementAudienceView.manager
          ? _ui('preview_as_employee', 'Podgląd pracownika')
          : _ui('back_to_manager_view', 'Wróć do managera'),
      icon: value == _SettlementAudienceView.manager
          ? Icons.visibility_outlined
          : Icons.admin_panel_settings_outlined,
      selected: false,
      enabled: enabled,
      onTap: () => onChanged(target),
    );
  }
}

class _AudienceViewSelector extends ConsumerWidget {
  final _SettlementAudienceView value;
  final bool enabled;
  final ValueChanged<_SettlementAudienceView> onChanged;

  const _AudienceViewSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        CrmDashboardTabPill(
          label: _ui('manager_view', 'Widok managera'),
          icon: Icons.admin_panel_settings_outlined,
          selected: value == _SettlementAudienceView.manager,
          enabled: enabled,
          onTap: () => onChanged(_SettlementAudienceView.manager),
        ),
        CrmDashboardTabPill(
          label: _ui('employee_view', 'Widok pracownika'),
          icon: Icons.visibility_outlined,
          selected: value == _SettlementAudienceView.employee,
          enabled: enabled,
          onTap: () => onChanged(_SettlementAudienceView.employee),
        ),
      ],
    );
  }
}

class _RangeSelector extends ConsumerWidget {
  final _SettlementRange value;
  final bool enabled;
  final ValueChanged<_SettlementRange> onChanged;

  const _RangeSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CrmDashboardTabPill(
          label: _ui('settlement_current_month', 'Ten miesiąc'),
          icon: Icons.today_outlined,
          selected: value == _SettlementRange.currentMonth,
          enabled: enabled,
          onTap: () => onChanged(_SettlementRange.currentMonth),
        ),
        const SizedBox(width: 8),
        CrmDashboardTabPill(
          label: _ui('settlement_previous_month', 'Poprzedni'),
          icon: Icons.history_toggle_off_outlined,
          selected: value == _SettlementRange.previousMonth,
          enabled: enabled,
          onTap: () => onChanged(_SettlementRange.previousMonth),
        ),
      ],
    );
  }
}

class _DashboardTabs extends ConsumerWidget {
  final _SettlementDashboardTab value;
  final EmployeeSettlementPermissionsModel permissions;
  final _SettlementAudienceView audienceView;
  final bool hasDocuments;
  final bool showRules;
  final bool showSettings;
  final bool scrollable;
  final ValueChanged<_SettlementDashboardTab> onChanged;

  const _DashboardTabs({
    required this.value,
    required this.permissions,
    required this.audienceView,
    required this.hasDocuments,
    required this.showRules,
    required this.showSettings,
    required this.onChanged,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CrmDashboardTabPill(
          label: _ui('settlement_tab_dashboard', 'Dashboard'),
          icon: Icons.dashboard_customize_outlined,
          selected: value == _SettlementDashboardTab.dashboard,
          onTap: () => onChanged(_SettlementDashboardTab.dashboard),
        ),
        const SizedBox(width: 8),
        CrmDashboardTabPill(
          label: _ui('settlement_tab_history', 'Historia'),
          icon: Icons.history_outlined,
          selected: value == _SettlementDashboardTab.history,
          onTap: () => onChanged(_SettlementDashboardTab.history),
        ),
        if (showRules) ...[
          const SizedBox(width: 8),
          CrmDashboardTabPill(
            label: _ui('settlement_tab_rules', 'Reguły'),
            icon: Icons.rule_folder_outlined,
            selected: value == _SettlementDashboardTab.rules,
            onTap: () => onChanged(_SettlementDashboardTab.rules),
          ),
        ],
        const SizedBox(width: 8),
        CrmDashboardTabPill(
          label: _ui('settlement_tab_documents', 'Dokumenty'),
          icon: Icons.folder_shared_outlined,
          selected: value == _SettlementDashboardTab.documents,
          enabled: hasDocuments,
          onTap: () => onChanged(_SettlementDashboardTab.documents),
        ),
        if (showSettings) ...[
          const SizedBox(width: 8),
          CrmDashboardTabPill(
            label: _ui('settlement_tab_settings', 'Ustawienia'),
            icon: Icons.notifications_active_outlined,
            selected: value == _SettlementDashboardTab.settings,
            onTap: () => onChanged(_SettlementDashboardTab.settings),
          ),
        ],
      ],
    );

    if (!scrollable) return row;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: row,
    );
  }
}

class _SettlementBreakdownChart extends ConsumerWidget {
  final CompensationSettlementModel settlement;
  final String currency;

  const _SettlementBreakdownChart({
    required this.settlement,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final items = [
      _ChartItem(_ui('earnings', 'Naliczenia'), settlement.earningsTotal),
      _ChartItem(_ui('deductions', 'Potrącenia'), settlement.deductionsTotal),
      _ChartItem(_ui('reimbursements', 'Zwroty'), settlement.reimbursementsTotal),
      _ChartItem(_ui('paid', 'Zapłacone'), settlement.paidAmount),
      _ChartItem(_ui('outstanding', 'Do zapłaty'), settlement.outstandingAmount),
    ];
    final maxValue = items.fold<double>(
      0,
      (previous, item) => item.value > previous ? item.value : previous,
    );

    return CrmDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _ui('settlement_breakdown_chart', 'Szybki wykres rozliczenia'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              CrmDashboardPill(
                label: 'settlement_status_${settlement.status}'.tr,
                icon: Icons.circle,
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final item in items) ...[
            _ChartRow(
              item: item,
              maxValue: maxValue,
              currency: currency,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ChartItem {
  final String label;
  final double value;

  const _ChartItem(this.label, this.value);
}

class _ChartRow extends ConsumerWidget {
  final _ChartItem item;
  final double maxValue;
  final String currency;

  const _ChartRow({
    required this.item,
    required this.maxValue,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final factor = maxValue <= 0 ? 0.0 : (item.value / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: theme.textColor.withAlpha(170),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              _money(item.value, currency),
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: factor,
            minHeight: 9,
            backgroundColor: theme.themeColor.withAlpha(16),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.themeColor.withAlpha(190),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettlementLinesPreviewCard extends StatelessWidget {
  final EmployeeSettlementDashboardModel data;
  final VoidCallback? onAddLine;
  final ThemeColors theme;

  const _SettlementLinesPreviewCard({
    required this.data,
    required this.onAddLine,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final lines = data.currentSettlement!.lines;
    final visibleLines = lines.take(6).toList(growable: false);

    return CrmDashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _ui('current_settlement_items', 'Pozycje bieżącego rozliczenia'),
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${lines.length} ${'items_count'.tr}',
                  style: TextStyle(color: theme.textColor.withAlpha(160)),
                ),
                if (onAddLine != null) ...[
                  const SizedBox(width: 10),
                  CoreOutlinedButton(
                    onPressed: onAddLine,
                    child: Text(
                      'add_adjustment'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                data.permissions.canManage
                    ? 'settlement_table_empty_manager'.tr
                    : 'settlement_table_empty_employee'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else ...[
            for (final line in visibleLines)
              ListTile(
                leading: Icon(
                  line.direction == 'deduction'
                      ? Icons.remove_circle_outline
                      : line.direction == 'reimbursement'
                          ? Icons.replay_circle_filled_outlined
                          : Icons.add_circle_outline,
                  color: theme.textColor,
                ),
                title: Text(
                  line.title,
                  style: TextStyle(color: theme.textColor),
                ),
                subtitle: Text(
                  [
                    'settlement_line_type_${line.lineType}'.tr,
                    line.eventLabel ?? line.description,
                    line.calculationDescription,
                    if (line.isManual) 'manual'.tr,
                  ].where((item) => item.isNotEmpty).join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.textColor.withAlpha(150)),
                ),
                trailing: Text(
                  _money(line.amount, data.currency),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: theme.textColor,
                  ),
                ),
              ),
            if (lines.length > visibleLines.length)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CrmDashboardPill(
                    label: _ui(
                      'settlement_more_items_hint',
                      'Więcej pozycji zobaczysz po odświeżeniu / w szczegółach',
                    ),
                    icon: Icons.more_horiz,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DocumentsTabCard extends ConsumerWidget {
  final CompensationAgreementModel agreement;
  final bool isMobile;

  const _DocumentsTabCard({
    required this.agreement,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    if (agreement.documentBinding?.canView != true) {
      return CrmDashboardCard(
        child: Text(
          _ui('no_agreement_document_access', 'Brak dostępu do dokumentów tej umowy.'),
          style: TextStyle(color: theme.textColor),
        ),
      );
    }

    return CrmDashboardCard(
      child: CompensationAgreementDocumentsSection(
        agreement: agreement,
        isMobile: isMobile,
        embedded: false,
      ),
    );
  }
}

class _NotificationSettingsTabCard extends ConsumerWidget {
  final bool isMobile;
  final VoidCallback onOpenDialog;

  const _NotificationSettingsTabCard({
    required this.isMobile,
    required this.onOpenDialog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CrmDashboardCard(
          child: Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: theme.textColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ui('compensation_notification_settings', 'Ustawienia powiadomień'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: theme.textColor,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ui(
                        'compensation_notification_settings_hint',
                        'Tu ustawiasz, które zdarzenia rozliczeń mają wysyłać powiadomienia.',
                      ),
                      style: TextStyle(color: theme.textColor.withAlpha(160)),
                    ),
                  ],
                ),
              ),
              CoreOutlinedButton(
                onPressed: onOpenDialog,
                child: Text(
                  _ui('open_in_dialog', 'Otwórz w oknie'),
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CompensationNotificationPreferencesCard(isMobile: isMobile),
      ],
    );
  }
}


class _EmployeePreviewBanner extends ConsumerWidget {
  const _EmployeePreviewBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return CrmDashboardCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_outlined, color: theme.textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ui('employee_preview_mode_title', 'Podgląd widoku pracownika'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _ui(
                    'employee_preview_mode_message',
                    'Akcje managerskie są ukryte. To jest podgląd UI, a nie logowanie jako pracownik.',
                  ),
                  style: TextStyle(
                    color: theme.textColor.withAlpha(165),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeePreviewLockedCard extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmployeePreviewLockedCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return CrmDashboardCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(165),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoAgreementState extends ConsumerWidget {
  final EmployeeSettlementDashboardModel data;
  final VoidCallback? onConfigure;

  const _NoAgreementState({required this.data, required this.onConfigure});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return CrmDashboardCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.permissions.canManage
                    ? 'no_compensation_agreement_title'.tr
                    : 'employee_compensation_not_configured_title'.tr,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: theme.textColor,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                data.permissions.canManage
                    ? 'no_compensation_agreement_manager_message'
                        .trParams({'employee': data.employeeName})
                    : 'employee_compensation_not_configured_message'.tr,
                style: TextStyle(
                  color: theme.textColor.withAlpha(175),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CrmDashboardPill(label: 'fixed_salary'.tr, icon: Icons.payments_outlined),
                  CrmDashboardPill(label: 'hourly_billing'.tr, icon: Icons.schedule),
                  CrmDashboardPill(label: 'commission_billing'.tr, icon: Icons.percent),
                  CrmDashboardPill(label: 'milestone_billing'.tr, icon: Icons.flag_outlined),
                  CrmDashboardPill(label: 'custom_rules'.tr, icon: Icons.extension_outlined),
                ],
              ),
              if (onConfigure != null) ...[
                const SizedBox(height: 18),
                CoreFilledButton(
                  onPressed: onConfigure,
                  child: Text(
                    'configure_settlements'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ],
            ],
          );
          final visual = Container(
            width: constraints.maxWidth < 780 ? double.infinity : 220,
            height: 180,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 84,
              color: theme.themeColor.withAlpha(130),
            ),
          );
          if (constraints.maxWidth < 780) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [visual, const SizedBox(height: 20), content],
            );
          }
          return Row(children: [visual, const SizedBox(width: 26), Expanded(child: content)]);
        },
      ),
    );
  }
}

class _AgreementCard extends ConsumerWidget {
  final CompensationAgreementModel agreement;
  final VoidCallback? onEdit;
  final VoidCallback? onDocuments;

  const _AgreementCard({
    required this.agreement,
    required this.onEdit,
    required this.onDocuments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          agreement.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          '${'relationship_${agreement.relationshipType}'.tr} • '
          '${'compensation_mode_${agreement.compensationMode}'.tr} • '
          '${'pay_frequency_${agreement.payFrequency}'.tr}',
          style: TextStyle(color: theme.textColor.withAlpha(175)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CrmDashboardPill(
              label: 'agreement_status_${agreement.status}'.tr,
              icon: Icons.circle,
            ),
            CrmDashboardPill(
              label: '${agreement.currency} • ${agreement.validFrom}',
              icon: Icons.calendar_today_outlined,
            ),
            if (agreement.baseAmount > 0)
              CrmDashboardPill(
                label: _money(agreement.baseAmount, agreement.currency),
                icon: Icons.payments_outlined,
              ),
          ],
        ),
      ],
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if (onDocuments != null)
          CoreOutlinedButton(
            onPressed: onDocuments,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_shared_outlined,
                  size: 17,
                  color: theme.textColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'agreement_documents'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ],
            ),
          ),
        if (onEdit != null)
          CoreOutlinedButton(
            onPressed: onEdit,
            child: Text('edit'.tr, style: TextStyle(color: theme.textColor)),
          ),
      ],
    );
    return CrmDashboardCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;
          final header = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.dock_outlined, size: 30, color: theme.textColor),
              const SizedBox(width: 14),
              Expanded(child: content),
              if (!isNarrow) actions,
            ],
          );
          if (!isNarrow) return header;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 14),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _Metrics extends ConsumerWidget {
  final EmployeeSettlementDashboardModel data;
  const _Metrics({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final values = [
      ('employee_settlement_total'.tr, data.summary.total, Icons.account_balance_wallet_outlined),
      ('employee_settlement_paid'.tr, data.summary.paid, Icons.check_circle_outline),
      ('employee_settlement_unpaid'.tr, data.summary.unpaid, Icons.pending_actions_outlined),
      ('employee_settlement_deductions'.tr, data.summary.deductions, Icons.remove_circle_outline),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 620
            ? constraints.maxWidth
            : constraints.maxWidth < 1100
                ? (constraints.maxWidth - 12) / 2
                : (constraints.maxWidth - 36) / 4;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in values)
              SizedBox(
                width: width,
                child: CrmDashboardCard(
                  child: Row(
                    children: [
                      Icon(item.$3, size: 28, color: theme.textColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              style: TextStyle(
                                color: theme.textColor.withAlpha(170),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _money(item.$2, data.currency),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.w900,
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

class _NoSettlementCard extends ConsumerWidget {
  final EmployeeSettlementDashboardModel data;
  final bool busy;
  final VoidCallback? onCalculate;

  const _NoSettlementCard({
    required this.data,
    required this.busy,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return CrmDashboardCard(
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 42,
            color: theme.textColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'no_settlement_for_period'.trParams({'period': data.period}),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.summary.pendingEvents > 0
                      ? 'pending_events_ready'.trParams({
                          'count': data.summary.pendingEvents.toString(),
                        })
                      : 'no_events_for_settlement'.tr,
                  style: TextStyle(color: theme.textColor.withAlpha(170)),
                ),
              ],
            ),
          ),
          if (onCalculate != null)
            CoreFilledButton(
              onPressed: busy ? null : onCalculate,
              child: Text(
                'calculate_settlement'.tr,
                style: TextStyle(color: theme.textColor),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettlementOverview extends ConsumerWidget {
  final EmployeeSettlementDashboardModel data;
  final bool busy;
  final VoidCallback? onAddLine;
  final VoidCallback? onPublish;
  final VoidCallback? onRegisterPayment;
  final VoidCallback? onAcknowledge;

  const _SettlementOverview({
    required this.data,
    required this.busy,
    required this.onAddLine,
    required this.onPublish,
    required this.onRegisterPayment,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final settlement = data.currentSettlement!;
    final progress = settlement.netToPay <= 0
        ? 0.0
        : (settlement.paidAmount / settlement.netToPay).clamp(0.0, 1.0);

    return CrmDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'current_settlement'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              CrmDashboardPill(
                label: 'settlement_status_${settlement.status}'.tr,
                icon: Icons.circle,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _LabelValue('net_to_pay'.tr, _money(settlement.netToPay, settlement.currency)),
              _LabelValue('paid'.tr, _money(settlement.paidAmount, settlement.currency)),
              _LabelValue('outstanding'.tr, _money(settlement.outstandingAmount, settlement.currency)),
              _LabelValue('due_date'.tr, settlement.dueDate ?? 'not_calculated'.tr),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (onAddLine != null)
                CoreOutlinedButton(
                  onPressed: busy ? null : onAddLine,
                  child: Text('add_adjustment'.tr, style: TextStyle(color: theme.textColor)),
                ),
              if (onPublish != null)
                CoreFilledButton(
                  onPressed: busy ? null : onPublish,
                  child: Text('publish_to_employee'.tr, style: TextStyle(color: theme.textColor)),
                ),
              if (onRegisterPayment != null)
                CoreFilledButton(
                  onPressed: busy ? null : onRegisterPayment,
                  child: Text('register_payment'.tr, style: TextStyle(color: theme.textColor)),
                ),
              if (onAcknowledge != null)
                CoreFilledButton(
                  onPressed: busy ? null : onAcknowledge,
                  child: Text('acknowledge_settlement'.tr, style: TextStyle(color: theme.textColor)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettlementLinesCard extends StatelessWidget {
  final EmployeeSettlementDashboardModel data;
  final VoidCallback? onAddLine;
  final ThemeColors theme;

  const _SettlementLinesCard({required this.data, required this.onAddLine, required this.theme});

  @override
  Widget build(BuildContext context) {
    final lines = data.currentSettlement!.lines;
    return CrmDashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'employee_settlement_table'.tr,
                    style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text(
                  '${lines.length} ${'items_count'.tr}',
                  style: TextStyle(color: theme.textColor.withAlpha(170)),
                ),
                if (onAddLine != null) ...[
                  const SizedBox(width: 10),
                  CoreOutlinedButton(
                    onPressed: onAddLine,
                    child: Text('add_adjustment'.tr, style: TextStyle(color: theme.textColor)),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                data.permissions.canManage
                    ? 'settlement_table_empty_manager'.tr
                    : 'settlement_table_empty_employee'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w900,
                        ),
              ),
            )
          else
            for (final line in lines)
              ListTile(
                leading: Icon(
                  line.direction == 'deduction'
                      ? Icons.remove_circle_outline
                      : line.direction == 'reimbursement'
                          ? Icons.replay_circle_filled_outlined
                          : Icons.add_circle_outline,
                  color: theme.textColor,
                ),
                title: Text(line.title, style: TextStyle(color: theme.textColor)),
                subtitle: Text(
                  [
                    'settlement_line_type_${line.lineType}'.tr,
                    line.eventLabel ?? line.description,
                    line.calculationDescription,
                    if (line.isManual) 'manual'.tr,
                  ].where((item) => item.isNotEmpty).join(' • '),
                  
                    style: TextStyle(
                          color: theme.textColor.withAlpha(150),
                        ),
                ),
                trailing: Text(
                  _money(line.amount, data.currency),
                  style: TextStyle(fontWeight: FontWeight.w900, color: theme.textColor),
                ),
              ),
        ],
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  final EmployeeSettlementDashboardModel data;
  final VoidCallback? onAdd;
  final ValueChanged<CompensationRuleModel>? onEdit;
  final ThemeColors theme;

  const _RulesCard({required this.data, required this.onAdd, required this.onEdit, required this.theme});

  @override
  Widget build(BuildContext context) {
    final rules = data.agreement?.rules ?? const <CompensationRuleModel>[];
    return CrmDashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'compensation_rules'.tr,
                    
                    style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                if (onAdd != null)
                  CoreOutlinedButton(onPressed: onAdd, child: Text('add_rule'.tr, 
                    style: TextStyle(
                          color: theme.textColor,
                          
                        ),)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (rules.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                data.permissions.canManage
                    ? 'no_compensation_rules_manager'.tr
                    : 'no_compensation_rules_employee'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                          color: theme.textColor,
                        ),
              ),
            )
          else
            for (final rule in rules)
              ListTile(
                onTap: onEdit == null ? null : () => onEdit!(rule),
                leading: Icon(Icons.rule_folder_outlined, color: theme.textColor),
                title: Text(rule.title,
                    style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w900,
                        ),),
                subtitle: Text(
                  '${'rule_method_${rule.calculationMethod}'.tr} • '
                  '${rule.eventType.isEmpty ? 'all_events'.tr : rule.eventType}',
                  
                    style: TextStyle(
                          color: theme.textColor.withAlpha(150)
                        ),
                ),
                trailing: Text(
                  rule.isActive ? 'status_active'.tr : 'inactive'.tr,
                  
                    style: TextStyle(
                          color: theme.textColor,
                        ),
                ),
              ),
        ],
      ),
    );
  }
}

class _PaymentsCard extends ConsumerWidget {
  final EmployeeSettlementDashboardModel data;
  const _PaymentsCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final payouts = data.currentSettlement?.payouts ??
        const <CompensationPayoutModel>[];
    return CrmDashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'recent_payments'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: theme.textColor,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
          const Divider(height: 1),
          if (payouts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'no_registered_payments'.tr,
                style: TextStyle(color: theme.textColor),
              ),
            )
          else
            for (final payout in payouts)
              ListTile(
                leading: Icon(Icons.payments_outlined, color: theme.textColor),
                title: Text(
                  _money(payout.amount, payout.currency),
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  '${'payment_method_${payout.paymentMethod}'.tr} • '
                  '${payout.paidAt ?? payout.scheduledFor ?? 'unknown_date'.tr}',
                  style: TextStyle(color: theme.textColor.withAlpha(150)),
                ),
                trailing: Text(
                  payout.status,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final EmployeeSettlementDashboardModel data;
  final ThemeColors theme;
  const _HistoryCard({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    return CrmDashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'settlement_history'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: theme.textColor,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
          const Divider(height: 1),
          if (data.history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'no_settlement_history_message'.tr,
                style: TextStyle(color: theme.textColor),
              ),
            )
          else
            for (final settlement in data.history)
              ListTile(
                leading: Icon(Icons.history, color: theme.textColor),
                title: Text('${settlement.periodStart} – ${settlement.periodEnd}',
                    style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w900,
                        ),),
                subtitle: Text('settlement_status_${settlement.status}'.tr,
                    style: TextStyle(
                          color: theme.textColor.withAlpha(150),
                        ),
                ),
                trailing: Text(
                  _money(settlement.netToPay, settlement.currency),
                  style: TextStyle(fontWeight: FontWeight.w900, color: theme.textColor),
                ),
              ),
        ],
      ),
    );
  }
}

class _LabelValue extends ConsumerWidget {
  final String label;
  final String value;
  const _LabelValue(this.label, this.value);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme.textColor.withAlpha(150),
              ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

String _money(double value, String currency) {
  return '${value.toStringAsFixed(2)} $currency';
}

String _currentPeriod() {
  final now = DateTime.now();
  return _formatPeriod(DateTime(now.year, now.month, 1));
}

String _previousPeriod() {
  final now = DateTime.now();
  return _formatPeriod(DateTime(now.year, now.month - 1, 1));
}

String _formatPeriod(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}';
}

String _ui(String key, String fallback) {
  final translated = key.tr;
  return translated == key ? fallback : translated;
}

List<String> _periodOptions() {
  final now = DateTime.now();
  return List.generate(24, (index) {
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
