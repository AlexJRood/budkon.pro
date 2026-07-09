import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:crm_agent/add_client_form/provider/buy_filter_provider.dart';
import 'package:intl/intl.dart';


// import 'package:hously_flutter/state_managers/screen/calendar/custom_recurrence_event_provider.dart';

final sellOfferfilterButtonProvider =
    StateNotifierProvider<CrmAddFilterButtonNotifier, Map<String, dynamic>>((ref) {
  return CrmAddFilterButtonNotifier();
});

class CrmAddFilterButtonNotifier extends StateNotifier<Map<String, dynamic>> {
  CrmAddFilterButtonNotifier() : super({});

  void updateFilter(String key, dynamic value) {
    state = {...state, key: value};
  }

  void clearUiFilters() {
    state = {};
  }
}

class CrmAddFilterButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  const CrmAddFilterButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentthememode = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).primaryColor;
    final selectedBackgroundColor = colorScheme;

    final unselectedBackgroundColor = currentthememode == ThemeMode.system
        ? Colors.white // Default color for system theme when not selected
        : currentthememode == ThemeMode.light
            ? Colors.white // Light mode background
            : AppColors.dark; // Dark mode background

    final selectedTextColor =
        currentthememode == ThemeMode.system ? Colors.white : Colors.black;

    final unselectedTextColor = currentthememode == ThemeMode.system
        ? AppColors.textColorDark
        : currentthememode == ThemeMode.light
            ? AppColors.textColorDark
            : AppColors.textColorLight;
    final bool isSelected = ref.watch(sellOfferfilterButtonProvider
        .select((state) => state[filterKey] == filterValue));

    return ElevatedButton(
      onPressed: () {
        final filterNotifier = ref.read(buyOfferFilterCacheProvider.notifier);
        if (isSelected) {
          ref.read(sellOfferfilterButtonProvider.notifier).updateFilter(filterKey, null);
          filterNotifier.removeFilter(filterKey);
        } else {
          ref
              .read(sellOfferfilterButtonProvider.notifier)
              .updateFilter(filterKey, filterValue);
          filterNotifier.addFilter(filterKey, filterValue);
        }
      },
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        backgroundColor:
            isSelected ? selectedBackgroundColor : unselectedBackgroundColor,
        foregroundColor: isSelected ? selectedTextColor : unselectedTextColor,
        side: isSelected ? null : const BorderSide(color: Colors.grey),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor),
      ),
    );
  }
}

class CrmAddEstateTypeFilterButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  const CrmAddEstateTypeFilterButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> selectedValues = List<String>.from(ref
        .watch(sellOfferfilterButtonProvider.select((state) => state[filterKey] ?? [])));
    final currentthememode = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final selectedBackgroundColor = currentthememode == ThemeMode.system
        ? Colors.blue // Default color for system theme when selected
        : currentthememode == ThemeMode.light
            ? colorScheme.primary // Flex color scheme for light mode
            : colorScheme.primary; // Flex color scheme for dark mode

    final unselectedBackgroundColor = currentthememode == ThemeMode.system
        ? Colors.white // Default color for system theme when not selected
        : currentthememode == ThemeMode.light
            ? Colors.white // Light mode background
            : AppColors.dark; // Dark mode background

    final selectedTextColor = currentthememode == ThemeMode.system
        ? Colors.white
        : colorScheme.onPrimary;

    final unselectedTextColor = currentthememode == ThemeMode.system
        ? AppColors.textColorDark
        : currentthememode == ThemeMode.light
            ? AppColors.textColorDark
            : AppColors.textColorLight;
    final bool isSelected = selectedValues.contains(filterValue);

    return ElevatedButton(
      onPressed: () {
        if (isSelected) {
          selectedValues.remove(filterValue);
        } else {
          selectedValues.add(filterValue);
        }
        ref
            .read(sellOfferfilterButtonProvider.notifier)
            .updateFilter(filterKey, selectedValues);
        ref
            .read(buyOfferFilterCacheProvider.notifier)
            .addFilter(filterKey, selectedValues.join(','));
      },
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        backgroundColor:
            isSelected ? selectedBackgroundColor : unselectedBackgroundColor,
        foregroundColor: isSelected ? selectedTextColor : unselectedTextColor,
        side: isSelected ? null : const BorderSide(color: Colors.grey),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor),
      ),
    );
  }
}

class CrmAddAdditionalInfoFilterButton extends ConsumerWidget {
  final String text;
  final String filterKey;

  const CrmAddAdditionalInfoFilterButton({
    super.key,
    required this.text,
    required this.filterKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
        sellOfferfilterButtonProvider.select((state) => state[filterKey] ?? false));

    final currentthememode = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final selectedBackgroundColor = colorScheme.primary;

    final unselectedBackgroundColor = currentthememode == ThemeMode.system
        ? Colors.white // Default color for system theme when not selected
        : currentthememode == ThemeMode.light
            ? Colors.white // Light mode background
            : AppColors.dark; // Dark mode background

    final selectedTextColor = currentthememode == ThemeMode.system
        ? Colors.white
        : colorScheme.onPrimary;

    final unselectedTextColor = currentthememode == ThemeMode.system
        ? AppColors.textColorDark
        : currentthememode == ThemeMode.light
            ? AppColors.textColorDark
            : AppColors.textColorLight;

    return ElevatedButton(
      onPressed: () {
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        final currentState =ref.read(sellOfferfilterButtonProvider.notifier).state[filterKey] ?? false;
        final newState = !currentState;
        ref
            .read(sellOfferfilterButtonProvider.notifier)
            .updateFilter(filterKey, newState);

        if (newState) {
          ref.read(buyOfferFilterCacheProvider.notifier).addFilter(filterKey, 'true');
        } else {
          ref.read(buyOfferFilterCacheProvider.notifier).removeFilter(filterKey);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? selectedBackgroundColor : unselectedBackgroundColor,
        foregroundColor: isSelected ? selectedTextColor : unselectedTextColor,
        side: isSelected ? null : const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(text,
          style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor,
          )),
    );
  }
}

class CrmAddBuildTextField extends ConsumerWidget {
  const CrmAddBuildTextField({
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
    return Material(
      borderRadius: BorderRadius.circular(10.0),
      elevation: 2,
      child: SizedBox(
        height: 35.0,
        child: TextField(
          controller: controller,
          onChanged: (value) {
            ref.read(buyOfferFilterCacheProvider.notifier).addFilter(filterKey, value);
          },
          style: AppTextStyles.interMedium14dark.copyWith(color: textFieldColor),
          cursorColor: currentthememode == ThemeMode.system ? Colors.black : cursorcolor,
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
      ),
    );
  }
}

class CrmAddBuildNumberField extends ConsumerWidget {
  const CrmAddBuildNumberField({
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
    final formatter = NumberFormat('#,###');

    final currentthememode = ref.watch(themeProvider);
    final themecolors=ref.watch(themeColorsProvider);
    final textFieldColor = themecolors.textFieldColor;
    final cursorcolor = Theme.of(context).primaryColor;
    final inputDecorationTheme = Theme.of(context).inputDecorationTheme;

    return Material(
      borderRadius: BorderRadius.circular(10.0),
      elevation: 2,
      child: SizedBox(
        height: 35.0,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (newValue.text.isEmpty) {
                return newValue.copyWith(text: '');
              }
              final int value = int.parse(newValue.text.replaceAll(',', ''));
              final String newText = formatter.format(value);
              return newValue.copyWith(
                text: newText,
                selection: TextSelection.collapsed(offset: newText.length),
              );
            }),
          ],
          style: AppTextStyles.interMedium14dark.copyWith(color: textFieldColor),
          cursorColor: currentthememode == ThemeMode.system ? Colors.black : cursorcolor,
          decoration: InputDecoration(
            labelText: labelText,
            filled: inputDecorationTheme.filled,
            fillColor: inputDecorationTheme.fillColor,
            border: inputDecorationTheme.border,
            focusedBorder: inputDecorationTheme.focusedBorder,
            labelStyle: inputDecorationTheme.labelStyle,
            floatingLabelStyle: inputDecorationTheme.floatingLabelStyle,
          ),
          onChanged: (value) {
            final unformattedValue = value.replaceAll(',', '');
            ref
                .read(buyOfferFilterCacheProvider.notifier)
                .addFilter(filterKey, unformattedValue);
          },
        ),
      ),
    );
  }
}

class CrmAddBuildDropdownButtonFormField extends ConsumerWidget {
  const CrmAddBuildDropdownButtonFormField({
    super.key,
    this.currentValue,
    required this.items,
    required this.filterKey,
    required this.labelText,
  });

  final String? currentValue;
  final List<String> items;
  final String filterKey;
  final String labelText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentthememode = ref.watch(themeProvider);
    final textFieldColor =
        currentthememode == ThemeMode.system ? Colors.black : Colors.white;
    final colorScheme = Theme.of(context).primaryColor;
    final colorSchemecheck = ref.watch(colorSchemeProvider);

    //  final theme=Theme.of(context);
    return Material(
      borderRadius: BorderRadius.circular(10.0),
      elevation: 2,
      child: SizedBox(
        height: 35.0,
        child: DropdownButtonFormField<String>(
          style: TextStyle(
            color: currentthememode == ThemeMode.system
                ? AppColors.light
                : currentthememode == ThemeMode.light
                    ? AppColors.light
                    : AppColors.light,
          ),
          dropdownColor: currentthememode == ThemeMode.system
              ? AppColors.light
              : currentthememode == ThemeMode.light
                  ? AppColors.light
                  : AppColors.dark,
          focusColor: currentthememode == ThemeMode.system
              ? AppColors.light
              : currentthememode == ThemeMode.light
                  ? colorScheme
                  : colorScheme,
          value: currentValue,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value,
                  style: AppTextStyles.interMedium14dark.copyWith(
                    color: currentthememode == ThemeMode.system
                        ? AppColors.textColorDark
                        : currentthememode == ThemeMode.light
                            ? AppColors.textColorDark
                            : AppColors.textColorLight,
                  )),
            );
          }).toList(),
          onChanged: (String? newValue) {
            ref
                .read(sellOfferfilterButtonProvider.notifier)
                .updateFilter(filterKey, newValue);
            ref
                .read(buyOfferFilterCacheProvider.notifier)
                .addFilter(filterKey, newValue);
          },
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: AppTextStyles.interMedium14dark.copyWith(
              color: currentthememode == ThemeMode.system
                  ? AppColors.textColorDark
                  : currentthememode == ThemeMode.light
                      ? AppColors.textColorDark
                      : AppColors.textColorLight,
            ),
            floatingLabelStyle: TextStyle(
              color: colorSchemecheck == null &&
                      (currentthememode == ThemeMode.system ||
                          currentthememode == ThemeMode.dark)
                  ? textFieldColor
                  : colorScheme,
            ),
            contentPadding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
            fillColor: currentthememode == ThemeMode.system
                ? AppColors.light
                : currentthememode == ThemeMode.light
                    ? AppColors.light
                    : AppColors.dark,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: colorScheme),
            ),
          ),
          isExpanded: true,
          iconSize: 24.0,
        ),
      ),
    );
  }
}
