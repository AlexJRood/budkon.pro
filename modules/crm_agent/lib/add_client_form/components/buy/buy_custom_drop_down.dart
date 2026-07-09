import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:crm_agent/add_client_form/provider/buy_filter_provider.dart';
import 'package:crm_agent/add_client_form/components/buy/buy_from_filter_components.dart';

import 'package:get/get_utils/get_utils.dart';

class CrmAddCustomDropdownMap extends ConsumerWidget {
  final String label; // nazwa pola dla użytkownika
  final List<Map<String, String>> options; // [{text, filterKey}]
  final String? value; // trzymamy filterKey
  final void Function(String?) onChanged;
  final double height;
  final double width;

  const CrmAddCustomDropdownMap({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.height = 46,
    required this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final validValue = options.any((o) => o['filterKey'] == value) ? value : null;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: theme.dashboardBoarder),
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue, // filterKey lub null
          isExpanded: true,
          borderRadius: BorderRadius.circular(6),
          icon: AppIcons.iosArrowDown(color: theme.textColor),
          dropdownColor: theme.dashboardContainer,
          style: TextStyle(color: theme.textColor),
          hint: Text(label, style: TextStyle(color: theme.textColor)),
          onChanged: onChanged,
          items: options.map((opt) {
            final fk = opt['filterKey']!;
            final txt = opt['text']!;
            return DropdownMenuItem<String>(
              value: fk, // wartość to filterKey
              child: Text(txt, style: TextStyle(fontSize: 14, color: theme.textColor)),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class DropdownField {
  final String label; // nazwa pola wyświetlana w UI
  final String value; // filterKey

  const DropdownField({required this.label, this.value = ''});

  DropdownField copyWith({String? label, String? value}) =>
      DropdownField(label: label ?? this.label, value: value ?? this.value);
}

class CrmAddDropdownStateNotifier extends StateNotifier<Map<String, DropdownField>> {
  CrmAddDropdownStateNotifier()
      : super({
          'building_type': DropdownField(label: 'Type of building'.tr),
          'building_material': DropdownField(label: 'Building Material'.tr),
          'heating_type': DropdownField(label: 'Heating type'.tr),
          'advertiser_type': DropdownField(label: 'Advertiser type'.tr),
        });

  // aktualizacja WYŁĄCZNIE value (filterKey) + propagacja do filtrów
  void updateValue(String key, String value, WidgetRef ref) {
    final f = state[key];
    if (f == null) return;
    state = {...state, key: f.copyWith(value: value)};
    // integracja z Twoimi providerami filtrów
    ref.read(buyOfferfilterButtonProvider.notifier).updateFilter(key, value);
    ref.read(buyOfferFilterCacheProvider.notifier).addFilter(key, value);
  }

  // (opcjonalnie) aktualizacja etykiety
  void updateLabel(String key, String label) {
    final f = state[key];
    if (f == null) return;
    state = {...state, key: f.copyWith(label: label)};
  }

  // wstępne wypełnienie (przekazujesz filterKey z API)
  void prefillDropdowns({required Map<String, dynamic> filters, required WidgetRef ref}) {
    // mapowanie nazw z API → klucze w stanie
    final map = <String, String>{
      'building_type': (filters['building_type'] ?? '').toString(),
      'building_material': (filters['building_material'] ?? '').toString(),
      'heating_type': (filters['heating_type'] ?? '').toString(),
      'advertiser_type': (filters['advertiser_type'] ?? '').toString(),
    };
    map.forEach((k, v) {
      if (v.isNotEmpty) updateValue(k, v, ref);
    });
  }
}

final crmAddDropdownProvider =
    StateNotifierProvider<CrmAddDropdownStateNotifier, Map<String, DropdownField>>(
  (ref) => CrmAddDropdownStateNotifier(),
);

// (opcjonalnie) tylko wartości (np. do payloadu API)
final crmAddDropdownValuesProvider = Provider<Map<String, String>>((ref) {
  final fields = ref.watch(crmAddDropdownProvider);
  return fields.map((k, v) => MapEntry(k, v.value));
});
