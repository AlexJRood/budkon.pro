import 'package:crm/contact_panel/components/transaction_success_tile.dart';
import 'package:crm/contact_panel/components/transaction_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/contact_panel/components/client_text_styles.dart';
import 'package:core/theme/lottie.dart';
import 'package:crm/contact_panel/data/client_view_db_calendar_provider.dart';

import 'package:get/get_utils/get_utils.dart';

class NewClientMobileTransaction extends ConsumerStatefulWidget {
  final int id;

  final dynamic data;
  const NewClientMobileTransaction({
    super.key,
    required this.id,
    required this.data,
  });

  @override
  ConsumerState<NewClientMobileTransaction> createState() => _NewClientMobileTransactionState();
}

class _NewClientMobileTransactionState extends ConsumerState<NewClientMobileTransaction> {

  @override
  void initState() {
   
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        ref.read(calendarTransActionByClientProvider.notifier)
            .getTransActionByClient(widget.data.id.toString());
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final transactionData = ref.watch(calendarTransActionByClientProvider);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(5),
      ),
      height: 500,
      child: transactionData.isEmpty
          ? Center(child: AppLottie.noResults(size: 450))
          :ListView.builder(
        addAutomaticKeepAlives: false,
        cacheExtent: 300.0,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: transactionData.length,
        itemBuilder: (context, index) {
          final transaction = transactionData[index];
          final commision = transaction.isCommisssionPercentage ? '%' : transaction.currency;


          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 22,
                    child: Row(
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: (transaction.client.avatar == null ||
                              transaction.client.avatar!.isEmpty)
                              ? Image.asset(
                            'assets/images/image.png',
                            fit: BoxFit.cover,
                          )
                              : Image.network(
                            transaction.client.avatar!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                Image.asset(
                                  'assets/images/image.png',
                                  fit: BoxFit.cover,
                                ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.client.name,
                                style: customtextStyle(context, ref),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                transaction.transactionType,
                                style: textStylesubheading(context, ref),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Text(transaction.transactionType,
                        style: customtextStyle(context, ref)),
                  ),
                  Expanded(
                    flex: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Paymentstatuscontainer(
                              status: transaction.status ?? 'Unknown'.tr),
                        ),
                        const Expanded(flex: 2, child: SizedBox())
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(transaction.amount,
                            style: customtextStyle(context, ref)),
                        Text(
                          transaction.currency,
                          style: textStylesubheading(context, ref),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 9,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${transaction.commission} $commision',
                          style: textStylesubheading(context, ref),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Text(transaction.dateCreate.toString(),
                        style: customtextStyle(context, ref)),
                  ),
                  Expanded(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                       Text(
                          (transaction.paymentMethods?.trim().isNotEmpty ?? false)
                              ? transaction.paymentMethods!.trim()
                              : 'No Payment Method'.tr,
                          style: customtextStyle(context, ref),
                        ),

                        Text(
                          transaction.name,
                          style: textStylesubheading(context, ref),
                        )
                      ],
                    ),
                  ),
                   Expanded(flex: 5, child: Customiconbuttom(clientId: widget.id.toString(),transactionId: transaction.id.toString(),)),
                ],
              ),
              Divider(
                  color: const Color.fromARGB(255, 109, 109, 109)
                      .withAlpha((255 * 0.2).toInt())),
            ],
          );
        },
      ),
    );
  }
}
