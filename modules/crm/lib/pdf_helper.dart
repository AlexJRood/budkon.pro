import 'dart:typed_data';
import 'package:crm/shared/models/bill_model.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:get/get_utils/get_utils.dart';

Future<Uint8List> pdfBuilder(BillModel bill) async {
  final pdf = Document();
  final imageLogo = MemoryImage(
      (await rootBundle.load('assets/tec-1.png')).buffer.asUint8List());
  pdf.addPage(
    Page(
      build: (context) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${'attention_to_label'.tr} ${bill.client}".tr),
                    Text(bill.address),
                  ],
                ),
                SizedBox(height: 150, width: 150, child: Image(imageLogo)),
              ],
            ),
            Container(height: 50),
            Table(
              border: TableBorder.all(color: PdfColors.black),
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'bill_for_payment_title'.tr,
                        style: Theme.of(context).header4,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                ...bill.items.map(
                  (e) => TableRow(
                    children: [
                      Expanded(
                        flex: 2,
                        child: textAndPadding(e.description),
                      ),
                      Expanded(
                        flex: 1,
                        child: textAndPadding("\$${e.cost}"),
                      )
                    ],
                  ),
                ),
                TableRow(
                  children: [
                    textAndPadding('tax_label'.tr, align: TextAlign.right),
                    textAndPadding(
                        '\$${(bill.totalCost() * 0.1).toStringAsFixed(2)}'),
                  ],
                ),
                TableRow(
                  children: [
                    textAndPadding('total_label'.tr, align: TextAlign.right),
                    textAndPadding(
                        '\$${(bill.totalCost() * 1.1).toStringAsFixed(2)}')
                  ],
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'thank_you_for_custom'.tr,
                style: Theme.of(context).header2,
              ),
            ),
            Text(
                'forward_slip_message'.tr),
            Divider(
              height: 1,
            ),
            Container(height: 50),
            Table(
              border: TableBorder.all(color: PdfColors.black),
              children: [
                TableRow(
                  children: [
                    textAndPadding('account_number_label'.tr),
                    textAndPadding(
                      '1234 1234',
                    )
                  ],
                ),
                TableRow(
                  children: [
                    textAndPadding(
                      'account_name_label'.tr
                    ),
                    textAndPadding(
                      'account_name_value'.tr,
                    )
                  ],
                ),
                TableRow(
                  children: [
                    textAndPadding(
                      'total_amount_to_be_paid_label'.tr,
                    ),
                    textAndPadding(
                        '\$${(bill.totalCost() * 1.1).toStringAsFixed(2)}')
                  ],
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Text(
                'cheques_payable_message'.tr,
                style: Theme.of(context).header2,
                textAlign: TextAlign.center,
              ),
            )
          ],
        );
      },
    ),
  );
  return pdf.save();
}

Widget textAndPadding(
  final String text, {
  final TextAlign align = TextAlign.left,
}) =>
    Padding(
      padding: const EdgeInsets.all(1),
      child: Text(
        text,
        textAlign: align,
      ),
    );
