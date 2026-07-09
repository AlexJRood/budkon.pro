import 'package:core/ui/device_type_util.dart';
import 'package:crm/contact_panel/sections/fav_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';




enum AdViewMode { list, grid, map }

class FavClientView extends ConsumerWidget {
  final int clientId;
  final AgentTransactionModel transaction;
  final bool isMobile;

  const FavClientView({
    super.key,
    this.isMobile = false,
    required this.clientId,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Column(
      children: [    
            SizedBox(
              height: isMobile ? TopAppBarSize.resolve(context) : 0 
            ),
        Expanded(
          child: Builder(
            builder: (_) {
              return FavListClientTable( transactionId: transaction.id, clientId: clientId, isMobile: isMobile);
            },
          ),
        ),
      ],
    );
  }
}