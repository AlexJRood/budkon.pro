import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';

List<PieAction> buildPieMenuActionsClientsPro(
    WidgetRef ref, dynamic action, dynamic actionId, BuildContext context,) {
  return [
    PieAction(
      tooltip: Text('tooltip_archive_client'.tr),
      onSelect: () async {
        final confirmed = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('title_confirmation'.tr),
            content: Text(
              'msg_confirm_archive_client'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('btn_cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();  
                   ref.read(clientProvider.notifier).deleteClient(action);
                },
                child: Text('btn_delete'.tr),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await ref.read(clientProvider.notifier).deleteClient(action);
          // await ref.read(removeSavedSearchProvider).removeSavedSearch(action);
        }
      },
      child: FaIcon(FontAwesomeIcons.trash),
    ),
    PieAction(
      tooltip: Text('tooltip_statuses'.tr),
      onSelect: () async {   

        final nav = ref.read(navigationService);
        final path = nav.currentPath == '/' ? '' : nav.currentPath;

        nav.pushNamedScreen(
          '$path/${Routes.contactStatuses}',
            data: {
              'isFilter': true,
            }
        );
      },
      child: const FaIcon(FontAwesomeIcons.filter),
    ),
    PieAction(
      tooltip: Text('tooltip_change_client_status'.tr),
      onSelect: () async {   
        final nav = ref.read(navigationService);
        final path = nav.currentPath;
        nav.pushNamedScreen(
          '$path/${Routes.contactStatuses}',
            data: {
              'contact': actionId,
              'isFilter': false,
            }
        );
         
      },
      child: const FaIcon(FontAwesomeIcons.arrowsRotate),
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