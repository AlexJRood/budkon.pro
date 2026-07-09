import 'package:crm/data/finance/api_servises_expenses_plans.dart';
import 'package:crm/data/finance/api_servises_revenue.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/models/expenses_plan_model.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:crm/shared/models/revenue/revenue_plan_model.dart';
import 'package:core/platform/navigation_service.dart';

import 'package:get/get_utils/get_utils.dart';

class FinancalPlansCrmSideButtons extends StatelessWidget {
  final WidgetRef ref;

  const FinancalPlansCrmSideButtons({
    super.key,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: IntrinsicWidth(
        child: SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SideButtonsDashboard(
                  onPressed: () {
                    _showCreatePlanDialog(context, ref);
                  },
                  icon: Icons.add,
                  text: 'Dodaj plan'.tr),
              const SizedBox(height: 10),
              SideButtonsDashboard(
                  onPressed: () {
                    ref.read(navigationService).pushNamedScreen(
                          Routes.viewPopChanger,
                        );
                  },
                  icon: Icons.view_carousel_sharp,
                  text: 'widok'.tr),
              const SizedBox(height: 10),
              SideButtonsDashboard(
                  onPressed: () {
                    ref
                        .read(navigationService)
                        .pushNamedScreen(Routes.proPlans);
                  },
                  icon: Icons.monetization_on_outlined,
                  text: 'Plany finansowe'.tr),
              const SizedBox(height: 10),
              SideButtonsDashboard(
                  onPressed: () {
                    Navigator.pushNamed(context, '/pro/finance/revenue/add');
                  },
                  icon: Icons.monetization_on_outlined,
                  text: 'Dodaj'.tr),
              const SizedBox(
                height: 10,
              ),
              SideButtonsDashboard(
                  onPressed: () {
                    Navigator.pushNamed(
                        context, '/pro/finance/revenue/add/AddViewerForm');
                  },
                  icon: Icons.add_box_outlined,
                  text: 'Dodaj'.tr),
            ],
          ),
        ),
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
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);
    final colorscheme = ref.watch(colorSchemeProvider);
    return ElevatedButton(
      style: buttonSideDashboard.copyWith(
          backgroundColor: WidgetStatePropertyAll(
              colorscheme == FlexScheme.blackWhite
                  ? Theme.of(context).colorScheme.onSecondary.withAlpha((255 * 0.5).toInt())
                  : theme.textFieldColor.withAlpha(125))), // Użycie przekazanego lub domyślnego stylu
      onPressed: onPressed,
      child: Column(
        children: [
          Icon(
            icon,
            color: colorscheme == FlexScheme.blackWhite
                ? theme.textFieldColor
                : Theme.of(context).iconTheme.color,
            size: 25,
          ),
          const SizedBox(
            height: 5,
          ),
          Text(text,
              style: AppTextStyles.interMedium10.copyWith(
                color: colorscheme == FlexScheme.blackWhite
                    ? theme.textFieldColor
                    : Theme.of(context).iconTheme.color,
              ))
        ],
      ),
    );
  }
}

void _showCreatePlanDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) {
      final formKeyFinancalPlans = GlobalKey<FormState>();
      double amount = 0;
      String currency = 'USD';
      String status = 'Pending'.tr;
      int year = DateTime.now().year;
      int month = DateTime.now().month;
      bool isRevenue = true; // Default to revenue, can toggle to expense
      String title = '';
      String note = '';
      List<String> selectedTags = [];
      final List<String> availableTags = [
        'Business'.tr,
        'Personal'.tr,
        'Tax'.tr,
        'Urgent'.tr
      ]; // Example tags

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Create Financial Plan'.tr),
            content: Form(
              key: formKeyFinancalPlans,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Field// Spacing between chips and form fields
                  // Toggle between Expense or Revenue using ChoiceChip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        checkmarkColor: Theme.of(context).iconTheme.color,
                        label: Text('Revenue'.tr),
                        selected: isRevenue,
                        onSelected: (selected) {
                          setState(() {
                            isRevenue = true; // Set as revenue
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        checkmarkColor: Theme.of(context).iconTheme.color,
                        label: Text('Expense'.tr),
                        selected: !isRevenue,
                        onSelected: (selected) {
                          setState(() {
                            isRevenue = false; // Set as expense
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Title'.tr),
                    onSaved: (value) {
                      title = value ?? '';
                    },
                  ),
                  const SizedBox(height: 10),
                  // Note Field
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Note'.tr),
                    maxLines: 3,
                    onSaved: (value) {
                      note = value ?? '';
                    },
                  ),

                  const SizedBox(height: 10),
                  // Other fields like Amount, Currency, Status, Year, Month
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Amount'.tr),
                    keyboardType: TextInputType.number,
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
                  const SizedBox(height: 10),
                  // Tags Selection using ChoiceChips
                  Wrap(
                    spacing: 5.0,
                    runSpacing: 5.0,
                    children: availableTags.map((tag) {
                      return ChoiceChip(
                        checkmarkColor: Theme.of(context).iconTheme.color,
                        label: Text(tag),
                        selected: selectedTags.contains(tag),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedTags.add(tag);
                            } else {
                              selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
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
                  if (formKeyFinancalPlans.currentState?.validate() ?? false) {
                    formKeyFinancalPlans.currentState?.save();
                    if (isRevenue) {
                      final newPlan = RevenuePlanModel(
                        id: 0, // ID will be assigned by the backend
                        amount: amount,
                        currency: currency,
                        status: status,
                        dateCreate: DateTime.now().toIso8601String(),
                        year: year,
                        month: month,
                        name: title,
                        note: note,
                        tags: selectedTags,
                      );
                      ref
                          .read(revenuePlanProvider.notifier)
                          .createRevenuePlan(newPlan)
                          .then((_) {
                        ref.invalidate(
                            availableYearsRevenueProvider); // Refresh the list of available years
                      });
                    } else {
                      final newPlan = ExpensesPlanModel(
                        id: 0, // ID will be assigned by the backend
                        amount: amount,
                        currency: currency,
                        status: status,
                        dateCreate: DateTime.now().toIso8601String(),
                        year: year,
                        month: month,
                        name: title,
                        note: note,
                        tags: selectedTags,
                      );
                      ref
                          .read(expensesPlanProvider.notifier)
                          .createExpensePlan(newPlan)
                          .then((_) {
                        ref.invalidate(
                            availableYearsExpensesPlansProvider); // Refresh the list of available years
                      });
                    }
                    ref.read(navigationService).beamPop(); // Close the dialog
                  }
                },
                child: Text('Create'.tr),
              ),
            ],
          );
        },
      );
    },
  );
}
