import 'package:crm/data/components/finance_chart/provider.dart';
import 'package:crm_agent/crm/widgets/invoice_details_view.dart';
import 'package:crm_agent/models/expense/crm_expenses_download_model.dart';
import 'package:crm_agent/models/revenue_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/lottie.dart';

class FinancialWidget extends ConsumerStatefulWidget {
  final bool isMobile;

  /// Przewija widok tak, by domyślnie był przy prawej krawędzi.
  final bool alignRight;

  /// Zwiększa wysokość kart (np. gdy widget jest rozciągnięty).
  final bool isExpanded;

  /// Wyświetla pozycje w kolumnie zamiast poziomego slidera.
  final bool vertical;

  const FinancialWidget({
    super.key,
    this.isMobile = false,
    this.alignRight = false,
    this.isExpanded = false,
    this.vertical = false,
  });

  @override
  ConsumerState<FinancialWidget> createState() => _FinancialWidgetState();
}

class _FinancialWidgetState extends ConsumerState<FinancialWidget> {
  late final ScrollController _scrollController;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'pl_PL',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentData = ref.watch(revenueAndExpensesProvider);
    final prevData = ref.watch(prevMonthRevenueAndExpensesProvider);
    final theme = ref.watch(themeColorsProvider);
    final screenSize = MediaQuery.of(context).size;

    return currentData.when(
      data: (data) {
        final revenues = data['revenues'] as List<AgentRevenueModel>;
        final expenses = data['expenses'] as List<CrmExpensesDownloadModel>;

        if (revenues.isEmpty && expenses.isEmpty) {
          return prevData.when(
            data: (prevMonthData) {
              final prevRevenues =
                  prevMonthData['revenues'] as List<AgentRevenueModel>;
              final prevExpenses =
                  prevMonthData['expenses'] as List<CrmExpensesDownloadModel>;
              return _buildContent(
                context, theme, screenSize, prevRevenues, prevExpenses,
                isPrevMonth: true,
              );
            },
            loading: () => const ShimmerlistPlaceholder(),
            error: (_, __) =>
                _buildContent(context, theme, screenSize, revenues, expenses),
          );
        }

        return _buildContent(context, theme, screenSize, revenues, expenses);
      },
      loading: () => const ShimmerlistPlaceholder(),
      error: (error, stackTrace) {
        debugPrint('financial widget error $error');
        return const ShimmerlistPlaceholder();
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    dynamic theme,
    Size screenSize,
    List<AgentRevenueModel> revenues,
    List<CrmExpensesDownloadModel> expenses, {
    bool isPrevMonth = false,
  }) {
    // When showing the prev-month label in a fixed-height cell we go compact:
    // save 6px per chip row (×2=12) + 8px spacing + 4px label padding = 24px,
    // which exactly offsets the label height so the total stays the same.
    final bool compact = isPrevMonth && !widget.isExpanded && !widget.vertical;
    final double cardHeight = widget.isExpanded ? 50.0 : (compact ? 24.0 : 30.0);
    final double hPadding = widget.isExpanded ? 20.0 : 15.0;
    final double midSpacing = compact ? 2.0 : 10.0;

    final revenueItems = revenues.isEmpty
        ? [_buildEmptyCard(theme, cardHeight, hPadding, isRevenue: true)]
        : revenues
            .map((r) => _buildRevenueCard(
                context, theme, screenSize, r, cardHeight, hPadding))
            .toList();

    final expenseItems = expenses.isEmpty
        ? [_buildEmptyCard(theme, cardHeight, hPadding, isRevenue: false)]
        : expenses
            .map((e) => _buildExpenseCard(
                context, theme, screenSize, e, cardHeight, hPadding))
            .toList();

    final prevMonthLabel = isPrevMonth
        ? Padding(
            padding: EdgeInsets.only(bottom: compact ? 0.0 : 4.0),
            child: Text(
              'prev_month_data'.tr,
              style: AppTextStyles.interMedium14.copyWith(
                color: theme.textColor.withAlpha(128),
                fontSize: 11,
              ),
            ),
          )
        : null;

    if (widget.vertical) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if (prevMonthLabel != null) prevMonthLabel,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: revenueItems,
            ),
            SizedBox(height: midSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: expenseItems,
            ),
          ],
        ),
      );
    }

    return DragScrollView(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        reverse: widget.alignRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: revenueItems,
            ),
            SizedBox(height: midSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: expenseItems,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(
    dynamic theme,
    double cardHeight,
    double hPadding, {
    required bool isRevenue,
  }) {
    return Container(
      height: cardHeight,
      width: widget.vertical ? double.infinity : null,
      margin: widget.vertical
          ? const EdgeInsets.only(bottom: 6.0)
          : const EdgeInsets.only(right: 10.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    isRevenue ? 'no_revenues'.tr : 'no_expenses'.tr,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTextStyles.interMedium14.copyWith(
                      color: theme.textColor.withAlpha(178),
                    ),
                  ),
                ),
                AppLottie.noResults(size: cardHeight - 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard(
    BuildContext context,
    dynamic theme,
    Size screenSize,
    AgentRevenueModel revenue,
    double cardHeight,
    double hPadding,
  ) {
    final formattedAmount =
        currencyFormat.format(double.parse(revenue.amount));
    return PieMenu(
      theme: PieTheme.of(context).copyWith(
        overlayColor: _overlayColor(theme),
      ),
      onPressedWithDevice: (kind) {
        if (kind == PointerDeviceKind.mouse ||
            kind == PointerDeviceKind.touch) {
          _showRevenueDetails(context, theme, screenSize, revenue);
        }
      },
      child: _cardChip(
        theme: theme,
        text: '$formattedAmount ${revenue.currency}',
        textColor: AppColors.revenueGreen,
        cardHeight: cardHeight,
        hPadding: hPadding,
      ),
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    dynamic theme,
    Size screenSize,
    CrmExpensesDownloadModel expense,
    double cardHeight,
    double hPadding,
  ) {
    final formattedAmount =
        currencyFormat.format(double.parse(expense.amount));
    return PieMenu(
      theme: PieTheme.of(context).copyWith(
        overlayColor: _overlayColor(theme),
      ),
      onPressedWithDevice: (kind) {
        if (kind == PointerDeviceKind.mouse ||
            kind == PointerDeviceKind.touch) {
          _showExpenseDetails(context, theme, screenSize, expense);
        }
      },
      child: _cardChip(
        theme: theme,
        text: '- $formattedAmount ${expense.currency}',
        textColor: AppColors.expensesRed,
        cardHeight: cardHeight,
        hPadding: hPadding,
      ),
    );
  }

  Widget _cardChip({
    required dynamic theme,
    required String text,
    required Color textColor,
    required double cardHeight,
    required double hPadding,
  }) {
    return Container(
      height: cardHeight,
      width: widget.vertical ? double.infinity : null,
      margin: widget.vertical
          ? const EdgeInsets.only(bottom: 6.0)
          : const EdgeInsets.only(right: 10.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTextStyles.interMedium14.copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );
  }

  Color _overlayColor(dynamic theme) {
    final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;
    final base = uiIsDark ? Colors.black : Colors.white;
    return base.withValues(alpha: 0.70);
  }

  void _showRevenueDetails(
    BuildContext context,
    dynamic theme,
    Size screenSize,
    AgentRevenueModel revenue,
  ) {
    if (widget.isMobile) {
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
            builder: (context, scrollController) => ExpensesViewDetailsWidget(
              revenue: revenue,
              isMobile: widget.isMobile,
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
                borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              height: screenSize.height / 1.2,
              width: screenSize.width / 1.2,
              child: ExpensesViewDetailsWidget(
                revenue: revenue,
                isMobile: widget.isMobile,
              ),
            ),
          );
        },
      );
    }
  }

  void _showExpenseDetails(
    BuildContext context,
    dynamic theme,
    Size screenSize,
    CrmExpensesDownloadModel expense,
  ) {
    if (widget.isMobile) {
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
            builder: (context, scrollController) => ExpensesViewDetailsWidget(
              expense: expense,
              isMobile: widget.isMobile,
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
                borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              height: screenSize.height / 1.2,
              width: screenSize.width / 1.2,
              child: ExpensesViewDetailsWidget(
                expense: expense,
                isMobile: widget.isMobile,
              ),
            ),
          );
        },
      );
    }
  }
}

class ShimmerlistPlaceholder extends StatefulWidget {
  const ShimmerlistPlaceholder({super.key});

  @override
  State<ShimmerlistPlaceholder> createState() => _ShimmerlistPlaceholderState();
}

class _ShimmerlistPlaceholderState extends State<ShimmerlistPlaceholder> {
  late final ScrollController scrollcontroller;

  @override
  void initState() {
    super.initState();
    scrollcontroller = ScrollController();
  }

  @override
  void dispose() {
    scrollcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DragScrollView(
          controller: scrollcontroller,
          child: SingleChildScrollView(
            controller: scrollcontroller,
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    8,
                    (index) => Container(
                      height: 25,
                      margin: const EdgeInsets.only(right: 10.0),
                      child: const ShimmerPlaceholder(
                        radius: 5.0,
                        height: 25,
                        width: 100,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    8,
                    (index) => Container(
                      height: 25,
                      margin: const EdgeInsets.only(right: 10.0),
                      child: const ShimmerPlaceholder(
                        radius: 5.0,
                        height: 25,
                        width: 100,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
