import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/icons.dart';

import 'package:get/get_utils/get_utils.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final List<String> options;
  final String value;
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
    required this.width
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E), // Matches the dark dropdown background
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: AppIcons.iosArrowDown(color: const Color(0xFF919191)),
          dropdownColor: const Color(0xFF2C2C2E), // Matches dropdown background
          style: const TextStyle(color: Colors.white),
          onChanged: onChanged,
          items: options
              .map((option) => DropdownMenuItem(
            value: option,
            child: Text(
              option,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ))
              .toList(),
        ),
      ),
    );
  }
}


/// TODO change to version 2.0+
class DropdownStateNotifier extends StateNotifier<Map<String, String>> {
  DropdownStateNotifier()
      : super({
    'building_type': 'Apartment'.tr,
    'building_material': 'Concrete'.tr,
    'heating_type': 'Gas'.tr,
    'advertiser_type': 'Agent'.tr,
  });

  void updateValue(String key, String value) {
    state = {...state, key: value};
  }
}

// Provider for DropdownStateNotifier
final dropdownProvider =
StateNotifierProvider<DropdownStateNotifier, Map<String, String>>(
      (ref) => DropdownStateNotifier(),
);