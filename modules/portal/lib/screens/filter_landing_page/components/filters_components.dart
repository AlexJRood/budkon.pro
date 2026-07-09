import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:intl/intl.dart';

import 'package:core/platform/filters/filters_const.dart';

final filterButtonProvider =
    StateNotifierProvider<FilterButtonNotifier, Map<String, dynamic>>((ref) {
  return FilterButtonNotifier();
});

class FilterButtonNotifier extends StateNotifier<Map<String, dynamic>> {
  FilterButtonNotifier() : super({});

  void updateFilter(String key, dynamic value) {
    state = {...state, key: value};
  }

  void clearUiFilters() {
    state = {};
  }

  void updateRangeFilter(String key, RangeValues values) {
    state = {...state, key: values};
  }

  void loadSavedFilters(Map<String, dynamic> savedFilters) {
    state = savedFilters;
  }

  void removeFilter(String key) {
    state = Map<String, dynamic>.from(state)..remove(key);
  }
}

class FilterButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;
  final bool quickFilter;

  const FilterButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    this.quickFilter = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentthememode = ref.watch(themeProvider);

    final unselectedBackgroundColor = currentthememode == ThemeMode.system
        ? AppColors.white
        : currentthememode == ThemeMode.light
            ? AppColors.dark
            : AppColors.light;

    final selectedBackgroundColor = currentthememode == ThemeMode.system
        ? AppColors.graphite
        : currentthememode == ThemeMode.light
            ? AppColors.light
            : AppColors.dark;

    final selectedTextColor = currentthememode == ThemeMode.system
        ? Colors.white
        : currentthememode == ThemeMode.light
            ? AppColors.dark
            : Colors.white;

    final unselectedTextColor = currentthememode == ThemeMode.system
        ? AppColors.dark
        : currentthememode == ThemeMode.light
            ? Colors.white
            : AppColors.dark;

    final bool isSelected = ref.watch(
      filterButtonProvider.select((state) => state[filterKey] == filterValue),
    );

    return ElevatedButton(
      onPressed: () {
        final filterNotifier = ref.read(filterCacheProvider.notifier);
        if (isSelected) {
          ref.read(filterButtonProvider.notifier).updateFilter(filterKey, null);
          filterNotifier.removeFilter(filterKey);
        } else {
          ref
              .read(filterButtonProvider.notifier)
              .updateFilter(filterKey, filterValue);
          filterNotifier.addFilter(filterKey, filterValue);
        }
      },
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        padding: quickFilter ? EdgeInsets.zero : null,
        backgroundColor:
            isSelected ? selectedBackgroundColor : unselectedBackgroundColor,
        foregroundColor: isSelected ? selectedTextColor : unselectedTextColor,
      ),
      child: Text(
        text,
        style: AppTextStyles.interMedium12dark.copyWith(
          color: isSelected ? selectedTextColor : unselectedTextColor,
          fontSize: 14.sp,
        ),
      ),
    );
  }
}

class EstateTypeFilterButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;
  final bool quickFilter;

  const EstateTypeFilterButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    this.quickFilter = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> selectedValues = List<String>.from(
      ref.watch(filterButtonProvider.select((state) => state[filterKey] ?? [])),
    );

    final currentthememode = ref.watch(themeProvider);

    final unselectedBackgroundColor = currentthememode == ThemeMode.system
        ? AppColors.white
        : currentthememode == ThemeMode.light
            ? AppColors.dark
            : AppColors.light;

    final selectedBackgroundColor = currentthememode == ThemeMode.system
        ? AppColors.graphite
        : currentthememode == ThemeMode.light
            ? AppColors.light
            : AppColors.dark;

    final selectedTextColor = currentthememode == ThemeMode.system
        ? Colors.white
        : currentthememode == ThemeMode.light
            ? AppColors.dark
            : Colors.white;

    final unselectedTextColor = currentthememode == ThemeMode.system
        ? AppColors.dark
        : currentthememode == ThemeMode.light
            ? Colors.white
            : AppColors.dark;

    final bool isSelected = selectedValues.contains(filterValue);

    return ElevatedButton(
      onPressed: () {
        if (isSelected) {
          selectedValues.remove(filterValue);
        } else {
          selectedValues.add(filterValue);
        }
        ref
            .read(filterButtonProvider.notifier)
            .updateFilter(filterKey, selectedValues);
        ref
            .read(filterCacheProvider.notifier)
            .addFilter(filterKey, selectedValues.join(','));
      },
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        padding: quickFilter ? EdgeInsets.zero : null,
        backgroundColor:
            isSelected ? selectedBackgroundColor : unselectedBackgroundColor,
        foregroundColor: isSelected ? selectedTextColor : unselectedTextColor,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,

        child: Text(
          text,
          style: AppTextStyles.interMedium12dark.copyWith(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class AdditionalInfoFilterButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final bool quickFilter;

  const AdditionalInfoFilterButton({
    super.key,
    required this.text,
    required this.filterKey,
    this.quickFilter = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      filterButtonProvider.select((state) => state[filterKey] ?? false),
    );

    final currentthememode = ref.watch(themeProvider);

    final unselectedBackgroundColor = currentthememode == ThemeMode.system
        ? AppColors.white
        : currentthememode == ThemeMode.light
            ? AppColors.dark
            : AppColors.light;

    final selectedBackgroundColor = currentthememode == ThemeMode.system
        ? AppColors.graphite
        : currentthememode == ThemeMode.light
            ? AppColors.light
            : AppColors.dark;

    final selectedTextColor = currentthememode == ThemeMode.system
        ? Colors.white
        : currentthememode == ThemeMode.light
            ? AppColors.dark
            : Colors.white;

    final unselectedTextColor = currentthememode == ThemeMode.system
        ? AppColors.dark
        : currentthememode == ThemeMode.light
            ? Colors.white
            : AppColors.dark;

    return ElevatedButton(
      onPressed: () {
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        final currentState =
            ref.read(filterButtonProvider.notifier).state[filterKey] ?? false;
        final newState = !currentState;

        ref
            .read(filterButtonProvider.notifier)
            .updateFilter(filterKey, newState);

        if (newState) {
          ref.read(filterCacheProvider.notifier).addFilter(filterKey, 'true');
        } else {
          ref.read(filterCacheProvider.notifier).removeFilter(filterKey);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? selectedBackgroundColor : unselectedBackgroundColor,
        foregroundColor: isSelected ? selectedTextColor : unselectedTextColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
        padding: quickFilter ? EdgeInsets.zero : null,
      ),
      child: Text(
        text,
        style: AppTextStyles.interMedium12dark.copyWith(
          color: isSelected ? selectedTextColor : unselectedTextColor,
          fontSize: 14.sp,
        ),
      ),
    );
  }
}

class BuildTextField extends ConsumerWidget {
  const BuildTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.filterKey,
  });

  final TextEditingController controller;
  final String labelText;
  final String filterKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputDecorationTheme = Theme.of(context).inputDecorationTheme;
    final cursorcolor = Theme.of(context).primaryColor;
    final currentthememode = ref.watch(themeProvider);
    final themecolors = ref.watch(themeColorsProvider);
    final textFieldColor = themecolors.textFieldColor;

    return SizedBox(
      height: 40.0,
      child: TextField(
        controller: controller,
        onChanged: (value) {
          ref.read(filterCacheProvider.notifier).addFilter(filterKey, value);
        },
        style: AppTextStyles.interMedium14dark.copyWith(color: textFieldColor),
        cursorColor:
            currentthememode == ThemeMode.system ? Colors.black : cursorcolor,
        decoration: InputDecoration(
          labelText: labelText,
          filled: inputDecorationTheme.filled,
          fillColor: inputDecorationTheme.fillColor,
          border: inputDecorationTheme.border,
          focusedBorder: inputDecorationTheme.focusedBorder,
          labelStyle: inputDecorationTheme.labelStyle,
          floatingLabelStyle: inputDecorationTheme.floatingLabelStyle,
        ),
      ),
    );
  }
}


class BuildNumberField extends ConsumerWidget {
  const BuildNumberField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.filterKey,
    this.focusNode,
    this.nextFocusNode,
    this.isLast = false,
    this.formatWithSpaces = true,
  });

  final TextEditingController controller;
  final String labelText;
  final String filterKey;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final bool isLast;
  final bool formatWithSpaces;

  String _formatWithSpaces(String digits) {
    if (digits.isEmpty) return '';
    final int value = int.parse(digits);
    return NumberFormat('#,###').format(value).replaceAll(',', ' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentthememode = ref.watch(themeProvider);
    final cursorcolor = Theme.of(context).primaryColor;
    final theme = ref.read(themeColorsProvider);

    return SizedBox(
      height: 40.0,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          if (formatWithSpaces)
            TextInputFormatter.withFunction((oldValue, newValue) {
              final digits = newValue.text.replaceAll(' ', '');

              if (digits.isEmpty) {
                return const TextEditingValue(
                  text: '',
                  selection: TextSelection.collapsed(offset: 0),
                );
              }

              final String formatted = _formatWithSpaces(digits);

              return TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }),
        ],
        style: AppTextStyles.interMedium14dark.copyWith(
          color: theme.textColor,
          fontSize: 14.sp,
        ),
        cursorColor:
            currentthememode == ThemeMode.system ? Colors.black : cursorcolor,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: AppTextStyles.interMedium14.copyWith(
            color: theme.textColor,
          ),
          floatingLabelStyle: AppTextStyles.interLight14.copyWith(
            color: theme.textColor,
          ),
          filled: true,
          fillColor: theme.textFieldColor,
          focusColor: Colors.transparent,
          hoverColor: theme.themeColor.withAlpha((255 * 0.25).toInt()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
            borderSide: BorderSide(
              color: theme.textColor.withAlpha((255 * 0.5).toInt()),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
            borderSide: BorderSide(
              color: theme.textColor.withAlpha((255 * 0.5).toInt()),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
            borderSide: BorderSide(color: theme.themeColor),
          ),
        ),
        onChanged: (value) {
          final unformattedValue = value.replaceAll(' ', '');

          if (unformattedValue.isEmpty) {
            ref.read(filterCacheProvider.notifier).removeFilter(filterKey);
          } else {
            ref.read(filterCacheProvider.notifier).addFilter(
              filterKey,
              unformattedValue,
            );
          }
        },
        focusNode: focusNode,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        scrollPadding: EdgeInsets.only(
          left: 20,
          top: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              BottomBarSize.resolve(context) +
              100,
        ),
        onSubmitted: (_) {
          if (isLast) {
            FocusScope.of(context).unfocus();
          } else {
            nextFocusNode?.requestFocus();
          }
        },
        onTap: () {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await Future.delayed(const Duration(milliseconds: 250));
            if (!context.mounted) return;

            await Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              alignment: 0.15,
            );
          });
        },
      ),
    );
  }
}


/// Dropdown that supports SINGLE SOURCE OF TRUTH options:
/// - shows `text`
/// - stores/sends `filterKey`
class BuildDropdownButtonFormField extends ConsumerWidget {
  const BuildDropdownButtonFormField({
    super.key,
    this.currentValue,
    this.items,
    this.options,
    required this.filterKey,
    required this.labelText,
  });

  final String? currentValue;

  /// Legacy: list of visible values (kept for backward compatibility).
  final List<String>? items;

  /// New: [{text, filterKey}]
  final List<Map<String, String>>? options;

  final String filterKey;
  final String labelText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    // Resolve options. If not provided, fallback to legacy `items`.
    final resolved = (options != null && options!.isNotEmpty)
        ? options!
        : (items ?? const <String>[])
            .map((t) => {'text': t, 'filterKey': t})
            .toList();

    // Ensure currentValue exists in options, otherwise set null to avoid exceptions.
    String? value = currentValue;
    final hasValue = resolved.any((o) => o['filterKey'] == value);
    if (!hasValue) value = null;

    return SizedBox(
      height: 50.0,
      child: DropdownButtonFormField<String>(
        iconEnabledColor: theme.textColor,
        iconDisabledColor: theme.textColor,
        style: TextStyle(color: theme.textColor),
        dropdownColor: theme.dashboardContainer,
        focusColor: theme.dashboardContainer,
        value: value,
        items: resolved.map<DropdownMenuItem<String>>((opt) {
          final v = opt['filterKey'] ?? '';
          final text = opt['text'] ?? v;
          return DropdownMenuItem<String>(
            value: v,
            child: Text(
              text,
              style: AppTextStyles.interMedium14dark.copyWith(
                color: theme.textColor,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          final ui = ref.read(filterButtonProvider.notifier);
          final cache = ref.read(filterCacheProvider.notifier);

          // Treat null/empty/'any' as "no filter".
          if (FilterPopConst.isAnyValue(newValue)) {
            ui.removeFilter(filterKey);
            cache.removeFilter(filterKey);
            return;
          }

          ui.updateFilter(filterKey, newValue);
          cache.addFilter(filterKey, newValue!);
        },
        hint: Text(
          labelText,
          style: AppTextStyles.interMedium14dark.copyWith(
            color: theme.textColor,
            fontSize: 14.sp,
          ),
        ),
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.never,
          floatingLabelStyle: TextStyle(color: theme.textColor),
          contentPadding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          fillColor: theme.dashboardContainer,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
            borderSide: BorderSide(
              color: theme.dashboardContainer.withAlpha((255 * 0.5).toInt()),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
            borderSide: BorderSide(
              color: theme.dashboardContainer.withAlpha((255 * 0.5).toInt()),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
            borderSide: BorderSide(color: theme.dashboardContainer),
          ),
        ),
        isExpanded: true,
        iconSize: 24.0,
        menuMaxHeight: 500,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
