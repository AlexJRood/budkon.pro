import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/filters/new_widgets/custom_drop_down.dart';
import 'package:network_monitoring/widgets/filter/controllers.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:intl/intl.dart';

final networkMonitoringFilterButtonProvider = StateNotifierProvider<
  NetworkMonitoringFilterButtonNotifier,
  Map<String, dynamic>
>((ref) {
  return NetworkMonitoringFilterButtonNotifier();
});

class NetworkMonitoringFilterButtonNotifier
    extends StateNotifier<Map<String, dynamic>> {
  NetworkMonitoringFilterButtonNotifier() : super({});

  void updateFilterNM(String key, dynamic value) {
    state = {...state, key: value};
  }

  void updateRangeFilterNM(String key, RangeValues values) {
    state = {...state, key: values};
  }

  void clearUiFiltersNM(WidgetRef ref) {
    state = {};
    ref.read(dropdownProvider.notifier).clearAll();
    ref.read(nmControllersProvider).clearAllTextFields();
  }

  void loadSavedFilters(Map<String, dynamic> savedFilters) {
    state = savedFilters;
  }
}

class NetworkMonitoringFilterButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;
  final double width;
  final bool isTablet;

  const NetworkMonitoringFilterButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    this.width = 240,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSelected = ref.watch(
      networkMonitoringFilterButtonProvider.select(
        (state) => state[filterKey] == filterValue,
      ),
    );
    final theme = ref.read(themeColorsProvider);

    return ElevatedButton(
      style: elevatedButtonStyleRounded10withoutPadding,
      onPressed: () {
        final filterNotifier = ref.read(
          networkMonitoringFilterCacheProvider.notifier,
        );
        if (isSelected) {
          ref
              .read(networkMonitoringFilterButtonProvider.notifier)
              .updateFilterNM(filterKey, null);
          filterNotifier.removeFilterNM(filterKey);
        } else {
          ref
              .read(networkMonitoringFilterButtonProvider.notifier)
              .updateFilterNM(filterKey, filterValue);
          filterNotifier.addFilterNM(filterKey, filterValue);
        }
      },
      child: Container(
        width: width,
        height: isTablet ? 32 : 50,
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.fillColor.withAlpha((255 * 0.5).toInt()),
                      theme.fillColor,
                    ],
                  )
                  : null,
          color: !isSelected ? theme.textFieldColor : theme.fillColor,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: (isTablet ? AppTextStyles.interMedium : const TextStyle()).copyWith(
                color: isSelected ? AppColors.white : theme.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NetworkMonitoringFilterButtonRooms extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;
  final double width;

  const NetworkMonitoringFilterButtonRooms({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    this.width = 240,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSelected = ref.watch(
      networkMonitoringFilterButtonProvider.select(
        (state) => state[filterKey] == filterValue,
      ),
    );
    final theme = ref.read(themeColorsProvider);

    return ElevatedButton(
      style: elevatedButtonStyleRounded10withoutPadding,
      onPressed: () {
        final filterNotifier = ref.read(
          networkMonitoringFilterCacheProvider.notifier,
        );
        if (isSelected) {
          ref
              .read(networkMonitoringFilterButtonProvider.notifier)
              .updateFilterNM(filterKey, null);
          filterNotifier.removeFilterNM(filterKey);
        } else {
          ref
              .read(networkMonitoringFilterButtonProvider.notifier)
              .updateFilterNM(filterKey, filterValue);
          filterNotifier.addFilterNM(filterKey, filterValue);
        }
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.fillColor.withAlpha((255 * 0.5).toInt()),
                        theme.fillColor,
                      ],
                    )
                    : null,
            color: !isSelected ? theme.textFieldColor : theme.fillColor,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(
                  color: isSelected ? AppColors.white : theme.textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NetworkMonitoringEstateTypeFilterButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;
  final Color? color;
  final bool isTablet;

  const NetworkMonitoringEstateTypeFilterButton({
    super.key,
    this.color,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> selectedValues = List<String>.from(
      ref.watch(
        networkMonitoringFilterButtonProvider.select(
          (state) => state[filterKey] ?? [],
        ),
      ),
    );
    final bool isSelected = selectedValues.contains(filterValue);
    final theme = ref.read(themeColorsProvider);
    final isColor = color != null;

    return ElevatedButton(
      style: elevatedButtonStyleRounded10withoutPadding,
      onPressed: () {
        if (isSelected) {
          selectedValues.remove(filterValue);
        } else {
          selectedValues.add(filterValue);
        }
        ref
            .read(networkMonitoringFilterButtonProvider.notifier)
            .updateFilterNM(filterKey, selectedValues);
        ref
            .read(networkMonitoringFilterCacheProvider.notifier)
            .addFilterNM(filterKey, selectedValues.join(','));
      },
      child: Container(
        height: isTablet ? 32 : 50,
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? isColor
                  
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color!,
                        color!
                      ],
                    )
                    : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.fillColor.withAlpha((255 * 0.5).toInt()),
                        theme.fillColor,
                      ],
                    )

                  : null,
          color: !isSelected ? theme.textFieldColor : theme.fillColor,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),

        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: (isTablet ? AppTextStyles.interMedium : const TextStyle()).copyWith(
              color: isSelected ? AppColors.white : theme.textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class NetworkMonitoringAdditionalInfoFilterButton extends ConsumerWidget {
  final String text;
  final String filterKey;

  const NetworkMonitoringAdditionalInfoFilterButton({
    super.key,
    required this.text,
    required this.filterKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      networkMonitoringFilterButtonProvider.select(
        (state) => state[filterKey] ?? false,
      ),
    );
    final theme = ref.read(themeColorsProvider);

    return ElevatedButton(
      style: elevatedButtonStyleRounded10withoutPadding,
      onPressed: () {
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        final currentState =
            ref
                .read(networkMonitoringFilterButtonProvider.notifier)
                .state[filterKey] ??
            false;
        final newState = !currentState;
        ref
            .read(networkMonitoringFilterButtonProvider.notifier)
            .updateFilterNM(filterKey, newState);

        if (newState) {
          ref
              .read(networkMonitoringFilterCacheProvider.notifier)
              .addFilterNM(filterKey, 'true');
        } else {
          ref
              .read(networkMonitoringFilterCacheProvider.notifier)
              .removeFilterNM(filterKey);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.fillColor.withAlpha((255 * 0.5).toInt()),
                      theme.fillColor,
                    ],
                  )
                  : null,
          color: !isSelected ? theme.textFieldColor : null,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                color: isSelected ? AppColors.white : theme.textColor,
              ),
            ),
          ),
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
    final theme = ref.read(themeColorsProvider);

    return SizedBox(
      height: 50.0,
      child: TextField(
        controller: controller,
        onChanged: (value) {
          ref
              .read(networkMonitoringFilterCacheProvider.notifier)
              .addFilterNM(filterKey, value);
        },
        style: AppTextStyles.interMedium14dark.copyWith(color: theme.textColor),
        decoration: InputDecoration(
          label: Text(labelText),
          hintStyle: TextStyle(color: theme.textColor),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.fillColor),
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}

class BuildNumberField extends ConsumerWidget {
  final TextEditingController controller;
  final String labelText;
  final String filterKey;
  final bool isTablet;

  const BuildNumberField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.filterKey,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.isTablet = false,
  });


  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat('#,###');
    final theme = ref.read(themeColorsProvider);

    return SizedBox(
      height: isTablet ? 36.0 : 50.0,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        cursorColor: theme.textColor,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
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
        style: (isTablet ? AppTextStyles.interMedium : AppTextStyles.interMedium14)
            .copyWith(color: theme.textColor),
        decoration: InputDecoration(
          label: Text(
            labelText,
            style: (isTablet ? AppTextStyles.interMedium : const TextStyle())
                .copyWith(color: theme.textColor),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.textColor),
          ),
          filled: true,
          fillColor: theme.textFieldColor,
        ),
        onChanged: (value) {
          final unformattedValue = value.replaceAll(',', '');
          ref
              .read(networkMonitoringFilterCacheProvider.notifier)
              .addFilterNM(filterKey, unformattedValue);
        },
      ),
    );
  }
}

class BuildDropdownButtonFormField extends ConsumerWidget {
  const BuildDropdownButtonFormField({
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
          focusColor: theme.dashboardContainer,
          icon: AppIcons.iosArrowDown(color: theme.textColor),

          initialValue: currentValue,
          items:
              items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(color: theme.textColor)),
                );
              }).toList(),
          onChanged: (String? newValue) {
            ref
                .read(networkMonitoringFilterButtonProvider.notifier)
                .updateFilterNM(filterKey, newValue);
            ref
                .read(networkMonitoringFilterCacheProvider.notifier)
                .addFilterNM(filterKey, newValue);
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
