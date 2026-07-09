import 'package:crm_fliper/finance/widget/finance_custom_tap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/crm/providers/dashboard_provider.dart';
import 'package:get/get.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import 'package:core/user/user_contact/type_provider.dart';
import 'package:core/user/user_contact/type_model.dart';

final selectedContactTypeProvider = StateProvider<int?>((ref) => null);
final selectedTransactionFilterProvider = StateProvider<String?>((ref) => null);
final selectedCommissionDisplayProvider = StateProvider<String?>((ref) => null);

Map<String, String> get commissionLabels => {
      'expected': 'Estimated'.tr,
      'closed': 'Closed'.tr,
      'failed': 'Missed'.tr,
    };

Map<String, String> get transactionFilters => {
      'all': 'All Properties'.tr,
      'success': 'Only Success'.tr,
      'failed': 'Only Failed'.tr,
    };

class DashboardLastMountViewWidget extends ConsumerWidget {
  final bool isMobile;
  final bool isTablet;

  const DashboardLastMountViewWidget({
    super.key,
    this.isMobile = false, this.isTablet = false,
  });

  static const double _fallbackDesktopHeight = 180;
  static const double _fallbackMobileHeight = 330;

  String _formatWithSpaces(num? value, {String suffix = ' PLN'}) {
    if (value == null) return '-';

    final isNeg = value < 0;
    final digits = value.abs().toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;

    for (int i = digits.length - 1; i >= 0; i--) {
      buf.write(digits[i]);
      count++;

      if (count % 3 == 0 && i != 0) {
        buf.write(' ');
      }
    }

    final formatted = String.fromCharCodes(
      buf.toString().runes.toList().reversed,
    );

    return '${isNeg ? '-' : ''}$formatted$suffix';
  }

  double _lottieSize(BoxConstraints constraints, {double fallback = 220}) {
    final height =
        constraints.maxHeight.isFinite ? constraints.maxHeight : fallback;
    final width = constraints.maxWidth.isFinite ? constraints.maxWidth : fallback;

    return (height < width ? height : width).clamp(80.0, fallback);
  }

  void _updateDashboardParams({
    required WidgetRef ref,
    int? viewerTypeId,
    String? transactionStatusFilter,
    String? commissionDisplay,
    bool preserveViewerType = true,
    bool preserveTransactionFilter = true,
    bool preserveCommissionDisplay = true,
  }) {
    final current = ref.read(dashboardParamsProvider);

    ref.read(dashboardParamsProvider.notifier).state = DashboardParams(
      period: current.period,
      year: current.year,
      month: current.month,
      compareToPrevious: current.compareToPrevious,
      viewerTypeId:
          preserveViewerType ? current.viewerTypeId : viewerTypeId,
      transactionStatusFilter: preserveTransactionFilter
          ? current.transactionStatusFilter
          : transactionStatusFilter,
      commissionDisplay: preserveCommissionDisplay
          ? current.commissionDisplay
          : commissionDisplay,
    );
  }

  Widget _buildShell({
    required ThemeColors theme,
    required BoxConstraints constraints,
    required Widget child,
  }) {
    final hasBoundedHeight = constraints.maxHeight.isFinite;
    final fallbackHeight = isMobile ? _fallbackMobileHeight : _fallbackDesktopHeight;

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: child,
      ),
    );

    if (hasBoundedHeight) {
      return SizedBox.expand(child: content);
    }

    return SizedBox(
      height: fallbackHeight,
      child: content,
    );
  }

  Widget _buildLoading({
    required ThemeColors theme,
    required BoxConstraints constraints,
  }) {
    return _buildShell(
      theme: theme,
      constraints: constraints,
      child: Center(
        child: AppLottie.loading(
          size: _lottieSize(
            constraints,
            fallback: isMobile ? 260 : 220,
          ),
        ),
      ),
    );
  }

  Widget _buildError({
    required ThemeColors theme,
    required BoxConstraints constraints,
    required Object error,
  }) {
    return _buildShell(
      theme: theme,
      constraints: constraints,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            'Error: $error'.tr,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuIcon() {
    return const Icon(
      Icons.more_vert,
      color: Colors.grey,
      size: 18,
    );
  }

  Widget _buildTransactionPopup({
    required WidgetRef ref,
  }) {
    return SizedBox(
      width: 34,
      height: 34,
      child: PopupMenuButton<String?>(
        initialValue: ref.read(selectedTransactionFilterProvider),
        icon: _menuIcon(),
        color: Colors.grey[900],
        tooltip: 'Filter'.tr,
        itemBuilder: (context) {
          return transactionFilters.entries.map((entry) {
            return PopupMenuItem<String?>(
              value: entry.key,
              child: Text(
                entry.value,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList();
        },
        onSelected: (value) {
          ref.read(selectedTransactionFilterProvider.notifier).state = value;

          _updateDashboardParams(
            ref: ref,
            transactionStatusFilter: value,
            preserveViewerType: true,
            preserveTransactionFilter: false,
            preserveCommissionDisplay: true,
          );
        },
      ),
    );
  }

  Widget _buildCommissionPopup({
    required WidgetRef ref,
  }) {
    return SizedBox(
      width: 34,
      height: 34,
      child: PopupMenuButton<String?>(
        initialValue: ref.read(selectedCommissionDisplayProvider),
        icon: _menuIcon(),
        color: Colors.grey[900],
        tooltip: 'Filter'.tr,
        itemBuilder: (context) {
          return commissionLabels.entries.map((entry) {
            return PopupMenuItem<String?>(
              value: entry.key,
              child: Text(
                entry.value,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList();
        },
        onSelected: (value) {
          ref.read(selectedCommissionDisplayProvider.notifier).state = value;

          _updateDashboardParams(
            ref: ref,
            commissionDisplay: value,
            preserveViewerType: true,
            preserveTransactionFilter: true,
            preserveCommissionDisplay: false,
          );
        },
      ),
    );
  }

  Widget _buildContactTypePopup({
    required WidgetRef ref,
    required AsyncValue<List<UserContactType>> contactTypes,
  }) {
    return contactTypes.when(
      data: (types) {
        return SizedBox(
          width: 34,
          height: 34,
          child: PopupMenuButton<int?>(
            initialValue: ref.read(selectedContactTypeProvider),
            icon: _menuIcon(),
            color: Colors.grey[900],
            tooltip: 'Filter'.tr,
            itemBuilder: (context) {
              return [
                PopupMenuItem<int?>(
                  value: null,
                  child: Text(
                    'All'.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                ...types.map(
                  (e) => PopupMenuItem<int?>(
                    value: e.id,
                    child: Text(
                      e.contactType,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ];
            },
            onSelected: (newId) {
              ref.read(selectedContactTypeProvider.notifier).state = newId;

              _updateDashboardParams(
                ref: ref,
                viewerTypeId: newId,
                preserveViewerType: false,
                preserveTransactionFilter: true,
                preserveCommissionDisplay: true,
              );
            },
          ),
        );
      },
      loading: () {
        return const SizedBox(
          width: 24,
          height: 24,
          child: Padding(
            padding: EdgeInsets.all(4),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      error: (e, _) {
        return const SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.error,
            color: Colors.red,
            size: 18,
          ),
        );
      },
    );
  }

  List<_DashboardMetricCardData> _buildMetricData({
    required BuildContext context,
    required WidgetRef ref,
    required AsyncValue<List<UserContactType>> contactTypes,
    required dynamic transactions,
    required String transactionValue,
    required double transactionChange,
    required String commissionValue,
    required double commissionChange,
    required dynamic contacts,
    required dynamic compare,
  }) {
    return [
      _DashboardMetricCardData(
        title: 'contacts_title'.tr,
        value: contacts?.total?.toString() ?? '-',
        change: compare?.contacts['total']?.changePercent ?? 0,
        onTap: () {
          ref.read(navigationService).pushNamedScreen(Routes.proClients);
        },
      ),
      _DashboardMetricCardData(
        title: 'PROPERTIES SOLD'.tr,
        value: transactionValue,
        change: transactionChange,
        onTap: () {
          ref.read(navigationService).pushNamedScreen(Routes.proDraggable);
          ref.read(financeTabIndexProvider.notifier).state = 0;
        },
        trailing: _buildTransactionPopup(ref: ref),
      ),
      _DashboardMetricCardData(
        title: 'ESTIMATED COMMISSIONS'.tr,
        value: commissionValue,
        change: commissionChange,
        onTap: () {
          ref.read(navigationService).pushNamedScreen(Routes.proDraggable);
          ref.read(financeTabIndexProvider.notifier).state = 1;
        },
        trailing: _buildCommissionPopup(ref: ref),
      ),
      _DashboardMetricCardData(
        title: 'CUSTOMERS'.tr,
        value: contacts?.total?.toString() ?? '-',
        change: compare?.contacts['total']?.changePercent ?? 0,
        onTap: () {
          ref.read(navigationService).pushNamedScreen(Routes.proClients);
        },
        trailing: _buildContactTypePopup(
          ref: ref,
          contactTypes: contactTypes,
        ),
      ),
    ];
  }

  Widget _buildMetricsLayout({
    required List<_DashboardMetricCardData> cards,
    required bool mobileMode,
    required bool compact,
    required bool veryCompact,
    required double width,
    required double height,
  }) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    if (veryCompact) {
      final cardWidth = width < 420 ? width * 0.78 : 230.0;

      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return SizedBox(
            width: cardWidth,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: cards[index].onTap,
              child: DbLastMountCard(
                title: cards[index].title,
                value: cards[index].value,
                change: cards[index].change,
                trailing: cards[index].trailing,
                isMobile: true,
                compact: true,
                veryCompact: true,
              ),
            ),
          );
        },
      );
    }

    if (isTablet) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: cards[0].onTap,
                      child: DbLastMountCard(
                        title: cards[0].title,
                        value: cards[0].value,
                        change: cards[0].change,
                        trailing: cards[0].trailing,
                        isMobile: false,
                        compact: true,
                        veryCompact: false,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: EdgeInsets.symmetric(
                      vertical: compact ? 10 : 14,
                      horizontal: 4,
                    ),
                    color: Colors.grey.withOpacity(0.25),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: cards[1].onTap,
                      child: DbLastMountCard(
                        title: cards[1].title,
                        value: cards[1].value,
                        change: cards[1].change,
                        trailing: cards[1].trailing,
                        isMobile: false,
                        compact: true,
                        veryCompact: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              color: Colors.grey.withOpacity(0.25),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: cards[2].onTap,
                      child: DbLastMountCard(
                        title: cards[2].title,
                        value: cards[2].value,
                        change: cards[2].change,
                        trailing: cards[2].trailing,
                        isMobile: false,
                        compact: true,
                        veryCompact: false,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: EdgeInsets.symmetric(
                      vertical: compact ? 10 : 14,
                      horizontal: 4,
                    ),
                    color: Colors.grey.withOpacity(0.25),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: cards[3].onTap,
                      child: DbLastMountCard(
                        title: cards[3].title,
                        value: cards[3].value,
                        change: cards[3].change,
                        trailing: cards[3].trailing,
                        isMobile: false,
                        compact: true,
                        veryCompact: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (mobileMode || width < 760) {
      final crossAxisCount = width >= 560 ? 2 : 1;
      final cardHeight = compact ? 82.0 : 104.0;

      return GridView.builder(
        primary: false,
        padding: const EdgeInsets.all(8),
        physics: const ClampingScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisExtent: cardHeight,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final card = cards[index];

          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: card.onTap,
            child: DbLastMountCard(
              title: card.title,
              value: card.value,
              change: card.change,
              trailing: card.trailing,
              isMobile: true,
              compact: compact,
              veryCompact: false,
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: cards[i].onTap,
                child: DbLastMountCard(
                  title: cards[i].title,
                  value: cards[i].value,
                  change: cards[i].change,
                  trailing: cards[i].trailing,
                  isMobile: false,
                  compact: compact,
                  veryCompact: false,
                ),
              ),
            ),
            if (i != cards.length - 1)
              Container(
                width: 1,
                margin: EdgeInsets.symmetric(
                  vertical: compact ? 14 : 18,
                  horizontal: 4,
                ),
                color: Colors.grey.withOpacity(0.25),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactTypes = ref.watch(userContactTypesProvider);
    final dashboard = ref.watch(dashboardProvider);
    final theme = ref.watch(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite;
        final double height = hasBoundedHeight
    ? constraints.maxHeight
    : (isTablet
        ? 260.00
        : (isMobile
            ? _fallbackMobileHeight
            : _fallbackDesktopHeight));
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 900.0;

        final mobileMode = isMobile || width < 760;
        final compact = height < 170 || width < 900;
        final veryCompact = height < 118;

        return dashboard.when(
          data: (data) {
            final transactions = data?.transactions;
            final compare = data?.compareToPrevious;
            final revenue = data?.revenue;
            final contacts = data?.contacts;

            final selectedTransaction =
                ref.watch(selectedTransactionFilterProvider);
            final selectedCommission =
                ref.watch(selectedCommissionDisplayProvider);

            String getTransactionValue() {
              switch (selectedTransaction) {
                case 'success':
                  return transactions?.success.toString() ?? '-';
                case 'failed':
                  return transactions?.failed.toString() ?? '-';
                default:
                  return transactions?.total.toString() ?? '-';
              }
            }

            double getTransactionChange() {
              switch (selectedTransaction) {
                case 'success':
                  return compare?.transactions['success']?.changePercent ?? 0;
                case 'failed':
                  return compare?.transactions['failed']?.changePercent ?? 0;
                default:
                  return compare?.transactions['total']?.changePercent ?? 0;
              }
            }

        String getCommissionValue() {
          switch (selectedCommission) {
            case 'closed':
              return _formatWithSpaces(revenue?.closedCommissions);
            case 'failed':
              return _formatWithSpaces(revenue?.failedCommissions);
            default:
              return _formatWithSpaces(revenue?.expectedCommissions);
          }
        }


            double getCommissionChange() {
              switch (selectedCommission) {
                case 'closed':
                  return compare?.revenue['closed_commissions']
                          ?.changePercent ??
                      0;
                case 'failed':
                  return compare?.revenue['failed_commissions']
                          ?.changePercent ??
                      0;
                default:
                  return compare?.revenue['expected_commissions']
                          ?.changePercent ??
                      0;
              }
            }

            final cards = _buildMetricData(
              context: context,
              ref: ref,
              contactTypes: contactTypes,
              transactions: transactions,
              transactionValue: getTransactionValue(),
              transactionChange: getTransactionChange(),
              commissionValue: getCommissionValue(),
              commissionChange: getCommissionChange(),
              contacts: contacts,
              compare: compare,
            );

            return _buildShell(
              theme: theme,
              constraints: constraints,
              child: _buildMetricsLayout(
                cards: cards,
                mobileMode: mobileMode,
                compact: compact,
                veryCompact: veryCompact,
                width: width,
                height: height,
              ),
            );
          },
          loading: () {
            return _buildLoading(
              theme: theme,
              constraints: constraints,
            );
          },
          error: (e, _) {
            return _buildError(
              theme: theme,
              constraints: constraints,
              error: e,
            );
          },
        );
      },
    );
  }
}
class _DashboardMetricCardData {
  final String title;
  final String value;
  final double change;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _DashboardMetricCardData({
    required this.title,
    required this.value,
    required this.change,
    required this.onTap,
    this.trailing,
  });
}

class DbLastMountCard extends ConsumerWidget {
  final String title;
  final String value;
  final double change;
  final Widget? trailing;
  final bool isMobile;
  final bool compact;
  final bool veryCompact;

  const DbLastMountCard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    this.trailing,
    this.isMobile = false,
    this.compact = false,
    this.veryCompact = false,
  });

  Widget _buildChangeBadge({
    required ThemeColors theme,
  }) {
    final isNegative = change < 0;
    final isZero = change == 0;

    final color = isNegative
        ? const Color.fromRGBO(255, 106, 106, 1)
        : const Color.fromRGBO(166, 227, 184, 1);

    final bgColor = isNegative
        ? const Color.fromRGBO(255, 106, 106, 0.1)
        : const Color.fromRGBO(166, 227, 184, 0.1);

    final icon = isNegative ? Icons.trending_down : Icons.trending_up;

    if (isZero) {
      return Text(
        '${change.toStringAsFixed(1)}%',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.textColor.withValues(alpha: 0.6),
          fontSize: veryCompact ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: veryCompact ? 5 : 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: veryCompact ? 12 : 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${change.toStringAsFixed(1)}%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: veryCompact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueText({
    required ThemeColors theme,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: theme.textColor,
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard({
    required ThemeColors theme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: veryCompact ? 8 : 10,
        vertical: veryCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withValues(alpha: 0.6),
                    fontSize: veryCompact ? 10 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: veryCompact ? 4 : 8),
                _buildValueText(theme: theme),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildChangeBadge(theme: theme),
                if (!veryCompact) ...[
                  const SizedBox(height: 4),
                  Text(
                    'from last month'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          trailing ?? const SizedBox(width: 34, height: 34),
        ],
      ),
    );
  }

  Widget _buildDesktopCard({
    required ThemeColors theme,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisAlignment:
            compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withValues(alpha: 0.6),
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing ?? const SizedBox(width: 34, height: 34),
            ],
          ),
          SizedBox(height: compact ? 4 : 6),
          _buildValueText(theme: theme),
          if (!compact) const SizedBox(height: 6),
          if (compact) const SizedBox(height: 4),
          Row(
            children: [
              _buildChangeBadge(theme: theme),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'from last month'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    if (isMobile || compact || veryCompact) {
      return _buildCompactCard(theme: theme);
    }

    return _buildDesktopCard(theme: theme);
  }
}