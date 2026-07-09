import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';

import 'package:crm/data/finance/transaction_filters_provider.dart';
import 'package:crm/shared/models/transaction/transaction_status_model.dart';

class TransactionFiltersBody extends ConsumerWidget {
  final bool isMobile;
  final ThemeColors theme;
  final TransactionFiltersState filters;
  final List<TransactionStatus> statuses;

  final TextEditingController searchCtrl;

  const TransactionFiltersBody({
    super.key,
    required this.isMobile,
    required this.theme,
    required this.filters,
    required this.statuses,
    required this.searchCtrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(theme: theme, title: 'Search'.tr),
        const SizedBox(height: 8),
        _SearchField(theme: theme, controller: searchCtrl),
        const SizedBox(height: 16),

        _SectionTitle(theme: theme, title: 'Status'.tr),
        const SizedBox(height: 8),
        _StatusChips(theme: theme, statuses: statuses),
        const SizedBox(height: 16),

        _SectionTitle(theme: theme, title: 'Basic'.tr),
        const SizedBox(height: 8),
        _BasicFields(theme: theme),
        const SizedBox(height: 16),

        _SectionTitle(theme: theme, title: 'Amount Range'.tr),
        const SizedBox(height: 8),
        _RangeRow(
          theme: theme,
          leftLabel: 'Min'.tr,
          rightLabel: 'Max'.tr,
          leftValue: filters.amountMin,
          rightValue: filters.amountMax,
          onLeft: (v) => ref.read(transactionFiltersProvider.notifier).setAmountMin(v),
          onRight: (v) => ref.read(transactionFiltersProvider.notifier).setAmountMax(v),
        ),
        const SizedBox(height: 16),

        _SectionTitle(theme: theme, title: 'Commission Range'.tr),
        const SizedBox(height: 8),
        _RangeRow(
          theme: theme,
          leftLabel: 'Min'.tr,
          rightLabel: 'Max'.tr,
          leftValue: filters.commissionMin,
          rightValue: filters.commissionMax,
          onLeft: (v) => ref.read(transactionFiltersProvider.notifier).setCommissionMin(v),
          onRight: (v) => ref.read(transactionFiltersProvider.notifier).setCommissionMax(v),
        ),
        const SizedBox(height: 16),

        _SectionTitle(theme: theme, title: 'Flags'.tr),
        const SizedBox(height: 8),
        _TriStateChips(
          theme: theme,
          title: 'Paid'.tr,
          value: filters.isPaid,
          onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setIsPaid(v),
        ),
        const SizedBox(height: 10),
        _TriStateChips(
          theme: theme,
          title: 'Commission NET'.tr,
          value: filters.isCommissionNetValue,
          onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setIsCommissionNetValue(v),
        ),
        const SizedBox(height: 10),
        _TriStateChips(
          theme: theme,
          title: 'Seller'.tr,
          value: filters.isSeller,
          onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setIsSeller(v),
        ),
        const SizedBox(height: 10),
        _TriStateChips(
          theme: theme,
          title: 'Buyer'.tr,
          value: filters.isBuyer,
          onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setIsBuyer(v),
        ),
        const SizedBox(height: 16),

        _SectionTitle(theme: theme, title: 'Scope'.tr),
        const SizedBox(height: 8),
        _TriStateChips(
          theme: theme,
          title: 'Only mine'.tr,
          value: filters.onlyMine,
          onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setOnlyMine(v),
        ),
        const SizedBox(height: 10),
        _TriStateChips(
          theme: theme,
          title: 'Only viewed'.tr,
          value: filters.onlyViewed,
          onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setOnlyViewed(v),
        ),
        const SizedBox(height: 10),
        _TriStateChips(
          theme: theme,
          title: 'Only completed'.tr,
          value: filters.onlyCompleted,
          onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setOnlyCompleted(v),
        ),
        const SizedBox(height: 16),

        _SectionTitle(theme: theme, title: 'Include'.tr),
        const SizedBox(height: 8),
        _TriStateChips(
          theme: theme,
          title: 'Archived'.tr,
          value: filters.includeArchived,
          onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setIncludeArchived(v),
        ),
        const SizedBox(height: 10),
        _TriStateChips(
          theme: theme,
          title: 'Completed'.tr,
          value: filters.includeCompleted,
          onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setIncludeCompleted(v),
        ),
        const SizedBox(height: 10),
        _TriStateChips(
          theme: theme,
          title: 'Closed'.tr,
          value: filters.includeClosed,
          onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setIncludeClosed(v),
        ),
        const SizedBox(height: 16),

        _SectionTitle(theme: theme, title: 'Created date'.tr),
        const SizedBox(height: 8),
        _DateRangeRow(
          theme: theme,
          from: filters.dateFrom,
          to: filters.dateTo,
          onFrom: (d) => ref.read(transactionFiltersProvider.notifier).setDateFrom(d),
          onTo: (d) => ref.read(transactionFiltersProvider.notifier).setDateTo(d),
        ),
        const SizedBox(height: 16),

        _SectionTitle(theme: theme, title: 'Closed date'.tr),
        const SizedBox(height: 8),
        _DateRangeRow(
          theme: theme,
          from: filters.closedFrom,
          to: filters.closedTo,
          onFrom: (d) => ref.read(transactionFiltersProvider.notifier).setClosedFrom(d),
          onTo: (d) => ref.read(transactionFiltersProvider.notifier).setClosedTo(d),
        ),
        const SizedBox(height: 16),

        _SectionTitle(theme: theme, title: 'Sort'.tr),
        const SizedBox(height: 8),
        _OrderingChips(theme: theme),
        const SizedBox(height: 16),

        if (isMobile) const SizedBox(height: 80),
      ],
    );
  }
}

/* ===================== UI pieces ===================== */

class _SectionTitle extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  const _SectionTitle({required this.theme, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 14),
    );
  }
}

class _SearchField extends ConsumerWidget {
  final ThemeColors theme;
  final TextEditingController controller;
  const _SearchField({required this.theme, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setSearch(v),
        decoration: InputDecoration(
          hintText: 'Search transactions...'.tr,
          hintStyle: TextStyle(color: theme.textColor),
          prefixIcon:  Icon(Icons.search, size: 18,color: theme.textColor,),
          filled: true,
          fillColor: theme.dashboardContainer,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _StatusChips extends ConsumerWidget {
  final ThemeColors theme;
  final List<TransactionStatus> statuses;
  const _StatusChips({required this.theme, required this.statuses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(transactionFiltersProvider).statusId;

    ChoiceChip chip(String label, int? id) {
      final selected = current == id;
      return ChoiceChip(
        label: Text(label, style: TextStyle(color: selected ? theme.themeTextColor : theme.textColor)),
        selected: selected,
        selectedColor: theme.themeColor,
        checkmarkColor: theme.themeTextColor,
        backgroundColor: theme.dashboardContainer,
        onSelected: (_) => ref.read(transactionFiltersProvider.notifier).setStatusId(id),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('All'.tr, null),
        ...statuses.map((s) => chip(s.statusName, s.id)),
      ],
    );
  }
}

class _BasicFields extends ConsumerWidget {
  final ThemeColors theme;
  const _BasicFields({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(transactionFiltersProvider);

Widget field({
  required String label,
  required String? value,
  required ValueChanged<String> onChanged,
  String hint = '',
}) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              color: theme.textColor.withAlpha((255 * .8).toInt()),
              fontSize: 12,
            )),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextFormField(
            initialValue: value ?? '',
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: theme.textColor),
              filled: true,
              fillColor: theme.dashboardContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


    return Column(
      children: [
        Row(
          children: [
            field(
              label: 'Currency'.tr,
              value: f.currency,
              hint: 'PLN'.tr,
              onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setCurrency(v.trim().isEmpty ? null : v.trim()),
            ),
            const SizedBox(width: 10),
            field(
              label: 'Payment method'.tr,
              value: f.paymentMethod,
              hint: 'cash / transfer...'.tr,
              onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setPaymentMethod(v.trim().isEmpty ? null : v.trim()),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transaction type'.tr, style: TextStyle(color: theme.textColor.withAlpha((255 * .8).toInt()), fontSize: 12)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 44,
                    child: TextField(
                      controller: TextEditingController(text: f.transactionType ?? '')
                        ..selection = TextSelection.collapsed(offset: (f.transactionType ?? '').length),
                      onChanged: (v) => ref.read(transactionFiltersProvider.notifier).setTransactionType(v.trim().isEmpty ? null : v.trim()),
                      decoration: InputDecoration(
                        hintText: 'sale / rent...'.tr,
                        hintStyle: TextStyle(color: theme.textColor),
                        filled: true,
                        fillColor: theme.dashboardContainer,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RangeRow extends StatelessWidget {
  final ThemeColors theme;
  final String leftLabel;
  final String rightLabel;
  final double? leftValue;
  final double? rightValue;
  final ValueChanged<double?> onLeft;
  final ValueChanged<double?> onRight;

  const _RangeRow({
    required this.theme,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftValue,
    required this.rightValue,
    required this.onLeft,
    required this.onRight,
  });

  double? _parse(String v) {
    final t = v.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  @override
  Widget build(BuildContext context) {
    Widget numberField(String label, double? value, ValueChanged<double?> onChanged) {
      final txt = value == null ? '' : value.toString();
      final ctrl = TextEditingController(text: txt)..selection = TextSelection.collapsed(offset: txt.length);

      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: theme.textColor.withAlpha((255 * .8).toInt()), fontSize: 12)),
            const SizedBox(height: 6),
            SizedBox(
              height: 44,
              child: TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => onChanged(_parse(v)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.dashboardContainer,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        numberField(leftLabel, leftValue, onLeft),
        const SizedBox(width: 10),
        numberField(rightLabel, rightValue, onRight),
      ],
    );
  }
}

class _TriStateChips extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const _TriStateChips({
    required this.theme,
    required this.title,
    required this.value,
    required this.onChanged,
  });

          @override
          Widget build(BuildContext context) {
            ChoiceChip chip(String label, bool? v) {
              final selected = value == v;
              return ChoiceChip(
                label: Text(label, style: TextStyle(color: selected ? theme.themeTextColor : theme.textColor)),
                selected: selected,
                selectedColor: theme.themeColor,
                checkmarkColor: theme.themeTextColor,
                backgroundColor: theme.dashboardContainer,
                onSelected: (isNowSelected) {
          // jeśli kliknęliśmy już zaznaczony chip (Yes/No), cofamy do Any
          if (selected && v != null) {
            onChanged(null);
            return;
          }
          onChanged(v);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: theme.textColor.withAlpha((255 * .85).toInt()), fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('Any'.tr, null),
            chip('Yes'.tr, true),
            chip('No'.tr, false),
          ],
        ),
      ],
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  final ThemeColors theme;
  final DateTime? from;
  final DateTime? to;
  final ValueChanged<DateTime?> onFrom;
  final ValueChanged<DateTime?> onTo;

  const _DateRangeRow({
    required this.theme,
    required this.from,
    required this.to,
    required this.onFrom,
    required this.onTo,
  });

  String _fmt(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")}';
  }

  Future<DateTime?> _pick(BuildContext context, DateTime? initial) async {
    final now = DateTime.now();
    final init = initial ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(init.year, init.month, init.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            dialogBackgroundColor: theme.adPopBackground,
            colorScheme: base.colorScheme.copyWith(
              primary: theme.themeColor,
              onPrimary: theme.themeTextColor,
              surface: theme.adPopBackground,
              onSurface: theme.textColor,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    Widget dateBox(String label, DateTime? value, Future<void> Function() onTap) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: theme.textColor.withAlpha((255 * .8).toInt()), fontSize: 12)),
            const SizedBox(height: 6),
            InkWell(
              onTap: onTap,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_fmt(value), style: TextStyle(color: theme.textColor)),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        dateBox('From'.tr, from, () async => onFrom(await _pick(context, from))),
        const SizedBox(width: 10),
        dateBox('To'.tr, to, () async => onTo(await _pick(context, to))),
      ],
    );
  }
}

class _OrderingChips extends ConsumerWidget {
  final ThemeColors theme;
  const _OrderingChips({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(transactionFiltersProvider).ordering;

    ChoiceChip chip(String label, String? value) {
      final selected = current == value;
      return ChoiceChip(
        label: Text(label, style: TextStyle(color: selected ? theme.themeTextColor : theme.textColor)),
        selected: selected,
        selectedColor: theme.themeColor,
        checkmarkColor: theme.themeTextColor,
        backgroundColor: theme.dashboardContainer,
        onSelected: (_) => ref.read(transactionFiltersProvider.notifier).setOrdering(value),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Default'.tr, null),
        chip('Newest'.tr, '-date_create'),
        chip('Oldest'.tr, 'date_create'),
        chip('Amount ↓'.tr, '-amount'),
        chip('Amount ↑'.tr, 'amount'),
        chip('Updated ↓'.tr, '-date_update'),
        chip('Updated ↑'.tr, 'date_update'),
        chip('Viewed ↓'.tr, '-last_viewed'),
        chip('Viewed ↑'.tr, 'last_viewed'),
      ],
    );
  }
}
