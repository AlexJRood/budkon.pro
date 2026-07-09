import 'package:crm_agent/add_client_form/widgets/buy_recent_search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/add_client_form/controllers/transaction_controlers.dart';
import 'package:crm_agent/add_client_form/widgets/transaction.dart';
import 'package:crm_agent/add_client_form/components/event/event_view_widget.dart';

class BuyWidget extends ConsumerWidget {
  final GlobalKey<FormState> buyFormKey;

  final bool isMobile;

  const BuyWidget({super.key, required this.buyFormKey, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tranactionIsSellerController = ref.watch(
      transactionControllersProvider,
    );
    tranactionIsSellerController.isBuyerController.value = true;

    return Form(
      key: buyFormKey,
      child: Column(
        spacing: 20,
        children: [
          BuyRecentSearchWidget(isMobile: isMobile),
          TransactionCardWidget(isMobile: isMobile),
          ViewWidget(isMobile: isMobile),
        ],
      ),
    );
  }
}
