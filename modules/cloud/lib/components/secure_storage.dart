import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';



class SecuredCloudStorageSection extends ConsumerWidget {
  const SecuredCloudStorageSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border.all(
          color: theme.dashboardBoarder,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: AppIcons.lockOutline(color: theme.textColor),
        title: Text("Secured Cloud Storage".tr, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700)),
        subtitle: Text("Documents that are secured in our storage".tr, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w100)),
        trailing: ElevatedButton(
          onPressed: () {},
            style: elevatedButtonStyleRounded10.copyWith(
              backgroundColor: WidgetStateProperty.all(theme.themeColor),
            ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Ask for access".tr, style: TextStyle(color: AppColors.white)),
          ),
        ),
      ),
    );
  }
}
