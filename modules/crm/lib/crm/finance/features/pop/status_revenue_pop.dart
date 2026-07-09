import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:crm/crm/finance/features/revenue/revenue_status_dialog.dart';
import 'package:crm/shared/models/revenue_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatusPopRevenue extends ConsumerWidget {
  final AgentRevenueModel? transaction;
  final bool isFilter;
  const StatusPopRevenue({
    super.key, this.transaction, required this.isFilter});


  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return PopPageManager(
      isNamedRoute: true,
              tag: 'StatusPopRevenue-${UniqueKey().toString()}',
            child: RevenueStatusDialog(contact: transaction, isFilter: isFilter,),
    );
  }
}
