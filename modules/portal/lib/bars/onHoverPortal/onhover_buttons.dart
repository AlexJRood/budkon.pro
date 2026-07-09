import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/button_style.dart';



class PopupHoverButton extends ConsumerWidget {
  final String label;
  final Widget? icon;
  final String route;
  final Color color;
  final Map<String, dynamic>? filters;

  const PopupHoverButton({
    super.key,
    required this.label,
    this.icon,
    required this.route,
    required this.color,
    this.filters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref
  ) {
  final nav = ref.read(navigationService);

    return MouseRegion(
      onEnter: (_) {},
      child: ElevatedButton(
        style: elevatedButtonStyleRounded10,
         onPressed: () {
                      if (filters != null) {
                        // Wyczyść stare filtry
                        ref.read(filterCacheProvider.notifier).clearFilters();
                        ref.read(filterButtonProvider.notifier).clearUiFilters();

                        // Załaduj nowe
                        filters!.forEach((key, value) {
                        // Upewniamy się, że updateFilter dostaje List<String>
                        ref.read(filterButtonProvider.notifier).updateFilter(key, value);

                        // Dla cache zawsze string
                        ref.read(filterCacheProvider.notifier).addFilter(
                          key,
                          value is List ? value.join(',') : value.toString(),
                        );
                      });
                      }
                      // Przejście do ekranu
                      nav.pushNamedScreen(route);
                    },

        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (icon != null) icon!,
              if (icon != null) const SizedBox(width: 10),
              Text(label, style: AppTextStyles.interMedium14.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}


