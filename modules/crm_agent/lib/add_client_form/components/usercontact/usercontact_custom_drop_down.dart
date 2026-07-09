import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:crm_agent/add_client_form/provider/sell_estate_data_provider.dart';

class DropdownState {
  final String selectedValue;
  const DropdownState({required this.selectedValue});
}

class DropdownNotifierUserContact extends StateNotifier<Map<String, DropdownState>> {
  DropdownNotifierUserContact() : super(const {});

  // scopeKey izoluje stan pomiędzy formularzami
  static String keyOf(int id, String valueKey, [String? scopeKey]) {
    final scope = (scopeKey == null || scopeKey.trim().isEmpty)
        ? 'global'
        : scopeKey.trim();
    return '$scope::$valueKey#$id';
  }

  void updateSelectedValue(
    int id,
    String valueKey,
    String newValue,
    WidgetRef ref, {
    String? scopeKey,
    bool writeToCache = true,
  }) {
    final k = keyOf(id, valueKey, scopeKey);
    state = {
      ...state,
      k: DropdownState(selectedValue: newValue),
    };

    if (writeToCache) {
      ref.read(sellOfferFilterCacheProvider.notifier).addData(valueKey, newValue);
    }
  }

  // seed initialValue tylko do lokalnego stanu dropdowna, bez zewnętrznego cache
  void seedSelectedValue(
    int id,
    String valueKey,
    String newValue, {
    String? scopeKey,
  }) {
    final k = keyOf(id, valueKey, scopeKey);
    state = {
      ...state,
      k: DropdownState(selectedValue: newValue),
    };
  }

  DropdownState getState(
    int id,
    String valueKey, {
    String? scopeKey,
  }) {
    final k = keyOf(id, valueKey, scopeKey);
    return state[k] ?? const DropdownState(selectedValue: '');
  }

  void reset(
    int id,
    String valueKey, {
    String? scopeKey,
  }) {
    final k = keyOf(id, valueKey, scopeKey);
    final next = {...state}..remove(k);
    state = next;
  }

  void resetScope(String scopeKey) {
    final normalized = scopeKey.trim();
    if (normalized.isEmpty) return;

    final prefix = '$normalized::';
    final next = {...state};
    next.removeWhere((key, value) => key.startsWith(prefix));
    state = next;
  }
}

final sellOfferDropDownProvider =
    StateNotifierProvider<DropdownNotifierUserContact, Map<String, DropdownState>>(
  (ref) => DropdownNotifierUserContact(),
);

class AddClientFormCustomDropDown extends ConsumerWidget {
  final int id;
  final List<String> options;
  final List<String> values;
  final String hintText;
  final String valueKey;
  final String? initialValue;
  final String? scopeKey;
  final void Function(String newValue, int id, String valueKey)? onChangedExtra;

  const AddClientFormCustomDropDown({
    super.key,
    required this.id,
    required this.options,
    required this.values,
    required this.hintText,
    required this.valueKey,
    this.initialValue,
    this.scopeKey,
    this.onChangedExtra,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      options.length == values.length,
      'options (labels) and values (ids) must have the same length',
    );

    final theme = ref.watch(themeColorsProvider);
    final stateMap = ref.watch(sellOfferDropDownProvider);
    final storageKey = DropdownNotifierUserContact.keyOf(id, valueKey, scopeKey);

    final dropdownState =
        stateMap[storageKey] ?? const DropdownState(selectedValue: '');

    final hasProviderValue = dropdownState.selectedValue.trim().isNotEmpty;
    final canSeedInitial = !hasProviderValue &&
        initialValue != null &&
        initialValue!.trim().isNotEmpty &&
        values.contains(initialValue);

    if (canSeedInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(sellOfferDropDownProvider.notifier).seedSelectedValue(
              id,
              valueKey,
              initialValue!,
              scopeKey: scopeKey,
            );
      });
    }

    final String? effectiveValue = values.contains(dropdownState.selectedValue)
        ? dropdownState.selectedValue
        : (values.contains(initialValue) ? initialValue : null);

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (effectiveValue == null)
              ? theme.dashboardBoarder
              : theme.textColor,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          hint: Text(
            hintText,
            style: TextStyle(color: theme.textColor, fontSize: 12),
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(6),
          dropdownColor: theme.dashboardContainer,
          icon: AppIcons.iosArrowDown(color: theme.textColor),
          style: TextStyle(color: theme.textColor, fontSize: 14),
          items: List.generate(options.length, (i) {
            return DropdownMenuItem<String>(
              value: values[i],
              child: Text(options[i]),
            );
          }),
          onChanged: (String? newValue) {
            if (newValue == null) return;

            ref.read(sellOfferDropDownProvider.notifier).updateSelectedValue(
                  id,
                  valueKey,
                  newValue,
                  ref,
                  scopeKey: scopeKey,
                );

            onChangedExtra?.call(newValue, id, valueKey);
          },
        ),
      ),
    );
  }
}