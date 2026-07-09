import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';

import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:core/theme/apptheme.dart';

// selected_additional_info_provider.dart

// Zwraca: najpierw stan z UI, a jeśli brak — z cache; domyślnie false.
final additionalInfoSelectedProvider = Provider.family<bool, String>((
  ref,
  filterKey,
) {
  // 1) Spróbuj z UI (networkMonitoringFilterButtonProvider trzyma bool w state[filterKey])
  final uiState = ref.watch(networkMonitoringFilterButtonProvider);
  final uiHas = uiState.containsKey(filterKey);
  if (uiHas) {
    final v = uiState[filterKey];
    return v == true; // tylko true nas interesuje
  }

  // 2) Fallback: z cache (string/bool)
  final cache = ref.read(networkMonitoringFilterCacheProvider.notifier);
  final raw = cache.filters[filterKey];
  if (raw is bool) return raw;
  if (raw is String) return raw.toLowerCase() == 'true';

  // 3) Domyślnie false
  return false;
});

class AdditionalInfoFilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;

  const AdditionalInfoFilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(additionalInfoSelectedProvider(filterKey));
    final theme = ref.watch(themeColorsProvider);

    return InkWell(
      onTap: () {
        final buttons = ref.read(
          networkMonitoringFilterButtonProvider.notifier,
        );
        final cache = ref.read(networkMonitoringFilterCacheProvider.notifier);

        if (isSelected) {
          // OFF
          buttons.updateFilterNM(filterKey, false);
          cache.removeFilterNM(filterKey);
        } else {
          // ON
          buttons.updateFilterNM(filterKey, true);
          cache.addFilterNM(filterKey, 'true'); // cache trzyma stringi
        }
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, minHeight: 48),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
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
