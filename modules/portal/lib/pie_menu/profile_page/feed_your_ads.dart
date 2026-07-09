import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import '../../screens/edit_offer/providers/remove_ad_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:pie_menu/pie_menu.dart';

import 'package:get/get_utils/get_utils.dart';

List<PieAction> buildPieMenuYourAds(
    WidgetRef ref, dynamic action, BuildContext context,{VoidCallback? onDeleted,}) {
  final theme = ref.watch(themeColorsProvider);
  return [
    PieAction(
      tooltip: Text('Edit Ad'.tr,style: TextStyle(color: theme.textColor),),
      onSelect: () {
        ref.read(navigationService).pushNamedReplacementScreen(
              '${Routes.editOffer}/${action.id}',
            );
      },
      child: const FaIcon(FontAwesomeIcons.penToSquare),
    ),
    PieAction(
      tooltip:Text('delete_ad'.tr,style: TextStyle(color: theme.textColor),),
      onSelect: () async {
        final confirmed = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: theme.adPopBackground,
            title: Text('confirmation'.tr,style: TextStyle(color: theme.textColor),),
            content:
                Text('are_you_sure_delete_ad'.tr,style: TextStyle(color: theme.textColor),),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'.tr,style: TextStyle(color: theme.textColor),),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: theme.themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Delete'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          final deleted = await ref.read(removeAdProvider).removeAd(action.id);
          if (deleted) {
            onDeleted?.call();
          }
        }
      },
      child: FaIcon(FontAwesomeIcons.trash),
    ),
  ];
}

extension ContextExtension on BuildContext {
  void showSnackBarLikeSection(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
