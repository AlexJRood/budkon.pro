import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';

import 'package:get/get_utils/get_utils.dart';


class CustomDropdownMap extends ConsumerWidget {
  final String label;
  final List<Map<String, String>> options; // expects keys: text, filterKey
  final String? value; // stores filterKey
  final void Function(String?) onChanged;
  final double height;
  final double width;

  const CustomDropdownMap({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    // Ensure provided value exists in options; otherwise show hint
    final validValue = options.any((o) => o['filterKey'] == value) ? value : null;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue, // filterKey or null
          isExpanded: true,
          icon: AppIcons.iosArrowDown(color: theme.textColor),
          dropdownColor: theme.dashboardContainer,
          style: TextStyle(color: theme.textColor),
          hint: Text(label, style: TextStyle(color: theme.textColor)),
          onChanged: onChanged,
          items: options.map((opt) {
            final fk = opt['filterKey']!;
            final txt = opt['text']!;
            return DropdownMenuItem<String>(
              value: fk, // keep filterKey in state
              child: Text(txt, style: TextStyle(fontSize: 14, color: theme.textColor)),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Single field state (label shown to user + stored filterKey value)
class DropdownField {
  final String label; // UI label
  final String value; // filterKey value

  const DropdownField({required this.label, this.value = ''});

  DropdownField copyWith({String? label, String? value}) =>
      DropdownField(label: label ?? this.label, value: value ?? this.value);
}



class DropdownStateNotifier extends StateNotifier<Map<String, DropdownField>> {
  DropdownStateNotifier(this._ref)
      : super({
          'building_type'     : DropdownField(label: 'Type of building'.tr),
          'building_material' : DropdownField(label: 'Building material'.tr),
          'heating_type'      : DropdownField(label: 'Heating type'.tr),
          'advertiser_type'   : DropdownField(label: 'Advertiser type'.tr),
        }) {
    _seedFromCache();     // <- zasianie na starcie
    _liveSyncFromCache(); // <- (opcjonalnie) słuchanie zmian cache
  }

  final Ref _ref;

  void _seedFromCache() {
    final cache = _ref.read(networkMonitoringFilterCacheProvider.notifier);
    final f = cache.filters;

    final initial = <String, String>{
      'building_type'     : (f['building_type'] ?? '').toString(),
      'building_material' : (f['building_material'] ?? '').toString(),
      'heating_type'      : (f['heating_type'] ?? '').toString(),
      'advertiser_type'   : (f['advertiser_type'] ?? '').toString(),
    };

    // Ustaw również pustkę (żeby force’ować null w DropdownButton)
    final next = <String, DropdownField>{}..addAll(state);
    initial.forEach((k, v) {
      final field = next[k];
      if (field != null && field.value != v) {
        next[k] = field.copyWith(value: v);
      }
    });
    state = next;
  }


    void clearAll() {
    final next = <String, DropdownField>{};
    for (final entry in state.entries) {
      next[entry.key] = entry.value.copyWith(value: '');
    }
    state = next;
  }

  // (opcjonalne) gdy cache się zmienia, dociągaj do UI (np. gdy coś wypełni inny widok)
  void _liveSyncFromCache() {
    _ref.listen<Map<String, dynamic>>(
      networkMonitoringFilterCacheProvider,
      (_, __) {
        final cache = _ref.read(networkMonitoringFilterCacheProvider.notifier);
        final f = cache.filters;

        final next = <String, DropdownField>{}..addAll(state);
        for (final k in state.keys) {
          final v = (f[k] ?? '').toString(); // może być pusty po clear
          if (next[k]!.value != v) {
            next[k] = next[k]!.copyWith(value: v);
          }
        }
        state = next;
      },
    );
  }


  // bez zmian
  void updateValue(String key, String value, WidgetRef ref) {
    final f = state[key];
    if (f == null) return;
    state = {...state, key: f.copyWith(value: value)};
    ref.read(networkMonitoringFilterButtonProvider.notifier).updateFilterNM(key, value);
    ref.read(networkMonitoringFilterCacheProvider.notifier).addFilterNM(key, value);
  }

  void updateLabel(String key, String label) {
    final f = state[key];
    if (f == null) return;
    state = {...state, key: f.copyWith(label: label)};
  }

  // (zostaw jeśli gdzieś jawnie zasilasz)
  void prefillDropdowns({
    required Map<String, dynamic> filters,
    required WidgetRef ref,
  }) {
    for (final k in state.keys) {
      final v = (filters[k] ?? '').toString();
      updateValue(k, v, ref); // pozwól też na '', wtedy Dropdown się wyczyści
    }
  }

}


// Provider exposing the map of fields
final dropdownProvider =
    StateNotifierProvider<DropdownStateNotifier, Map<String, DropdownField>>(
  (ref) => DropdownStateNotifier(ref),
);

// (Optional) Helper to get only values map if some APIs expect {key: filterKey}
final dropdownValuesProvider = Provider<Map<String, String>>((ref) {
  final fields = ref.watch(dropdownProvider);
  return fields.map((k, v) => MapEntry(k, v.value));
});
