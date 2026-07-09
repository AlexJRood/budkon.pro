import 'package:association/screens/events/models/event_models.dart';
import 'package:association/screens/events/providers/event_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/theme/apptheme.dart';



class CategoriesChips extends ConsumerWidget {
  const CategoriesChips({required this.cats});
  final List<EventCategoryModel> cats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(eventsFilterProvider).category;
    final theme = ref.read(themeColorsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text('Kategorie:  ', style: TextStyle(color: theme.textColor)),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(
                  'Wszystkie',
                  style: TextStyle(color: theme.textColor),
                ),
                selected: current.isEmpty,
                onSelected: (_) =>
                    ref.read(eventsFilterProvider.notifier).state = ref
                        .read(eventsFilterProvider)
                        .copyWith(category: ''),
              ),
              ...cats.map(
                (c) => ChoiceChip(
                  label: Text(c.name, style: TextStyle(color: theme.textColor)),
                  selected: current == c.name,
                  onSelected: (_) =>
                      ref.read(eventsFilterProvider.notifier).state = ref
                          .read(eventsFilterProvider)
                          .copyWith(category: c.name),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

