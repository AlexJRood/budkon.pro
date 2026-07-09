import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reports/reports/create_report_page/providers/providers_report.dart';
import 'package:reports/reports/create_report_page/widgets/components/filter_chips_custom.dart';
import 'package:core/theme/backgroundgradient.dart';

class BedroomAndBathroomMobile extends ConsumerWidget {
  const BedroomAndBathroomMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(propertyValuationFormProvider);
   

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bedroom',
          style: TextStyle(color:CustomColors.secondaryWidgetTextColor(context, ref)),
        ),
        const SizedBox(height: 10),
        Row(
          children: ['Any', '1', '2', '3', '4+'].map((label) {
            final isSelected =
                (formState.bedrooms == 2147483647 && label == 'Any') ||
                (formState.bedrooms == 4 && label == '4+') ||
                (formState.bedrooms.toString() == label);

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CustomFilterChip(
                label: label,
                isSelected: isSelected,
                onTap: () {
                  final selectedValue = label == 'Any'
                      ? 2147483647
                      : label == '4+'
                          ? 4
                          : int.tryParse(label) ?? 0;

                  ref
                      .read(propertyValuationFormProvider.notifier)
                      .updateField('bedrooms', selectedValue);
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Text(
          'Bathroom',
          style: TextStyle(color:CustomColors.secondaryWidgetTextColor(context, ref)),
        ),
        const SizedBox(height: 10),
        Row(
          children: ['Any', '1', '2', '3', '4+'].map((label) {
            final isSelected =
                (formState.bathrooms == 2147483647 && label == 'Any') ||
                (formState.bathrooms == 4 && label == '4+') ||
                (formState.bathrooms.toString() == label);

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CustomFilterChip(
                label: label,
                isSelected: isSelected,
                onTap: () {
                  final selectedValue = label == 'Any'
                      ? 2147483647
                      : label == '4+'
                          ? 4
                          : int.tryParse(label) ?? 0;

                  ref
                      .read(propertyValuationFormProvider.notifier)
                      .updateField('bathrooms', selectedValue);
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
