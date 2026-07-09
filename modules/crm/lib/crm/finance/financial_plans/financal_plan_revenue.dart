import 'package:crm/crm/finance/features/revenue/functions_revenue.dart';
import 'package:crm/data/finance/api_servises_revenue.dart';
import 'package:crm/data/finance/filter_plans.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

import 'buttons.dart';

class FinancialPlansRevenue extends ConsumerStatefulWidget {
  const FinancialPlansRevenue({super.key});

  @override
  _FinancialPlansContainerState createState() =>
      _FinancialPlansContainerState();
}

class _FinancialPlansContainerState
    extends ConsumerState<FinancialPlansRevenue> {
  final Set<int> _selectedPlans = {}; // Set to store selected plan IDs

  @override
  Widget build(BuildContext context) {
    final revenuePlans = ref.watch(revenuePlanProvider);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenPadding = screenWidth / 10;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenPadding),
          child: Column(
            children: [
              const FilterSection(), // Sekcja filtrów

              Expanded(
                child: revenuePlans.when(
                  data:
                      (plans) => ListView.builder(
                        addAutomaticKeepAlives: false,
                        cacheExtent: 300.0,
                        itemCount: plans.length,
                        itemBuilder: (context, index) {
                          final plan = plans[index];
                          final isSelected = _selectedPlans.contains(
                            plan.id,
                          ); // Check if the plan is selected
                          return GestureDetector(
                            onLongPress: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedPlans.remove(plan.id);
                                } else {
                                  _selectedPlans.add(plan.id);
                                }
                              });
                            },
                            onTap: () {
                              if (_selectedPlans.isNotEmpty) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedPlans.remove(plan.id);
                                  } else {
                                    _selectedPlans.add(plan.id);
                                  }
                                });
                              } else {
                                // Handle regular tap (e.g., open plan details)
                              }
                            },
                            child: PieMenu(
                               theme: PieTheme.of(context).copyWith(
                        overlayColor:
                            (() {
                              final theme = ref.watch(themeColorsProvider);
                              final bool uiIsDark =
                                  theme.textColor.computeLuminance() > 0.5;

                              final base =
                                  uiIsDark ? Colors.black : Colors.white;
                              return base.withValues(alpha: 0.70);
                            })(),
                      ),
                              onPressedWithDevice: (kind) {
                                if (kind == PointerDeviceKind.mouse ||
                                    kind == PointerDeviceKind.touch) {
                                  // Logika PieMenu
                                }
                              },
                              actions: pieMenuFinancalPlansRevenue(
                                ref,
                                context,
                                plan.id,
                                plan,
                              ),
                              child: Container(
                                color: Colors.transparent,
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  elevation: 2.0,
                                  color:
                                      isSelected
                                          ? Colors.grey[500]
                                          : (plan.isPaid
                                              ? AppColors.dark50
                                              : AppColors.light),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${plan.name}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                plan.isPaid
                                                    ? AppColors.light
                                                    : AppColors.dark,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${plan.year}-${plan.month.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color:
                                                plan.isPaid
                                                    ? AppColors.light
                                                    : AppColors.dark,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'Status: ${plan.status}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${plan.currency} ${plan.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.revenueGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stack) => Center(child: Text('Error: $error'.tr)),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            children: [
              if (_selectedPlans.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    confirmDeleteMultiplePlans(context, ref, _selectedPlans);
                  },
                  icon: AppIcons.delete(),
                  label: Text('Delete Selected'.tr),
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    addMultiplePlansToRevenue(context, ref, _selectedPlans);
                  },
                  icon: AppIcons.add(),
                  label: Text('Add to Expenses'.tr),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    togglePaymentStatusForSelectedPlans(
                      context,
                      ref,
                      _selectedPlans,
                    );
                  },
                  icon: const Icon(Icons.payment),
                  label: Text('Toggle Payment Status'.tr),
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.blue),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedPlans.clear();
                    });
                  },
                  icon: AppIcons.close(),
                  label: Text('Clear Selection'.tr),
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ],
              FinancalPlansCrmSideButtons(ref: ref),
            ],
          ),
        ),
      ],
    );
  }
}

class FilterSection extends ConsumerStatefulWidget {
  const FilterSection({super.key});

  @override
  _FilterSectionState createState() => _FilterSectionState();
}

class _FilterSectionState extends ConsumerState<FilterSection> {
  bool allowMultipleSelection = false;
  String _selectedOrdering = 'amount'; // Domyślne sortowanie

  @override
  Widget build(BuildContext context) {
    final availableYearsAsync = ref.watch(availableYearsRevenueProvider);
    final filters = ref.watch(filtersPlansProvider);
    final theme = ref.watch(themeColorsProvider);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wspólny przełącznik dla wielu lat i miesięcy
          availableYearsAsync.when(
            data: (years) {
              return Wrap(
                spacing: 8.0,
                children:
                    years.map((year) {
                      final isSelected = filters.years.contains(year);
                      return ChoiceChip(
                        checkmarkColor: Theme.of(context).iconTheme.color,
                        backgroundColor: theme.fillColor,
                        selectedColor:
                            Theme.of(
                              context,
                            ).primaryColor, // Color when selected
                        label: Text(
                          '$year',
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Theme.of(context).iconTheme.color
                                    : theme.textFieldColor,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          if (allowMultipleSelection) {
                            ref
                                .read(filtersPlansProvider.notifier)
                                .toggleYear(year);
                          } else {
                            ref
                                .read(filtersPlansProvider.notifier)
                                .setYear(year);
                          }
                          _applyFilters(ref);
                        },
                      );
                    }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stack) => Center(
                  child: Text(
                    'Error loading years'.tr,
                    style: TextStyle(color: Theme.of(context).iconTheme.color),
                  ),
                ),
          ),
          const SizedBox(height: 20),

          // Sekcja wyboru miesięcy
          Wrap(
            spacing: 8.0,
            children: List.generate(12, (index) {
              final month = index + 1;
              final isSelected = filters.months.contains(month);
              return ChoiceChip(
                checkmarkColor: Theme.of(context).iconTheme.color,
                selectedColor: Theme.of(context).primaryColor,
                backgroundColor: theme.fillColor,
                label: Text(
                  _monthName(month),
                  style: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).iconTheme.color
                            : theme.textFieldColor,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) {
                  if (allowMultipleSelection) {
                    ref.read(filtersPlansProvider.notifier).toggleMonth(month);
                  } else {
                    ref.read(filtersPlansProvider.notifier).setMonth(month);
                  }
                  _applyFilters(ref);
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          // Przycisk do czyszczenia filtrów
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Wybierz wiele lat i miesięcy'.tr,
                  style: AppTextStyles.interMedium10.copyWith(
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                Switch(
                  value: allowMultipleSelection,
                  onChanged: (value) {
                    setState(() {
                      allowMultipleSelection = value;
                      if (!allowMultipleSelection) {
                        final currentYear = DateTime.now().year;
                        final currentMonth = DateTime.now().month;
                        ref.read(filtersPlansProvider.notifier).clearYears();
                        ref.read(filtersPlansProvider.notifier).clearMonths();
                        ref
                            .read(filtersPlansProvider.notifier)
                            .setYear(currentYear);
                        ref
                            .read(filtersPlansProvider.notifier)
                            .setMonth(currentMonth);
                      }
                    });
                    _applyFilters(ref);
                  },
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    color: theme.fillColor.withAlpha(
                      (255 * 0.9).toInt(),
                    ), // Whitish background
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12, // Light shadow
                        blurRadius: 4,
                        offset: Offset(2, 2), // Subtle offset
                      ),
                    ],
                  ),
                  child: DropdownButton<String>(
                    style: AppTextStyles.interMedium.copyWith(
                      color: theme.textFieldColor,
                    ), // Apply custom text style
                    dropdownColor: theme.fillColor, // Dropdown background color
                    value: _selectedOrdering,
                    underline: SizedBox(), // Removes default underline
                    items: [
                      DropdownMenuItem(
                        value: 'amount',
                        child: Text('Kwota rosnąco'.tr),
                      ),
                      DropdownMenuItem(
                        value: '-amount',
                        child: Text('Kwota malejąco'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'year',
                        child: Text('Rok rosnąco'.tr),
                      ),
                      DropdownMenuItem(
                        value: '-year',
                        child: Text('Rok malejąco'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'month',
                        child: Text('Miesiąc rosnąco'.tr),
                      ),
                      DropdownMenuItem(
                        value: '-month',
                        child: Text('Miesiąc malejąco'.tr),
                      ),
                      DropdownMenuItem(value: 'status', child: Text('Status')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedOrdering = value ?? 'amount';
                      });
                      _applyFilters(ref);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    ref.read(filtersPlansProvider.notifier).clearFilters();
                    _applyFilters(ref);
                  },
                  child: Text(
                    'Wyczyść filtry'.tr,
                    style: AppTextStyles.interMedium.copyWith(
                      color: Theme.of(context).iconTheme.color,
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

  String _monthName(int month) {
    final monthNames = [
      'Styczeń'.tr,
      'Luty'.tr,
      'Marzec'.tr,
      'Kwiecień'.tr,
      'Maj'.tr,
      'Czerwiec'.tr,
      'Lipiec'.tr,
      'Sierpień',
      'Wrzesień'.tr,
      'Październik'.tr,
      'Listopad'.tr,
      'Grudzień',
    ];
    return monthNames[month - 1];
  }
}

void _applyFilters(WidgetRef ref) {
  final filters = ref.read(filtersPlansProvider);
  ref
      .read(revenuePlanProvider.notifier)
      .fetchRevenuePlans(
        years: filters.years.isNotEmpty ? filters.years : null,
        months: filters.months.isNotEmpty ? filters.months : null,
        ordering: filters.ordering,
      );
}
