import 'package:flutter/material.dart';
import 'package:crm/shared/models/bill_model.dart';
import 'package:get/get_utils/get_utils.dart';

// import 'package:printing/printing.dart';

class PdfPreviewPage extends StatelessWidget {
  final BillModel bill;
  const PdfPreviewPage({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Bill Preview'.tr),
      ),
      // body: InteractiveViewer(
      //   panEnabled: false,
      //   boundaryMargin: const EdgeInsets.all(80),
      //   minScale: 0.5,
      //   maxScale: 4,
      //   child: PdfPreview(
      //     loadingWidget: const CupertinoActivityIndicator(),
      //     build: (context) => pdfBuilder(bill),
      //   ),
      // ),
    );
  }
}
