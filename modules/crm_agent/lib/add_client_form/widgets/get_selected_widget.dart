import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/add_client_form/provider/send_form_provider.dart';
import 'package:crm_agent/add_client_form/widgets/sell.dart';
import 'package:crm_agent/add_client_form/components/event/event_view_widget.dart';
import 'package:crm_agent/add_client_form/widgets/buy.dart';
import 'package:get/get_utils/get_utils.dart';



class GetSelectedWidget extends ConsumerWidget {

  final GlobalKey<FormState> sellFormKey;
  final GlobalKey<FormState> buyFormKey;
  final bool isMobile;
  const GetSelectedWidget(
      {super.key,
      required this.sellFormKey,
      required this.buyFormKey,

      this.isMobile = false});
@override
Widget build(BuildContext context, WidgetRef ref) {
  final selectedTab = ref.watch(selectedTabProvider);
  final view = 'VIEW'.tr;
  final sell = 'SELL'.tr;
  final buy = 'BUY'.tr;

  if (selectedTab == view) {
    return ViewWidget(isMobile: isMobile);
  } else if (selectedTab == sell) {
    return SellWidget(formKey: sellFormKey, isMobile: isMobile);
  } else if (selectedTab == buy) {
    return BuyWidget(buyFormKey: buyFormKey, isMobile: isMobile);
  } else {
    return const SizedBox();
  }
}

}
