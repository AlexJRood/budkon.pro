import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class ParkingRow extends StatelessWidget {
  const ParkingRow({
    super.key,
    required this.isEditing,
    required this.theme,
    required this.parkingController,
  });

  final bool isEditing;
  final ThemeColors theme;
  final ValueNotifier<bool> parkingController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'parking_space'.tr,
          style: AppTextStyles.interRegular.copyWith(
            fontSize: 14,
            color: theme.textColor,
          ),
        ),
        const Spacer(),
        if (isEditing)
          ValueListenableBuilder<bool>(
            valueListenable: parkingController,
            builder:
                (context, hasParking, _) => InkWell(
                  onTap: () => parkingController.value = !hasParking,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox.adaptive(
                        activeColor: theme.themeColor,
                        checkColor: theme.themeTextColor,
                        value: hasParking,
                        onChanged: (v) => parkingController.value = v ?? false,
                      ),
                      Text(
                        (hasParking ? 'Yes'.tr : 'No'.tr),
                        style: AppTextStyles.interRegular.copyWith(
                          fontSize: 14,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
          )
        else
          Text(
            (parkingController.value ? 'Tak' : 'Nie').tr,
            style: AppTextStyles.interRegular.copyWith(
              fontSize: 14,
              color: theme.textColor,
            ),
          ),
      ],
    );
  }
}
