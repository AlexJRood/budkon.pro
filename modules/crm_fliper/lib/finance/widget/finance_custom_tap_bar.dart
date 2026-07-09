import 'package:crm_fliper/selection_and_negotiations/widgets/flipper_custom_tap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/shell/manager/bar_manager.dart';

final financeTabIndexProvider = StateProvider<int>((ref) => 0);

class FinanceCustomTapBar extends ConsumerStatefulWidget {
  final AppModule appModule;
  final bool isTablet;

  /// ✅ potrzebne dla association żeby zbudować /association/admin/<id>/finance/...
  final int? companyId;

  const FinanceCustomTapBar({
    super.key,
    required this.appModule,
    this.isTablet = false,
    this.companyId,
  });

  @override
  ConsumerState<FinanceCustomTapBar> createState() =>
      _FinanceCustomTapBarState();
}

class _FinanceCustomTapBarState extends ConsumerState<FinanceCustomTapBar> {
  String _routeForIndex(int idx) {
    // agentCrm routes (zakładam że są "gotowe", bez :id)
    if (widget.appModule == AppModule.agentCrm) {
      if (idx == 0) return Routes.proFinanceDashboard;
      if (idx == 1) return Routes.proFinanceRevenue;
      return Routes.proFinanceExpenses;
    }

    // association routes (MUSZĄ mieć id)
    if (widget.appModule == AppModule.association) {
      final id = widget.companyId;
      if (id == null) return ''; // brak scope -> nic nie rób

      if (idx == 0) return Routes.associationFinanceOf(id);
      if (idx == 1) return Routes.associationFinanceRevenueOf(id);
      return Routes.associationFinanceExpenseOf(id);
    }

    // fallback
    return '';
  }

  void _selectTab(int idx) {
    ref.read(financeTabIndexProvider.notifier).state = idx;

    final route = _routeForIndex(idx);
    if (route.isEmpty) return;

    // ✅ updateUrl tylko z KONKRETNYM route (bez :id)
    updateUrl(route);

    // opcjonalnie: historia w apce (jak używasz currentRoute highlight)
    ref.read(navigationHistoryProvider.notifier).addPage(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final color = theme.themeColor;
    final textColor = theme.textColor;

    final tabIndex = ref.watch(financeTabIndexProvider);

    if (widget.isTablet) {
      final labels = ["Dashboard".tr, "Revenues".tr, "Expenses".tr];
      final currentLabel = labels[tabIndex.clamp(0, 2)];

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: PopupMenuButton<int>(
          onSelected: _selectTab,
          offset: const Offset(0, 45),
          color: theme.textFieldColor,
          itemBuilder: (context) {
            return List.generate(labels.length, (index) {
              final isSelected = tabIndex == index;
              return PopupMenuItem<int>(
                value: index,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.themeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: isSelected ? theme.themeTextColor : textColor,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.textFieldColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.dashboardBoarder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentLabel,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, color: textColor, size: 18),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 380.w,
        height: 45.h,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 4,
          children: [
            SelectionNegotiationTapBar(
              color: color,
              textColor: textColor,
              ref: ref,
              index: 0,
              title: "Dashboard".tr,
              selectIndex: () => _selectTab(0),
              tabIndex: tabIndex,
            ),
            SelectionNegotiationTapBar(
              color: color,
              textColor: textColor,
              ref: ref,
              index: 1,
              title: "Revenues".tr,
              selectIndex: () => _selectTab(1),
              tabIndex: tabIndex,
            ),
            SelectionNegotiationTapBar(
              color: color,
              textColor: textColor,
              ref: ref,
              index: 2,
              title: "Expenses".tr,
              selectIndex: () => _selectTab(2),
              tabIndex: tabIndex,
            ),
          ],
        ),
      ),
    );
  }
}
