import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:crm/data/finance/remove_expenses.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:pie_menu/pie_menu.dart';

List<PieAction> pieMenuCrmExpenses(
    WidgetRef ref, dynamic action, dynamic actionId, BuildContext context) {
  return [
    PieAction(
      tooltip: Text('delete_revenue'.tr),
      onSelect: () async {
        final confirmed = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('confirmation_title'.tr),
            content:
                Text('confirm_delete_revenue'.tr),
            actions: [
              TextButton(
                onPressed: () => ref.read(navigationService).beamPop(false),
                child:  Text('cancel_button'.tr),
              ),
              TextButton(
                onPressed: () => ref.read(navigationService).beamPop(true),
                child:  Text('delete_button'.tr),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await ref.read(removeCrmExpensesProvider).removeCrmExpenses(action);
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
