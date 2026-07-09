import 'dart:async';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:crm/crm/finance/dashboard/api_dashboard.dart';
import 'package:crm/crm/finance/providers/finance_company_scope.dart';
import 'package:crm_fliper/finance/widget/finance_custom_tap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/crm/finance_crm_pc.dart';
import 'package:crm_agent/crm/finance_crm_tablet.dart';
import 'package:crm_agent/crm/finance_crm_mobile.dart';
import 'package:crm_agent/crm/widgets/finance_crm_widgets.dart';

class FinanceCrmPage extends ConsumerStatefulWidget {
  final AppModule appModule;
  final int? companyId;
  const FinanceCrmPage({super.key, this.companyId, required this.appModule});

  @override
  ConsumerState<FinanceCrmPage> createState() => _FinanceCrmPageState();
}

class _FinanceCrmPageState extends ConsumerState<FinanceCrmPage> {
  final sideMenuKey = GlobalKey<SideMenuState>();

  @override
  void initState() {
    super.initState();
    _initProviders();
  }

  @override
  void didUpdateWidget(covariant FinanceCrmPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateProviders(oldWidget);
  }

  void _initProviders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kind =
          widget.appModule == AppModule.association
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

  void _updateProviders(FinanceCrmPage oldWidget) {
    final kind =
        widget.appModule == AppModule.association
            ? FinanceScopeKind.association
            : FinanceScopeKind.company;

    final oldKind =
        oldWidget.appModule == AppModule.association
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
    final tabIndex = ref.watch(financeTabIndexProvider);
    final selectedSegment = switch (tabIndex) {
      1 => '/revenue',
      2 => '/expenses',
      _ => '/transactions',
    };

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: widget.appModule,
      layoutTypePc: LayoutTypePc.stack,
      enableScrool: false,
      verticalButtons: SegmentFloatingPanel(
        selectedSegment: selectedSegment,
        onSelectionChanged: (selected) {
          final val = selected.first;
          if (val == '/revenue') {
            ref.read(financeTabIndexProvider.notifier).state = 1;
          } else if (val == '/expenses') {
            ref.read(financeTabIndexProvider.notifier).state = 2;
          } else {
            ref.read(financeTabIndexProvider.notifier).state = 0;
          }
        },
      ),
      childPc: FinanceCrmPc(
        appModule: widget.appModule,
        companyId: widget.companyId,
      ),
      childTablet: FinanceCrmTablet(
        appModule: widget.appModule,
        companyId: widget.companyId,
      ),
      childMobile: FinanceCrmMobile(selectedSegment: selectedSegment),
    );
  }
}
