import 'package:core/ui/device_type_util.dart';
import 'package:crm/contact_panel/viewer/viewer_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';




enum AdViewMode { calendar, list, board }

class ViewerClientView extends ConsumerWidget {
  final int clientId;
  final AgentTransactionModel transaction;
  final bool isMobile;

  const ViewerClientView({
    super.key,
    this.isMobile = false,
    required this.clientId,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Column(
      children: [    
            // SizedBox(
            //   height: isMobile ? TopAppBarSize.resolve(context) : 0 
            // ),
        Expanded(
          child: Builder(
            builder: (_) {
              return ViewerListClientTable( transactionId: transaction.id, clientId: clientId, isMobile: isMobile);
            },
          ),
        ),
      ],
    );
  }
}