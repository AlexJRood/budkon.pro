import 'package:crm/employee_panel/provider/employee_leave_entitlement_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

class EmployeeLeaveBalanceCard extends ConsumerWidget {
  final int employeeId;
  final int year;
  final bool canManage;
  final VoidCallback? onChanged;

  const EmployeeLeaveBalanceCard({
    super.key,
    required this.employeeId,
    required this.year,
    this.canManage = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final params = EmployeeLeaveDashboardParams(employeeId: employeeId, year: year);
    final state = ref.watch(employeeLeaveDashboardProvider(params));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: state.when(
        loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
        error: (error, _) => Text(error.toString(), style: TextStyle(color: theme.textColor)),
        data: (data) {
          final balance = data.balance;
          final policy = data.policy;
          final progress = balance.accruedDays <= 0
              ? 0.0
              : (balance.usedDays / balance.accruedDays).clamp(0.0, 1.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.themeColor.withAlpha(24),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dashboardBoarder),
                    ),
                    child: Icon(Icons.beach_access_outlined, color: theme.textColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'leave_balance'.tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${balance.availableDays.toStringAsFixed(2)} ${'days_available'.tr}',
                          style: TextStyle(
                            color: theme.textColor.withAlpha(170),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canManage)
                    CoreOutlinedButton(
                      onPressed: () => _openBackfillDialog(context, ref, data),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_outlined, size: 18),
                          const SizedBox(width: 7),
                          Text('backfill'.tr),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.adPopBackground,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _LeaveMetric(label: 'annual_limit'.tr, value: balance.limitDays),
                  _LeaveMetric(label: 'accrued'.tr, value: balance.accruedDays),
                  _LeaveMetric(label: 'used'.tr, value: balance.usedDays),
                  _LeaveMetric(label: 'pending'.tr, value: balance.pendingDays),
                  _LeaveMetric(label: 'carried_over'.tr, value: balance.carriedOverDays),
                  _LeaveMetric(label: 'cashed_out'.tr, value: balance.cashedOutDays),
                ],
              ),
              if (policy != null) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PolicyPill(
                      icon: Icons.gavel_outlined,
                      label: policy.entitlementMode == 'statutory_pl'
                          ? 'PL ${policy.annualEntitlementDays.toStringAsFixed(0)} dni ustawowo'
                          : '${policy.customEntitlementDays.toStringAsFixed(2)} dni custom',
                    ),
                    _PolicyPill(
                      icon: Icons.timelapse_outlined,
                      label: _accrualLabel(policy.accrualMethod),
                    ),
                    _PolicyPill(
                      icon: Icons.percent_outlined,
                      label: 'FTE ${policy.fullTimeEquivalent.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ],
              if (canManage) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CoreOutlinedButton(
                        onPressed: () => _openCashoutDialog(context, ref, data),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payments_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text('cashout_unused_leave'.tr),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openBackfillDialog(
    BuildContext context,
    WidgetRef ref,
    EmployeeLeaveDashboardModel data,
  ) async {
    final used = TextEditingController(text: data.balance.usedDays.toStringAsFixed(2));
    final carried = TextEditingController(text: data.balance.carriedOverDays.toStringAsFixed(2));
    final adjustment = TextEditingController(text: data.balance.manualAdjustmentDays.toStringAsFixed(2));
    final note = TextEditingController(text: data.balance.note);

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('backfill_leave_data'.tr),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CoreTextField(label: 'used_days'.tr, controller: used, keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  CoreTextField(label: 'carried_over_days'.tr, controller: carried, keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  CoreTextField(label: 'manual_adjustment_days'.tr, controller: adjustment, keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  CoreTextField(label: 'note'.tr, controller: note, minLines: 2, maxLines: 4),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('cancel'.tr)),
              ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('save'.tr)),
            ],
          );
        },
      );

      if (saved == true) {
        await ref.read(employeeLeaveActionsProvider.notifier).backfill(
              employeeId: employeeId,
              year: year,
              usedDays: double.tryParse(used.text.replaceAll(',', '.')),
              carriedOverDays: double.tryParse(carried.text.replaceAll(',', '.')),
              manualAdjustmentDays: double.tryParse(adjustment.text.replaceAll(',', '.')),
              note: note.text.trim(),
            );
        ref.invalidate(employeeLeaveDashboardProvider(EmployeeLeaveDashboardParams(employeeId: employeeId, year: year)));
        onChanged?.call();
      }
    } finally {
      used.dispose();
      carried.dispose();
      adjustment.dispose();
      note.dispose();
    }
  }

  Future<void> _openCashoutDialog(
    BuildContext context,
    WidgetRef ref,
    EmployeeLeaveDashboardModel data,
  ) async {
    final days = TextEditingController(text: data.balance.availableDays.toStringAsFixed(2));
    final reason = TextEditingController();
    final terminationDate = TextEditingController();
    var approveNow = true;
    var overrideWarning = false;

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setLocalState) {
              return AlertDialog(
                title: Text('cashout_unused_leave'.tr),
                content: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ekwiwalent przy umowie o pracę używaj głównie przy zakończeniu stosunku pracy. Dla B2B/agency możesz użyć własnej polityki.',
                      ),
                      const SizedBox(height: 12),
                      CoreTextField(label: 'days'.tr, controller: days, keyboardType: TextInputType.number),
                      const SizedBox(height: 10),
                      CoreTextField(label: 'termination_date_optional'.tr, controller: terminationDate, hintText: 'YYYY-MM-DD'),
                      const SizedBox(height: 10),
                      CoreTextField(label: 'reason'.tr, controller: reason, minLines: 2, maxLines: 4),
                      SwitchListTile(
                        value: approveNow,
                        onChanged: (value) => setLocalState(() => approveNow = value),
                        title: Text('approve_now'.tr),
                      ),
                      SwitchListTile(
                        value: overrideWarning,
                        onChanged: (value) => setLocalState(() => overrideWarning = value),
                        title: Text('override_legal_warning'.tr),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('cancel'.tr)),
                  ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('save'.tr)),
                ],
              );
            },
          );
        },
      );

      if (saved == true) {
        await ref.read(employeeLeaveActionsProvider.notifier).createCashout(
              employeeId: employeeId,
              agreementId: data.policy?.agreement,
              policyId: data.policy?.id,
              year: year,
              days: double.tryParse(days.text.replaceAll(',', '.')) ?? 0,
              terminationDate: terminationDate.text.trim().isEmpty ? null : terminationDate.text.trim(),
              reason: reason.text.trim(),
              approveNow: approveNow,
              overrideLegalWarning: overrideWarning,
            );
        ref.invalidate(employeeLeaveDashboardProvider(EmployeeLeaveDashboardParams(employeeId: employeeId, year: year)));
        onChanged?.call();
      }
    } finally {
      days.dispose();
      reason.dispose();
      terminationDate.dispose();
    }
  }
}

class _LeaveMetric extends ConsumerWidget {
  final String label;
  final double value;

  const _LeaveMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      width: 138,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(color: theme.textColor, fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PolicyPill extends ConsumerWidget {
  final IconData icon;
  final String label;

  const _PolicyPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.textColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: theme.textColor, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

String _accrualLabel(String value) {
  switch (value) {
    case 'upfront_prorated':
      return 'Roczny limit proporcjonalny';
    case 'manual':
      return 'Ręcznie';
    default:
      return 'Nalicza miesięcznie';
  }
}
