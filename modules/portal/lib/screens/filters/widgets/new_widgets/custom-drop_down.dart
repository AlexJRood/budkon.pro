import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/icons.dart';

import 'package:get/get_utils/get_utils.dart';


class CustomDropdown extends StatelessWidget {
  final String label;                         // tekst podpowiedzi (hint/label)
  final List<Map<String, String>> options;    // [{ 'text': ..., 'filterKey': ... }]
  final String? value;                        // przechowujemy filterKey
  final void Function(String?) onChanged;
  final double height;
  final double width;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final validValue = options.any((o) => o['filterKey'] == value) ? value : null;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue, // filterKey lub null
          isExpanded: true,
          icon: AppIcons.iosArrowDown(color: const Color(0xFF919191)),
          dropdownColor: const Color(0xFF2C2C2E),
          style: const TextStyle(color: Colors.white),
          hint: Text(label, style: const TextStyle(color: Colors.white)),
          onChanged: onChanged,
          items: options.map((opt) {
            final fk  = opt['filterKey']!;
            final txt = opt['text']!;
            return DropdownMenuItem<String>(
              value: fk,
              child: Text(txt, style: const TextStyle(fontSize: 14, color: Colors.white)),
            );
          }).toList(),
        ),
      ),
    );
  }
}


class DropdownField {
  final String label; // etykieta dla usera
  final String value; // filterKey trzymany w stanie
  const DropdownField({required this.label, this.value = ''});

  DropdownField copyWith({String? label, String? value}) =>
      DropdownField(label: label ?? this.label, value: value ?? this.value);
}

class DropdownStateNotifier extends StateNotifier<Map<String, DropdownField>> {
  DropdownStateNotifier()
      : super({
          'building_type':  DropdownField(label: 'Type of building'.tr),
          'building_material': DropdownField(label: 'Building Material'.tr),
          'heating_type':     DropdownField(label: 'Heating type'.tr),
          'advertiser_type':      DropdownField(label: 'Advertiser'.tr),
        });

  void updateValue(String key, String filterKey) {
    final f = state[key];
    if (f == null) return;
    state = {...state, key: f.copyWith(value: filterKey)};
  }

  void updateLabel(String key, String label) {
    final f = state[key];
    if (f == null) return;
    state = {...state, key: f.copyWith(label: label)};
  }
}

final dropdownProvider =
  StateNotifierProvider<DropdownStateNotifier, Map<String, DropdownField>>(
    (ref) => DropdownStateNotifier(),
  );

// (opcjonalnie) sam słownik wartości do payloadu API
final dropdownValuesProvider = Provider<Map<String, String>>((ref) {
  final m = ref.watch(dropdownProvider);
  return m.map((k, v) => MapEntry(k, v.value));
});
