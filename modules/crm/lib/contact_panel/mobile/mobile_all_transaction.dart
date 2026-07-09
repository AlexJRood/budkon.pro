import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/contact_panel/components/const.dart';
import 'package:crm/contact_panel/components/client_text_styles.dart';

import 'package:get/get_utils/get_utils.dart';

class MobileAllTransaction extends ConsumerStatefulWidget {
  const MobileAllTransaction({super.key});

  @override
  _MobileAllTransactionState createState() => _MobileAllTransactionState();
}

class _MobileAllTransactionState extends ConsumerState<MobileAllTransaction> {
  List<Map<String, String>> filteredTransactions = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredTransactions = List.from(transactions);
  }

  void filterSearchResults(String query) {
    setState(() {
      filteredTransactions = transactions.where((transaction) {
        String project = transaction['project']!.toLowerCase();
        String status = transaction['status']!.toLowerCase();
        String amount = transaction['amount']!.toLowerCase();

        return project.contains(query.toLowerCase()) ||
            status.contains(query.toLowerCase()) ||
            amount.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    return Scaffold(
      backgroundColor: theme.checkoutbackground,
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                const SizedBox(
                  width: 10,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                  ),
                  onPressed: () {
                    ref.read(navigationService).beamPop();
                  },
                ),
                const Spacer(),
                Text(
                  "Transaction".tr,
                  style: TextStyle(
                      color: theme.mobileTextcolor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  width: 30,
                ),
                const Spacer(),
                Icon(
                  Icons.add,
                  color: theme.mobileTextcolor,
                ),
              ],
            ),
            Divider(
              color: theme.mobileTextcolor.withAlpha((255 * 0.2).toInt()),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                style: TextStyle(color: theme.mobileTextcolor),
                controller: searchController,
                onChanged: filterSearchResults,
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(0),
                    fillColor: Colors.transparent,
                    filled: true,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.mobileTextcolor),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    hintText: "Search ...".tr,
                    hintStyle: TextStyle(color: theme.mobileTextcolor),
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.mobileTextcolor,
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    )),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: theme.checkoutbackground,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ListView.builder(
                  addAutomaticKeepAlives: false,
                  cacheExtent: 300.0,
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
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
                                    child: Image.asset(
                                      'assets/images/image.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaction['project']!,
                                          style: customtextStyle(context, ref),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines:
                                              1, // Truncates text to prevent overflow
                                        ),
                                        Text(
                                          transaction['location']!,
                                          style:
                                              textStylesubheading(context, ref),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines:
                                              1, // Truncates text to prevent overflow
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 8,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction['amount']!,
                                    style: customtextStyle(context, ref),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    '${transaction['amounteuro']!} EUR',
                                    style: textStylesubheading(context, ref),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          color: const Color.fromARGB(255, 161, 161, 161)
                              .withAlpha((255 * 0.2).toInt()),
                        ),
                      ],
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
