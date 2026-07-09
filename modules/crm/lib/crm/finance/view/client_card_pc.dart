import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

class ClientCardPc extends ConsumerWidget {
  final int id;
  final VoidCallback onTap;
  final String avatar;
  final String name;
  final String lastName;
  final String email;
  final String phoneNumber;

  const ClientCardPc({
    super.key,
    required this.onTap,
    required this.id,
    required this.avatar,
    required this.name,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = screenWidth / 1920 * 90;
    itemWidth = max(60.0, min(itemWidth, 90.0));
    double minBaseTextSize = 12;
    double maxBaseTextSize = 16;
    double dynamicFontSize = minBaseTextSize +
        (itemWidth - 120) / (180 - 120) * (maxBaseTextSize - minBaseTextSize);
    dynamicFontSize =
        max(minBaseTextSize, min(dynamicFontSize, maxBaseTextSize));

    return ElevatedButton(
      style: elevatedButtonStyleRounded20,
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: itemWidth,
            height: itemWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              image: DecorationImage(
                image: NetworkImage(avatar),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text('$name $lastName', style: AppTextStyles.interMedium18),
              Text(phoneNumber, style: AppTextStyles.interLight16),
              Text(email, style: AppTextStyles.interLight),
            ],
          ),
        ],
      ),
    );
  }
}
