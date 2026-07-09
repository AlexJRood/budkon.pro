import 'package:crm/invoices/form/provider/form_provider.dart';
import 'package:crm/invoices/form/provider/invoice_number_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/text_field.dart';

import 'package:crm/invoices/form/models/revenue_expenses_form_state_model.dart';

class InvoiceFormWidget extends ConsumerStatefulWidget {
  final ThemeColors theme;
  final bool isMobile;

  const InvoiceFormWidget({
    super.key,
    required this.theme,
    required this.isMobile,
  });

  @override
  ConsumerState<InvoiceFormWidget> createState() => _InvoiceFormWidgetState();
}

class _InvoiceFormWidgetState extends ConsumerState<InvoiceFormWidget> {
  // Local UI state: shows/hides "Sale date" picker.
  bool _saleDateEnabled = false;

  // Stores the due date before switching to "paid" to allow restoring it.
  DateTime? _dueDateBeforePaid;

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<DateTime?> _pickDate({
    required BuildContext context,
    required DateTime initial,
  }) async {
    final theme = ref.read(themeColorsProvider);
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: theme.dashboardContainer,
          colorScheme: ColorScheme.light(
            primary: theme.themeColor,
            onPrimary: theme.textColor,
            surface: theme.dashboardContainer,
            onSurface: theme.textColor,
            outline: theme.dashboardBoarder,
            primaryContainer: theme.dashboardContainer,
            onPrimaryContainer: theme.textColor,
          ),
          dividerColor: theme.dashboardBoarder,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: theme.textColor,
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: theme.dashboardContainer,
            headerBackgroundColor: theme.themeColor,
            headerForegroundColor: theme.textColor,
            dayForegroundColor: MaterialStatePropertyAll(theme.textColor),
            weekdayStyle: TextStyle(color: theme.textColor),
            dayStyle: TextStyle(color: theme.textColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dashboardBoarder),
            ),
          ),
        ),
        child: child!,
      ),
    );

    return picked;
  }

  List<String> _eventsForDay({
    required DateTime day,
    required DateTime? invoiceDate,
    required DateTime? saleDate,
    required DateTime? paymentDate,
  }) {
    final events = <String>[];
    if (invoiceDate != null && isSameDay(day, invoiceDate)) events.add('invoice');
    if (saleDate != null && isSameDay(day, saleDate)) events.add('sale');
    if (paymentDate != null && isSameDay(day, paymentDate)) events.add('payment');
    return events;
  }


ProviderSubscription<RevenueExpensesFormState>? _formSub;

@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    ref.read(revenueFormProvider.notifier).ensureDefaults(
          defaultPaymentTermDays: 14,
        );

    final s = ref.read(revenueFormProvider);
    final inv = s.selectedDate;
    final sale = s.selectedSaleDate;
    final shouldEnable =
        (inv != null && sale != null && !isSameDay(inv, sale));

    if (mounted) {
      setState(() => _saleDateEnabled = shouldEnable);
    }

    await ref.read(invoiceNumberProvider.notifier).refreshFromForm();
  });

  _formSub = ref.listenManual<RevenueExpensesFormState>(
    revenueFormProvider,
    (prev, next) {
      final prevType = prev?.invoiceType;
      final nextType = next.invoiceType;

      final prevDate = prev?.selectedDate;
      final nextDate = next.selectedDate;

      final typeChanged = prevType != nextType;
      final dateChanged = prevDate != nextDate;

      if (typeChanged || dateChanged) {
        ref.read(invoiceNumberProvider.notifier).refreshFromForm();

        if (!_saleDateEnabled && nextDate != null) {
          ref.read(revenueFormProvider.notifier).setSaleDate(nextDate);
        }

        final prevPay = prev?.selectedPaymentDate;
        if (prev?.isPaid == true && next.isPaid == true && prevPay != null) {
          final nextPay = next.selectedPaymentDate;
          if (nextPay == null || !isSameDay(prevPay, nextPay)) {
            ref.read(revenueFormProvider.notifier).setPaymentDate(prevPay);
          }
        }
      }
    },
  );
}

@override
void dispose() {
  _formSub?.close();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final bool isMobile = widget.isMobile;

    final formState = ref.watch(revenueFormProvider);
    final notifier = ref.read(revenueFormProvider.notifier);

    final invoiceValue = _fmtDate(formState.selectedDate);
    final paymentValue = _fmtDate(formState.selectedPaymentDate);
    final saleValue = _fmtDate(formState.selectedSaleDate);

    Widget dateButton({
      required String label,
      required String value,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return CoreOutlinedButton(
        onPressed: onTap,
        child: DateButtonContent(
          label: label,
          value: value,
          icon: icon,
        ),
      );
    }

    Future<void> onPickInvoiceDate() async {
      final now = _dateOnly(DateTime.now());
      final initial = formState.selectedDate ?? now;

      final picked = await _pickDate(context: context, initial: initial);
      if (picked == null) return;

      // Preserve paid date if already paid.
      final prevPaymentDate = formState.selectedPaymentDate;
      final wasPaid = formState.isPaid;

      final d = _dateOnly(picked);
      notifier.setInvoiceDate(d);

      // If sale date toggle is OFF -> always keep it equal to invoice date.
      if (!_saleDateEnabled) {
        notifier.setSaleDate(d);
      }

      // If it was paid, restore the payment date after invoice date change.
      if (wasPaid && prevPaymentDate != null) {
        notifier.setPaymentDate(prevPaymentDate);
      }
    }

    Future<void> onPickSaleDate() async {
      final now = _dateOnly(DateTime.now());
      final initial = formState.selectedSaleDate ?? formState.selectedDate ?? now;

      final picked = await _pickDate(context: context, initial: initial);
      if (picked == null) return;

      notifier.setSaleDate(_dateOnly(picked));
    }

    Future<void> onPickPaymentDate() async {
      final now = _dateOnly(DateTime.now());
      final initial = formState.selectedPaymentDate ?? formState.selectedDate ?? now;

      final picked = await _pickDate(context: context, initial: initial);
      if (picked == null) return;

      notifier.setPaymentDate(_dateOnly(picked));
    }

    // ✅ Clickable whole "Paid"
    Widget paidToggle() {
      final isChecked = formState.isPaid;

      void togglePaid() {
        final next = !isChecked;

        if (next) {
          // Going -> PAID: remember current due date and set payment date to sale day by default.
          _dueDateBeforePaid = formState.selectedPaymentDate;

          final fallback = _dateOnly(
            formState.selectedSaleDate ?? formState.selectedDate ?? DateTime.now(),
          );

          notifier.setPaymentDate(fallback);
        } else {
          // Going -> UNPAID: restore previous due date if we have one.
          if (_dueDateBeforePaid != null) {
            notifier.setPaymentDate(_dueDateBeforePaid!);
          }
        }

        notifier.setPaid(next);
      }

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: togglePaid,
          child: Container(
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dashboardBoarder),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: isMobile ? 10 : 6,
            ),
            child: Row(
              children: [
                IgnorePointer(
                  child: Checkbox(
                    value: isChecked,
                    onChanged: (_) {},
                    activeColor: theme.themeColor,
                    checkColor: theme.textColor,
                    side: BorderSide(color: theme.dashboardBoarder),
                  ),
                ),
                Expanded(
                  child: Text(
                    'paid'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- Typ dokumentu jako chips (responsive) ---
    Widget invoiceTypeChips() {
      final selectedInvoice = formState.invoiceType == 'Invoice';
      final selectedProforma = formState.invoiceType == 'Proforma';

      Widget chip({
        required bool selected,
        required VoidCallback onTap,
        required IconData icon,
        required String text,
      }) {
        return ChoiceChip(
          selected: selected,
          onSelected: (_) => onTap(),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.white : theme.textColor,
              ),
              const SizedBox(width: 6),
              Text(text),
            ],
          ),
          labelStyle: TextStyle(
            color: selected ? AppColors.white : theme.textColor,
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: theme.adPopBackground,
          selectedColor: theme.themeColor,
          side: BorderSide(color: theme.dashboardBoarder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }

      // Comments in English.
      // On mobile we use Wrap to avoid overflow (Row + Spacer can overflow on small widths).
      final chips = <Widget>[
        chip(
          selected: selectedInvoice,
          onTap: () => notifier.setInvoiceType('Invoice'),
          icon: Icons.receipt_long,
          text: 'invoice'.tr,
        ),
        chip(
          selected: selectedProforma,
          onTap: () => notifier.setInvoiceType('Proforma'),
          icon: Icons.description_outlined,
          text: 'proforma'.tr,
        ),
      ];

      return Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: isMobile ? 12 : 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'document_type'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (isMobile)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips,
              )
            else
              Row(
                children: [
                  ...chips.expand((w) => [w, const SizedBox(width: 8)]).toList()
                    ..removeLast(),
                ],
              ),
          ],
        ),
      );
    }

    // --- Presety terminu płatności (responsive) ---
    final presets = <(InvoiceDuePreset, String, IconData)>[
      (InvoiceDuePreset.day1, '1_day'.tr, Icons.today),
      (InvoiceDuePreset.day3, '3_days'.tr, Icons.today_outlined),
      (InvoiceDuePreset.week1, '1_week'.tr, Icons.calendar_view_week),
      (InvoiceDuePreset.week2, '2_weeks'.tr, Icons.calendar_view_week),
      (InvoiceDuePreset.week3, '3_weeks'.tr, Icons.calendar_view_week),
      (InvoiceDuePreset.month1, '1_month'.tr, Icons.calendar_month),
      (InvoiceDuePreset.month3, '3_months'.tr, Icons.calendar_month),
    ];

    Widget duePresetChips() {
      final isPaid = formState.isPaid;

      String titleLabel() => isPaid ? 'payment_deadline'.tr : 'payment_due_date'.tr;
      String dateLabel() => isPaid ? 'payment_date'.tr : 'payment_date_alt'.tr;

      return Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleLabel(),
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            paidToggle(),
            const SizedBox(height: 10),
            dateButton(
              label: dateLabel(),
              value: paymentValue,
              icon: isPaid ? Icons.verified_outlined : Icons.payments_outlined,
              onTap: onPickPaymentDate,
            ),
            if (!isPaid) ...[
              const SizedBox(height: 10),

              // Comments in English.
              // Mobile: Wrap gives better usability than a tiny fixed-height horizontal list.
              if (isMobile)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (preset, label, icon) in presets)
                      ChoiceChip(
                        selected: formState.duePreset == preset,
                        onSelected: (_) => notifier.setDuePreset(preset),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 16,
                              color: (formState.duePreset == preset)
                                  ? AppColors.white
                                  : theme.textColor,
                            ),
                            const SizedBox(width: 6),
                            Text(label),
                          ],
                        ),
                        labelStyle: TextStyle(
                          color: (formState.duePreset == preset)
                              ? AppColors.white
                              : theme.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: theme.adPopBackground,
                        selectedColor: theme.themeColor,
                        side: BorderSide(color: theme.dashboardBoarder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                  ],
                )
              else
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: presets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final (preset, label, icon) = presets[i];
                      final selected = formState.duePreset == preset;

                      return ChoiceChip(
                        selected: selected,
                        onSelected: (_) => notifier.setDuePreset(preset),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 16,
                              color: selected ? AppColors.white : theme.textColor,
                            ),
                            const SizedBox(width: 6),
                            Text(label),
                          ],
                        ),
                        labelStyle: TextStyle(
                          color: selected ? AppColors.white : theme.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: theme.adPopBackground,
                        selectedColor: theme.themeColor,
                        side: BorderSide(color: theme.dashboardBoarder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      );
    }

    Widget invoiceNumberBox() {
      final previewAsync = ref.watch(invoiceNumberProvider);
      final reservationId = formState.invoiceNumberReservationId;
      final expiresAt = formState.invoiceNumberReservationExpiresAt;

      String expiresLabel() {
        if (expiresAt == null) return '';
        final d = expiresAt;
        final hh = d.hour.toString().padLeft(2, '0');
        final mm = d.minute.toString().padLeft(2, '0');
        return '${'valid_until'.tr} $hh:$mm';
      }

      return Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'document_number'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'refresh_number'.tr,
                  onPressed: () =>
                      ref.read(invoiceNumberProvider.notifier).refreshFromForm(),
                  icon: Icon(Icons.refresh, color: theme.textColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            previewAsync.when(
              data: (_) {
                final number = formState.invoiceNumberController.text;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: formState.invoiceNumberController,
                      readOnly: true,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.adPopBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.dashboardBoarder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.dashboardBoarder),
                        ),
                        suffixIcon: (expiresAt != null)
                            ? Padding(
                                padding:
                                    const EdgeInsets.only(right: 10, top: 14),
                                child: Text(
                                  expiresLabel(),
                                  style: TextStyle(
                                    color: theme.textColor.withAlpha(160),
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null,
                        suffixIconConstraints:
                            const BoxConstraints(minWidth: 0, minHeight: 0),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (reservationId != null && reservationId.isNotEmpty)
                      Text(
                        'reservation_active'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(160),
                          fontSize: 12,
                        ),
                      ),
                    if (number.isEmpty)
                      Text(
                        'no_number_refresh'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(160),
                          fontSize: 12,
                        ),
                      ),
                  ],
                );
              },
              loading: () => Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'generating_number'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ],
              ),
              error: (e, _) => Text(
                '${'number_error'.tr} $e',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Issue date + optional sale date (toggle-based)
    Widget issueAndSaleDateTile() {
      final invoiceDate = formState.selectedDate ?? _dateOnly(DateTime.now());

      return Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'issue_date'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            dateButton(
              label: 'issue_date'.tr,
              value: invoiceValue,
              icon: Icons.event,
              onTap: onPickInvoiceDate,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'sale_date_different_from_issue'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(220),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: _saleDateEnabled,
                  onChanged: (v) {
                    setState(() => _saleDateEnabled = v);

                    if (!v) {
                      // When toggle OFF: enforce sale date == invoice date
                      notifier.setSaleDate(invoiceDate);
                    } else {
                      // When toggle ON: ensure sale date is at least set (start from invoice date)
                      if (formState.selectedSaleDate == null) {
                        notifier.setSaleDate(invoiceDate);
                      }
                    }
                  },
                  activeColor: theme.themeColor,
                ),
              ],
            ),
            if (_saleDateEnabled) ...[
              const SizedBox(height: 10),
              dateButton(
                label: 'sale_date'.tr,
                value: saleValue,
                icon: Icons.sell_outlined,
                onTap: onPickSaleDate,
              ),
            ],
          ],
        ),
      );
    }

    Widget leftSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          invoiceTypeChips(),
          const SizedBox(height: 20),
          invoiceNumberBox(),
          const SizedBox(height: 14),
          issueAndSaleDateTile(),
          const SizedBox(height: 14),
          duePresetChips(),
          const SizedBox(height: 20),
          CoreDropdown<String>(
            label: 'payment_method'.tr,
            value: formState.paymentMethods,
            options: const ['Cash', 'Bank transfer'],
            onChanged: (v) {
              if (v == null) return;
              notifier.setPaymentMethod(v);
            },
            fillColor: theme.dashboardContainer,
          ),
        ],
      );
    }

    Widget calendarPreview() {
      // Range: invoiceDate -> paymentDate
      final DateTime? startRaw = formState.selectedDate;
      final DateTime? endRaw = formState.selectedPaymentDate;

      DateTime? safeStart = startRaw;
      DateTime? safeEnd = endRaw;

      if (safeStart != null && safeEnd != null && safeEnd.isBefore(safeStart)) {
        final tmp = safeStart;
        safeStart = safeEnd;
        safeEnd = tmp;
      }

      final bool hasRange = safeStart != null && safeEnd != null;

      DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

      bool inRange(DateTime day) {
        if (!hasRange) return false;
        final d = dateOnly(day);
        final s = dateOnly(safeStart!);
        final e = dateOnly(safeEnd!);
        return !d.isBefore(s) && !d.isAfter(e);
      }

      bool isStart(DateTime day) => hasRange && isSameDay(day, safeStart);
      bool isEnd(DateTime day) => hasRange && isSameDay(day, safeEnd);
      bool isToday(DateTime day) => isSameDay(day, DateTime.now());

      bool isSale(DateTime day) =>
          formState.selectedSaleDate != null && isSameDay(day, formState.selectedSaleDate);

      BorderRadius rangeRadius(DateTime day) {
        final start = isStart(day);
        final end = isEnd(day);

        if (start && end) return BorderRadius.circular(12);
        if (start) return const BorderRadius.horizontal(left: Radius.circular(12));
        if (end) return const BorderRadius.horizontal(right: Radius.circular(12));
        return BorderRadius.zero;
      }

      // Comments in English.
      // Unified border logic so sale date can be highlighted even outside the range.
      BoxBorder? cellBorder(DateTime day) {
        // Priority: range endpoints first
        if (isStart(day)) return Border.all(color: theme.themeColor, width: 1.5);
        if (isEnd(day)) return Border.all(color: Colors.green, width: 1.5);

        // Sale date border only when toggle is ON and sale differs from invoice date.
        final saleEnabled = _saleDateEnabled &&
            formState.selectedSaleDate != null &&
            formState.selectedDate != null &&
            !isSameDay(formState.selectedSaleDate, formState.selectedDate);

        if (saleEnabled && isSale(day)) {
          return Border.all(color: Colors.orangeAccent, width: 1.5);
        }

        if (isToday(day)) return Border.all(color: theme.textColor.withAlpha(120), width: 1.5);
        return null;
      }

      Widget buildDayCell(DateTime day, {required bool isOutside}) {
        final ranged = inRange(day);
        final textColor = isOutside ? theme.textColor.withAlpha(120) : theme.textColor;
        final today = isSameDay(day, DateTime.now());
        final hasBorder = cellBorder(day) != null;

        return Center(
          child: Container(
            width: double.infinity,
            height: isMobile ? 34 : 36,
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
            alignment: Alignment.center,
            decoration: (ranged || today || hasBorder)
                ? BoxDecoration(
                    color: theme.adPopBackground,
                    borderRadius: rangeRadius(day),
                    border: cellBorder(day),
                  )
                : null,
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: ranged ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        );
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dashboardBoarder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: formState.focusedDay,
          onPageChanged: notifier.setFocusedDay,
          eventLoader: (day) => _eventsForDay(
            day: day,
            invoiceDate: formState.selectedDate,
            saleDate: formState.selectedSaleDate,
            paymentDate: formState.selectedPaymentDate,
          ),
          selectedDayPredicate: (_) => false,
          onDaySelected: (selectedDay, focusedDay) {
            notifier.setFocusedDay(focusedDay);
          },
          headerStyle: HeaderStyle(
            leftChevronIcon: Icon(Icons.chevron_left, color: theme.textColor),
            rightChevronIcon: Icon(Icons.chevron_right, color: theme.textColor),
            titleTextStyle: TextStyle(color: theme.textColor),
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: CalendarStyle(
            defaultTextStyle: TextStyle(color: theme.textColor),
            weekendTextStyle: TextStyle(color: theme.textColor),
            outsideTextStyle: TextStyle(color: theme.textColor.withAlpha(120)),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) => buildDayCell(day, isOutside: false),
            outsideBuilder: (context, day, focusedDay) => buildDayCell(day, isOutside: true),
            todayBuilder: (context, day, focusedDay) => buildDayCell(day, isOutside: false),
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return const SizedBox.shrink();

              final hasInvoice = events.contains('invoice');
              final hasSale = events.contains('sale');
              final hasPayment = events.contains('payment');

              Widget dot(Color c) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  );

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasInvoice) dot(theme.themeColor),
                  if (hasSale) dot(Colors.orangeAccent),
                  if (hasPayment) dot(Colors.green),
                ],
              );
            },
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: theme.adPopBackground,
      ),
      padding: const EdgeInsets.all(20),
      margin: isMobile ? const EdgeInsets.symmetric(horizontal: 10) : const EdgeInsets.symmetric(horizontal: 20),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftSection(),
                const SizedBox(height: 20),
                calendarPreview(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: leftSection()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: calendarPreview()),
              ],
            ),
    );
  }
}