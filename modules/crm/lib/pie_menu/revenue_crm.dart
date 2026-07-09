import 'package:core/kernel/kernel.dart';
import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:crm/data/finance/remove_revenue.dart';
import 'package:crm/widget/manage_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:pie_menu/pie_menu.dart';

List<PieAction> pieMenuCrmRevenues({
  required WidgetRef ref,
  required dynamic action,
  required dynamic actionId,
  required BuildContext context,
  required Color textColor,
}) {
  final theme = ref.watch(themeColorsProvider);
  return [

    
    PieAction(
      tooltip: Text('delete_transaction'.tr,style: TextStyle(color: theme.textColor),),
      onSelect: () async {
     
     
     final confirmed = await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(
                'confirm_title'.tr,
              ),
              content: Text(
                'confirm_delete_invoice'.tr,
              ),
              actions: [
                TextButton(
                  onPressed:
                      () => ref
                          .read(
                            navigationService,
                          )
                          .beamPop(false),
                  child: Text(
                    'cancel_button'.tr,
                  ),
                ),
                TextButton(
                  onPressed:
                      () => ref
                          .read(
                            navigationService,
                          )
                          .beamPop(true),
                  child: Text('delete_button'.tr),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        await ref
            .read(
              removeCrmRevenueProvider,
            )
            .removeCrmRevenue(
              actionId,
            );
      }
      },

      child: AppIcons.delete(color: AppColors.white),
    ),



    PieAction(
      tooltip: Text('edit_transaction'.tr, style: TextStyle(color: theme.textColor),),
      onSelect: () async {
        await PopPageManager.show(
          autoHeight: true,
          width: MediaQuery.of(context).size.height * 0.9,
          context,
          child: (moduleRegistry.slot('crm.transactionDetailsEditor')?.call(context, {'transaction': action})) ?? const SizedBox.shrink(),
          tag: 'tx-edit-$actionId',
          shouldBeADrawer: true, 
          isNamedRoute: false,
        );
      },

      child: AppIcons.pencil(color: AppColors.white),
    ),

    PieAction(
      tooltip: Text('manage_transaction'.tr,style: TextStyle(color: theme.textColor),),
      onSelect: () async {
        await PopPageManager.show(
          autoHeight: true,
          context,
          child: ManageTransaction(transaction: action, textColor: textColor),
          tag: 'tx-manage-$actionId',
          shouldBeADrawer: true, 
          isNamedRoute: false,
        );
      },

      child: AppIcons.document(color: AppColors.white),
    ),



  ];
}

extension ContextExtension on BuildContext {
  void showSnackBarLikeSection(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
