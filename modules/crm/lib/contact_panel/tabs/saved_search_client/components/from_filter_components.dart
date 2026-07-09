import 'package:crm/data/clients/ad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/text_field.dart';


// import 'package:hously_flutter/state_managers/screen/calendar/custom_recurrence_event_provider.dart';

final filterButtonProvider =
    StateNotifierProvider<ClientPanelFilterButtonNotifier, Map<String, dynamic>>((ref) {
  return ClientPanelFilterButtonNotifier();
});

class ClientPanelFilterButtonNotifier extends StateNotifier<Map<String, dynamic>> {
  ClientPanelFilterButtonNotifier() : super({});

  void updateFilter(String key, dynamic value) {
    state = {...state, key: value};
  }

  void clearUiFilters() {
    state = {};
  }
}

class ClientPanelFilterButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  const ClientPanelFilterButton({
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
    final bool isSelected = ref.watch(filterButtonProvider
        .select((state) => state[filterKey] == filterValue));

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

class ClientPanelEstateTypeFilterButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  const ClientPanelEstateTypeFilterButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> selectedValues = List<String>.from(ref
        .watch(filterButtonProvider.select((state) => state[filterKey] ?? [])));
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
            .read(filterButtonProvider.notifier)
            .updateFilter(filterKey, selectedValues);
        ref
            .read(filterCacheProvider.notifier)
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

class ClientPanelAdditionalInfoFilterButton extends ConsumerWidget {
  final String text;
  final String filterKey;

  const ClientPanelAdditionalInfoFilterButton({
    super.key,
    required this.text,
    required this.filterKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
        filterButtonProvider.select((state) => state[filterKey] ?? false));

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
        final currentState =
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
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

class ClientPanelBuildTextField extends ConsumerWidget {
  const ClientPanelBuildTextField({
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
            ref.read(filterCacheProvider.notifier).addFilter(filterKey, value);
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

class ClientPanelBuildNumberField extends ConsumerWidget {
  const ClientPanelBuildNumberField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.filterKey,
    this.focusNode,
    this.nextFocusNode,
  });

  final TextEditingController controller;
  final String labelText;
  final String filterKey;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat('#,###');
    final theme =ref.watch(themeColorsProvider);


    return Material(
      borderRadius: BorderRadius.circular(10.0),
      elevation: 2,
      child: SizedBox(
        height: 46.0,
        child: CoreTextField(
          focusNode: focusNode,
          nextFocusNode: nextFocusNode,
          fillColor: theme.dashboardContainer,
          label: labelText,
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
          onChanged: (value) {
            final unformattedValue = value.replaceAll(',', '');
            ref
                .read(filterCacheProvider.notifier)
                .addFilter(filterKey, unformattedValue);
          },
        ),
      ),
    );
  }
}

class ClientPanelBuildDropdownButtonFormField extends ConsumerWidget {
  const ClientPanelBuildDropdownButtonFormField({
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
    final theme = ref.watch(themeColorsProvider);

    //  final theme=Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8.0),
      elevation: 2,
      child: SizedBox(
        height: 46.0,
        child: DropdownButtonFormField<String>(
          
          hint: Text(labelText, style: TextStyle(color: theme.textColor)),
          style: TextStyle(color: theme.textColor),
          dropdownColor: theme.dashboardContainer,
          focusColor :theme.dashboardContainer,
          icon: AppIcons.iosArrowDown(color: theme.textColor),

          value: currentValue,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                  value,
                  style: TextStyle(color: theme.textColor),
                  ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            ref
                .read(filterButtonProvider.notifier)
                .updateFilter(filterKey, newValue);
            ref
                .read(filterCacheProvider.notifier)
                .addFilter(filterKey, newValue);
          },
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(color: theme.textColor),
            floatingLabelStyle: TextStyle(color: theme.textColor),
            contentPadding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),

            filled: false,

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
              borderSide: BorderSide(color: theme.dashboardBoarder),
            ),
          ),
          isExpanded: true,
          iconSize: 24.0,
        ),
      ),
    );
  }
}
