import 'package:crm/crm/finance/features/transactions/filters.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

import 'package:crm/data/finance/transaction_provider.dart';
import 'package:crm/data/finance/transaction_filters_provider.dart'; // ✅ ADD (for activeCount)

/// Przycisk w stylu SideButtonsDashboard, ale dedykowany do filtrów transakcji.
/// Otwiera TransactionFiltersDialog w formie:
/// - PC: AlertDialog
/// - Mobile: BottomSheet
class SideButtonsTransactionFiltersButton extends ConsumerWidget {
  final bool isMobile;

  /// jeśli chcesz, możesz przekazać inny ikon lub tekst
  final IconData icon;
  final String text;

  const SideButtonsTransactionFiltersButton({
    super.key,
    required this.isMobile,
    this.icon = Icons.tune,
    this.text = 'Filters',
  });

  void _openFilters(BuildContext context, WidgetRef ref, TransactionState data) {
    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (ctx, scrollCtrl) {
            return TransactionFiltersDialog(
              statuses: data.statuses,
              isMobile: true,
              scrollController: scrollCtrl,
            );
          },
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => TransactionFiltersDialog(
        statuses: data.statuses,
        isMobile: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Badge: liczba aktywnych filtrów
    final count = ref.watch(transactionFiltersProvider).activeCount();
    final label = count == 0 ? text : '$text ($count)';

    // weź aktualne statusy z providera (musimy je przekazać do dialogu)
    final txAsync = ref.watch(transactionProvider);

    return txAsync.when(
      loading: () => SideButtonsDashboard(
        onPressed: () {},
        icon: icon,
        text: label, // ✅ use label
      ),
      error: (_, __) => SideButtonsDashboard(
        onPressed: () {},
        icon: icon,
        text: label, // ✅ use label
      ),
      data: (data) => SideButtonsDashboard(
        onPressed: () => _openFilters(context, ref, data),
        icon: icon,
        text: label, // ✅ use label
      ),
    );
  }
}

class SideButtonsDashboard extends ConsumerWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String text;

  const SideButtonsDashboard({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return GestureDetector(
      onTap: onPressed,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: Radius.circular(6),
        color: theme.textColor.withAlpha((255 * 0.75).toInt()),
        dashPattern: [6, 3],
        strokeWidth: 1.5,
        child: Container(
          width: 130,
          height: 45.h,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: theme.textColor,
                size: 20,
              ),
              SizedBox(width: 6.w),
              Text(
                text,
                style: AppTextStyles.interMedium10.copyWith(
                  color: theme.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SideButtonsDashboardDropdown extends ConsumerWidget {
  final IconData icon;
  final String text;

  /// Każdy item: label + callback
  final List<SideButtonsDropdownItem> items;

  const SideButtonsDashboardDropdown({
    super.key,
    required this.icon,
    required this.text,
    required this.items,
  });

  Future<void> _openMenu(BuildContext context, WidgetRef ref) async {
    final theme = ref.read(themeColorsProvider);

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final box = context.findRenderObject() as RenderBox?;

    if (overlay == null || box == null) return;

    final position = box.localToGlobal(Offset.zero, ancestor: overlay);

    final selected = await showMenu<int>(
      context: context,
      color: theme.adPopBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + box.size.height + 6,
        position.dx + box.size.width,
        position.dy,
      ),
      items: List.generate(items.length, (index) {
        final item = items[index];
        return PopupMenuItem<int>(
          value: index,
          child: Row(
            children: [
              Icon(item.icon ?? icon, size: 18, color: theme.textColor),
              SizedBox(width: 8.w),
              Text(
                item.label,
                style: AppTextStyles.interMedium10.copyWith(
                  color: theme.textColor,
                ),
              ),
            ],
          ),
        );
      }),
    );

    if (selected == null) return;
    items[selected].onTap();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return GestureDetector(
      onTap: () => _openMenu(context, ref),
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(6),
        color: theme.textColor.withAlpha((255 * 0.75).toInt()),
        dashPattern: const [6, 3],
        strokeWidth: 1.5,
        child: Container(
          width: 150,
          height: 45.h,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.textColor, size: 20),
              SizedBox(width: 6.w),
              Text(
                text,
                style: AppTextStyles.interMedium10.copyWith(
                  color: theme.textColor,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(Icons.keyboard_arrow_down,
                  color: theme.textColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class SideButtonsDropdownItem {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const SideButtonsDropdownItem({
    required this.label,
    required this.onTap,
    this.icon,
  });
}
