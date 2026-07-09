import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';

import 'package:crm_agent/add_client_form/provider/sell_estate_data_provider.dart';


class DropdownState {
  final String filterKey; // przechowujemy klucz do API
  DropdownState({required this.filterKey});
}

class DropdownNotifier extends StateNotifier<Map<int, DropdownState>> {
  DropdownNotifier() : super(<int, DropdownState>{});

  void updateSelectedValue(int id, String newFilterKey) {
    state = {...state}..[id] = DropdownState(filterKey: newFilterKey);
  }
}

final addClientDropDownProvider =
    StateNotifierProvider<DropdownNotifier, Map<int, DropdownState>>(
  (ref) => DropdownNotifier(),
);


class AddClientFormCustomDropDown extends ConsumerWidget {
  final int id;
  /// [{ 'text': 'Apartment', 'filterKey': 'apartment' }, ...]
  final List<Map<String, String>> options;
  final String hintText;
  /// klucz do zapisu w cache/payload (np. 'building_type')
  final String valueKey;
  final String? Function(String?)? validator;

  const AddClientFormCustomDropDown({
    super.key,
    required this.id,
    required this.options,
    required this.hintText,
    required this.valueKey,
    this.validator,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dropdownMap = ref.watch(addClientDropDownProvider);
    final dropdownState = dropdownMap[id] ?? DropdownState(filterKey: '');
    final sellOfferDraftData = ref.read(sellOfferFilterCacheProvider.notifier);
    final theme = ref.watch(themeColorsProvider);

    // Czy aktualny filterKey istnieje w opcjach?
    final hasValue = options.any((o) => o['filterKey'] == dropdownState.filterKey);
    final String? currentFilterKey = hasValue ? dropdownState.filterKey : null;

    return FormField<String>(
      initialValue: currentFilterKey,
      validator: validator ?? (v) => null,
      builder: (state) {
        final String? errorText = state.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: errorText == null ? theme.dashboardBoarder : Theme.of(context).colorScheme.error,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  borderRadius: BorderRadius.circular(6),
                  isExpanded: true,
                  value: state.value, // to jest filterKey lub null
                  hint: Text(hintText, style: TextStyle(color: theme.textColor, fontSize: 14)),
                  onChanged: (String? newFilterKey) {
                    if (newFilterKey == null) return;

                    // aktualizacja FormField
                    state.didChange(newFilterKey);

                    // aktualizacja providera (trzymamy filterKey)
                    ref.read(addClientDropDownProvider.notifier)
                       .updateSelectedValue(id, newFilterKey);

                    // zapis do draftu/aplikacji (z kluczem domenowym)
                    sellOfferDraftData.addData(valueKey, newFilterKey);
                  },
                  icon: AppIcons.iosArrowDown(color: theme.textColor),
                  dropdownColor: theme.dashboardContainer,
                  style: TextStyle(color: theme.textColor, fontSize: 14),
                  // Każdy item: value = filterKey, label = text
                  items: options.map((opt) {
                    final fk = opt['filterKey']!;
                    final txt = opt['text']!;
                    return DropdownMenuItem<String>(
                      value: fk,
                      child: Text(txt, style: TextStyle(color: theme.textColor)),
                    );
                  }).toList(),
                ),
              ),
            ),

            if (errorText != null) ...[
              const SizedBox(height: 6),
              Text(
                errorText,
                style:  TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12, height: 1.1),
              ),
            ],
          ],
        );
      },
    );
  }
}
