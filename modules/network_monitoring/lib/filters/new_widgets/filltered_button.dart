import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';

import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

class FilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;
  final double? minHeight;
  final double? minWidth;
  final AlignmentGeometry? alignment;

  const FilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    this.minHeight = 46,
    this.minWidth = 46,
    this.alignment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSelected = ref.watch(
      networkMonitoringFilterButtonProvider.select(
        (state) => state[filterKey] == filterValue,
      ),
    );
    final theme = ref.watch(themeColorsProvider);

    return InkWell(
      onTap: () {
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
        constraints:
            (minHeight != null || minWidth != null)
                ? BoxConstraints(
                  minHeight: minHeight ?? 0,
                  minWidth: minWidth ?? 0,
                )
                : null,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        alignment: alignment ?? Alignment.centerLeft,
        decoration: BoxDecoration(
          color: isSelected ? theme.themeColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? theme.themeTextColor : theme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class NetworkMonitoringBuildNumberField extends ConsumerWidget {
  const NetworkMonitoringBuildNumberField({
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
    final theme = ref.read(themeColorsProvider);

    return Material(
      borderRadius: BorderRadius.circular(10.0),
      elevation: 2,
      child: SizedBox(
        height: 46.0,
        child: CoreTextField(
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
                .read(networkMonitoringFilterCacheProvider.notifier)
                .addFilterNM(filterKey, unformattedValue);
          },
        ),
      ),
    );
  }
}
