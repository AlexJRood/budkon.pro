import 'package:crm/contact_panel/tabs/saved_search_client/components/from_filter_components.dart';
import 'package:crm/data/clients/ad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:get/get_utils/get_utils.dart';

class ClientPanelCustomDropdown extends ConsumerWidget {
  final String label;                         // nazwa pola dla użytkownika
  final List<Map<String, String>> options;    // [{text, filterKey}]
  final String? value;                        // przechowujemy filterKey
  final void Function(String?) onChanged;
  final double height;
  final double width;

  const ClientPanelCustomDropdown({
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
    final validValue = options.any((o) => o['filterKey'] == value) ? value : null;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.textFieldColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue, // filterKey lub null
          isExpanded: true,
          icon: AppIcons.iosArrowDown(color: theme.textColor),
          dropdownColor: theme.dashboardContainer,
          style: TextStyle(color: theme.textColor),
          hint: Text(label, style: TextStyle(color: theme.textColor)),
          onChanged: onChanged,
          items: options.map((opt) {
            final fk  = opt['filterKey']!;
            final txt = opt['text']!;
            return DropdownMenuItem<String>(
              value: fk,
              child: Text(txt, style: TextStyle(fontSize: 14, color: theme.textColor)),
            );
          }).toList(),
        ),
      ),
    );
  }
}




class DropdownField {
  final String label; // etykieta pokazywana w UI
  final String value; // filterKey
  const DropdownField({required this.label, this.value = ''});

  DropdownField copyWith({String? label, String? value}) =>
      DropdownField(label: label ?? this.label, value: value ?? this.value);
}

class ClientPanelDropdownStateNotifier
    extends StateNotifier<Map<String, DropdownField>> {
  ClientPanelDropdownStateNotifier(this._ref)
      : super({
          'building_type'  : DropdownField(label: 'Type of building'.tr),
          'building_material': DropdownField(label: 'Building Material'.tr),
          'heating_type'     : DropdownField(label: 'Heating type'.tr),
          'advertiser_type'      : DropdownField(label: 'Advertiser'.tr),
        }
        ){
    _seedFromCache();     // <- zasianie na starcie
    _setupLiveSync(); // <- (opcjonalnie) słuchanie zmian cache
  }

  



  final Ref _ref;
  ProviderSubscription<Map<String, dynamic>>? _sub; // ← trzymaj subskrypcję

  void _seedFromCache() {
    final cache = _ref.read(filterCacheProvider.notifier);
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




  void _setupLiveSync() {
    _sub = _ref.listen<Map<String, dynamic>>(
      filterCacheProvider,
      (prev, next) {
        final cache = _ref.read(filterCacheProvider.notifier);
        final f = cache.filters;

        final nextState = <String, DropdownField>{}..addAll(state);
        for (final k in state.keys) {
          final v = (f[k] ?? '').toString();
          if (nextState[k]!.value != v) {
            nextState[k] = nextState[k]!.copyWith(value: v);
          }
        }
        state = nextState;
      },
      // często przydatne, jeśli chcesz od razu zgrać stan na starcie
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _sub?.close(); // ← ZAMKNIJ subskrypcję
    super.dispose();
  }

  // bez zmian
  void updateValue(String key, String value, WidgetRef ref) {
    final f = state[key];
    if (f == null) return;
    state = {...state, key: f.copyWith(value: value)};
    ref.read(filterButtonProvider.notifier).updateFilter(key, value);
    ref.read(filterCacheProvider.notifier).addFilter(key, value);
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

final clientPanelDropdownProvider = StateNotifierProvider<
    ClientPanelDropdownStateNotifier, Map<String, DropdownField>>(
  (ref) => ClientPanelDropdownStateNotifier(ref),
);

// (opcjonalnie) tylko wartości do payloadu
final clientPanelDropdownValuesProvider = Provider<Map<String, String>>((ref) {
  final m = ref.watch(clientPanelDropdownProvider);
  return m.map((k, v) => MapEntry(k, v.value));
});
