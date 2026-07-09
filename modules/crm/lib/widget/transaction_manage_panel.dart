import 'package:core/ui/device_type_util.dart';
import 'package:crm/widget/manage_transaction.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

class TransactionManagePanel extends ConsumerWidget {
  final AgentTransactionModel transaction;
  final bool isMobile;

  const TransactionManagePanel({
    super.key,
    required this.transaction,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    // Dla nowych transakcji (id==0) nie ma sensu pokazywać complete/archive/reopen
    final isNew = transaction.id == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: theme.themeColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'manage_transaction_title'.tr,
                style: TextStyle(
                  color: theme.themeTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              AppIcons.setting(color: theme.themeTextColor),
            ],
          ),
        ),

        // Body
        Container(
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: isNew
              ? _NewTxInfo(theme: theme)
              : ManageTransaction(
                  transaction: transaction,
                  textColor: theme.textColor,
                  isClientView: true,
                ),
        ),

        SizedBox(height: BottomBarSize.resolve(context))
      ],
    );
  }
}

class _NewTxInfo extends StatelessWidget {
  final ThemeColors theme;
  const _NewTxInfo({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.bordercolor),
      ),
      child: Row(
        children: [
          AppIcons.moreVertical(color: theme.textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'save_transaction_first_message'.tr,
              style: AppTextStyles.interRegular14.copyWith(color: theme.textColor),
            ),
          ),
        ],
      ),
    );
  }
}
