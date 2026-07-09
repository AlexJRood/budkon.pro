import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/backgroundgradient.dart';

class PlanCard extends ConsumerWidget {
  
  final int index;
  final String title;
  final String subtitle;
  final List<String> features;
  final String price;
  final String? oldPrice;
  final bool isPopular;
  final String description;
  final String popularLabel;
  final bool isSelected;
  final VoidCallback onSelect;
  final bool isTablet;

  const PlanCard({
    super.key,
   
    required this.index,
    this.description = '',
    required this.title,
    required this.subtitle,
    required this.features,
    required this.price,
    this.oldPrice,
    this.isPopular = false,
    this.popularLabel = '',
    required this.isSelected,
    required this.onSelect,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onSelect,
      child: Stack(
        children: [
          Container(
            
            height: screenWidth >= 2000 ? 700 :isTablet?520: 450,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CustomColors.secondaryWidgetColor(context, ref),
              border: Border.all(
                color:
                    isSelected
                        ? Colors.blue
                        : CustomColors.secondaryWidgetTextColor(
                          context,
                          ref,
                        ).withAlpha(51),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.tr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.tr,
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(
                      context,
                      ref,
                    ).withAlpha(153),
                  ),
                ),
                const SizedBox(height: 16),
                for (var feature in features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: CustomColors.secondaryWidgetTextColor(context, ref),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature.tr,
                            style: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ).withAlpha(230),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          description.tr,
                          style: TextStyle(
                            color: CustomColors.secondaryWidgetTextColor(
                              context,
                              ref,
                            ).withAlpha(230),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
                Spacer(),
                Row(
                  children: [
                    if (oldPrice != null)
                      Text(
                        oldPrice!.tr,
                        style: TextStyle(
                          fontSize: 20,
                          decoration: TextDecoration.lineThrough,
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            ref,
                          ).withAlpha(128),
                        ),
                      ),
                    if (oldPrice != null) const SizedBox(width: 6),
                    Text(
                      price.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 25,
                        color: CustomColors.secondaryWidgetTextColor(context, ref),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Text(
                  popularLabel.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final plansDummy = [
  PlanModel(
    title: 'Basic',
    subtitle: 'for one month',
    price: '\$0',
    features: [
      'Twice as many views at the top with Booster',
      'Twice as many views at the top with Booster',
      'Twice as many views at the top with Booster',
    ],
    description: 'Advertising without promotion services',
  ),
  PlanModel(
    title: 'Plus',
    subtitle: 'for 7 days',
    price: '\$11.00',
    oldPrice: '\$14.00',
    isPopular: true,
    popularLabel: 'Most popular',
    features: [
      'Twice as many views at the top with Booster',
      '1 repost per day during peak category traffic',
      'A tag on your ad',
    ],
  ),
  PlanModel(
    title: 'Turbo',
    subtitle: 'for 7 days',
    price: '\$15.00',
    oldPrice: '\$20.00',
    features: [
      '5 times more views at the top with Booster',
      '3 reposts per day during peak category traffic',
      'Highlighted in the list with animation',
    ],
  ),
];

class PlanModel {
  final String title;
  final String subtitle;
  final String price;
  final String? oldPrice;
  final bool isPopular;
  final String popularLabel;
  final String description;
  final List<String> features;

  PlanModel({
    required this.title,
    required this.subtitle,
    required this.price,
    this.oldPrice,
    this.isPopular = false,
    this.popularLabel = '',
    this.description = '',
    required this.features,
  });
}
