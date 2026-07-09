import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';
import 'dart:math' as math;

class RealEstateCard extends ConsumerWidget {
  final String imageUrl;
  final String address1;
  final String address2;
  final String size;
  final String rooms;
  final String baths;
  final String price;

  RealEstateCard({
    Key? key,
    this.imageUrl =
        'https://images.unsplash.com/photo-1565402170291-8491f14678db?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8cmVhbCUyMGVzdGF0ZXxlbnwwfHwwfHx8MA%3D%3D',
    required this.address1,
    required this.address2,
    required this.size,
    required this.rooms,
    required this.baths,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, raints) {
        double screenWidth = raints.maxWidth;

        double baseWidth = 1920;
        double cardHeight =
            screenWidth <= baseWidth
                ? 150
                : math.min(
                  200,
                  150 + (screenWidth - baseWidth) * 0.03,
                ); // increase 3% of overflow

        double imageWidth =
            screenWidth <= baseWidth
                ? 250
                : math.min(
                  300,
                  250 + (screenWidth - baseWidth) * 0.05,
                ); // increase 5% of overflow

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 5),
          child: Card(
            color: CustomColors.secondaryWidgetColor(context, ref),
            child: SizedBox(
              height: cardHeight,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      imageUrl,
                      width: imageWidth,
                      height: cardHeight,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey,
                          child: Icon(Icons.error, color: CustomColors.secondaryWidgetTextColor(context, ref)),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address1,
                            style: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(context, ref),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            address2,
                            style: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(102),
                              fontSize: 13,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                          Spacer(),
                          Row(
                            children: [
                              AppIcons.straighten(
                                color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(153),
                                width: 16,
                                height: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                size,
                                style: TextStyle(
                                  color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(153),
                                ),
                              ),
                              SizedBox(width: 16),
                              AppIcons.bed(
                                color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(153),
                                width: 16,
                                height: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                rooms,
                                style: TextStyle(
                                  color: CustomColors.secondaryWidgetTextColor(context, ref).withValues(alpha: 0.6),
                                ),
                              ),
                              SizedBox(width: 16),
                              AppIcons.bathroom(
                                color: CustomColors.secondaryWidgetTextColor(context, ref).withValues(alpha: 0.6),
                                width: 16,
                                height: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                baths,
                                style: TextStyle(
                                  color: CustomColors.secondaryWidgetTextColor(context, ref).withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          Divider(color: CustomColors.secondaryWidgetTextColor(context, ref).withValues(alpha: 0.6),),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'FOR SALE'.tr,
                                style: TextStyle(
                                  color: CustomColors.secondaryWidgetTextColor(context, ref).withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                price,
                                style: TextStyle(
                                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Example usage:
/*
RealEstateCard(
  imageUrl: 'https://example.com/property-image.jpg',
  address: 'Biaty Kamień Street, Warszawa, Mokotów, Poland',
  size: '98 m²',
  rooms: '2 Rooms',
  baths: '2 Bath',
  price: '\$165,000',
),
*/

class MobileRealEstateCard extends ConsumerWidget {
  final String imageUrl;
  final String address1;
  final String address2;
  final String size;
  final String rooms;
  final String baths;
  final String price;

  MobileRealEstateCard({
    Key? key,
    this.imageUrl =
        'https://images.unsplash.com/photo-1565402170291-8491f14678db?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8cmVhbCUyMGVzdGF0ZXxlbnwwfHwwfHx8MA%3D%3D',
    required this.address1,
    required this.address2,
    required this.size,
    required this.rooms,
    required this.baths,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
      final theme = ref.watch(themeColorsProvider);
    return Card(
      color:theme.dashboardContainer,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 180,
                  color: Colors.grey,
                  child: Icon(Icons.error, color: Colors.white, size: 40),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address1,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  address2,
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(153),
                    fontSize: 14,
                    
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Row(
                      children: [
                        AppIcons.straighten(
                          color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(153),
                          height: 16,
                          width: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          size,
                          style: TextStyle(
                            color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(153),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 10),
                    Row(
                      children: [
                        AppIcons.bed(
                          color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(153),
                          width: 16,
                          height: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          rooms,
                          style: TextStyle(
                            color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(102),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 10),
                    Row(
                      children: [
                        AppIcons.bathroom(
                          color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(153),
                          height: 16,
                          width: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          baths,
                          style: TextStyle(
                            color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(153),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Divider(color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(153)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FOR SALE'.tr,
                      style: TextStyle(
                        color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(102),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      price,
                      style: TextStyle(
                          color: theme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}