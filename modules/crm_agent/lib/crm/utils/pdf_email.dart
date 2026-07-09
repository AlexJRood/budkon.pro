import 'dart:convert';

import 'package:crm_agent/crm/widgets/invoice_pdf.dart' show InvoicePdf;
import 'package:crm_agent/models/expense/crm_expenses_download_model.dart'
    show CrmExpensesDownloadModel;
import 'package:crm_agent/models/revenue_model.dart' show AgentRevenueModel;
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart' show ApiServices;
import 'package:core/theme/apptheme.dart' show ThemeColors;

Future<void> onTapEmailInvoice({
  required BuildContext context,
  required ThemeColors theme,
  required Object data, // AgentRevenueModel | CrmExpensesDownloadModel
  required String? clientEmail, // prefill from client
}) async {
  final subjectCtrl = TextEditingController(
    text: '${'invoice_email_subject_prefix'.tr} ${_invoiceNo(data)} ${'invoice_email_subject_suffix'.tr}'

  );
  final toCtrl = TextEditingController(text: clientEmail ?? '');
  final ccCtrl = TextEditingController();
  final bccCtrl = TextEditingController();
  final msgCtrl = TextEditingController(
   text: '${'invoice_email_body_hello'.tr}\n\n${'invoice_email_body_message'.tr} ${_invoiceNo(data)}.\n\n${'invoice_email_body_best_regards'.tr}\nHOUSLY'
  );

  bool attachPdf = true;
  bool includeLink = true;

  final sent = await showDialog<bool>(
    context: context,
    builder:
        (_) => AlertDialog(
          title: Text('send_invoice_title'.tr),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: toCtrl,
                  decoration: InputDecoration(labelText: 'to_label'.tr),
                ),
                TextField(
                  controller: ccCtrl,
                  decoration: InputDecoration(labelText: 'cc_label'.tr),
                ),
                TextField(
                  controller: bccCtrl,
                  decoration: InputDecoration(labelText: 'bcc_label'.tr),
                ),
                TextField(
                  controller: subjectCtrl,
                  decoration:  InputDecoration(labelText: 'subject_label'.tr),
                ),
                TextField(
                  controller: msgCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(labelText:'message_label'.tr),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatefulBuilder(
                      builder:
                          (c, set) => Checkbox(
                            value: attachPdf,
                            onChanged: (v) {
                              set(() => attachPdf = v ?? true);
                            },
                          ),
                    ),
                    Text('attach_pdf'.tr),
                  ],
                ),
                Row(
                  children: [
                    StatefulBuilder(
                      builder:
                          (c, set) => Checkbox(
                            value: includeLink,
                            onChanged: (v) {
                              set(() => includeLink = v ?? true);
                            },
                          ),
                    ),
                    Text('include_secure_link'.tr)
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel_button'.tr)
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('send_button'.tr)
            ),
          ],
        ),
  );

  if (sent != true) return;
  if ((toCtrl.text).trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('recipient_email_required'.tr))
    );
    return;
  }

  // 1) Build PDF (bytes)
  final pdfBytes = await InvoicePdf.build(theme: theme, data: data);
  final filename =
      'INV-${_invoiceNo(data).isEmpty ? DateTime.now().millisecondsSinceEpoch : _invoiceNo(data)}.pdf';

  // 2) (Optional) upload PDF to get a secure URL
  String? pdfUrl;
  // if (includeLink) {
  //   final uploadRes = await ApiServices.post(
  //     '/files/upload',
  //     fileField: 'file',
  //     filename: filename,
  //     bytes: pdfBytes,
  //     contentType: 'application/pdf',
  //   );
  //   pdfUrl = uploadRes.data['url'] as String?;
  // }

  // 3) Send email via backend
  // Attach PDF as base64 only if attachPdf == true
  final payload = {
    'to': toCtrl.text,
    'cc': ccCtrl.text,
    'bcc': bccCtrl.text,
    'subject': subjectCtrl.text,
    'message': msgCtrl.text,
    'invoice_id': _invoiceId(data), // if you have it
    'pdf_filename': attachPdf ? filename : null,
    'pdf_base64': attachPdf ? base64Encode(pdfBytes) : null,
    'pdf_url': pdfUrl,
  };

  try {
    await ApiServices.post('/invoices/send-email', data: payload);
    // 4) mark as sent (optional separate endpoint)
    await ApiServices.post(
      '/invoices/${_invoiceId(data)}/mark-sent',
      data: {'sent_at': DateTime.now().toIso8601String()},
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('invoice_emailed_success'.tr))
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${'failed_to_send'.tr}: $e')));
  }
}

String _invoiceNo(Object data) {
  if (data is AgentRevenueModel) return data.invoiceNumber ?? '';
  if (data is CrmExpensesDownloadModel) return data.invoiceNumber ?? '';
  return '';
}

int? _invoiceId(Object data) {
  if (data is AgentRevenueModel) return data.id;
  if (data is CrmExpensesDownloadModel) return data.id;
  return null;
}

/// Email send to backend

// {
//   "to": "client@domain.com",
//   "cc": "acc@domain.com",
//   "bcc": "",
//   "subject": "Invoice #123 from HOUSLY",
//   "message": "…",
//   "invoice_id": 123,
//   "pdf_filename": "INV-123.pdf",
//   "pdf_base64": "<base64 bytes>",    // optional
//   "pdf_url": "https://…/INV-123.pdf" // optional
// }
