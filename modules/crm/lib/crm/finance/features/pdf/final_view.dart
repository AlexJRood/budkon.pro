import 'package:crm/shared/models/bill_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/navigation_service.dart';

import 'package:get/get_utils/get_utils.dart';

class FinalView extends ConsumerWidget {
  FinalView({super.key});

  final bills = <BillModel>[
    // BillModel(transactionid: transactionid, client: client, amount: amount, date: date, paymentMethod: paymentMethod, note: note, status: status, transactionName: transactionName, invoiceNumber: invoiceNumber, address: address, name: name, items: items, invoiceData: invoiceData)
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Bills'.tr), centerTitle: true),
      body: ListView(
        children: [
          ...bills.map(
            (billModel) => ListTile(
              title: Text(billModel.name),
              subtitle: Text(billModel.client),
              trailing: Text('\$${billModel.totalCost().toStringAsFixed(2)}'),
              onTap: () => ref.read(navigationService).pushNamedScreen(
                Routes.detail,
                data: {'singleBillItem': billModel},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
