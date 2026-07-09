

import 'package:core/platform/api/api_buttons.dart';
import 'package:flutter/material.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:get/get.dart';

class FlieActions extends StatelessWidget{
  final dynamic id;
  final dynamic ref;
  const FlieActions({super.key, required this.id, required this.ref});


  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final nav = ref.read(navigationService);

    return Column(
      children: [
        ApiButton(
          icon: AppIcons.delete(color: theme.textColor),
          label: 'remove_file'.tr,
          endpoint: "https://www.superbee.cloud/storage/files/$id/",
          method: ApiMethod.delete,
          hasToken: true,
          ref: ref,
          onSuccess: (resp) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('remove_file'.tr)),
            );
            nav.closePopup();
          },
          onError: (err) => debugPrint("FlieActions error: $err"),
        )
      ],
    );
  }
}