import 'package:crm/data/finance/api_servises_expenses_plans.dart';
import 'package:crm/data/finance/filter_plans.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/common/models/expenses_plan_model.dart';

List<PieAction> pieMenuFinancalPlansExpenses(
    WidgetRef ref, BuildContext context, planId, ExpensesPlanModel plan) {
  return [
    PieAction(
      tooltip:  Text('Usuń'.tr),
      onSelect: () async {
        confirmDeletePlan(context, ref, planId);
      },
      child: FaIcon(FontAwesomeIcons.trash),
    ),
    PieAction(
      tooltip:  Text('Edytuj'.tr),
      onSelect: () async {
        showEditPlanDialog(context, ref, plan);
      },
      child: const FaIcon(FontAwesomeIcons.filter),
    ),



PieAction(
  tooltip: Text('Dodaj do kosztów'.tr),
  onSelect: () async {
    final messenger = ScaffoldMessenger.of(context); // zapisz przed await

    await ref.read(expensesPlanProvider.notifier).addPlanToExpense(planId);

    messenger.showSnackBar(
      SnackBar(
        content: Text('Plan dodany do kosztów'.tr),
        duration: const Duration(seconds: 2),
      ),
    );
  },
  child: const FaIcon(FontAwesomeIcons.circlePlus),
),





    PieAction(
  tooltip: plan.isPaid
      ? Text('Oznacz jako nieopłacone'.tr)
      : Text('Oznacz jako opłacone'.tr),
  onSelect: () async {
    final messenger = ScaffoldMessenger.of(context);

    await ref
        .read(expensesPlanProvider.notifier)
        .togglePaymentStatusForPlans([planId]);

    messenger.showSnackBar(
      SnackBar(
        content: Text(plan.isPaid
            ? 'Oznaczono jako nieopłacone'.tr
            : 'Oznaczono jako opłacone'.tr),
        duration: const Duration(seconds: 2),
      ),
    );
  },
  child: plan.isPaid
      ? const FaIcon(FontAwesomeIcons.circleXmark)
      : const FaIcon(FontAwesomeIcons.circleCheck),
),

  ];
}

extension ContextExtension on BuildContext {
  void showSnackBarLikeSection(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

void confirmDeletePlan(BuildContext context, WidgetRef ref, int planId) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Confirm Delete'.tr),
        content: Text('Are you sure you want to delete this plan?'.tr),
        actions: [
          TextButton(
            onPressed: () => ref.read(navigationService).beamPop(),
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(expensesPlanProvider.notifier).deleteExpensePlan(planId);
              ref.read(navigationService).beamPop();
            },
            child: Text('Delete'.tr),
          ),
        ],
      );
    },
  );
}

void showEditPlanDialog(
    BuildContext context, WidgetRef ref, ExpensesPlanModel plan) {
  showDialog(
    context: context,
    builder: (context) {
      final formKeyFunctions = GlobalKey<FormState>();
      double amount = plan.amount;
      String currency = plan.currency;
      String status = plan.status;
      int year = plan.year;
      int month = plan.month;

      return AlertDialog(
        title: Text('Edit Financial Plan'.tr),
        content: Form(
          key: formKeyFunctions,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Amount'.tr),
                keyboardType: TextInputType.number,
                initialValue: amount.toString(),
                onSaved: (value) {
                  amount = double.tryParse(value ?? '0') ?? 0;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Currency'.tr),
                initialValue: currency,
                onSaved: (value) {
                  currency = value ?? 'USD';
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Status'),
                initialValue: status,
                onSaved: (value) {
                  status = value ?? 'Pending'.tr;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Year'.tr),
                initialValue: year.toString(),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  year = int.tryParse(value ?? year.toString()) ?? year;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Month'.tr),
                initialValue: month.toString(),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  month = int.tryParse(value ?? month.toString()) ?? month;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(navigationService).beamPop();
            },
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKeyFunctions.currentState?.validate() ?? false) {
                formKeyFunctions.currentState?.save();
                final updatedPlan = ExpensesPlanModel(
                  id: plan.id,
                  amount: amount,
                  currency: currency,
                  status: status,
                  dateCreate: plan.dateCreate,
                  year: year,
                  month: month,
                );
                ref
                    .read(expensesPlanProvider.notifier)
                    .updateExpensePlan(updatedPlan);
                ref.read(navigationService).beamPop();
              }
            },
            child: Text('Save'.tr),
          ),
        ],
      );
    },
  );
}

void confirmDeleteMultiplePlans(
    BuildContext context, WidgetRef ref, Set<int> selectedPlans) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Confirm Delete'.tr),
        content: Text('Are you sure you want to delete these plans?'.tr),
        actions: [
          TextButton(
            onPressed: () => ref.read(navigationService).beamPop(),
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              for (var planId in selectedPlans) {
                ref
                    .read(expensesPlanProvider.notifier)
                    .deleteExpensePlan(planId);
              }
              ref.read(navigationService).beamPop();
            },
            child: Text('Delete'.tr),
          ),
        ],
      );
    },
  );
}

void addMultiplePlansToExpenses(
    BuildContext context, WidgetRef ref, Set<int> selectedPlans) {
  for (var planId in selectedPlans) {
    // Here you would call your existing function to add plan to expense.
    ref.read(expensesPlanProvider.notifier).addPlanToExpense(planId);
  }
  context.showSnackBarLikeSection('Plans added to expenses.'.tr);
}


Future<void> togglePaymentStatusForSelectedPlans(
    BuildContext context, WidgetRef ref, Set<int> selectedPlans) async {
  final filters = ref.read(filtersPlansProvider);

  try {
    await ref
        .read(expensesPlanProvider.notifier)
        .togglePaymentStatusForPlans(selectedPlans.toList());

    if (context.mounted) {
      context.showSnackBarLikeSection('Payment status updated.'.tr);
    }

    await ref.read(expensesPlanProvider.notifier).fetchExpensesPlans(
          years: filters.years.isNotEmpty ? filters.years : null,
          months: filters.months.isNotEmpty ? filters.months : null,
          ordering: filters.ordering,
        );
  } catch (e) {
    if (context.mounted) {
      context.showSnackBarLikeSection('Error updating payment status.'.tr);
    }
  }
}

